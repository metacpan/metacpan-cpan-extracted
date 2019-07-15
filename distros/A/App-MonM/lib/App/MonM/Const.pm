package App::MonM::Const; # $Id: Const.pm 76 2019-07-07 05:20:28Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::Const - Interface for App::MonM general constants

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Const;

=head1 DESCRIPTION

This module provide interface for App::MonM general constants

=head2 SHARED CONSTANTS

=over 4

=item HOSTNAME

    Hostname

=item PREFIX

    Prefix of project

=item PROJECTNAME

    Project name

=item PROJECTNAMEL

    Project name in lower case

=item IS_TTY

    Returns boolean TTY status if current session runs under terminal

=back

=head2 NOT IMPORTED CONSTANTS

=over 4

=item TRUE, FALSE, VOID

    1, 0, '' values

=item OK, DONE, ERROR, SKIPPED, PASSED, FAILED, UNKNOWN, PROBLEM

    Test result statuses

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION @EXPORT @EXPORT_OK/;
$VERSION = '1.00';

use Sys::Hostname qw/hostname/;
use Try::Tiny;

use base qw/Exporter/;

use constant {
        PROJECTNAME         => "MonM",
        PROJECTNAMEL        => "monm",
        PREFIX              => "monm",

        # TTY
        IS_TTY              => (-t STDOUT) ? 1 : 0,
        SCREENWIDTH_DEFAULT => 80,

        # BOOLEAN
        TRUE                => 1,
        FALSE               => 0,
        VOID                => '',

        # Test results
        OK                  => "OK",        # for SMALL operations
        DONE                => "DONE",      # for LONG operations
        ERROR               => "ERROR",     # for operations
        SKIPPED             => "SKIPPED",   # for tests
        PASSED              => "PASSED",    # for tests
        FAILED              => "FAILED",    # for tests
        UNKNOWN             => "UNKNOWN",   # for tests
        PROBLEM             => "PROBLEM",   # for tests
    };

@EXPORT = (qw/
        PROJECTNAME
        PROJECTNAMEL
        PREFIX
        HOSTNAME
        IS_TTY
        SCREENWIDTH
    /);
@EXPORT_OK = (qw/
        TRUE FALSE VOID
        OK DONE ERROR SKIPPED PASSED FAILED UNKNOWN PROBLEM
    /);

my $myhostname = undef;
*HOSTNAME = sub {
    $myhostname ||= (hostname() // 'unknown host');
    return $myhostname;
};

my $myscreenw = undef;
*SCREENWIDTH = sub {
    return $myscreenw if defined $myscreenw;
    if (IS_TTY) {
        try {
            require Term::ReadKey;
            my $w = (Term::ReadKey::GetTerminalSize())[0];
            $myscreenw = $w < SCREENWIDTH_DEFAULT ? SCREENWIDTH_DEFAULT : $w;
        } catch {
            $myscreenw = SCREENWIDTH_DEFAULT;
        };
    } else {
        $myscreenw = SCREENWIDTH_DEFAULT;
    }
    return $myscreenw;
};

1;

__END__
