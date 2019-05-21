package CTK::Skel::Daemon; # $Id: Daemon.pm 266 2019-05-18 07:59:05Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Skel::Daemon - Daemon project skeleton for CTK::Helper

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Daemon project skeleton for CTK::Helper

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<CTK::Skel>, L<CTK::Helper>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant SIGNATURE => "daemon";

use vars qw($VERSION);
$VERSION = '1.00';

sub build {
    my $self = shift;
    my $rplc = $self->{rplc};
    $self->maybe::next::method();
    return 1;
}
sub dirs {
    my $self = shift;
    $self->{subdirs}{(SIGNATURE)} = [
        {
            path => 'bin',
            mode => 0755,
        },
        {
            path => 'lib',
            mode => 0755,
        },
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool {
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;

__DATA__

-----BEGIN FILE-----
Name: %PROJECT_NAMEL%
File: bin/%PROJECT_NAMEL%
Mode: 711

#!/usr/bin/perl -w
use strict; # %DOLLAR%Id%DOLLAR%

%PODSIG%head1 NAME

%PROJECT_NAMEL% - blah-blah-blah

%PODSIG%head1 SYNOPSIS

    %PROJECT_NAMEL% [options] command [args]

    %PROJECT_NAMEL% [-dvty] [-c /path/to/%PROJECT_NAMEL%.conf]
        [-f 1] [-i 6] command [args]

    %PROJECT_NAMEL% start

    %PROJECT_NAMEL% stop

    %PROJECT_NAMEL% status

    %PROJECT_NAMEL% restart

    %PROJECT_NAMEL% reload

%PODSIG%head1 OPTIONS

%PODSIG%over

%PODSIG%item B<-c /path/to/file.conf, --config=/path/to/file.conf>

Sets config file

Default: /etc/%PROJECT_NAMEL%/%PROJECT_NAMEL%.conf

%PODSIG%item B<-d, --debug>

Print debug information on STDOUT

%PODSIG%item B<-f N, --forks=N>

How many forks create on the one process. Default for agent: 1

Default: 1

%PODSIG%item B<-h, --help>

Show short help information and quit

%PODSIG%item B<-H, --longhelp>

Show long help information and quit

%PODSIG%item B<-i VALUE, --interval=VALUE>

Set the interval value between runs of the current and next operations.
For example, "6" i.e. one iteration per 6 seconds in one minute.

Default: 6

%PODSIG%item B<-t, --test>

Enable test mode

%PODSIG%item B<-v, --verbose>

Verbose option. Include Verbose debug data in the STDOUT and to error-log output

%PODSIG%item B<-V, --version>

Print the version number of the program and quit

%PODSIG%back

%PODSIG%head1 COMMANDS

%PODSIG%over

%PODSIG%item B<reload>

    %PROJECT_NAMEL% reload

Reload daemon

%PODSIG%item B<restart>

    %PROJECT_NAMEL% restart

Restart daemon

%PODSIG%item B<start>

    %PROJECT_NAMEL% start

Start daemon

%PODSIG%item B<status>

    %PROJECT_NAMEL% status

Get status of daemon

%PODSIG%item B<stop>

    %PROJECT_NAMEL% stop

Stop daemon

%PODSIG%back

%PODSIG%head1 DESCRIPTION

blah-blah-blah

See C<README> file

%PODSIG%head1 HISTORY

See C<Changes> file

%PODSIG%head1 TO DO

See C<TODO> file

%PODSIG%head1 SEE ALSO

L<CTK>

%PODSIG%head1 AUTHOR

%AUTHOR% L<%HOMEPAGE%> E<lt>%ADMIN%E<gt>

%PODSIG%head1 COPYRIGHT

Copyright (C) %YEAR% %AUTHOR%. All Rights Reserved

%PODSIG%head1 LICENSE

This program is distributed under the GNU GPL v3.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

%PODSIG%cut

use Getopt::Long;
use Pod::Usage;
use Sys::Syslog qw//;
use CTK::App;
use CTK::Daemon;
use %PROJECT_NAME%;

my %options;
Getopt::Long::Configure("bundling");
GetOptions(\%options,
    # NoUsed keys map:
    #
    # a A b B   C   D e E
    #   F g G       I j J
    # k K l L m M n N o O
    # p P q Q r R s S   T
    # u U     w W x X y Y
    # z Z
    "help|usage|h",         # Show help page
    "longhelp|H",           # Show long help page
    "version|ver|V",        # Show version
    "debug|d",              # Debug mode
    "verbose|v",            # Verbose mode
    "test|testmode|t",      # Test mode
    "config|c=s",           # Config file
    "interval|i=i",         # Operation interval (5, 10, 20, 30 secs)
    "forks|f=i",            # Forks
) || pod2usage(-exitval => 1, -verbose => 0, -output => \*STDERR);
pod2usage(-exitval => 0, -verbose => 1) if $options{help};
pod2usage(-exitval => 0, -verbose => 2) if $options{longhelp};
printf("Version: %s\n", %PROJECT_NAME%->VERSION) && exit(0) if $options{version};
my $command = shift(@ARGV);
my @arguments = @ARGV ? @ARGV : ();
pod2usage(-exitval => 1, -verbose => 99, -sections => 'SYNOPSIS|OPTIONS|COMMANDS', -output => \*STDERR)
    unless $command && grep {$_ eq $command} @{(CTK::Daemon::LSB_COMMANDS())};

# CTK Singleton instance
my $ctk = new CTK::App(
        project => '%PROJECT_NAME%',
        #ident   => '%PROJECT_NAMEL%',
        options => {%options},
        debug   => $options{debug},
        verbose => $options{verbose},
        log     => 1,
        test    => $options{test},
        logfacility => Sys::Syslog::LOG_DAEMON,
        $options{config} ? (configfile => $options{config}) : (),
    );

# Daemon
my $daemon = new %PROJECT_NAME%('%PROJECT_NAMEL%',
        ctk     => $ctk,
        forks   => $options{forks},
        interval=> $options{interval},
    );

# Run
my $exitval = $daemon->ctrl($command);

exit $exitval;
-----END FILE-----

-----BEGIN FILE-----
Name: %PROJECT_NAME%.pm
File: lib/%PROJECT_NAME%.pm
Mode: 644

package %PROJECT_NAME%; # %DOLLAR%Id%DOLLAR%
use strict;

%PODSIG%head1 NAME

%PROJECT_NAME% - %PROJECT_NAME% daemon

%PODSIG%head1 VERSION

Version %PROJECT_VERSION%

%PODSIG%head1 SYNOPSIS

    use %PROJECT_NAME%;

%PODSIG%head1 DESCRIPTION

%PROJECT_NAME% daemon

%PODSIG%head2 new

See L<CTK::Daemon/"new">

%PODSIG%head2 init

See L<CTK::Daemon/"init">

%PODSIG%head2 run

See L<CTK::Daemon/"run">

%PODSIG%head2 down

See L<CTK::Daemon/"down">

%PODSIG%head1 HISTORY

%PODSIG%over

%PODSIG%item B<%PROJECT_VERSION% %GMT%>

Init version

%PODSIG%back

See C<Changes> file

%PODSIG%head1 SEE ALSO

L<CTK>, L<CTK::Daemon>

%PODSIG%head1 AUTHOR

%AUTHOR% E<lt>%ADMIN%E<gt>

%PODSIG%head1 COPYRIGHT

Copyright (C) %YEAR% %AUTHOR%. All Rights Reserved

%PODSIG%head1 LICENSE

This program is distributed under the GNU GPL v3.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

%PODSIG%cut

use vars qw($VERSION);
$VERSION = '%PROJECT_VERSION%';

use base qw/CTK::Daemon/;

use constant {
    FORKS   => 1,
    INTERVAL=> 1,
    MAXITER => 10, # 10 iterations max
};

sub new {
    my $class = shift;
    my $name = shift;
    my %daemon_options = @_;
    $daemon_options{forks} //= FORKS;
    my $self = $class->SUPER::new($name, %daemon_options);
    $self->{interval} = $daemon_options{interval} || INTERVAL;
    $self->logger->log_info("Daemon object created");
    return $self;
}

# Before running
sub init {
    my $self = shift; # Daemon object
    $self->logger->log_info("Init here!");
}

sub run {
    my $self = shift; # Daemon object
    my $ctk = $self->get_ctk; # CTK object
    my $logger = $self->logger; # Logger from daemon object for internal only (in Daemon context)
    return 1 unless $self->ok; # Return with true status while any error occurred

    my $iteration = 0; # Iteration number
    my $interval = abs($self->{interval}) || INTERVAL; # Time interval. 1 op per n sec
    $logger->log_info("Runned (ID=%d; PID=%d; Interval=%d)",
        $self->{workerident},
        $self->{workerpid},
        $interval,
    );

    # Cycle
    while ($self->ok) { # Check it every time
        $iteration++;
        last if $iteration > MAXITER;
        $logger->log_info("=> iteration (ID=%d; PID=%d; Iteration=%d/%d)",
            $self->{workerident},
            $self->{workerpid},
            $iteration, MAXITER
        );

        # If occurred usual error:
        #    $logger->log_error("...");
        #    next;

        # If occurred exception error
        #    $logger->log_crit("...");
        #    $self->exception(1);
        #    last;

        # For skip this loop
        #    $self->skip(1);
        #    next;

        if ($ctk->testmode && $iteration == 3) {
            $ctk->error("Test error, go to next iteration");
            next;
        }
        if ($ctk->testmode && $iteration == 6) {
            $ctk->error("Test fatal error");
            $self->exception(1);
            next;
        }

        last unless $self->ok; # Check it every time (after loop too)
    } continue {
        CTK::Daemon::mysleep $interval; # Delay!
    }

    return 1; # 0 if fatal errors occurred
}

sub down { # After process
    my $self = shift;
    my $logger = $self->logger;
    my $ctk = $self->get_ctk;
    $logger->log_info("Cleanup here!");
    if ($self->exception) {
        $logger->log_error("Exception error: %s", $ctk->error || "unknown error");
    }
    elsif ($self->interrupt) {
        $logger->log_error("Aborted");
    }
    elsif ($self->skip) {
        $logger->log_info("Skipped process");
    }
    else {
        $logger->log_info("Normal finished");
    }
    return 1;
}

1;
-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.PL
File: Makefile.PL
Mode: 755

#!/usr/bin/perl -w
use strict;
use lib qw/inc/;
use ExtUtils::MakeMaker;
use CTK;
use MY;

my $ctk = new CTK( project => '%PROJECT_NAME%' );
WriteMakefile(
    'NAME'              => '%PROJECT_NAME%',
    'DISTNAME'          => '%PROJECT_NAME%',
    'MIN_PERL_VERSION'  => 5.016001,
    'VERSION_FROM'      => 'lib/%PROJECT_NAME%.pm',
    'ABSTRACT_FROM'     => 'lib/%PROJECT_NAME%.pm',
    'PREREQ_PM'         => {
            'CTK'   => %CTKVERSION%,
        },
    'EXE_FILES'         => [qw(
            bin/%PROJECT_NAMEL%
        )],
    'AUTHOR'            => '%AUTHOR%, <%HOMEPAGE%>, <%ADMIN%>',
    'LICENSE'           => 'gpl',
    'META_MERGE'        => {
        resources => {
            homepage        => '%HOMEPAGE%',
            repository      => 'https://my.git.com/%PROJECT_NAMEL%.git',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
    macro => {
            PROJECT_NAME    => '%PROJECT_NAME%',
            PROJECT_NAMEL   => '%PROJECT_NAMEL%',
            PROJECT_CONFDIR => $ctk->root,
        },
    clean => {
            FILES => '$(INST_CONF) *.tmp',
        },
);

1;
-----END FILE-----

-----BEGIN FILE-----
Name: MANIFEST
File: MANIFEST
Mode: 644

# Generated by CTKlib %CTKVERSION%
# %DOLLAR%Id%DOLLAR%

# General files
Changes                         Changes list
INSTALL                         Installation instructions
LICENSE                         License file
Makefile.PL                     Makefile builder
MANIFEST                        This file
README                          !!! README FIRST !!!
TODO                            TO DO

# Scripts
bin/%PROJECT_NAMEL%

# Libraries
lib/%PROJECT_NAME%.pm

# Includes
inc/README
inc/MY.pm
inc/PostConf.pm

# Configs
conf/%PROJECT_NAMEL%.conf
conf/conf.d/README
conf/conf.d/extra-log.conf
conf/conf.d/extra-sendmail.conf

# Tests
t/01-use.t

-----END FILE-----
