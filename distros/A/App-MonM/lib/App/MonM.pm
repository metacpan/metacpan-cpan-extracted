package App::MonM; # $Id: MonM.pm 151 2022-09-16 07:45:23Z abalama $
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM - Simple monitoring tool

=head1 VERSION

Version 1.09

=head1 SYNOPSIS

    # monm checkit
    # monm report
    # monm show

=head1 DESCRIPTION

Simple monitoring tool

=head2 FEATURES

=over 4

=item Checking availability of sites (http/https)

=item Checking of database health (DBI)

=item Checking internal and external counters using system commands and tools (command)

=item Supports SMTP, POP3, FTP, SSH protocols, and etc.

=item Interface for SMS sending

=item Easy installation and configuration

=item A small number of system dependencies

=back

=head2 SYSTEM REQUIREMENTS

=over 4

=item Perl v5.16+

=item L<libwww|https://github.com/libwww-perl/libwww-perl>

=item L<libnet|https://metacpan.org/dist/libnet>

=item L<Email::MIME|https://github.com/rjbs/Email-MIME>

=item L<Net-SNMP|https://net-snmp.sourceforge.io/>

To use this module in full powerful, you must have Net-SNMP installed
on your system. More specifically you need the Perl modules that come with it.

DO NOT INSTALL SNMP or Net::SNMP from CPAN!

The SNMP module is matched to an install of net-snmp, and must be installed
from the net-snmp source tree.

The Perl module C<SNMP> is found inside the net-snmp distribution. Go to the
F<perl/> directory of the distribution to install it, or run
C<./configure --with-perl-modules> from the top directory of the net-snmp
distribution.

Net-SNMP can be found at https://net-snmp.sourceforge.io/

=back

=head2 INSTALLATION

    # sudo cpan install App::MonM

...and then:

    # sudo monm configure

=head2 CONFIGURATION

By default configuration file located in C</etc/monm> directory

B<NOTE:> each configuration option (directive) detailed describes in C<monm.conf> file,
see also C<conf.d/checkit-foo.conf.sample> file for example of MonM checkit configuration

=head3 GENERAL DIRECTIVES

=over 4

=item B<DaemonUser>, B<DaemonGroup>

    DaemonUser monmu
    DaemonGroup monmu

Defines a username and groupname for daemon working

Default: monmu

=item B<Expires>

    Expires 1d

Defines the lifetime of a record in the database.
After this time, the record from the database will be deleted automatically.

Format for time can be in any of the following forms:

    20   -- in 20 seconds
    180s -- in 180 seconds
    2m   -- in 2 minutes
    12h  -- in 12 hours
    1d   -- in 1 day
    3M   -- in 3 months
    2y   -- in 2 years

Default: 1d (1 day)

=item B<Interval>

    Interval 20

Defines worker interval. This interval determines how often
the cycle of checks will be started.

Default: 20

=item B<LogEnable>

    LogEnable on

Activate or deactivate the logging: on/off (yes/no)

Default: off

=item B<LogFile>

    LogFile /var/log/monm.log

Defines path to custom log file

Default: use syslog

=item B<LogIdent>

    LogIdent myProgramName

Defines LogIdent string. We not recommended use it

Default: none

=item B<LogLevel>

    LogLevel warning

Defines log level

Allowed levels: debug, info, notice, warning, error,
crit, alert, emerg, fatal, except

Default: debug

=item B<Workers>

    Workers 3

Defines workers number

Default: 3

=back

=head3 USER AND GROUP DIRECTIVES

=over 4

=item B<Group>

The "Group" section combines several users into named groups.
This allows you to reduce the lists of recipients of notifications

    <Group Foo>
        Enable on
        User Bob, Alice
        User Ted
    </Group>

Each group has a status - enabled/disabled (see Enable directive)

=item B<User>

The User section allows you to define the user name and settings.

    <User Bob>
        Enable on

        At Sun[off];Mon-Thu[08:30-12:30,13:30-18:00];Fri[10:00-20:30];Sat[off]

        <Channel SendMail>
            To bob@example.com
        </Channel>

        <Channel SMSGW>
            To +1-424-254-5301
            At Mon-Fri[08:30-18:30]
        </Channel>
    </User>

Each user has a status - enabled/disabled (see Enable directive). User settings
are disabled by default. User settings contains channel sections, the settings
of which are taken either from globally defined channel sections or from those
defines within the scope of this user only

=back

=head3 CHANNEL DIRECTIVES

See L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=head3 CHECKIT DIRECTIVES

See L<App::MonM::Checkit/CONFIGURATION DIRECTIVES>

=head2 CRONTAB

To automatically launch the program, you can using standard scheduling tools, such as crontab

    * * * * * monm checkit >/dev/null 2>>/var/log/monm-error.log

For daily reporting:

    0 8 * * * monm report >/dev/null 2>>/var/log/monm-error.log

=head1 INTERNAL METHODS

=over 4

=item B<again>

The CTK method for classes extension. For internal use only!

See L<CTK/again>

=item B<notifier>

    my $notifier = $app->notifier;

Returns the Notifier object

=item B<notify>

    $app->notify();

Sends notifications

=item B<raise>

    return $app->raise("Red message");

Sends message to STDERR and returns 0

=item B<store>

    my $store = $app->store();

Returns store object

=item B<trigger>

    my @errors = $app->trigger();

Runs triggers

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK>, L<Email::MIME>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.09';

use feature qw/ say /;

use Text::SimpleTable;
use File::Spec;
use File::stat qw//;
use Text::ParseWords qw/shellwords quotewords/;
use Text::Wrap qw/wrap/;

use CTK::Skel;
use CTK::Util qw/ preparedir dformat execute dtf tz_diff sendmail variant_stf lf_normalize sharedstatedir /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use App::MonM::Const;
use App::MonM::Util qw/
        blue green red yellow cyan magenta gray
        yep nope skip wow
        getBit setBit
        node2anode getCheckitByName
        getExpireOffset getTimeOffset explain
        slurp spurt
        merge
    /;
use App::MonM::Store;
use App::MonM::Checkit;
use App::MonM::QNotifier;
use App::MonM::Report;

use parent qw/CTK::App/;

use constant {
    TAB9            => " " x 9,
    EXPIRES         => 24*60*60, # 1 day
    SMSSBJ          => 'MONM CHECKIT REPORT',
    DATE_FORMAT     => '%YYYY-%MM-%DD %hh:%mm:%ss',
    TABLE_HEADERS   => [(
            [32, 'NAME'],
            [7,  'TYPE'],
            [19, 'LAST CHECK DATE'],
            [7,  'RESULT'],
        )],

    # Markers
    MARKER_OK       => '[  OK  ]',
    MARKER_FAIL     => '[ FAIL ]',
    MARKER_SKIP     => '[ SKIP ]',
    MARKER_INFO     => '[ INFO ]',
};

eval { require App::MonM::Notifier };
my $NOTIFIER_LOADED = 1 unless $@;
$NOTIFIER_LOADED = 0 if $NOTIFIER_LOADED && (App::MonM::Notifier->VERSION * 1) < 1.04;

sub again {
    my $self = shift;
       $self->SUPER::again(); # CTK::App again first!!

    # Datadir & Tempdir
    if ($self->option("datadir")) {
        # Prepare DataDir
        preparedir( $self->datadir() ) or do {
            $self->status(0);
            $self->raise("Can't prepare directory %s", $self->datadir());
        };
    } elsif ($self->option("daemondir")) {
        $self->datadir(File::Spec->catdir(sharedstatedir(), PREFIX));
    } else {
        $self->datadir($self->tempdir());
    }
    # Prepare TempDir
    preparedir( $self->tempdir() ) or do {
        $self->status(0);
        $self->raise("Can't prepare directory %s", $self->tempdir());
    };

    # Store
    my $db_file = File::Spec->catfile($self->datadir, App::MonM::Store::DB_FILENAME());
    my $store_conf = $self->config("store") || $self->config('dbi') || {file => $db_file};
       $store_conf = {file => $db_file} unless is_hash($store_conf);
    my %store_args = %$store_conf;
    $store_args{file} = $db_file unless ($store_args{file} || $store_args{dsn});
    my $store = App::MonM::Store->new(%store_args);
    $self->{store} = $store;
    #$self->debug(explain($store));

    # Notifier object init
    my %nargs = (config => $self->configobj);
    $self->{notifier} = $NOTIFIER_LOADED && lvalue($self->config("usemonotifier"))
        ? App::MonM::Notifier->new(%nargs)
        : App::MonM::QNotifier->new(%nargs);

    #$self->status($self->raise("Test error"));

    return $self; # CTK requires!
}
sub raise {
    my $self = shift;
    say STDERR red(@_);
    $self->log_error(sprintf(shift, @_));
    return 0;
}
sub store {
    my $self = shift;
    return $self->{store};
}
sub notifier {
    my $self = shift;
    return $self->{notifier};
}

__PACKAGE__->register_handler(
    handler     => "info",
    description => "Show statistic information",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;

    # General info
    printf("Hostname            : %s\n", HOSTNAME);
    printf("MonM version        : %s\n", $self->VERSION);
    printf("Date                : %s\n", _fdate());
    printf("Data dir            : %s\n", $self->datadir);
    printf("Temp dir            : %s\n", $self->tempdir);
    printf("Config file         : %s\n", $self->configfile);
    printf("Config status       : %s\n", $self->conf("loadstatus") ? green("OK") : magenta("ERROR: not loaded"));
    $self->raise($self->configobj->error) if !$self->configobj->status and length($self->configobj->error);
    printf("Notifier class      : %s\n", ref($self->notifier) || magenta("not initialized"));
    #$self->debug(explain($self->config)) if $self->conf("loadstatus") && $self->verbosemode;

    # DB status
    printf("DB DSN              : %s\n", $store->dsn);
    printf("DB status           : %s\n", $store->error ? red("ERROR") : green("OK"));
    my $db_is_ok = $store->error ? 0 : 1;
    if ($db_is_ok && $store->{file} && -e $store->{file}) {
        my $s = File::stat::stat($store->{file})->size;
        printf("DB file             : %s\n", $store->{file});
        printf("DB size             : %s\n", sprintf("%s (%d bytes)", _fbytes($s), $s));
        printf("DB modified         : %s\n", _fdate(File::stat::stat($store->{file})->mtime || 0));
    }
    $self->raise($store->error) unless $db_is_ok;

    # Checkets
    my @checkits = getCheckitByName($self->config("checkit"));
    my $noc = scalar(@checkits);
    printf("Checkits            : %s\n", $noc ? $noc : yellow("none"));
    if ($noc) {
        #print explain(\@checkits);
        my $tbl = Text::SimpleTable->new(
            [20, 'CHECKIT NAME'], # name
            [7,  'TYPE'], # type
            [7,  'TARGET'], # target
            [6,  'INTRVL'], # interval
            [3,  'TRG'], # trigger
            [27, 'RECIPIENTS'], # sendto
        );
        foreach my $ch (@checkits) {
            my $triggers = array($ch, "trigger");
            my $recipients = array($ch, "sendto");
            $tbl->row( # variant_stf($v->{source} // '', $src_len),
                variant_stf($ch->{name} // '', 20),
                $ch->{type} // 'http',
                $ch->{target} // 'status',
                $ch->{interval} || 0,
                scalar(@$triggers),
                join(", ", @$recipients),
            );
        }
        print $tbl->draw();
    }

    # Scheduler
    my $scheduler = App::MonM::Util::Scheduler->new;

    # Channels
    my $channels = $self->notifier->{ch_def} || {};
    my $chcnt = scalar(keys %$channels);
    printf("Channels            : %s\n", $chcnt ? $chcnt : yellow("none"));
    if ($chcnt) {
        my $tbl = Text::SimpleTable->new(
            [20, 'CHANNEL NAME'],
            [7,  'TYPE'],
            [42, 'TO (FROM)'],
            [7,  'ON/NOW'],
        );
        foreach my $ch_name (keys %$channels) {
            my $ch = hash($channels, $ch_name);
            $scheduler->add($ch_name, lvalue($ch, "at"));
            $tbl->row(
                $ch_name,
                lvalue($ch, "type") || '',
                lvalue($ch, "from")
                    ? sprintf("%s (%s)", lvalue($ch, "to") || '', lvalue($ch, "from"))
                    : lvalue($ch, "to") || '',
                sprintf("%s/%s",
                    lvalue($ch, "enable") || lvalue($ch, "enabled") ? 'Yes' : 'No',
                    $scheduler->check($ch_name) ? "Yes" : "No",
                ),
            );
            if ($self->verbosemode && $scheduler->getAtString($ch_name)) {
                printf("  Ch=%s; At=%s\n", $ch_name, $scheduler->getAtString($ch_name));
            }

        }
        print $tbl->draw();
    }

    # Users
    my @users = $self->notifier->getUsers;
    printf("Allowed users       : %s\n", @users ? join(", ", @users) : yellow("none"));
    if (@users) {
        my $tbl = Text::SimpleTable->new(
            [20, 'USERNAME'],
            [20, 'CHANNEL (BASEDON)'],
            [7,  'TYPE'],
            [19, 'TO'],
            [7,  'ON/NOW'],
        );
        my $old = "";
        foreach my $u (sort {$a cmp $b} @users) {
            # Get User node
            my $usernode = node($self->conf("user"), $u);
            next unless is_hash($usernode) && keys %$usernode;
            #print App::MonM::Util::explain($usernode);

            # Get user channels
            my $channels_usr = hash($usernode => "channel");
            foreach my $ch_name (keys %$channels_usr) {
                my $at = lvalue($channels_usr, $ch_name, "at") || lvalue($usernode, "at");
                my $basedon = lvalue($channels_usr, $ch_name, "basedon") || lvalue($channels_usr, $ch_name, "baseon") || '';
                my $ch = merge(
                    hash($self->notifier->{ch_def}, $basedon || $ch_name),
                    hash($channels_usr, $ch_name),
                    {$at ? (at => $at) : ()},
                );
                $scheduler->add($ch_name, lvalue($ch, "at"));
                #print App::MonM::Util::explain($ch);
                $tbl->row(
                    ($old eq $u) ? "" : $u,
                    $basedon ? sprintf("%s (%s)", $ch_name, $basedon): $ch_name,
                    lvalue($ch, "type") || '',
                    lvalue($ch, "to") || '',
                    sprintf("%s/%s",
                        lvalue($ch, "enable") || lvalue($ch, "enabled") ? 'Yes' : 'No',
                        $scheduler->check($ch_name) ? "Yes" : "No",
                    ),
                );
                if ($self->verbosemode && $scheduler->getAtString($ch_name)) {
                    printf("  Usr=%s; Ch=%s; At=%s\n", $u, $ch_name, $scheduler->getAtString($ch_name));
                }
            } continue {
                $old = $u;
            }
            unless (%$channels_usr) {
                $tbl->row( $u, '', '', '', '-------' );
            }
        }
        print $tbl->draw();
    }

    # Groups
    my @groups = $self->notifier->getGroups;
    printf("Allowed groups      : %s\n", @groups ? join(", ", @groups) : yellow("none"));
    if (@groups) {
        my $tbl = Text::SimpleTable->new(
            [20, 'GROUP NAME'],
            [62, 'USERS'],
        );
        foreach my $g (sort {$a cmp $b} @groups) {
            my @us = $self->notifier->getUsersByGroup($g);
            $tbl->row(
                $g,
                join(", ", @us),
            );
        }
        print $tbl->draw();
    }

    #print explain([$self->notifier->getUsersByGroup("Bar")]);

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "configure",
    description => "Generate configuration files",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;
    my $dir = shift(@arguments) || $self->root;

    # Creating configuration
    my $skel = CTK::Skel->new(
            -name   => PROJECTNAME,
            -root   => $dir,
            -skels  => {
                        config => 'App::MonM::ConfigSkel',
                    },
            -vars   => {
                    PROJECT         => PROJECTNAME,
                    PROJECTNAME     => PROJECTNAME,
                    PREFIX          => PREFIX,
                },
            -debug  => $self->verbosemode,
        );
    printf("Installing configuration to \"%s\"...\n", $dir);
    if ($skel->build("config")) {
        say green("Done. Configuration has been installed");
    } else {
        return $self->raise("Can't install configuration");
    }

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "checkit",
    description => "Checkit",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;
    return $self->raise($store->error) if $store->error;

    # Check configuration
    unless ($self->configobj->status) {
        return length($self->configobj->error)
            ? $self->raise($self->configobj->error)
            : "Can't load configuration file";
    }

    # Get checkits
    my @checkits = getCheckitByName($self->config("checkit"), @arguments);
    my $noc = scalar(@checkits);
    unless ($noc) {
        skip("No enabled <Checkit> configuration section found");
        $self->log_info("No enabled <Checkit> configuration section found");
        return 1;
    }

    # Create Checkit object
    my $checker = App::MonM::Checkit->new;

    # Get all records from DB
    my %all;
    foreach my $r ($store->getall) {
        $all{$r->{name}} = $r;
    }
    return $self->raise($store->error) if $store->error;
    # print explain(\@checkits);

    # Start
    my $curtime = time;
    my $status = 1;
    my $passed = 0;
    foreach my $checkit (sort {$a->{name} cmp $b->{name}} @checkits) {
        my $result = 1; # Check result
        my $name = $checkit->{name};
        my $info = $all{$name} || {}; # from database
        my $id = $info->{id} || 0;
        my $old = $info->{status} || 0;
        my $got = ($old << 1) & 15;
        my $pub = $info->{'time'} || 0;
        my $interval = getTimeOffset(lvalue($checkit, "interval") || 0);

        # Check interval first
        if ($interval) {
            if (($pub + $interval) >= $curtime) {
                print gray MARKER_SKIP;
                printf(" %s (%s)\n", $name, "Too little time has passed before a next check [delay $interval sec]");
                next;
            }
        }

        # Check
        $result = $checker->check($checkit);
        if ($result) {
            $got = setBit($got, 0); # Set first bit if result is PASSED
            $passed++;
        } else {
            $status = 0; # General status
        }

        # Show resulsts
        print $result ? green(MARKER_OK) : red(MARKER_FAIL);
        printf(" %s (%s >>> %s)\n", $name, $checker->source, $checker->message);
        if ($self->verbosemode) {
            printf "%sStatus=%s; Code=%s\n", TAB9,
                $checker->status || 0, $checker->code // '';
            say TAB9, $checker->note;
            if (defined($checker->content) && length($checker->content)) {
                $Text::Wrap::columns = SCREENWIDTH - 10;
                say TAB9, "-----BEGIN CONTENT-----";
                say wrap(TAB9, TAB9, lf_normalize($checker->content));
                say TAB9, "-----END CONTENT-----";
            }
        }
        if ($result && !$checker->status) {
            wow("%s", $checker->error);
        } elsif (!$result) {
            nope("%s", $checker->error);
        }

        # Save data to database
        my %data = (
            id      => $id,
            name    => $name, # Checkit name
            type    => $checker->type, # Checkit type
            result  => $result, # Checkit result
            source  => $checker->source, # Source string
            code    => $checker->code, # Checkit code value
            message => $checker->message, # Checkit message string
            note    => $checker->note, # Checkit note string
            status  => $got, # New status value (code of result) for store only!
            subject => sprintf("%s: Available %s [%s]", $result ? 'OK' : 'PROBLEM', $name, HOSTNAME), # Subject
        );
        my $chst = $id ? $store->set(%data) : $store->add(%data);
        unless ($chst) {
            $self->raise($store->error) if $store->error;
            $status = 0;
            next;
        }

        # Triggers and notifications
        # GOT = [0-0-1-1] = 3  -- OK
        # GOT = [1-1-0-0] = 12 -- PROBLEM
        if ($got == 3 or $got == 12) {
            my @errs;
            push @errs, $checker->error if $checker->error; # Checkit error string
            $data{status} = $checker->status; # Checkit status (NO RESULT!!);

            # Run triggers (FIRST)
            push @errs, $self->trigger(%data, trigger => array($checkit, "trigger"));

            # Send message via notifier (SECOND)
            $self->notify(%data, sendto => array($checkit, "sendto"), errors => \@errs);
        }
    }

    # Show Total resulsts
    print $status ? green(MARKER_OK) : red(MARKER_FAIL);
    printf(" Total passed %d checks of %d in %s\n", $passed, $noc, $self->tms());

    # Cleaning DB
    my $expire = getExpireOffset(lvalue($self->config("expires"))
        || lvalue($self->config("expire")) || EXPIRES);
    $store->clean(period => $expire) or do {
        return $store->error ? $self->raise($store->error) : 0;
    };

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "remind",
    description => "Retries sending notifies",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    return $self->raise(($self->notifier->error)) unless $self->notifier->remind;
    return 1;
});

__PACKAGE__->register_handler(
    handler     => "report",
    description => "Checkit report",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;

    # Init
    my (@errors, @table);
    my $status = 1;
    my $tbl = Text::SimpleTable->new(@{(TABLE_HEADERS)});

    # Header
    my @header;
    push @header, ["Hostname", HOSTNAME];
    push @header, ["Database DSN", $store->dsn];
    my $db_is_ok = $store->error ? 0 : 1;
    push @header, ["Database status", $db_is_ok ? "OK" : "ERROR"];
    unless ($db_is_ok) {
        push @errors, $store->dsn, $store->error, "";
        $status = $self->raise("%s: %s", $store->dsn, $store->error);
    }

    # Get checkits from config
    my @checkits = getCheckitByName($self->config("checkit"));
    my $noc = scalar(@checkits);
    push @header, ["Number of checks", $noc ? $noc : "no checks"];
    unless ($noc) {
        skip("No enabled <Checkit> configuration section found");
        $self->log_info("No enabled <Checkit> configuration section found");
        $status = 0;
    }

    # Get all records from DB
    my %all;
    if ($db_is_ok) {
        foreach my $r ($store->getall) {
            $all{$r->{name}} = $r;
        }
        if ($store->error) {
            push @errors, $store->dsn, $store->error, "";
            $status = $self->raise("%s: %s", $store->dsn, $store->error);
        }
    }

    # Checkits
    if ($status) {
        foreach my $checkit (sort {$a->{name} cmp $b->{name}} @checkits) {
            my $name = $checkit->{name};
            my $info = $all{$name} || {};
            my $last = $info->{"time"} || 0;
            my $v    = $info->{status} || 0;
            my $ostat = -1;
            if (getBit($v, 0) && getBit($v, 1) && getBit($v, 2)) { # Ok
                $ostat = 1;
            } elsif ((getBit($v, 0) + getBit($v, 1)) == 0) { # Problem
                $ostat = 0;
                $status = 0;
            }
            $tbl->row($name, $info->{type} || 'http',
                $last ? dtf(DATE_FORMAT, $last) : "",
                $ostat ? $ostat > 0 ? 'PASSED' : 'UNKNOWN' : 'FAILED',
            );
            unless ($ostat) {
                push @errors, sprintf("%s (%s >>> %s)", $name, $info->{source} || '', $info->{message} || ''), "";
            }
            #say(explain($info));
        }
        $tbl->hr;
    }
    $tbl->row('SUMMARY', "", "", $noc ? $status ? 'PASSED' : 'FAILED' : 'UNKNOWN');

    # Get SendMail config
    my $sendmail = hash($self->config('channel'), "SendMail");

    # Get output file
    my $outfile = $self->option("outfile");
    if ($outfile) {
        unless (File::Spec->file_name_is_absolute($outfile)) {
            $outfile = File::Spec->catfile($self->datadir, $outfile);
        }
    }

    # Get To value
    my $to = scalar(@arguments)
        ? join(", ", @arguments)
        : uv2null(value($sendmail, "to"));
    my $send_report = 1 if $to && $to !~ /\@example.com$/;
       $send_report = 0 if $outfile;
    push @header, ["Send report to", $to] if $send_report;
    push @header, ["Summary result", $status ? 'PASSED' : 'FAILED'];

    # Report generate
    my $report = App::MonM::Report->new(name => "last checks", configfile => $self->configfile);
    my $report_title = $status ? "checking report" : "error report";
    $report->common(@header); # Add common information
    $report->summary(         # Add summary table
        $status ? "All last checks successful" : "Errors occurred while checking",
        $tbl->draw(),         # Add report table
    );
    $report->errors(@errors); # Add list of occurred errors
    if ($outfile) {
        $report->abstract(sprintf("The %s for last checks on %s\n", $report_title, HOSTNAME));
        if (my $err = spurt($outfile, $report->as_string)) {
            nope($err);
            $self->log_error($err);
        } else {
            my $msg = sprintf("The report successfully saved to file: %s", $outfile);
            yep($msg);
            $self->log_debug($msg);
        }
        return $status;
    } elsif ($self->verbosemode) { # Draw to STDOUT
        printf("%s BEGIN REPORT ~~~\n", "~" x (SCREENWIDTH()-17)) if IS_TTY;
        printf("The %s for last checks on %s\n\n", $report_title, HOSTNAME);
        print $report->as_string;
        printf("%s END REPORT ~~~\n", "~" x (SCREENWIDTH()-15)) if IS_TTY;
    }

    # Send report
    if ($send_report) {
        $report->title($report_title);
        $report->footer($self->tms);

        # Send
        my $ns = $self->notifier->notify(
                to      => $to,
                subject => sprintf("%s %s (%s on %s)", PROJECTNAME, $report_title, "last checks", HOSTNAME),
                message => $report->as_string,
                after   => sub {
                    my $this = shift;
                    my $message = shift;
                    my $sent = shift;

                    if ($sent) {
                        my $msg = $this->channel->error
                            ? sprintf("Report was not sent to %s: %s", $message->recipient, $this->channel->error)
                            : sprintf("Report has been sent to %s", $message->recipient);
                        if ($this->channel->error) { skip($msg) }
                        else { yep($msg) }
                        $self->log_debug($msg);
                    } else {
                        my $err = sprintf("Report was not sent to %s: %s", $message->recipient, $this->channel->error || "unknown error");
                        nope($err);
                        $self->log_warning($err);
                    }

                    1;
                },
            );
        unless ($ns) {
            my $err = sprintf("Report was not sent to %s: %s", $to, $self->notifier->error);
            nope($err);
            $self->log_warning($err);
        }
    }

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "show",
    description => "Show table data",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;
    return $self->raise($store->error) if $store->error;

    # Get all records from DB
    my %all;
    foreach my $r ($store->getall) {
        $all{$r->{name}} = $r;
    }
    return $self->raise($store->error) if $store->error;

    # Check data
    my $n = scalar(keys %all) || 0;
    if ($n) {
        printf("Number of records: %d\n", $n);
    } else {
        return skip("No data");
    }

    # Show dump
    if ($self->verbosemode) {
        print(explain(\%all));
        return 1;
    }

    # Checkets
    my @checkits = getCheckitByName($self->config("checkit"));
    my %chckts = ();
    foreach my $ch (@checkits) {
        $chckts{$ch->{name}} = $ch;
    }

    # Generate table
    my $src_len = (SCREENWIDTH() - 88);
       $src_len = 32 if $src_len < 32;
    my $tbl = Text::SimpleTable->new(
            [20, 'CHECKIT'],
            [7,  'TYPE'],
            [7,  'TARGET'],
            [$src_len, 'SOURCE STRING'],
            [19, 'LAST CHECK DATE'],
            [6,  'INTRVL'], # interval
            [7,  'RESULT']
        );

    # Show table
    my $status = 1;
    foreach my $v (sort {$a->{name} cmp $b->{name}} values %all) {
        my $stv = $v->{status} || 0;
        my $ostat = -1;
        if (getBit($stv, 0) && getBit($stv, 1) && getBit($stv, 2)) { # Ok
            $ostat = 1;
        } elsif ((getBit($stv, 0) + getBit($stv, 1)) == 0) { # Problem
            $ostat = 0;
            $status = 0;
        }

        $tbl->row(
            variant_stf($v->{name} // '', 20),
            $v->{type} || 'http',
            lvalue(\%chckts, $v->{name} // '__default', "target") // 'status',
            variant_stf($v->{source} // '', $src_len),
            $v->{"time"} ? dtf(DATE_FORMAT, $v->{"time"})  : '',
            lvalue(\%chckts, $v->{name} // '__default', "interval") || 0,
            $ostat ? $ostat > 0 ? 'PASSED' : 'UNKNOWN' : 'FAILED'
        );

    }
    $tbl->hr;
    $tbl->row('SUMMARY', "", "", "", "", "", $status ? 'PASSED' : 'FAILED');
    say $tbl->draw();

    return $status;
});

sub trigger {
    my $self = shift;
    my %args = @_;
    my $name = $args{name} || 'virtual';
    my $message = $args{message} // "";
    my $source = $args{source} // "";
    my $subject = $args{subject};

    # Execute triggers
    my $triggers = $args{trigger} || [];
    my @errs;
    foreach my $trg (@$triggers) {
        next unless $trg;
        my $cmd = dformat($trg, {
            SUBJECT     => $subject,    SUBJ => $subject, SBJ => $subject,
            MESSAGE     => $message,    MSG  => $message,
            SOURCE      => $source,     SRC  => $source,
            NAME        => $name,
            TYPE        => $args{type} // "http",
            CODE        => $args{code} // '',
            STATUS      => $args{status} ? 'OK' : 'ERROR',
            RESULT      => $args{result} ? 'PASSED' : 'FAILED',
            NOTE        => $args{note} // '',
        });
        my $exe_err = '';
        my $exe_out = execute($cmd, undef, \$exe_err);
        my $exe_stt = ($? >> 8) ? 0 : 1;
        if ($exe_stt) {
            my $msg = sprintf("# %s", $cmd);
            print cyan MARKER_INFO;
            say " ", $msg;
            $self->log_info($msg);
            if (defined($exe_out) && length($exe_out) && $self->verbosemode) {
                say $exe_out if IS_TTY;
                $self->log_info($exe_out);
            }
        } else {
            my $msg = sprintf("Can't execute trigger %s", $cmd);
            print red MARKER_FAIL;
            say " ", $msg;
            $self->log_error($msg);
            push @errs, $msg;
            if ($exe_err) {
                chomp($exe_err);
                nope($exe_err);
                $self->log_error($exe_err);
                push @errs, $exe_err;
            }
        }
    }

    return @errs;
}
sub notify {
    my $self = shift;
    my %args = @_;
    my $name = $args{name} || 'virtual';
    my $sendto = $args{sendto} || [];
    my $subject = $args{subject};
    my @errors;
    my $errs = $args{errors};
    push @errors, @$errs if is_array($errs);
    #say(explain(\%args));

    # Header
    my @header;
    push @header, (
        ["Checkit",     $name], # Checkit name
        ["Type",        $args{type} || 'http'], # Checkit type
        ["Result",      $args{result} ? 'PASSED' : 'FAILED'], # Checkit result
        ["Source",      $args{source} || "UNKNOWN"], # Source string
        ["Status",      $args{status} ? 'OK' : 'ERROR'], # Checkit status (NO RESULT!!);
        ["Code",        $args{code} // "UNKNOWN"], # Checkit code value
        ["Note",        $args{note} // "No comments"], # Checkit note string
        ["Message",     $args{message} // ""], # Checkit message string
    );

    # Report
    my $report = App::MonM::Report->new(name => $name, configfile => $self->configfile);
    $report->title($args{result} ? "checking report" : "error report");
    $report->common(@header); # Common information
    $report->summary($args{result} ? "All checks successful" : "Errors occurred while checking"); # Summary
    $report->errors(@errors) if @errors; # List of occurred errors
    $report->footer($self->tms);

    # Send
    my $notify_status = $self->notifier->notify(
            to      => $sendto,
            subject => $subject,
            message => $report->as_string,
            before => sub {
                my $this = shift; # App::MonM::QNotifier object (this)
                my $message = shift; # App::MonM::Message object

                # Check internal errors
                if ($this->error) {
                    nope($this->error);
                    $self->log_error($this->error);
                }

                return 1;
            },
            after => sub {
                my $this = shift; # App::MonM::QNotifier object (this)
                my $message = shift; # App::MonM::Message object
                my $sent = shift; # Status of sending

                # Check internal errors
                if ($this->error) {
                    nope($this->error);
                    $self->log_error($this->error);
                }

                # Check sending status
                if ($sent) {
                    my $msg = $this->channel->error
                        ? sprintf("Message was not sent to %s: %s", $message->recipient, $this->channel->error)
                        : sprintf("Message has been sent to %s", $message->recipient);
                    if ($this->channel->error) { print red MARKER_FAIL }
                    else { print cyan MARKER_INFO }
                    say " ", $msg;
                    $self->log_debug($msg);
                } else {
                    my $err = sprintf("Message was not sent to %s: %s", $message->recipient, $this->channel->error || "unknown error");
                    print red MARKER_FAIL;
                    print " ";
                    nope($err);
                    $self->log_warning($err);
                }

                return 1;
            },
        );
    unless ($notify_status) {
        print red MARKER_FAIL;
        print " ";
        nope($self->notifier->error);
        $self->log_error($self->notifier->error);
    }

    return 1;
}

# Private methods
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GB", $n / (1024 ** 3);
    } elsif ($n >= 1024 ** 2) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n B";
    }
}
sub _fdate {
    my $d = shift || time;
    my $g = shift || 0;
    return "unknown" unless $d;
    return dtf(DATETIME_GMT_FORMAT, $d, 1) if $g;
    return dtf(DATETIME_FORMAT . " " . tz_diff(), $d);
}

1;

__END__
