package CPAN::FindDependencies::MakeMaker;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);

use File::Temp qw(tempdir);
use Cwd qw(getcwd abs_path);
use Capture::Tiny qw(capture);
use Config;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( getreqs_from_mm );

$VERSION = '1.0';

=head1 NAME

CPAN::FindDependencies::MakeMaker - retrieve dependencies specified in Makefile.PL's

=head1 SYNOPSIS

Dependencies are also specified in Makefile.PL files used with the ExtUtils::MakeMaker module.

=head1 FUNCTIONS

=over

=item getreqs_from_mm

Expects the contents of a Makefile.PL as a string.

Returns a hash reference of the form:

    {
        Module::Name => 0.1,
        ...
        Last::Module => 9.0,
    }

=back

=cut

sub getreqs_from_mm {
    my $MakefilePL = shift;
    local $/ = undef;

    my $cwd = getcwd();
    my $tempdir = tempdir(CLEANUP => 1);
    chdir($tempdir);

    # write Makefile.PL ...
    open(my $MKFH, '>Makefile.PL') || die("Can't write Makefile.PL in $tempdir\n");
    print $MKFH $MakefilePL;
    close($MKFH);

    if ($^O eq 'MSWin32') {
        # NB *not* for Cygwin, hence not Devel::CheckOS MicrosoftWindows
        require Win32::Job;
        my $job = Win32::Job->new;
        $job->spawn($Config{perlpath}, "perl Makefile.PL", {stdin  => 'NUL', 'stdout'=>'stdout.log','stderr'=>'stderr.log'});
        unless ($job->run(10)) {
            chdir($cwd);
            return "Makefile.PL didn't finish in a reasonable time\n";
        }
    } else {
        # execute, suppressing noise ...
        eval { capture {
            if(my $pid = fork()) { # parent
                local $SIG{ALRM} = sub {
                    kill 9, $pid; # quit RIGHT FUCKING NOW
                    die("Makefile.PL didn't finish in a reasonable time\n");
                };
                alarm(10);
                waitpid($pid, 0);
                alarm(0);
            } else {
                exec($Config{perlpath}, 'Makefile.PL');
            }
        } };
        if($@) {
            chdir($cwd);
            return $@;
        }
    }

    # read Makefile
    open($MKFH, 'Makefile') || warn "Can't read Makefile\n";
    my $makefile_str = <$MKFH>;
    close($MKFH);
    chdir($cwd);

    return _parse_makefile( $makefile_str );
}

sub _parse_makefile {
    my $makefile_str = shift;
    return "Unable to get Makefile" unless defined $makefile_str;
    my %required_version_for;
    my @prereq_lines = grep { /^\s*#.*PREREQ/ } split /\n/, $makefile_str;
    for my $line ( @prereq_lines ) {
        if ( $line =~ /PREREQ_PM \s+ => \s+ \{ \s* (.*) \s* \} $/x ) {
            no strict 'subs';
            %required_version_for = eval "( $1 )";
            return "Failed to eval $1: $@" if $@;
            use strict 'subs';
        } else {
            return "Unrecognized PREREQ line in Makefile.PL:\n$line";
        }
    }
    return \%required_version_for;
}

=head1 SECURITY

This module assumes that its input is trustworthy and can be safely
executed.  The only protection in place is that a vague attempt is made
to catch a Makefile.PL that just sits there doing nothing - either if it's
in a loop, or sitting at a prompt.  But even that can be defeated by
an especially naughty person.

=head1 BUGS/LIMITATIONS

Makefile.PLs that have external dependencies/calls that can fatally die will
not be able to be successfully parsed and then scanned for dependencies, e.g.
libwww-perl.5808.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-CPAN-FindDependencies.git>

=head1 SEE ALSO

L<CPAN::FindDepdendencies>

L<CPAN>

L<http://deps.cpantesters.org>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2009 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt> based largely
on code by Ian Tegebo (see L<http://rt.cpan.org/Public/Bug/Display.html?id=34814>)

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
