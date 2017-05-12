package Carp::Growl;

use warnings;
use strict;
use Carp;

use version; our $VERSION = '0.0.10';

use Growl::Any;

my $build_warnmess;

my $DEFAULT_FUNCS = +{};

BEGIN {
    $build_warnmess = sub {
        my ( $func, @args ) = @_;
        my ( $pkg, $file, $line ) = caller(1);
        my $self;
        unless (@args) {
            unshift @args,
                ( $func eq 'warn' ? "Warning: something's wrong" : "Died" );
        }
        $self = join( $", @args );
        unless ( $self =~ s/\n \z//msx ) {
            $self .= " at $file line $line.";
        }
        $self;
    };
}

if ( $] < 5.016000 ) {
    @{$DEFAULT_FUNCS}{qw/warn die/} = (
        sub { CORE::warn( $build_warnmess->( 'warn', @_ ), $/ ); },
        sub { CORE::die( $build_warnmess->( 'die', @_ ), $/ ); },
    );
}
else {
    $DEFAULT_FUNCS->{warn} = \&CORE::warn;
    $DEFAULT_FUNCS->{die}  = \&CORE::die;
}

my $g = Growl::Any->new( appname => __PACKAGE__, events => [qw/warn die/] );

our @CARP_NOT;

my $KEEP     = {};
my $imported = 0;

my $AVAILABLE_IMPORT_ARGS = [qw/global/];

my $validate_args = sub {
    my %bads;
    for my $good (@$AVAILABLE_IMPORT_ARGS) {
        $bads{$_}++ for grep { $_ ne $good } @_;
    }
    keys %bads;
};
for my $f (qw/carp croak/) {
    no strict 'refs';
    $DEFAULT_FUNCS->{$f} = *{ 'Carp::' . $f }{CODE};
}
my $BUILD_FUNC_ARGS = +{
    warn  => { event => 'warn', title => 'WARNING', },
    die   => { event => 'die',  title => 'FATAL', },
    carp  => { event => 'warn', title => 'WARNING', },
    croak => { event => 'die',  title => 'FATAL', },
};

sub _build_func {
    my $func = shift;
    if ( ( $func eq 'warn' || $func eq 'die' ) ) {
        return sub {
            $g->notify(
                $BUILD_FUNC_ARGS->{$func}->{event},    # event
                $BUILD_FUNC_ARGS->{$func}->{title},    # title
                $build_warnmess->( $func, @_ ),        # message
                undef,                                 # icon
                )
                if defined $^S;
            goto &{ $DEFAULT_FUNCS->{$func} };
        };
    }
    else {
        return sub {
            no strict 'refs';
#            if ( caller eq 'main' ) {
#                local *{'main::CARP_NOT'};
#                push @{ *{'main::CARP_NOT'} }, __PACKAGE__;
#            }
            my $msg = Carp::shortmess(@_);
            chomp $msg;
            $g->notify(
                $BUILD_FUNC_ARGS->{$func}->{event},    # event
                $BUILD_FUNC_ARGS->{$func}->{title},    # title
                $msg,                                  # message
                undef,                                 # icon
                )
                if defined $^S;
            goto &{ $DEFAULT_FUNCS->{$func} };
        };
    }
}

##~~~~~  IMPORT  ~~~~~##

sub import {
    my $self = shift;
    my @args = @_;
    if (@args) {
        my @bads = $validate_args->(@args);
        CORE::die 'Illegal args: "'
            . join( '", "', @bads )
            . '" for import()'
            if @bads;
        $imported = 2;
        goto &_global_import if grep { $_ eq 'global' } @args;
    }
    else {
        $imported = 1;
    }
    goto &_local_import;
}

sub _local_import {
    my $args = @_ ? \@_ : [ keys %$BUILD_FUNC_ARGS ];
    my $pkg = caller();
    no strict 'refs';
    for my $func ( keys %$BUILD_FUNC_ARGS ) {
        $KEEP->{$pkg}->{$func} = \&{ *{ $pkg . '::' . $func } }
            if defined *{ $pkg . '::' . $func }{CODE};
    }
    for my $func (@$args) {
        no warnings 'redefine';
        *{ $pkg . '::' . $func } = _build_func($func);
    }
    push @CARP_NOT, $pkg if $pkg ne 'main';
}

sub _global_import {
    no strict 'refs';
    no warnings 'redefine';
    my $pkg = caller;
    for my $func (qw/warn die/) {
        $KEEP->{'CORE::GLOBAL'}->{$func} = \&{ *{ 'CORE::GLOBAL::' . $func } }
            if defined *{ 'CORE::GLOBAL::' . $func }{CODE};
        *{ 'CORE::GLOBAL::' . $func } = _build_func($func);
        $KEEP->{$pkg}->{$func} = \&{ *{ $pkg . '::' . $func } }
            if defined *{ $pkg . '::' . $func }{CODE};
        undef &{ *{ $pkg . '::' . $func } }
            if defined *{ $pkg . '::' . $func }{CODE};
    }
    push @Carp::CARP_NOT, __PACKAGE__;
    @_ = qw/carp croak/;
    goto &_local_import;
}

##~~~~~  UNIMPORT  ~~~~~##

sub unimport {
    my $self = shift;
    my @args = @_;
    CORE::die 'Illegal args: "' . join( '", "', @args ) . '" for unimport()'
        if @args;
    $imported = 0;
    goto &_global_unimport;
}

sub _local_unimport {
    my $args = @_ ? \@_ : [ keys %$BUILD_FUNC_ARGS ];
    my ($pkg) = caller();
    no strict 'refs';
    no warnings 'redefine';
    for my $func (@$args) {
        if ( $KEEP->{$pkg}->{$func} ) {
            *{ $pkg . '::' . $func } = $KEEP->{$pkg}->{$func};
        }
        else {
            undef &{ *{ $pkg . '::' . $func } }
                if defined *{ $pkg . '::' . $func }{CODE};
        }
        @{ *{ $pkg . '::CARP_NOT' } }
            = grep { $_ ne __PACKAGE__ } @{ *{ $pkg . '::CARP_NOT' } };
    }
}

sub _global_unimport {
    no strict 'refs';
    no warnings 'redefine';
    for my $func (qw/warn die/) {
        if ( $KEEP->{'CORE::GLOBAL'}->{$func} ) {
            *{ 'CORE::GLOBAL::' . $func } = $KEEP->{'CORE::GLOBAL'}->{$func};
        }
        elsif ( defined *{ 'CORE::GLOBAL::' . $func }{CODE} ) {
            undef &{ *{ 'CORE::GLOBAL::' . $func } };
        }
    }
#    @_ = qw/carp croak/;
    goto &_local_unimport;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Carp::Growl - Send warnings to Growl


=head1 VERSION

This document describes Carp::Growl version 0.0.7


=head1 SYNOPSIS

    use Carp::Growl;

    warn "Here we are!!"; # display message on Growl notify

=head1 DESCRIPTION

Carp::Growl is a Perl module that can send warning messages to 
notification system such as Growl, and also outputs usual(to tty etc...)

Basically, you write like this to the beginning of your code.

    use Carp::Growl;

This works only in your 'package scope'.
If you want to work it globally, you use with arg 'global'.

    use Carp::Growl 'global';

C<warn> and C<die> are installed to C<CORE::GLOBAL::> name space,
and C<carp> and C<croak> are also installed as package function.

However, you can disable this module,

    no Carp::Growl;


=head1 DIAGNOSTICS

=over

=item C<< Illegal args: "%s"[, "%s"...] for (un)import >>

%s is not correct keyword for import|unimport.

Only C<global> is an available keyword for C<import>,
and C<unimport> takes no keywords.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Carp::Growl requires no environment variables.


=head1 DEPENDENCIES

Growl::Any
Carp
version

=head1 NOTICE

This module is installable even if you have no notification system
that can be used from Growl::Any.
However, it will not be helpful for you.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-carp-growl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

kpee  C<< <kpee.cpanx@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, kpee C<< <kpee.cpanx@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
