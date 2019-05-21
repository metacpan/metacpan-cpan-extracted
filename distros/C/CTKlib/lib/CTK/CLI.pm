package CTK::CLI; # $Id: CLI.pm 253 2019-05-09 19:32:24Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::CLI - Command line interface

=head1 VERSION

Version 1.72

=head1 SYNOPSIS

    use CTK::CLI qw/cli_prompt cli_select/;

    my $v = cli_prompt('Your name:', 'anonymous');
    debug( "Your name: $v" );

    my $v = cli_select('Your select:',[qw/foo bar baz/],'bar');
    debug( "Your select: $v" );

or in CTK context (as plugin):

    my $v = $ctk->cli_prompt('Your name:', 'anonymous');
    debug( "Your name: $v" );

    my $v = $ctk->cli_select('Your select:',[qw/foo bar baz/],'bar');
    debug( "Your select: $v" );

=head1 DESCRIPTION

Command line interface. Prompt and select methods

=head2 cli_prompt

    my $v = cli_prompt('Your name:', 'anonymous');
    debug( "Your name: $v" );

Show prompt string for typing data

=head2 cli_select

    my $v = cli_select('Your select:',[qw/foo bar baz/],'bar');
    debug( "Your select: $v" );

Show prompt string for select item

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<ExtUtils::MakeMaker>

=head1 TO DO

  * Use Term::ReadLine module. Sample:

    BEGIN { $ENV{TERM} = "dumb" if $^O eq "MSWin32" }
    use Term::ReadLine ();
    use Text::ParseWords qw(shellwords);

    my $term = new Term::ReadLine 'T01';
    my $prompt = "T> ";
    my $OUT = $term->OUT || \*STDOUT;
    while ( defined ($_ = $term->readline($prompt)) ) {
        last if /^(quit|exit)$/;
        my @w = shellwords($_);
        if (@w) {
        print join(" ",@w),"\n";
            $term->addhistory($_);
        }
    }
    print "\n";

=head1 BUGS

* none noted

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/$VERSION @EXPORT_OK/;
$VERSION = '1.72';

use base qw/Exporter/;

use ExtUtils::MakeMaker qw/prompt/;

@EXPORT_OK = (qw/
        cli_prompt cli_select
    /);

sub cli_prompt {
    # my $a = prompt('Input value a', '123');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]));
    my $msg = shift;
    my $def = shift;
    return prompt($msg, $def)
}
sub cli_select {
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]));
    my $msg = shift;
    my $sel = shift || [];
    my $def = shift;

    my $v = _cli_select($sel);
    my $d = defined($def) ? $def : $v->[1];
    print($v->[1],"\n") if $v->[0];
    $v = cli_prompt(defined($msg) ? $msg : '', $d);
    $v = _cli_select($sel, $v);

    return $v->[0] ? '' : $v->[1];
}

sub _cli_select {
    # Returns value or list of value, or defult value
    # First element - 0 - value/default value
    #                 1 - List of values
    my $v = shift;
    my $sel = shift;
    if (defined $v) {
        if (ref $v eq 'ARRAY') {
            if (defined($sel) && ($sel =~ /^\d+$/) && exists($v->[$sel-1])) {
                return [0,$v->[$sel-1]];
            } elsif (defined($sel) && grep {$_ eq $sel} @$v) {
                return [0,$sel];
            } else {
                my $c=0;
                my @r=();
                foreach (@$v) {$c++; push @r, "$c) $_"}
                return [1,"Select one item:\n\t".join(";\n\t",@r)."\n"];
            }
        } else {
            return [0,defined $sel ? $sel : $v];
        }
    } else {
        return [0,''];
    }
}

1;

__END__
