package B::CutNPaste;
use strict;
use warnings;
use vars qw( @ISA $VERSION );
use B qw( main_cv main_root main_start );
use B::Deparse;

BEGIN {
    @ISA     = 'B::Deparse';
    $VERSION = '0.31';

    for my $func (qw( begin_av init_av check_av end_av )) {

        ## no critic
        no strict 'refs';
        if ( defined &{"B::$func"} ) {
            B->import($func);
        }
        else {

           # If I couldn't create it, I'll just declare it to keep lint happy.
            eval "sub $func;";
        }
    }

    # B::perlstring was added in 5.8.0
    if ( defined &B::perlstring ) {
        B->import('perlstring');
    }
    else {
        *perlstring = sub { '"' . quotemeta( shift @_ ) . '"' };
    }

}

use Carp 'confess';
use IO::Handle ();

# use Data::Postponed 'postpone_forever';
sub postpone_forever { return shift @_ }

#_# OVERRIDE METHODS FROM B::Deparse
sub new {
    my $class = shift @_;
    my $self  = $class->SUPER::new(@_);
    $self->{__rename_vars} = $ENV{RENAME_VARS};
    $self->{__rename_subs} = $ENV{RENAME_SUBS};
    $self->{linenums} = 1;
    return $self;
}

sub compile {    ## no critic Complex
    my (@args) = @_;

    return sub {
        my $source = '';
        my $self   = __PACKAGE__->new(@args);

        # First deparse command-line args
        if ( defined $^I ) {    # deparse -i
            $source .= q(BEGIN { $^I = ) . perlstring($^I) . qq(; }\n);
        }
        if ($^W) {              # deparse -w
            $source .= qq(BEGIN { \$^W = $^W; }\n);
        }
        ## no critic PackageVar
        if ( $/ ne "\n" or defined $O::savebackslash ) {    # deparse -l -0
            my $fs = perlstring($/) || 'undef';
            my $bs = perlstring($O::savebackslash) || 'undef';
            $source .= qq(BEGIN { \$/ = $fs; \$\\ = $bs; }\n);
        }

        # I need to do things differently depending on the perl
        # version.
        if ( $] >= 5.008 ) {
            if ( defined &begin_av
                and begin_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for begin_av->ARRAY;
            }
            if ( defined &check_av
                and check_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for check_av->ARRAY;
            }
            if ( defined &init_av
                and init_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for init_av->ARRAY;
            }
            if ( defined &end_av
                and end_av->isa('B::AV') )
            {
                $self->todo( $_, 0 ) for end_av->ARRAY;
            }

            $self->stash_subs;
            $self->{curcv}    = main_cv;
            $self->{curcvlex} = undef;
        }
        else {

            # 5.6.x
            $self->stash_subs('main');
            $self->{curcv} = main_cv;
            $self->walk_sub( main_cv, main_start );
        }

        $source .= join "\n", $self->print_protos;
        @{ $self->{subs_todo} }
            = sort { $a->[0] <=> $b->[0] } @{ $self->{subs_todo} };
        $source .= join "\n", $self->indent( $self->deparse( main_root, 0 ) ),
            "\n"
            unless B::Deparse::null main_root;
            # B::Deparse
        my @text;
        while ( scalar @{ $self->{subs_todo} } ) {
            push @text, $self->next_todo;
        }
        $source .= join "\n", $self->indent( join "", @text ), "\n"
            if @text;

        # Print __DATA__ section, if necessary
        my $laststash
            = defined $self->{curcop}
            ? $self->{curcop}->stash->NAME
            : $self->{curstash};
        {
            ## no critic
            no strict 'refs';
            ## use critic
            if ( defined *{ $laststash . "::DATA" } ) {
                if ( eof *{ $laststash . "::DATA" } ) {

                    # I think this only happens when using B::Deobfuscate
                    # on itself.
                    {
                        local $/ = "__DATA__\n";
                        seek *{ $laststash . "::DATA" }, 0, 0;
                        readline *{ $laststash . "::DATA" };
                    }
                }

                $source .= "__DATA__\n";
                $source .= join '', readline *{ $laststash . "::DATA" };
            }
        }

        print($source);

        return;
    };
}

# get rid of %^H data
{
    no warnings 'redefine';
    sub B::Deparse::declare_hinthash {}
}

sub padname {
    my $self    = shift @_;
    my $padname = $self->SUPER::padname(@_);
    $padname =~ s/\w+/XXX/g if $self->{__rename_vars};
    return $padname;
}

sub gv_name {
    my $self = shift;
    my $gv_name = $self->SUPER::gv_name(@_);

    # XXX Somes modules break if we s/_/YYYY/ due to the
    # following:
    #
	#    $body = $kid->first->first->sibling; # skip OP_AND and OP_ITER
	#    if (!is_state $body->first and $body->first->name ne "stub") {
	#        confess unless $var eq '$_'; # XXX here's where we get an empty confess
	#        $body = $body->first;
	#        return $self->deparse($body, 2) . " foreach ($ary)";
	#    }
    # 
    # Also, it's probably only the BEGIN block, but if you rename that, your
    # code parses differently.
    if ( $gv_name ne '_' and $gv_name !~ /BEGIN|CHECK|INIT|END/ ) {
        $gv_name =~ s/\w+/YYYY/g if $self->{__rename_subs};
    }
    return $gv_name;
}

1;

__END__

=head1 NAME

B::CutNPaste

=DESCRIPTION

For internal use only. Used to "normalize" variable and subroutine names.

Ideas stolen from L<B::Deobfuscate> by Joshua ben Jore.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-code-cutnpaste at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Code-CutNPaste>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Code::CutNPaste

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Code-CutNPaste>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Code-CutNPaste>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Code-CutNPaste>

=item * Search CPAN

L<http://search.cpan.org/dist/Code-CutNPaste/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Code::CutNPaste
