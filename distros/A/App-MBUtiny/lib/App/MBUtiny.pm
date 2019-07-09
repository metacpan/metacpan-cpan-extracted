package App::MBUtiny; # $Id: MBUtiny.pm 129 2019-07-07 11:21:56Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny - Websites and any file system elements backup tool

=head1 VERSION

Version 1.12

=head1 SYNOPSIS

    # mbutiny test

    # mbutiny backup

    # mbutiny restore

    # mbutiny report

=head1 DESCRIPTION

Websites and any file system elements backup tool

=head2 FEATURES

=over 4

=item Backup Files and Folders

=item Backup small databases

=item Run external utilities for object preparation

=item Supported storage of backups on local drives

=item Supported storage of backups on remote SFTP storages

=item Supported storage of backups on remote FTP storages

=item Supported storage of backups on remote HTTP storages

=item Easy configuration

=item Monitoring feature enabled

=back

=head2 SYSTEM REQUIREMENTS

=over 4

=item Perl v5.16+

=item SSH client

=item libwww

=item libnet

=item zlib

=back

Recommended: Apache 2.2+ with CGI/FCGI modules

=head2 INSTALLATION

    # sudo cpan install App::MBUtiny

...and then:

    # sudo mbutiny configure

=head2 CONFIGURATION

By default configuration file located in C</etc/mbutiny> directory

Every configuration directive detailed described in C<mbutiny.conf> file, also
see C<hosts/foo.conf.sample> file for MBUtiny backup hosts configuration

=head2 CRONTAB

To automatically launch the program, we recommend using standard scheduling tools, such as crontab

    0 2 * * * mbutiny -l backup >/dev/null 2>>/var/log/mbutiny-error.log

Or for selected hosts only:

    0 2 * * * mbutiny -l backup foo bar >/dev/null 2>>/var/log/mbutiny-error.log
    15 2 * * * mbutiny -l backup baz >/dev/null 2>>/var/log/mbutiny-error.log

For daily reporting:

    0 9 * * * mbutiny -l report >/dev/null 2>>/var/log/mbutiny-error.log

=head2 COLLECTOR

Collector is a monitoring server that allows you to collect data on the status of performs backups.
The collector allows you to build reports on the collected data from various servers.

How it work?

    +------------+
    | Monitoring |<--http/https-+
    +------------+              |
                                |
    +----------+          +-----+-----+        +----------+
    | Server 1 |--local-->| COLLECTOR |--DBI-->| DataBase |
    +----------+          +-----+-----+        +----------+
                                ^
    +----------+                |
    | Server 2 |---http/https---+
    +----------+

For installation of the collector Your need Apache 2.2/2.4 web server and CGI/FastCGI script.
See C<collector.cgi.sample> in C</etc/mbutiny> directory

=head2 HTTP SERVER

If you want to use the HTTP server as a storage for backups, you need to install the CGI/FastCGI
script on Apache 2.2/2.4 web server.

See C<server.cgi>

=head1 INTERNAL METHODS

=over 4

=item B<again>

The CTK method for classes extension. For internal use only!

See L<CTK/again>

=item B<configure>

The internal method for initializing the project

=item B<excdir>

    my $excdir = $app->excdir;

Returns path to processed exclusions


=item B<getdbi>

    my $dbi = $app->getdbi;

Returns DBI object

=item B<objdir>

    my $objdir = $app->objdir;

Returns path to processed objects

=item B<rstdir>

    my $rstdir = $app->rstdir;

Returns path to restored backups

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<WWW::MLite>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT /;
$VERSION = '1.12';

use feature qw/say/;
use Carp;

use Text::SimpleTable;
use File::Spec;
use File::Path; # mkpath / rmtree
use Sys::Hostname qw/hostname/;

use CTK::Skel;
use CTK::Util qw/
        preparedir touch dtf dformat date2dig trim correct_number
        execute sharedstatedir sendmail variant_stf
    /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use App::MBUtiny::Storage;
use App::MBUtiny::Util qw/ filesize sha1sum md5sum xcopy node2anode explain /;
use App::MBUtiny::Collector qw/ int2type /;
use App::MBUtiny::Collector::DBI qw/COLLECTOR_DB_FILENAME COLLECTOR_DB_FILE/;

use base qw/ Exporter CTK::App /;

use constant {
    PROJECTNAME     => 'MBUtiny',
    PREFIX          => 'mbutiny',
    OBJECTS_DIR     => 'files',
    EXCLUDE_DIR     => 'excludes',
    RESTORE_DIR     => 'restore',
    VOIDFILE        => 'void.txt',
    DATE_FORMAT     => '%YYYY-%MM-%DD %hh:%mm:%ss',
    ARC_MASK        => '[HOST]-[YEAR]-[MONTH]-[DAY][EXT]',
    TABLE_HEADERS   => [(
            [19, 'DATE'],
            [20, 'PROCESS NAME'],
            [58, 'DESCRIPTION OF PROCCESS / DATA OF PROCCESS'],
            [4,  'STAT'],
        )],
    TEST_HEADERS   => [(
            [20, 'TEST NAME'],
            [60, 'TEST DETAILS / TEST DATA'],
            [4,  'STAT'],
        )],
    REPORT_TABLE_HEADERS => [(
            [32, 'HOST/ADDR'],
            [32, 'FILE/SIZE'],
            [3,  'TYP'],
            [19, 'DATE'],
            [4,  'STAT'],
        )],
    REPORT_HOSTS_HEADERS => [(
            [32, 'HOST'],
            [4,  'STAT'],
        )],
    REPORT_COLLECTORS_HEADERS => [(
            [95, 'URL'],
            [4,  'STAT'],
        )],

};

@EXPORT = (qw/
        PROJECTNAME PREFIX
    /);

my $TTY = 1 if -t STDOUT;
my $hostname = hostname() // 'unknown host';

sub again {
    my $self = shift;
    $App::MBUtiny::Util::DEBUG = 1 if $self->debugmode;

    # Datadir & Tempdir
    if ($self->option("datadir")) {
        preparedir( $self->datadir() );
    } else {
        $self->datadir($self->tempdir());
    }
    preparedir( $self->tempdir() );

    # Collector dir
    my $dbdir = File::Spec->catdir(sharedstatedir(), PREFIX);
    preparedir( $dbdir, 0777 ) unless -e $dbdir;

    # Set paths
    my $objdir = File::Spec->catdir($self->datadir, OBJECTS_DIR);
    my $excdir = File::Spec->catdir($self->datadir, EXCLUDE_DIR);
    my $rstdir = File::Spec->catdir($self->datadir, RESTORE_DIR);
    $self->{objdir} = $objdir;
    $self->{excdir} = $excdir;
    $self->{rstdir} = $rstdir;

    # Prepare dirs
    preparedir({
            objdir  => $objdir,
            excdir  => $excdir,
            rstdir  => $rstdir,
        });

    # Set VoidFile
    $self->{voidfile} = File::Spec->catfile($self->tempdir(), VOIDFILE);
    touch($self->{voidfile});

    # Set DBI
    $self->{_dbi} = undef;

    return $self->SUPER::again;
}
sub excdir {shift->{excdir}}
sub objdir {shift->{objdir}}
sub rstdir {shift->{rstdir}}
sub getdbi {shift->{_dbi}}

__PACKAGE__->register_handler(
    handler     => "configure",
    description => sprintf("Configure %s", PROJECTNAME),
    code => sub { shift->configure });

__PACKAGE__->register_handler(
    handler     => "config",
    description => "Alias for configure command",
    code => sub { shift->configure });

__PACKAGE__->register_handler(
    handler     => "test",
    description => "Testing",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my $status = 1;
    if ($self->testmode) {
        say("CLI arguments: ", join("; ",@arguments) || 'none' );
        say("Meta: ", explain($meta));
        say("CTK object: ", explain($self));
        say("App handlers: ", join(", ", $self->list_handlers));
        return 1;
    }

    # Get host-list
    my @hosts = $self->_getHosts();
    unless (scalar(@hosts)) {
        $self->log_warn("No enabled <Host> configuration section found");
        return 1;
    }

    # Start
    foreach my $pair (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @hosts) {
        my @header;
        my @errors;
        my $step = '';
        my $ostat = 1; # Operation status


        #
        # Init
        #
        my $name = _getName($pair); # Backup name
        my $host = node($pair, $name); # Config section
        my $hostskip = (!@arguments || grep {lc($name) eq lc($_)} @arguments) ? 0 : 1;
        my $enabled = value($host, 'enable') ? 1 : 0;
        if ($hostskip || !$enabled) {
            $self->log_info("Skip testing for \"%s\" backup host section", $name);
            next;
        }
        my $tbl = Text::SimpleTable->new(@{(TEST_HEADERS)});
        $self->log_info("Start testing for \"%s\" backup host section", $name);
        push @header, ["Backup name", $name];
        push @errors, $self->getdbi->dsn, $self->getdbi->error, "" if $self->getdbi->error;


        #
        # Loading backup data
        #
        my $buday   = (value($host, 'buday')   // $self->config('buday'))   || 0;
        my $buweek  = (value($host, 'buweek')  // $self->config('buweek'))  || 0;
        my $bumonth = (value($host, 'bumonth') // $self->config('bumonth')) || 0;
        push @header, (
                ["Daily backups", $buday],
                ["Weekly backups", $buweek],
                ["Monthly backups", $bumonth],
            );

        # Get mask vars
        my $arc = $self->_getArc($host);
        my $arcmask = value($host, 'arcmask') || ARC_MASK;
           $arcmask =~ s/\[DEFAULT\]/ARC_MASK()/gie;
        my %maskfmt = (
                HOST  => $name,
                YEAR  => '',
                MONTH => '',
                DAY   => '',
                EXT   => value($arc, 'ext') || '',
            );
        push @header, ["Backup mask", $arcmask];

        # Get saved dates
        my @dates = $self->_getDates($buday, $buweek, $bumonth);

        # Get paths
        push @header, (
                ["Work directory", $self->datadir],
                ["Directory for backups", $self->objdir],
                ["Directory for restores", $self->rstdir],
            );

        # Regular objects
        my $objects = array($host, 'object');
        my $regular_objects = 0;
        {
            my $i = 0;
            foreach my $o (@$objects) {
                next unless $o;
                my $st = (-e $o) ? 1 : 0;
                $regular_objects++ if $st;
                $tbl->row(sprintf("R-Object #%d", ++$i), $o, $st ? 'PASS' : 'SKIP');
            }
        }

        # Exclusive objects
        my $exclude_node = _node_correct(node($host, "exclude"), "object");
        my $exclusive_objects = 0;
        {
            my $i = 0;
            foreach my $exclude (@$exclude_node) {
                my $sgn = sprintf("X-object #%d", ++$i);
                my $exc_name = _getName($exclude);
                my $exc_object = uv2null(value($exclude, $exc_name, "object"));
                if (-e $exc_object and -d $exc_object) {
                    $exclusive_objects++;
                    $tbl->row($sgn, sprintf("%s: %s", $exc_name, $exc_object), 'PASS');
                } else {
                    $tbl->row($sgn, sprintf("%s: %s", $exc_name, $exc_object || "none"), 'SKIP');
                }
            }
        }

        # Check objects
        if ($regular_objects + $exclusive_objects) {
            $tbl->row("Objects", sprintf("%d objects found", $regular_objects + $exclusive_objects), 'PASS');
        } else {
            $tbl->row("Objects", "No available objects", 'FAIL');
            $ostat = 0;
        }


        #
        # Checking collectors
        #
        $step = "Collectors checking";
        $self->debug($step);
        my $collector = new App::MBUtiny::Collector(
                collector_config => $self->_getCollector($host),
                dbi => $self->getdbi, # For local storage only
            );
        my $colret = $collector->check;
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
            $ostat = 0;
        }
        $tbl->row($step,
            $collector->error ? "No available collectors" : $colret,
            $collector->error ? 'FAIL' : $colret ? 'PASS' : 'SKIP',
        );


        #
        # Testing storages
        #
        $step = "Storages testing";
        $self->debug($step);
        my $storage = new App::MBUtiny::Storage(
            name => $name, # Backup name
            host => $host, # Host config section
        );
        my $test = $storage->test or do {
            $self->log_error($storage->error);
            push @errors, $storage->error;
            $ostat = 0;
        };
        {
            my ($i, $j) = (0, 0);
            foreach my $tr ($storage->test_report) {
                my ($st, $vl, $er) = @$tr;
                $j++ if $st && $st > 0;
                $tbl->row(sprintf("Storage #%d", ++$i),
                    $vl, $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL'
                );
                push @errors, $er if $er;
            }
            $tbl->row($step,
                $j ? sprintf("%d available storages found", $j) : "No available storages found",
                $test ? $test < 0 ? 'SKIP' : 'PASS' : 'FAIL'
            );
            push @errors, "" unless $test;
        }


        #
        # File list fetching
        #
        $step = "Get file list";
        $self->debug($step);
        my @filelist = $storage->list;
        my $files_number = scalar(@filelist) || 0;
        $tbl->row($step,
            $files_number ? sprintf("%d files found", $files_number) : "No files found",
            $storage->error ? 'FAIL' : $files_number ? 'PASS' : 'SKIP',
        );
        if ($storage->error) {
            $self->log_error($storage->error);
            push @errors, $storage->error, "";
            $ostat = 0;
        };
        my $last_file = (sort {$b cmp $a} @filelist)[0];
        if ($files_number && $last_file) {
            push @header, ["Last backup file", $last_file];
            my $list = hash($storage->{list});
            foreach my $k (keys %$list) {
                my $l = array($list, $k);
                my $st = (grep {$_ eq $last_file} @$l) ? 1 : 0;
                $tbl->row(sprintf("%s storage", $k),
                    $st ? sprintf("File %s is available", $last_file) : sprintf("File %s missing", $last_file),
                    $st ? 'PASS' : 'SKIP',
                );
            }
            #say(explain($storage->{list}));
        }


        #
        # Getting information about file on collector
        #
        my %info = $collector->info(name => $name, file => $last_file);
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
        }
        if ($info{status}) {
            push @header, (
                ["File size", $info{size}],
                ["File MD5", $info{md5}],
                ["File SHA1", $info{sha1}],
            );
        }


        #
        # Get SendMail config
        #
        my $sm = $self->_getSendmail($host);
        my $to = uv2null(value($sm, "to"));
        my $send_report = 1 if $to
            && ($to !~ /\@example.com$/)
            && (value($sm, "sendreport") || (value($sm, "senderrorreport") && !$ostat));
        push @header, ["Send report to", $to] if $send_report;


        #
        # Report generate
        #
        $tbl->hr;
        $tbl->row('RESULT',
            $ostat ? 'All tests successful' : 'Errors have occurred!',
            $ostat ? 'PASS' : 'FAIL'
        );
        push @header, ["Summary status", $ostat ? 'PASS' : 'FAIL'];
        my @report;
        my $report_name = $ostat ? "report" : "error report";
        push @report, $self->_report_common(@header); # Common information
        push @report, $self->_report_summary($ostat ? "All tests successful" : "Errors occurred while testing"); # Summary table
        push @report, $tbl->draw() || ''; # Table
        push @report, $self->_report_errors(@errors); # List of occurred errors
        if ($TTY || $self->verbosemode) { # Draw to TTY
            printf("%s\n\n", "~" x 94);
            printf("The %s for %s backup host\n\n", $report_name, $name);
            print join("\n", @report, "");
        }


        #
        # SendMail (Send report)
        #
        if ($send_report) {
            unshift @report, $self->_report_title($report_name, $name);
            push @report, $self->_report_footer();
            my %ma = (); foreach my $k (keys %$sm) { $ma{"-".$k} = $sm->{$k} };
            $ma{"-subject"} = sprintf("%s %s (%s on %s)", PROJECTNAME, $report_name, $name, $hostname);
            $ma{"-message"} = join("\n", @report);

            # Send!
            my $sent = sendmail(%ma);
            if ($sent) { $self->debug(sprintf("Mail has been sent to: %s", $to)) }
            else { $self->error(sprintf("Mail was not sent to: %s", $to)) }
        }

        # Finish testing
        $self->log_info("Finish testing for \"%s\" backup host section", $name);

        # General status
        $status = 0 unless $ostat;
    }

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "backup",
    description => "Backup hosts",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my $status = 1;

    # Get host-list
    my @hosts = $self->_getHosts();
    unless (scalar(@hosts)) {
        $self->log_warn("No enabled <Host> configuration section found");
        return 1;
    }

    # Start
    foreach my $pair (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @hosts) {
        my @header;
        my @errors;
        my @paths_for_remove;
        my $step = '';
        my $ostat = 1; # Operation status


        #
        # Init
        #
        my $name = _getName($pair); # Backup name
        my $host = node($pair, $name); # Config section
        my $hostskip = (!@arguments || grep {lc($name) eq lc($_)} @arguments) ? 0 : 1;
        my $enabled = value($host, 'enable') ? 1 : 0;
        if ($hostskip || !$enabled) {
            $self->log_info("Skip backup process for \"%s\" backup host section", $name);
            next;
        }
        my $tbl = Text::SimpleTable->new(@{(TABLE_HEADERS)});
        $self->log_info("Start backup process for \"%s\" backup host section", $name);
        push @header, ["Backup name", $name];
        push @errors, $self->getdbi->dsn, $self->getdbi->error, "" if $self->getdbi->error;


        #
        # Loading backup data
        #
        my $buday   = (value($host, 'buday')   // $self->config('buday'))   || 0;
        my $buweek  = (value($host, 'buweek')  // $self->config('buweek'))  || 0;
        my $bumonth = (value($host, 'bumonth') // $self->config('bumonth')) || 0;
        push @header, (
                ["Daily backups", $buday],
                ["Weekly backups", $buweek],
                ["Monthly backups", $bumonth],
            );

        # Get mask vars
        my $arc = $self->_getArc($host);
        my $arcmask = value($host, 'arcmask') || ARC_MASK;
           $arcmask =~ s/\[DEFAULT\]/ARC_MASK()/gie;
        my %maskfmt = (
                HOST  => $name,
                YEAR  => '',
                MONTH => '',
                DAY   => '',
                EXT   => value($arc, 'ext') || '',
            );
        push @header, ["Backup mask", $arcmask];

        # Get saved dates
        my @dates = $self->_getDates($buday, $buweek, $bumonth);

        # Set exclusions files by dates
        my %keepfiles;
        foreach my $td (@dates) {
            ($maskfmt{YEAR}, $maskfmt{MONTH}, $maskfmt{DAY}) = ($1,$2,$3) if $td =~ /(\d{4})(\d{2})(\d{2})/;
            $keepfiles{dformat($arcmask, {%maskfmt})} = $td;
        }
        #say(explain(\%keepfiles));

        # Get objects
        my $objects = array($host, 'object');


        #
        # Checking collectors
        #
        $step = "Collectors checking";
        $self->debug($step);
        my $collector = new App::MBUtiny::Collector(
                collector_config => $self->_getCollector($host),
                dbi => $self->getdbi, # For local storage only
            );
        my $colret = $collector->check;
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
        }
        $tbl->row(dtf(DATE_FORMAT), $step,
            $collector->error ? "No available collectors" : $colret,
            $collector->error ? 'FAIL' : $colret ? 'PASS' : 'SKIP',
        );


        #
        # Running triggers (commands)
        # NOTE! Rundom order!
        #
        $step = "Triggers running";
        $self->debug($step);
        my $triggers = array($host, 'trigger');
        my $i = 0;
        foreach my $trg (@$triggers) {
            my $exe_err = '';
            my $exe_out = execute($trg, undef, \$exe_err);
            my $exe_stt = ($? >> 8) ? 0 : 1;
            if ($exe_stt) {
                $self->debug(sprintf("# %s", $trg));
                $self->debug(sprintf("%s\n", $exe_out))
                    if $self->verbosemode && defined($exe_out) && length($exe_out);
            } else {
                $self->log_error(sprintf("Trigger \"%s\":\n%s", $trg, $exe_err));
                push @errors, sprintf("# %s", $trg), $exe_err, "";
            }
            $tbl->row(dtf(DATE_FORMAT), sprintf("Running trigger #%d", ++$i), $trg, $exe_stt ? 'PASS' : 'FAIL');
        }
        $tbl->row(dtf(DATE_FORMAT), $step, "No triggers found", 'SKIP') unless $i;


        #
        # Exclusion handling
        #
        # <Exclude ["sample"]> # -- SubDirectory name for EXCLUDE_DIR, optional
        #    Object /tmp/exclude1 # -- Source directory
        #    Target /tmp/exclude2 # -- Destination directory, optional
        #    Exclude file1.txt
        #    Exclude file2.txt
        #    Exclude foo/file2.txt
        # </Exclude>
        #
        $step = "Exclusion handling";
        $self->debug($step);
        my $exclude_node = _node_correct(node($host, "exclude"), "object");
        #say(explain($exclude_node));
        $i = 0;
        foreach my $exclude (@$exclude_node) {
            my $sgn = sprintf("Exc copying #%d", ++$i);
            my $exc_name = _getName($exclude);
            my $exc_data = hash($exclude, $exc_name);
            my $exc_object = uv2null(value($exc_data, "object"));
            unless ($exc_object && (-e $exc_object and -d $exc_object)) {
                $tbl->row(dtf(DATE_FORMAT), $sgn, sprintf("%s: %s", $exc_name, $exc_object || 'no object'), 'SKIP');
                my $msg = sprintf("Object in <Exclude \"%s\"> section missing or incorrect directory \"%s\"", $exc_name, $exc_object);
                $self->log_warning($msg);
                push @errors, $msg, "";

                next;
            }
            my $exc_target = value($exc_data, "target") || File::Spec->catdir($self->excdir, $exc_name);
            if ($exc_target && -e $exc_target) {
                $tbl->row(dtf(DATE_FORMAT), $sgn, sprintf("%s: %s", $exc_name, $exc_object), 'SKIP');
                my $msg = sprintf("Target directory that specified in <Exclude \"%s\"> section already exists: \"%s\"", $exc_name, $exc_target);
                $self->log_warning($msg);
                push @errors, $msg, "";
                next;
            }
            my $exc_exclude = array($exc_data, "exclude") || [];
            $self->debug(sprintf("# X-Copy \"%s\" -> \"%s\"", $exc_object, $exc_target));

            # Exclusive copying!
            if (xcopy($exc_object, $exc_target, $exc_exclude)) {
                $tbl->row(dtf(DATE_FORMAT), $sgn, sprintf("%s: %s", $exc_name, $exc_object), 'PASS');
                push @$objects, $exc_target;
                push @paths_for_remove, $exc_target;
            } else {
                $tbl->row(dtf(DATE_FORMAT), $sgn, sprintf("%s: %s", $exc_name, $exc_object), 'FAIL');
                my $msg = sprintf("Copying directory \"%s\" to \"%s\" in exclusive mode failed!",
                        $exc_object, $exc_target
                    );
                $self->log_error($msg);
                push @errors, $msg, "";
            }
        }


        #
        # Objects checking
        #
        $step = "Objects checking";
        $self->debug($step);
        if (@$objects) {
            my $j = 0; $i = 0;
            foreach my $o (@$objects) {
                my $st = (-e $o) ? 1 : 0;
                $tbl->row(dtf(DATE_FORMAT), sprintf("Checking object #%d", ++$i), $o, $st ? 'PASS' : 'SKIP');
                if ($st) { $j++ } else { $o = undef }
            }
            $tbl->row(dtf(DATE_FORMAT), $step,
                $j ? sprintf("Will be processed %d objects", $j) : "No available objects found",
                $j ? 'PASS' : 'FAIL');
        } else {
            $ostat = 0;
            $tbl->row(dtf(DATE_FORMAT), $step, "Nothing to do! No objects found", 'FAIL');
        }


        #
        # Compressing
        #
        $step = "Objects compressing";
        $self->debug($step);
        my $cdd = date2dig();
        ($maskfmt{YEAR}, $maskfmt{MONTH}, $maskfmt{DAY}) = ($1,$2,$3) if $cdd =~ /(\d{4})(\d{2})(\d{2})/;
        my %tmpmsk = %maskfmt; $tmpmsk{EXT} = "";
        my $archive_name = dformat($arcmask, {%maskfmt});
        my $archive_file = File::Spec->catfile($self->objdir, $archive_name);
        my ($size, $md5, $sha1) = (0, "", "");
        {
            my $n = $self->_compress(
                list   => [grep {$_} @$objects],
                arcdef => $arc,
                archive=> File::Spec->catfile($self->objdir, dformat($arcmask, {%tmpmsk})),
            );
            my $st = $n && (-e $archive_file) ? 1 : 0;
            if ($st) {
                # Checksums calculation
                $size = filesize($archive_file) // 0;
                $md5 = md5sum($archive_file) // "";
                $sha1 = sha1sum($archive_file) // "";
                push @header, (
                    ["Archive name", $archive_name],
                    ["Archive size", $size],
                    ["Archive MD5", $md5],
                    ["Archive SHA1", $sha1],
                );
            } else {
                my $msg = sprintf("Compressing objects to \"%s\" failed: %s", $archive_file, $self->error);
                $self->log_error($msg);
                push @errors, $msg, "";
                $ostat = 0;
            }
            $tbl->row(dtf(DATE_FORMAT), $step, $archive_name, $st ? 'PASS' : 'FAIL');
        }


        #
        # Testing storages
        #
        $step = "Storages testing";
        $self->debug($step);
        my $storage = new App::MBUtiny::Storage(
                name => $name, # Backup name
                host => $host, # Host config section
                path => $self->objdir, # Where is located backup archive
                fixup => sub {
                    my $strg = shift; # Storage object
                    my $oper = shift // 'noop'; # Operation name
                    my $colret;
                    if ($oper =~ /^(del)|(rem)/i) {
                        my $f = shift;
                        $colret = $collector->fixup(
                                operation => $oper,
                                name    => $name,
                                file    => $f,
                            );
                    } else {
                        my $stts = shift // 0; # Operation status
                        my $cmnt = shift // ''; # Comment (details)
                        $colret = $collector->fixup(
                                operation => $oper,
                                status  => $stts,
                                error   => $strg->error,
                                name    => $name,
                                file    => $archive_name,
                                size    => $size,
                                md5     => $md5,
                                sha1    => $sha1,
                                comment => $cmnt,
                            );
                    }
                    if ($collector->error) {
                        my $msg = sprintf("Fixing error: %s", $collector->error);
                        $self->log_error($msg);
                        push @errors, $msg, "";
                    }
                    $tbl->row(dtf(DATE_FORMAT), "Fixing on collector",
                        $colret || "No available collectors found",
                        $collector->error ? 'FAIL' : $colret ? 'PASS' : 'SKIP',
                    );
                },
            );
        my $test = $storage->test or do {
            $self->log_error($storage->error);
            push @errors, $storage->error;
            $ostat = 0;
        };
        {
            my $j = 0; $i = 0;
            foreach my $tr ($storage->test_report) {
                my ($st, $vl, $er) = @$tr;
                $j++ if $st && $st > 0;
                $tbl->row(dtf(DATE_FORMAT), sprintf("Testing storage #%d", ++$i),
                    $vl, $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL'
                );
                push @errors, $er if $er;
            }
            $tbl->row(dtf(DATE_FORMAT), $step,
                $j ? sprintf("Will be used %d storages", $j) : "No available storages found",
                $test ? $test < 0 ? 'SKIP' : 'PASS' : 'FAIL'
            );
            push @errors, "" unless $test;
        }


        #
        # File list fetching
        #
        $step = "File list fetching";
        $self->debug($step);
        my @filelist = $storage->list;
        $tbl->row(dtf(DATE_FORMAT), $step,
            join("\n", @filelist) || "No files found",
            $storage->error ? 'FAIL' : @filelist ? 'PASS' : 'SKIP',
        );
        if ($storage->error) {
            $self->log_error($storage->error);
            push @errors, $storage->error, "";
            $ostat = 0;
        };
        #say(explain(\@filelist));


        #
        # Deleting old files
        #
        #say(explain(\%keepfiles));
        $step = "Deleting old files";
        $self->debug($step);
        {
            my $j = 0; $i = 0;
            foreach my $f (@filelist) {
                next if $keepfiles{$f};
                my $st = -1; # SKIP
                if ($test > 0) { # Test PASSed!
                    $st = $storage->del($f);
                    if ($st) {
                       $j++;
                    } else {
                        $self->log_error($storage->error);
                        push @errors, $storage->error, "";
                        $ostat = 0;
                    };
                }
                $tbl->row(dtf(DATE_FORMAT), sprintf("Deleting file #%d", ++$i),
                    $f,
                    $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL'
                );
            }
            $tbl->row(dtf(DATE_FORMAT), $step,
                $j ? sprintf("Were deleted %d files", $j) : "No files for delete found",
                $test ? $test < 0 ? 'SKIP' : 'PASS' : 'FAIL'
            );
        }


        #
        # Backup archive
        #
        $step = "Backup performing";
        $self->debug($step);
        {
            my $st = -1; # SKIP
            if ($test > 0) { # Test PASSed!
                $st = $storage->put(
                        name => $archive_name,
                        file => $archive_file,
                        size => $size,
                    );
                unless ($st) {
                    $self->log_error($storage->error);
                    push @errors, $storage->error, "";
                    $ostat = 0;
                };
            }
            $tbl->row(dtf(DATE_FORMAT), $step,
                $archive_name,
                $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL'
            );
        }


        #
        # Removing temporary data
        #
        $step = "Cleaning";
        $self->debug($step);
        $self->error("");
        if (-e $archive_file) {
            $self->debug(sprintf("# unlink \"%s\"", $archive_file));
            if (unlink($archive_file)) {
                $tbl->row(dtf(DATE_FORMAT), $step, $archive_file, 'PASS');
            } else {
                my $msg = sprintf("Can't delete file %s: %s", $archive_file, $!);
                $self->log_error($msg);
                push @errors, $msg, "";
                $ostat = 0;
                $tbl->row(dtf(DATE_FORMAT), $step, $archive_file, 'FAIL');
            }
        } else {
            $tbl->row(dtf(DATE_FORMAT), $step, $archive_file, 'SKIP');
        }
        foreach my $rmo (@paths_for_remove) {
            $self->debug(sprintf("# rmtree \"%s\"", $rmo));
            rmtree($rmo) if -e $rmo;
        }

        #
        # Get SendMail config
        #
        my $sm = $self->_getSendmail($host);
        my $to = uv2null(value($sm, "to"));
        my $send_report = 1 if $to
            && ($to !~ /\@example.com$/)
            && (value($sm, "sendreport") || (value($sm, "senderrorreport") && !$ostat));
        push @header, ["Send report to", $to] if $send_report;

        #
        # Report generate
        #
        $tbl->hr;
        $tbl->row(dtf(DATE_FORMAT), 'RESULT',
            $ostat ? 'All processes successful' : 'Errors have occurred!',
            $ostat ? 'PASS' : 'FAIL'
        );
        push @header, ["Summary status", $ostat ? 'PASS' : 'FAIL'];
        my @report;
        my $report_name = $ostat ? "backup report" : "backup error report";
        push @report, $self->_report_common(@header); # Common information
        push @report, $self->_report_summary($ostat ? "Backup is done" : "Errors occurred while performing backup"); # Summary table
        push @report, $tbl->draw() || ''; # Table
        push @report, $self->_report_errors(@errors); # List of occurred errors
        if ($TTY || $self->verbosemode) { # Draw to TTY
            printf("%s\n\n", "~" x 114);
            printf("The %s for %s backup host\n\n", $report_name, $name);
            print join("\n", @report, "");
        }


        #
        # SendMail (Send report)
        #
        if ($send_report) {
            unshift @report, $self->_report_title($report_name, $name);
            push @report, $self->_report_footer();
            my %ma = (); foreach my $k (keys %$sm) { $ma{"-".$k} = $sm->{$k} };
            $ma{"-subject"} = sprintf("%s %s (%s on %s)", PROJECTNAME, $report_name, $name, $hostname);
            $ma{"-message"} = join("\n", @report);

            # Send!
            my $sent = sendmail(%ma);
            if ($sent) { $self->debug(sprintf("Mail has been sent to: %s", $to)) }
            else { $self->error(sprintf("Mail was not sent to: %s", $to)) }
        }

        # Finish backup
        $self->log_info("Finish backup process for \"%s\" backup host section", $name);

        # General status
        $status = 0 unless $ostat;
    }

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "restore",
    description => "Restore hosts",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my $status = 1;

    # Get host-list
    my @hosts = $self->_getHosts();
    unless (scalar(@hosts)) {
        $self->log_warn("No enabled <Host> configuration section found");
        return 1;
    }

    # Date defined
    my $tdate = pop @arguments;
    my ( $_y, $_m, $_d ) = (localtime( time ))[5,4,3];
    my @ymd = (($_y+1900), ($_m+1), $_d);
    my $is_now = 1;
    if (defined($tdate)) {
        if ($tdate =~ /(\d{4})\D+(\d{2})\D+(\d{2})/) { # YYYY-MM-DD
            @ymd = ($1,$2,$3);
            $is_now = 0;
        } elsif ($tdate =~ /(\d{2})\D+(\d{2})\D+(\d{4})/) { # DD-MM-YYY
            @ymd = ($3,$2,$1);
            $is_now = 0;
        } else {
            push @arguments, $tdate;
        }
    }

    # Start
    foreach my $pair (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @hosts) {
        my @header;
        my @errors;
        my $step = '';
        my $ostat = 1; # Operation status


        #
        # Init
        #
        my $name = _getName($pair); # Backup name
        my $host = node($pair, $name); # Config section
        my $hostskip = (!@arguments || grep {lc($name) eq lc($_)} @arguments) ? 0 : 1;
        my $enabled = value($host, 'enable') ? 1 : 0;
        if ($hostskip || !$enabled) {
            $self->log_info("Skip restore process for \"%s\" backup host section", $name);
            next;
        }
        my $tbl = Text::SimpleTable->new(@{(TABLE_HEADERS)});
        $self->log_info("Start restore process for \"%s\" backup host section", $name);
        push @header, ["Backup name", $name];
        push @errors, $self->getdbi->dsn, $self->getdbi->error, "" if $self->getdbi->error;

        # Get mask vars
        my $arc = $self->_getArc($host);
        my $arcmask = value($host, 'arcmask') || ARC_MASK;
           $arcmask =~ s/\[DEFAULT\]/ARC_MASK()/gie;
        my %maskfmt = (
                HOST  => $name,
                YEAR  => sprintf("%04d", $ymd[0]),
                MONTH => sprintf("%02d", $ymd[1]),
                DAY   => sprintf("%02d", $ymd[2]),
                EXT   => value($arc, 'ext') || '',
            );
        my $archive_name = dformat($arcmask, {%maskfmt});
        push @header, ["Backup mask", $arcmask];


        #
        # Checking collectors
        #
        $step = "Collectors checking";
        $self->debug($step);
        my $collector = new App::MBUtiny::Collector(
                collector_config => $self->_getCollector($host),
                dbi => $self->getdbi, # For local storage only
            );
        my $colret = $collector->check;
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
        }
        $tbl->row(dtf(DATE_FORMAT), $step,
            $collector->error ? "No available collectors" : $colret,
            $collector->error ? 'FAIL' : $colret ? 'PASS' : 'SKIP',
        );


        #
        # Getting information about file on collector
        #
        my %info = $collector->info(name => $name, file => $is_now ? undef : $archive_name);
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
        }
        if ($info{status}) {
            $archive_name = $info{file} if $is_now;
            push @header, ["Archive name", $archive_name];
            push @header, (
                ["Archive size", $info{size}],
                ["Archive MD5", $info{md5}],
                ["Archive SHA1", $info{sha1}],
            );
        } else {
            push @header, ["Archive name", $archive_name];
        }
        my $archive_file = File::Spec->catfile($self->rstdir, $archive_name);
        push @header, ["Archive file", $archive_file];


        #
        # Testing storages
        #
        $step = "Storages testing";
        $self->debug($step);
        my $storage = new App::MBUtiny::Storage(
                name => $name, # Backup name
                host => $host, # Host config section
                path => $self->rstdir, # Where is located restored backup archive
                validate => sub {
                    my $strg = shift; # storage object
                    my $file = shift; # fetched file
                    if ($info{size}) { # Valid sizes
                        my $size = filesize($file) // 0;
                        unless ($size == $info{size}) {
                            $strg->error(sprintf("File size incorrect: got=%d; expected=%d", $size, $info{size}));
                            return 0;
                        }
                    }
                    if ($info{md5}) { # Valid md5
                        my $md5 = md5sum($file) // "";
                        unless ($md5 eq $info{md5}) {
                            $strg->error(sprintf("File MD5 checksum incorrect: got=%s; expected=%s", $md5, $info{md5}));
                            return 0;
                        }
                    }
                    if ($info{sha1}) { # Valid sha1
                        my $sha1 = sha1sum($file) // "";
                        unless ($sha1 eq $info{sha1}) {
                            $strg->error(sprintf("File SHA1 checksum incorrect: got=%s; expected=%s", $sha1, $info{sha1}));
                            return 0;
                        }
                    }
                    return 1;
                });
        my $test = $storage->test or do {
            $self->log_error($storage->error);
            push @errors, $storage->error;
            $ostat = 0;
        };
        {
            my $j = 0; my $i = 0;
            foreach my $tr ($storage->test_report) {
                my ($st, $vl, $er) = @$tr;
                $j++ if $st && $st > 0;
                $tbl->row(dtf(DATE_FORMAT), sprintf("Testing storage #%d", ++$i),
                    $vl, $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL'
                );
                push @errors, $er if $er;
            }
            $tbl->row(dtf(DATE_FORMAT), $step,
                $j ? sprintf("Will be used %d storages", $j) : "No available storages found",
                $test ? $test < 0 ? 'SKIP' : 'PASS' : 'FAIL'
            );
            push @errors, "" unless $test;
        }


        #
        # File list fetching
        #
        $step = "File list fetching";
        $self->debug($step);
        my @filelist = $storage->list;
        $tbl->row(dtf(DATE_FORMAT), $step,
            join("\n", @filelist) || "No files found",
            $storage->error ? 'FAIL' : @filelist ? 'PASS' : 'SKIP',
        );
        if ($storage->error) {
            $self->log_error($storage->error);
            push @errors, $storage->error, "";
            $ostat = 0;
        };
        my $is_exists = 0;
        if (grep {$_ eq $archive_name} @filelist) {
            $tbl->row(dtf(DATE_FORMAT), "The file searching", $archive_name, 'PASS');
            $is_exists = 1;
        } else {
            $tbl->row(dtf(DATE_FORMAT), "The file searching", "File not found", 'SKIP');
        }


        #
        # Restore archive
        #
        $step = "Restore performing";
        $self->debug($step);
        my $is_downloaded = 0;
        {
            my $st = -1; # SKIP
            if ($is_exists && $test > 0) { # Test PASSed and file is exists on storages!
                $st = $storage->get(
                    name => $archive_name,
                    file => $archive_file,
                );
                if ($st) {
                    $is_downloaded = 1 if $st == 1;
                } else {
                    $self->log_error($storage->error);
                    push @errors, $storage->error, "";
                    $ostat = 0;
                };
            }
            $tbl->row(dtf(DATE_FORMAT), $step,
                $archive_name,
                $st ? $st < 0 ? 'SKIP' : 'PASS' : 'FAIL'
            );
        }
        #print(explain($storage->{storages}));

        #
        # Extracting archive
        #
        $step = "Extracting archive";
        $self->debug($step);
        my $restore_dir = File::Spec->catdir($self->rstdir, $name,
            sprintf("%04d-%02d-%02d", $ymd[0], $ymd[1], $ymd[2]));
        if ($is_downloaded) {
            preparedir($restore_dir);
            my $st = $self->_extract(
                arcdef => $arc,
                archive=> $archive_file,
                dirdst => $restore_dir,
            );
            if ($st) {
                push @header, ["Location of restored backup", $restore_dir];
                $self->log_info("Downloaded backup archive: %s", $archive_file);
                $self->log_info("Location of restored backup: %s", $restore_dir);
            } else {
                my $msg = sprintf("Extracting archive \"%s\" failed: %s", $archive_file, $self->error);
                $self->log_error($msg);
                push @errors, $msg, "";
                $ostat = 0;
            }
            $tbl->row(dtf(DATE_FORMAT), $step, $archive_name, $st ? 'PASS' : 'FAIL');
        } else {
            $tbl->row(dtf(DATE_FORMAT), $step, $archive_name, 'SKIP');
        }


        #
        # Report generate
        #
        $tbl->hr;
        $tbl->row(dtf(DATE_FORMAT), 'RESULT',
            $ostat ? 'All processes successful' : 'Errors have occurred!',
            $ostat ? 'PASS' : 'FAIL'
        );
        push @header, ["Summary status", $ostat ? 'PASS' : 'FAIL'];
        my @report;
        my $report_name = $ostat ? "restore report" : "restore error report";
        push @report, $self->_report_common(@header); # Common information
        push @report, $self->_report_summary($ostat ? "Restore is done" : "Errors occurred while performing restore"); # Summary table
        push @report, $tbl->draw() || ''; # Table
        push @report, $self->_report_errors(@errors); # List of occurred errors
        if ($TTY || $self->verbosemode) { # Draw to TTY
            printf("%s\n\n", "~" x 114);
            printf("The %s for %s backup host\n\n", $report_name, $name);
            print join("\n", @report, "");
        }


        # Finish restore
        $self->log_info("Finish restore process for \"%s\" backup host section", $name);

        # General status
        $status = 0 unless $ostat;
    }

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "report",
    description => "Reporting",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my $status = 1;
    my @header;
    my @errors;
    my @comments;

    # Get host-list
    my @hosts = $self->_getHosts();
    unless (scalar(@hosts)) {
        $self->log_warn("No enabled <Host> configuration section found");
        return 1;
    }


    #
    # Init
    #
    my $tbl_report = Text::SimpleTable->new(@{(REPORT_TABLE_HEADERS)});
    my $tbl_hosts = Text::SimpleTable->new(@{(REPORT_HOSTS_HEADERS)});
    my $tbl_collectors = Text::SimpleTable->new(@{(REPORT_COLLECTORS_HEADERS)});
    $self->log_info("Start reporting for \"%s\"", $hostname);
    push @header, ["Hostname", $hostname];
    push @errors, $self->getdbi->dsn, $self->getdbi->error, "" if $self->getdbi->error;
    my @req_hosts = map {$_ = trim($_) } split(/\s+/, $self->config('require') || '');

    #
    # Hosts processing
    #
    my @collectors = ();
    foreach my $pair (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @hosts) {
        my $name = _getName($pair); # Backup name
        my $host = node($pair, $name); # Config section
        my $hostskip = (!@arguments || grep {lc($name) eq lc($_)} @arguments) ? 0 : 1;
        my $enabled = value($host, 'enable') ? 1 : 0;
        $tbl_hosts->row($name, ($hostskip || !$enabled) ? 'SKIP' : 'PASS');
        if ($hostskip || !$enabled) {
            $self->log_info("Skip reporting for \"%s\" backup host section", $name);
            next;
        }
        my $lcols = $self->_getCollector($host);
        push @collectors, @$lcols;
    }
    push @collectors, {} unless @collectors; # Default support
    #say(explain(\@collectors));

    #
    # Select collectors
    #
    my %cols;
    foreach my $col (@collectors) {
        my $url = value($col, 'url') || 'local';
        $cols{$url} = $col unless $cols{$url};
    }
    @collectors = values %cols;
    #say(explain(\@collectors));


    #
    # Collectors checking
    #
    my @ok_collectors = ();
    foreach my $col (@collectors) {
        my $url = value($col, 'url') || 'local';
        my $comment = value($col, 'comment');
        my $collector = new App::MBUtiny::Collector(
                collector_config => [$col],
                dbi => $self->getdbi, # For local storage only
            );
        my $colret = $collector->check;
        $tbl_collectors->row($colret, $collector->error ? 'FAIL' : $colret ? 'PASS' : 'SKIP');
        push @comments, sprintf("%s: %s", $colret || $url, $comment), "" if $comment;
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
            next;
        }
        next unless $colret;
        push @ok_collectors, $col
    }

    #
    # Collectors processing
    #
    my @backups;
    if (@ok_collectors) {
        my $collector = new App::MBUtiny::Collector(
                collector_config => [@ok_collectors],
                dbi => $self->getdbi, # For local storage only
            );
        @backups = $collector->report(); # start => 1561799600;
        if ($collector->error) {
            $self->log_error(sprintf("Collector error: %s", $collector->error));
            push @errors, $collector->error, "";
        }
    }

    #
    # Get report data about LAST backups on collector for each available host
    #
    my %requires;
    foreach (@req_hosts) {$requires{$_} = 0};
    foreach my $rec (@backups) {
        push @comments, sprintf("%s: %s", uv2null($rec->{file}), $rec->{comment}), "" if $rec->{comment};
        push @errors, uv2null($rec->{file}), $rec->{error}, "" if $rec->{error};
        my $nm = $rec->{name} || 'virtual';
        $tbl_report->row(
            sprintf("%s\n%s", $nm, uv2null($rec->{addr})),
            sprintf("%s\n%s (%s bytes)",
                    variant_stf(uv2null($rec->{file}), 32),
                    _fbytes(uv2zero($rec->{size})),
                    correct_number(uv2zero($rec->{size}))
                ),
            uc(substr(int2type(uv2zero($rec->{type})), 0, 3)),
            dtf(DATE_FORMAT, $rec->{'time'}),
            $rec->{status} ? 'PASS' : 'FAIL',
        );
        $requires{$nm} = 1 if $rec->{status};
    }

    #
    # Requires
    #
    if (grep { !$_ } values(%requires)) {
        $tbl_report->hr;
        foreach my $nm (grep {!$requires{$_}} keys %requires) {
            $tbl_report->row($nm,'','','',"UNKN");
        }
        $status = 0;
    }


    #
    # Get SendMail config
    #
    my $sm = $self->_getSendmail();
    my $to = uv2null(value($sm, "to"));
    my $send_report = 1 if $to
        && ($to !~ /\@example.com$/)
        && (value($sm, "sendreport") || (!$status && value($sm, "senderrorreport")));
    push @header, ["Send report to", $to] if $send_report;


    #
    # Report generate
    #
    $tbl_report->hr;
    $tbl_report->row('RESULT', '', '', '', $status ? 'PASS' : 'FAIL');
    push @header, ["Summary status", $status ? 'PASS' : 'FAIL'];
    my @report;
    my $report_name = $status ? "report" : "error report";
    push @report, $self->_report_common(@header); # Common information
    push @report, "Hosts:", $tbl_hosts->draw(); # Hosts table
    push @report, "Collectors:", $tbl_collectors->draw(); # Hosts table
    push @report, $self->_report_summary($status ? "All tests successful" : "Errors occurred while testing"); # Summary table
    push @report, $tbl_report->draw(); # Report table
    push @report, "Comments:", "", @comments, "" if @comments;
    push @report, $self->_report_errors(@errors); # List of occurred errors
    if ($TTY || $self->verbosemode) { # Draw to TTY
        printf("%s\n\n", "~" x 106);
        printf("The %s for all backup hosts on %s\n\n", $report_name, $hostname);
        print join("\n", @report, "");
    }


    #
    # SendMail (Send report)
    #
    if ($send_report) {
        unshift @report, $self->_report_title($report_name, "last backups");
        push @report, $self->_report_footer();
        my %ma = (); foreach my $k (keys %$sm) { $ma{"-".$k} = $sm->{$k} };
        $ma{"-subject"} = sprintf("%s %s (%s on %s)", PROJECTNAME, $report_name, "last backups", $hostname);
        $ma{"-message"} = join("\n", @report);

        # Send!
        my $sent = sendmail(%ma);
        if ($sent) { $self->debug(sprintf("Mail has been sent to: %s", $to)) }
        else { $self->error(sprintf("Mail was not sent to: %s", $to)) }
    }

    # Finish reporting
    $self->log_info("Finish reporting for \"%s\"", $hostname);

    return $status;
});


sub configure {
    my $self = shift;
    my $config = $self->configobj;

    # DBI object
    my $dbi_conf = $self->config('dbi') || {};
       $dbi_conf = {} unless is_hash($dbi_conf);
    my $dbi = new App::MBUtiny::Collector::DBI(%$dbi_conf);
    $self->{_dbi} = $dbi;
    if ($config->status) {
        $self->error($dbi->error) if $dbi->error;
        return 1;
    }

    # Creting DB
    if ($dbi->is_sqlite) {
        printf("Creating local database %s...\n", $dbi->{file});
    } else {
        printf("Checking database %s...\n", $dbi->dsn);
    }
    if ($dbi->error) {
        say "Fail.";
        $self->error($dbi->error);
    } else {
        say "Done.";
    }

    # Creating configuration
    my $skel = new CTK::Skel (
            -name   => PROJECTNAME,
            -root   => $self->root,
            -skels  => {
                        config => 'App::MBUtiny::ConfigSkel',
                    },
            -vars   => {
                    PROJECT         => PROJECTNAME,
                    PROJECTNAME     => PROJECTNAME,
                    PREFIX          => PREFIX,
                },
            -debug  => $self->debugmode,
        );
    #say("Skel object: ", explain($skel));
    printf("Creating configuration to %s...\n", $self->root);
    if ($skel->build("config")) {
        $self->CTK::Plugin::Config::init;
        $config = $self->configobj;
        unless ($config->status) {
            say "Fail.";
            return 0;
        }
        say "Done.";
    } else {
        say "Fail.";
        $self->error(sprintf("Can't %s initialize: %s", PREFIX, $self->root));
        return 0;
    }
    return 1;
}

# Private methods
sub _getHosts { # Get host-sections as array of hashes
    my $self = shift;
    my $hosts = $self->config("host");
    my @jobs = ();
    if (ref($hosts) eq 'ARRAY') {
        foreach my $r (@$hosts) {
            if ((ref($r) eq 'HASH') && exists $r->{enable}) {
                push @jobs, $r;
            } elsif (ref($r) eq 'HASH') {
                foreach my $k (keys %$r) {
                    push @jobs, { $k => $r->{$k} };
                }
            }
        }
    } elsif ((ref($hosts) eq 'HASH') && !exists $hosts->{enable}) {
        foreach my $k (keys %$hosts) {
            push @jobs, { $k => $hosts->{$k} };
        }
    } else {
        push @jobs, $hosts;
    }
    return @jobs;
}
sub _getDates { # Get available dates
    my $self = shift;
    my $buday   = shift || 0; # Dayly
    my $buweek  = shift || 0; # Weekly
    my $bumonth = shift || 0; # Monthly

    my %dates = ();
    my $wcnt = 0;
    my $mcnt = 0;

    # Set period as maximum days to "back"
    my $period = 7 * $buweek > $buday ? 7 * $buweek : $buday;
    $period = 30 * $bumonth if 30 * $bumonth > $period;

    for (my $i=0; $i<$period; $i++) {
        my ( $y, $m, $d, $wd ) = (localtime( time - $i * 86400 ))[5,4,3,6];
        my $date = sprintf( "%04d%02d%02d", ($y+1900), ($m+1), $d );

        if (($i < $buday)
                || (($i < $buweek * 7) && $wd == 0) # do weekly backups on sunday
                || (($i < $bumonth * 30) && $d == 1)) # do monthly backups on 1-st day of month
        {
            $dates{ $date } = 1;
        } else {
            $dates{ $date } = 0;
        }

        if (($i < $buday) || (($wd == 0) && (($wcnt++) < $buweek)) || (($d == 1) && (($mcnt++) < $bumonth))) {
            $dates{$date} ++;
        }

        delete $dates{$date} unless $dates{$date};
    }

    return sort keys %dates;
}
sub _getArc { # Get arc section or default arcdef record
    my $self = shift;
    my $host = shift || {};
    my $arcdef = hash($self->config('arc'));
       $arcdef = CTK::Plugin::Archive::ARC_OPTIONS()->{CTK::Plugin::Archive::ARC_DEFAULT()}
        unless value($arcdef, 'ext');
    my $arc = hash($host, 'arc');
    return $arcdef unless value($arc, 'ext');
    return $arc;
}
sub _getCollector {
    my $self = shift;
    my $host = shift || {};
    my $collector_def = $self->config('collector');
    my $collector = node($host, 'collector');
    return node2anode($collector_def) if is_void($collector);
    return node2anode($collector);
}
sub _getSendmail {
    my $self = shift;
    my $host = shift || {};
    my $sm_def = hash($self->config('sendmail'));
    my $sm = hash($host, 'sendmail');
    my %out = %$sm_def;
    foreach my $k (keys %$sm) {
        $out{$k} = $sm->{$k} if exists($sm->{$k})
    }

    $out{sendreport}        = (value($host => 'sendreport') // $self->config('sendreport')) || 0;
    $out{senderrorreport}   = (value($host => 'senderrorreport') // $self->config('senderrorreport')) || 0;

    return {%out};
}
sub _compress {
    my $self = shift;
    my %args = @_;
    my $list = $args{list} || [];
    my $arcdef = $args{arcdef} || {};
    my $archive = $args{archive} || "";

    # Arc
    my $arc_create = $arcdef->{create};
    my $arc_append = $arcdef->{append} || $arc_create;
    my $arc_ext = $arcdef->{ext} || '';
    my $arc_proc = $arcdef->{postprocess};

    # Compress
    my $count = 0;
    foreach my $o (@$list) {
        my $rplc = {
                NAME => $archive,
                EXT  => $arc_ext,
                FILE => sprintf("%s%s", $archive, $arc_ext),
                LIST => $o,
            };
        my $cmd = $count ? dformat($arc_append, $rplc) : dformat($arc_create, $rplc);
        $self->debug(sprintf("# %s", $cmd));
        my $errdata = "";
        my $outdata = execute( $cmd, undef, \$errdata, 1 );
        my $exe_stt = $? >> 8;
        $self->debug($outdata) if $self->verbosemode && defined($outdata) && length($outdata);
        $self->error($errdata) if $exe_stt;
        $count++;
    }

    # PostProc
    my @postproc;
    if ($arc_proc && ref($arc_proc) eq "ARRAY") {@postproc = @$arc_proc}
    elsif ($arc_proc) {@postproc = ($arc_proc)}
    foreach my $proc (@postproc) {
        next unless $proc;
        my $rplc = {
                NAME => $archive,
                EXT  => $arc_ext,
                FILE => sprintf("%s%s", $archive, $arc_ext),
            };
        my $cmd = dformat($proc, $rplc);
        $self->debug(sprintf("# %s", $cmd));
        my $errdata = "";
        my $outdata = execute( $cmd, undef, \$errdata, 1 );
        my $exe_stt = $? >> 8;
        $self->debug($outdata) if $self->verbosemode && defined($outdata) && length($outdata);
        $self->error($errdata) if $exe_stt;
    }

    return $count; # Number of objects
}
sub _extract {
    my $self = shift;
    my %args = @_;
    my $arcdef = $args{arcdef} || {};
    my $archive = $args{archive} || "";
    my $dirdst = $args{dirdst} || $self->rstdir;

    # Extract
    my $rplc = {
            FILE    => $archive,
            EXT     => $arcdef->{ext} || '',
            DIRDST  => $dirdst,
            DIROUT  => $dirdst,
        };
    my $cmd = dformat($arcdef->{extract}, $rplc);
    $self->debug(sprintf("# %s", $cmd));
    my $errdata = "";
    my $outdata = execute( $cmd, undef, \$errdata, 1 );
    my $exe_stt = $? >> 8;
    $self->debug($outdata) if $self->verbosemode && defined($outdata) && length($outdata);
    $self->error($errdata) if $exe_stt;

    return $exe_stt ? 0 : 1;
}

# Report internal methods
sub _report_title {
    my $self = shift;
    my $title = shift || "report";
    my $name = shift || "virtual";
    return (
        sprintf("Dear %s user,", PROJECTNAME),"",
        sprintf("This is a automatic-generated %s for %s backup\non %s, created by %s/%s",
            $title, $name, $hostname, __PACKAGE__, $VERSION),"",
        "Sections of this report:","",
        " * Common information",
        " * Summary",
        " * List of occurred errors","",
    );
}
sub _report_common {
    my $self = shift;
    my @hdr = @_;
    my @rep = (
        "-"x32,
        "COMMON INFORMATION",
        "-"x32,"",
    );
    my $maxlen = 0;
    foreach my $r (@hdr) {
        $maxlen = length($r->[0]) if $maxlen < length($r->[0])
    }
    foreach my $r (@hdr) {
        push @rep, sprintf("%s %s: %s", $r->[0], " "x($maxlen-length($r->[0])),  $r->[1]);
    }
    push @rep, "";
    return (@rep);
}
sub _report_summary {
    my $self = shift;
    my $summary = shift || "Ok";
    my @rep = (
        "-"x32,
        "SUMMARY",
        "-"x32,"",
    );
    push @rep, $summary, "";
    return (@rep);
}
sub _report_errors {
    my $self = shift;
    my @errs = @_;
    my @rep = (
        "-"x32,
        "LIST OF OCCURRED ERRORS",
        "-"x32,"",
    );
    if (@errs) {
        push @rep, @errs;
    } else {
        push @rep, "No errors occurred";
    }
    return (@rep, "");
}
sub _report_footer {
    my $self = shift;
    return sprintf(join("\n",
            "",
            "---",
            "Hostname    : %s",
            "Program     : %s (%s, Perl %s)",
            "Version     : %s/%s",
            "Config file : %s",
            "PID         : %d",
            "Work time   : %s",
            "Generated   : %s"
        ),
        $hostname, $0, $^O, $^V, PROJECTNAME, $VERSION, $self->configfile(),
        $$, $self->tms(), dtf("%w, %DD %MON %YYYY %hh:%mm:%ss"),
    );
}

# Private functions
sub _getName { # Get normalized name og structure
    my $struct = hash(shift);
    my @ks = keys %$struct;
    return '' unless @ks;
    return 'VIRTUAL' if exists $ks[1];
    return ($ks[0] && ref($struct->{$ks[0]}) eq 'HASH') ? $ks[0] : 'VIRTUAL';
}
sub _node_correct { # Virtual nodes supports
    my $j = shift; # Node
    my $kk = shift || 'object';

    my @nc = ();
    if (ref($j) eq 'ARRAY') {
        my $i = 0;
        foreach my $r (@$j) {$i++;
            if ((ref($r) eq 'HASH') && exists $r->{$kk}) {
                push @nc, { sprintf("virtual_%03d",$i) => $r };
            } elsif (ref($r) eq 'HASH') {
                foreach my $k (keys %$r) {
                    push @nc, { $k => $r->{$k} };
                }
            }
        }
    } elsif ((ref($j) eq 'HASH') && !exists $j->{$kk}) {
        foreach my $k (keys %$j) {
            push @nc, { $k => $j->{$k} };
        }
    } else {
        push @nc, { "virtual" => $j } if defined $j;
    }
    return [@nc];
}
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GB", $n / (1024 ** 3);
    } elsif ($n >= 1024 * 1024) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n bytes";
    }
}

sub DESTROY {
    my $self = shift;

    rmtree($self->{objdir}) if $self->{objdir} && -e $self->{objdir};
    rmtree($self->{excdir}) if $self->{excdir} && -e $self->{excdir};

    1;
}

1;

__END__
