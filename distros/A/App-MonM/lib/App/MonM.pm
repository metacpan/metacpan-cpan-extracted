package App::MonM; # $Id: MonM.pm 85 2019-07-14 12:03:14Z abalama $
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM - Simple monitoring tool

=head1 VERSION

Version 1.06

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

=item libwww

=item libnet

=item L<Net-SNMP|http://net-snmp.sourceforge.net>

To use this module, you must have Net-SNMP installed on your system.
More specifically you need the Perl modules that come with it.

DO NOT INSTALL SNMP or Net::SNMP from CPAN!

The SNMP module is matched to an install of net-snmp, and must be installed
from the net-snmp source tree.

The Perl module C<SNMP> is found inside the net-snmp distribution. Go to the
F<perl/> directory of the distribution to install it, or run
C<./configure --with-perl-modules> from the top directory of the net-snmp
distribution.

Net-SNMP can be found at http://net-snmp.sourceforge.net

=back

=head2 INSTALLATION

    # sudo cpan install App::MonM

...and then:

    # sudo monm configure

=head2 CONFIGURATION

By default configuration file located in C</etc/monm> directory

Every configuration directive detailed described in C<monm.conf> file, also
see C<conf.d/checkit-foo.conf.sample> file for MonM checkit configuration

=head2 CRONTAB

To automatically launch the program, we recommend using standard scheduling tools, such as crontab

    * * * * * monm -l checkit >/dev/null 2>>/var/log/monm-error.log

For daily reporting:

    0 8 * * * monm -l report >/dev/null 2>>/var/log/monm-error.log

=head1 INTERNAL METHODS

=over 4

=item B<again>

The CTK method for classes extension. For internal use only!

See L<CTK/again>

=item B<configure>

The internal method for initializing the project

=item B<getdbi>

    my $dbi = $app->getdbi;

Returns DBI object

=item B<nope>, B<skip>, B<wow>, B<yep>

    my $status = $app->nope("Format %s", "text");

Prints status message and returns status.

For nope returns - 0; for skip, wow, yep - 1

=item B<notify>

    $app->notify();

Sends notifications

=item B<trigger>

    $app->trigger();

Runs triggers

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

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.06';

use feature qw/ say /;

use Carp;
use Text::SimpleTable;
use File::Spec;
use File::Path; # mkpath / rmtree
use Try::Tiny;
use Text::ParseWords qw/shellwords/;

use CTK::Skel;
use CTK::Util qw/ preparedir dformat execute dtf sendmail variant_stf /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use App::MonM::Const;
use App::MonM::Util qw/
        blue green red yellow cyan
        getBit setBit
        getExpireOffset explain
    /;
use App::MonM::Store;
use App::MonM::Checkit;

use base qw/ CTK::App /;

use constant {
    TAB9            => " " x 9,
    EXPIRES          => 24*60*60, # 1 day
    SMSSBJ          => 'MONM CHECKIT REPORT',
    DATE_FORMAT     => '%YYYY-%MM-%DD %hh:%mm:%ss',
    TABLE_HEADERS   => [(
            [32, 'NAME'],
            [7,  'TYPE'],
            [19, 'LAST CHECK DATE'],
            [7,  'STATUS'],
        )],
};

eval { require App::MonM::Notifier::Agent };
my $NOTIFIER_LOADED = 1 unless $@;

sub again {
    my $self = shift;

    # Datadir & Tempdir
    if ($self->option("datadir")) {
        preparedir( $self->datadir() );
    } else {
        $self->datadir($self->tempdir());
    }
    preparedir( $self->tempdir() );

    # Notifier agent init
    $self->{notifier} = undef;

    return $self->SUPER::again;
}
sub configure {
    my $self = shift;
    my $config = $self->configobj;

    # DBI object
    my $dbi_file = File::Spec->catfile($self->datadir, App::MonM::Store::DB_FILENAME());
    my $dbi_conf = $self->config('dbi') || {file => $dbi_file};
       $dbi_conf = {file => $dbi_file} unless is_hash($dbi_conf);
    my $dbi = new App::MonM::Store(%$dbi_conf);
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
        say( IS_TTY ? red("Fail") : "Fail");
        $self->error($dbi->error);
    } else {
        say( IS_TTY ? green("Done") : "Done");
    }

    # Creating configuration
    my $skel = new CTK::Skel (
            -name   => PROJECTNAME,
            -root   => $self->root,
            -skels  => {
                        config => 'App::MonM::ConfigSkel',
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
            say( IS_TTY ? red("Fail") : "Fail");
            return 0;
        }
        say( IS_TTY ? green("Done") : "Done");
    } else {
        say( IS_TTY ? red("Fail") : "Fail");
        $self->error(sprintf("Can't %s initialize: %s", PREFIX, $self->root));
        return 0;
    }

    return 1;
}
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
    handler     => "checkit",
    description => "Checkit",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my $status = 1;

    printf("Start of checking for %s...\n", HOSTNAME);
    $self->wow("Will checked: %s", join(", ", @arguments)) if @arguments;

    # Get DBI
    my $dbi = $self->getdbi;
    return 0 if $dbi->error;

    # Get checkits
    my @checkits = $self->_getCheckits(@arguments);
    unless (scalar(@checkits)) {
        $self->log_warn("No enabled <Checkit> configuration section found");
        return 1;
    }

    # Create Checkit object
    my $checker = new App::MonM::Checkit;

    # Get all records from DB
    my %all;
    foreach my $r ($dbi->getall) {
        $all{$r->{name}} = $r;
    }
    if ($dbi->error) {
        $self->error($dbi->error);
        return 0;
    }

    # Init notifier and sending messages
    if ($NOTIFIER_LOADED) {
        $self->{notifier} = App::MonM::Notifier::Agent->new(
            configobj => $self->configobj,
        );
        my $agent = $self->{notifier};
        unless ($agent->status) {
            $self->error($agent->error);
            return 0;
        }

        # Run sending messages
        $agent->trysend() or do {
            $self->log_error($agent->error);
        };
    }

    # Start
    foreach my $checkit (sort {$a->{name} cmp $b->{name}} @checkits) {
        my $ostat = 1; # Operation status
        my $name = $checkit->{name};
        my $info = $all{$name} || {};
        my $id = $info->{id} || 0;
        my $old = $info->{status} || 0;
        my $got = ($old << 1) & 15;

        # Check
        $ostat = $checker->check($checkit);
        $self->log_info("Checking %s (%s >>> %s): %s", $name, $checker->source, $checker->message, $ostat ? 'OK' : "FAIL");
        if ($ostat) {
            $self->yep("Checking %s (%s >>> %s)", $name, $checker->source, $checker->message);
            $got = setBit($got, 0); # Set first bit
        } else {
            $self->nope("Checking %s (%s >>> %s)", $name, $checker->source, $checker->message);
            say(TAB9, red($checker->error));
        }

        # Save data to database
        my %rec = (
            id      => $id,
            name    => $name,
            type    => $checker->type,
            source  => $checker->source,
            status  => $got,
            message => $checker->message,
        );
        if ($id) {
            $dbi->set(%rec) or do {
                $self->error($dbi->error);
                $status = 0;
                next;
            };
        } else {
            $dbi->add(%rec) or do {
                $self->error($dbi->error);
                $status = 0;
                next;
            };
        }

        # Triggers, Sending and notifies
        # [0-0-1-1] = 3  -- OK
        # [1-1-0-0] = 12 -- PROBLEM
        if ($got == 3 or $got == 12 or $self->testmode) {
            my %data = (
                    name    => $name,
                    type    => $checker->type,
                    source  => $checker->source,
                    status  => $ostat,
                    error   => $checker->error,
                    message => $checker->message,
                    sendto  => array($checkit, "sendto"),
                    trigger => array($checkit, "trigger"),
                );
            $self->notify(%data);
            $self->trigger(%data);
        }

        # General status
        $status = 0 unless $ostat;
    }

    # Cleaning DB
    my $expire = getExpireOffset($self->config("expires") || $self->config("expire") || EXPIRES);
    $dbi->clean(period => $expire) or do {
        $self->error($dbi->error);
        return 0;
    };

    # Finish
    printf("Finish of checking for %s (%s)\n", HOSTNAME, $self->tms);

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "report",
    description => "Checkit report",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my (@header, @errors, @report, @table);
    my $status = 1;

    # Init
    my $tbl = Text::SimpleTable->new(@{(TABLE_HEADERS)});

    # Start reporting
    printf("Start of the checkit reporting for %s...\n", HOSTNAME);
    $self->wow("Will checked: %s", join(", ", @arguments)) if @arguments;
    $self->log_info("Start of the checkit reporting for \"%s\"", HOSTNAME);

    # Header
    push @header, ["Hostname", HOSTNAME];

    # Get DBI
    my $dbi = $self->getdbi;
    push @header, ["Database DSN", $dbi->dsn];
    if ($dbi->error) {
        push @errors, $dbi->dsn, $dbi->error, "";
        $self->log_error("%s: %s", $dbi->dsn, $dbi->error);
        $self->nope($dbi->dsn);
        say(TAB9, red($dbi->error));
        $status = 0;
    }

    # Get checkits
    my @checkits = $self->_getCheckits(@arguments);
    my $noc = scalar(@checkits);
    push @header, ["Number of checks", $noc ? $noc : "no checks"];
    unless ($noc) {
        $self->log_warn("No enabled <Checkit> configuration section found");
        $status = 0;
    }

    # Get all records from DB
    my %all;
    if ($status) {
        foreach my $r ($dbi->getall) {
            $all{$r->{name}} = $r;
        }
        if ($dbi->error) {
            push @errors, $dbi->dsn, $dbi->error, "";
            $self->log_error("%s: %s", $dbi->dsn, $dbi->error);
            $self->nope($dbi->dsn);
            say(TAB9, red($dbi->error));
            $status = 0;
        }
    }

    #
    # General cycle
    #
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
            $ostat ? $ostat > 0 ? 'OK' : 'UNKNOWN' : 'PROBLEM',
        );
        unless ($ostat) {
            push @errors, sprintf("%s (%s >>> %s)", $name, $info->{source} || '', $info->{message} || ''), "";
        }
        #say(explain($info));
    }
    $tbl->hr;
    $tbl->row('SUMMARY', "", "", $noc ? $status ? 'OK' : 'PROBLEM' : 'UNKNOWN');

    # Get SendMail config
    my $sendmail = hash($self->config('sendmail'));
    my $to = uv2null(value($sendmail, "to"));
    my $send_report = 1 if $to && $to !~ /\@example.com$/;
    push @header, ["Send report to", $to] if $send_report;

    #
    # Report generate
    #
    push @header, ["Summary status", $status ? 'OK' : 'PROBLEM'];
    my $report_name = $status ? "checking report" : "error report";
    push @report, $self->_report_common(@header); # Common information
    push @report, $self->_report_summary($status ? "All last checks successful" : "Errors occurred while checking"); # Summary table
    push @report, $tbl->draw(); # Report table
    push @report, $self->_report_errors(@errors); # List of occurred errors
    if (IS_TTY || $self->verbosemode) { # Draw to TTY
        printf("%s\n\n", "~" x SCREENWIDTH);
        printf("The %s for last checks on %s\n\n", $report_name, HOSTNAME);
        print join("\n", @report, "");
    }

    #
    # SendMail (Send report)
    #
    if ($send_report) {
        unshift @report, $self->_report_title($report_name, "last checks");
        push @report, $self->_report_footer();
        my %ma = (); foreach my $k (keys %$sendmail) { $ma{"-".$k} = $sendmail->{$k} };
        $ma{"-subject"} = sprintf("%s %s (%s on %s)", PROJECTNAME, $report_name, "last checks", HOSTNAME);
        $ma{"-message"} = join("\n", @report);

        # Send!
        my $sent = sendmail(%ma);
        if ($sent) {
            my $msg = sprintf("Mail has been sent to: %s", $to);
            $self->wow($msg);
            $self->log_info($msg);
        } else {
            my $msg = sprintf("Mail was not sent to: %s", $to);
            $self->skip($msg);
            $self->log_warning($msg);
        }
    }

    # Finish reporting
    printf("Finish of the checkit reporting for %s (%s)\n", HOSTNAME, $self->tms);
    $self->log_info("Finish of the checkit reporting for \"%s\" (%s)", HOSTNAME, $self->tms);

    return $status;
});

__PACKAGE__->register_handler(
    handler     => "show",
    description => "Show table data",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    $self->configure or return 0;
    my (@header, @errors, @report, @table);
    my $status = 1;

    # Start
    printf("Getting checkit data for %s...\n", HOSTNAME);

    # Get DBI
    my $dbi = $self->getdbi;
    if ($dbi->error) {
        $self->log_error("%s: %s", $dbi->dsn, $dbi->error);
        $self->nope($dbi->dsn);
        say(TAB9, red($dbi->error));
        return 0;
    }

    # Get all records from DB
    my %all;
    foreach my $r ($dbi->getall) {
        $all{$r->{name}} = $r;
    }
    if ($dbi->error) {
        $self->log_error("%s: %s", $dbi->dsn, $dbi->error);
        $self->nope($dbi->dsn);
        say(TAB9, red($dbi->error));
        return 0
    }
    my $n = scalar(keys %all) || 0;
    unless ($n) {
        $self->skip("No data");
        return 1;
    }

    if ($self->verbosemode) {
        print(explain(\%all));
        $self->yep("Number of records: %d", $n);
        return 1;
    }

    # Show table
eval <<'FORMATTING';
my @arr;
my $total;
say "";
say "Actual table data:
----------------------+----------------------------------+---------------------+---------";
format STDOUT_TOP =
 Name                 | Source string                    | Date                | Status
----------------------+----------------------------------+---------------------+---------
.
format STDOUT =
 @<<<<<<<<<<<<<<<<<<< | @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | @<<<<<<<<<<<<<<<<<< | @||||||
@arr
.
format STDOUTBOT =
----------------------+----------------------------------+---------------------+---------
 SUMMARY                                                                       | @||||||
$total
.
foreach my $v (sort {$a->{name} cmp $b->{name}} values %all) {
    @arr = ();
    my $stv = $v->{status} || 0;
    my $ostat = -1;
    if (getBit($stv, 0) && getBit($stv, 1) && getBit($stv, 2)) { # Ok
        $ostat = 1;
    } elsif ((getBit($stv, 0) + getBit($stv, 1)) == 0) { # Problem
        $ostat = 0;
        $status = 0;
    }
    push @arr, variant_stf($v->{name} // '', 20);
    push @arr, variant_stf($v->{source} // '', 32);
    push @arr, $v->{"time"} ? dtf(DATE_FORMAT, $v->{"time"})  : '';
    push @arr, $ostat ? $ostat > 0 ? 'OK' : 'UNKNOWN' : 'PROBLEM';
    write;
}
local $~ = "STDOUTBOT";
$total = $status ? "OK" : "PROBLEM";
write;
FORMATTING
say "";

    $self->yep("Number of records: %d", $n);
    return $status;
});

sub notify {
    my $self = shift;
    my %args = @_;
    my $name = $args{name} || 'virtual';
    my @errors;
    push @errors, $args{error} if $args{error};

    # Get SendMail config
    my $sendmail = hash($self->config('sendmail'));
    #say(explain($sendmail));

    # Get SMSGW
    my $smsgw = $self->config('smsgw');
    #say(explain($sendmail));

    #
    # Sorting receivers
    #
    my $sendto = $args{sendto} || [];
    my (@for_sendmail, @for_smsgw, @for_notifier);
    foreach my $rec (@$sendto) {
        next unless $rec;
        if ($rec =~ /\@/) { push @for_sendmail, $rec }
        elsif ($rec =~ /^[\(+]*\d+/) {
            $rec =~ s/[^0-9]//g;
            push @for_smsgw, $rec;
        }
        else { push @for_notifier, $rec }
    }

    #
    # Make subject and sms body
    #
    my $subject = sprintf("%s: Available %s [%s]",
        $args{status} ? 'OK' : 'PROBLEM',
        $name,
        HOSTNAME,
    );

    #
    # Send SMS
    #
    foreach my $phone (@for_smsgw) {
        unless ($smsgw) {
            my $msg = sprintf("Can't send SMS to %s: SMSGW is not defined!", $phone);
            $self->skip($msg);
            $self->log_error($msg);
            push @errors, $msg;
            next;
        }
        my $cmd = dformat($smsgw, {
            PHONE       => $phone,
            NUM         => $phone,
            TEL         => $phone,
            PHONE       => $phone,
            NUM         => $phone,
            NUMBER      => $phone,
            SUBJECT     => SMSSBJ,
            SUBJ        => SMSSBJ,
            MSG         => $subject,
            MESSAGE     => $subject,
        });
        my $exe_err = '';
        my $exe_out = execute($cmd, undef, \$exe_err);
        my $exe_stt = ($? >> 8) ? 0 : 1;
        if ($exe_stt) {
            my $msg = sprintf("# %s", $cmd);
            $self->wow($msg);
            $self->log_info($msg);
            if (defined($exe_out) && length($exe_out) && $self->verbosemode) {
                say(TAB9, cyan($exe_out)) if IS_TTY;
                $self->log_info($exe_out);
            }
        } else {
            my $msg = sprintf("Can't send SMS: %s", $cmd);
            $self->skip($msg);
            $self->log_warning($msg);
            push @errors, $msg;
            if ($exe_err) {
                chomp($exe_err);
                IS_TTY ? say(TAB9, yellow($exe_err)) : say($exe_err);
                $self->log_error($exe_err);
                push @errors, $exe_err;
            }
            push @errors, "";
        }
    }

    #
    # Make headers
    #
    my @header;
    push @header, (
        ["Checkit", $name],
        ["Type", $args{type} || 'http'],
        ["Status", $args{status} ? 'OK' : 'PROBLEM'],
        ["Source", $args{source} || "UNKNOWN"],
        ["Message", $args{message} // ""],
    );

    #
    # Make email report message
    #
    my @report;
    my $report_name = $args{status} ? "checking report" : "error report";
    push @report, $self->_report_common(@header); # Common information
    push @report, $self->_report_summary($args{status} ? "All checks successful" : "Errors occurred while checking"); # Summary table
    push @report, $self->_report_errors(@errors); # List of occurred errors

    # Data for Emails only
    unshift @report, $self->_report_title($report_name, $name);
    push @report, $self->_report_footer();

    #
    # Send report to Notifier (if installed)
    #
    my $agent = $self->{notifier};
    if ($NOTIFIER_LOADED && $agent && @for_notifier) {
        foreach my $to (shellwords(@for_notifier)) {
            $agent->create(
                to => $to,
                subject => $subject,
                message => join("\n", @report),
            ) or do {
                my $msg = sprintf("Can't send message via notifier: %s", $agent->error);
                $self->skip($msg);
                $self->log_warning($msg);
            };
            if ($agent->status) {
                my $msg = sprintf("The message has been successfully queued for sending to: %s", $to);
                $self->wow($msg);
                $self->log_info($msg);
            }
        }
    }

    #
    # SendMail (Send report)
    #
    my %ma = (); foreach my $k (keys %$sendmail) { $ma{"-".$k} = $sendmail->{$k} };
    $ma{"-subject"} = $subject;
    $ma{"-message"} = join("\n", @report);
    foreach my $to (@for_sendmail) {
        $ma{"-to"} = $to;
        my $sent = sendmail(%ma) if $to !~ /\@example.com$/;
        if ($sent) {
            my $msg = sprintf("Mail has been sent to: %s", $to);
            $self->wow($msg);
            $self->log_info($msg);
        } else {
            my $msg = sprintf("Mail was not sent to: %s", $to);
            $self->skip($msg);
            $self->log_warning($msg);
        }
    }

    return 1;
}
sub trigger {
    my $self = shift;
    my %args = @_;
    my $name = $args{name} || 'virtual';
    my $message = $args{message} || "";
    my $source = $args{source} || "";

    #
    # Make subject and sms body
    #
    my $subject = sprintf("%s: Available %s [%s]",
        $args{status} ? 'OK' : 'PROBLEM',
        $name,
        HOSTNAME,
    );

    #
    # Execute
    #
    my $triggers = $args{trigger} || [];
    foreach my $trg (@$triggers) {
        next unless $trg;
        my $cmd = dformat($trg, {
            SUBJECT     => $subject,
            SUBJ        => $subject,
            MSG         => $message,
            MESSAGE     => $message,
            SOURCE      => $source,
            NAME        => $name,
            TYPE        => $args{type} || "http",
            STATUS      => $args{status} ? 1 : 0,
        });
        my $exe_err = '';
        my $exe_out = execute($cmd, undef, \$exe_err);
        my $exe_stt = ($? >> 8) ? 0 : 1;
        if ($exe_stt) {
            my $msg = sprintf("# %s", $cmd);
            $self->yep($msg);
            $self->log_info($msg);
            if (defined($exe_out) && length($exe_out) && $self->verbosemode) {
                say(TAB9, green($exe_out)) if IS_TTY;
                $self->log_info($exe_out);
            }
        } else {
            my $msg = sprintf("Can't execute trigger: %s", $cmd);
            $self->nope($msg);
            $self->log_error($msg);
            if ($exe_err) {
                chomp($exe_err);
                IS_TTY ? say(TAB9, red($exe_err)) : say($exe_err);
                $self->log_error($exe_err);
            }
        }
    }

    return 1;
}

#######################
# Colored says methods
#######################
sub yep {
    my $self = shift;
    print(IS_TTY ? green('[  OK  ]') : '[  OK  ]', ' ', IS_TTY ? green(shift, @_) : sprintf(shift, @_), "\n");
    return 1;
}
sub nope {
    my $self = shift;
    print(IS_TTY ? red('[ FAIL ]') : '[ FAIL ]', ' ', IS_TTY ? red(shift, @_) : sprintf(shift, @_), "\n");
    return 0;
}
sub skip {
    my $self = shift;
    print(IS_TTY ? yellow('[ SKIP ]') : '[ SKIP ]', ' ', IS_TTY ? yellow(shift, @_) : sprintf(shift, @_), "\n");
    return 1;
}
sub wow {
    my $self = shift;
    print(IS_TTY ? blue('[ INFO ]') : '[ INFO ]', ' ', IS_TTY ? blue(shift, @_) : sprintf(shift, @_), "\n");
    return 1;
}

# Private methods
sub _getCheckits {
    my $self = shift;
    my @names = @_;
    my $sects = $self->config("checkit");
    my $i = 0;
    my @j = ();
    if (ref($sects) eq 'ARRAY') { # Array
        foreach my $r (@$sects) {
            if ((ref($r) eq 'HASH') && exists $r->{enable}) { # Anonymous
                $r->{name} = sprintf("virtual%d", ++$i);
                next unless (!@names || grep {$r->{name} eq lc($_)} @names);
                push @j, $r;
            } elsif (ref($r) eq 'HASH') { # Named
                foreach my $k (keys %$r) {
                    my $v = $r->{$k};
                    next unless ref($v) eq 'HASH';
                    $v->{name} = lc($k);
                    next unless (!@names || grep {$v->{name} eq lc($_)} @names);
                    push @j, $v;
                }
            }
        }
    } elsif ((ref($sects) eq 'HASH') && !exists $sects->{enable}) { # Hash {name => {...}}
        foreach my $k (keys %$sects) {
            my $v = $sects->{$k};
            next unless ref($v) eq 'HASH';
            $v->{name} = lc($k);
            next unless (!@names || grep {$v->{name} eq lc($_)} @names);
            push @j, $v;
        }
    } elsif (ref($sects) eq 'HASH') { # Hash {...}
        $sects->{name} = sprintf("virtual%d", ++$i);
        push @j, $sects if (!@names || grep {$sects->{name} eq lc($_)} @names);
    }
    return grep {$_->{enable}} @j;
}
sub _report_title {
    my $self = shift;
    my $title = shift || "report";
    my $name = shift || "virtual";
    return (
        sprintf("Dear %s user,", PROJECTNAME),"",
        sprintf("This is a automatic-generated %s for %s\non %s, created by %s/%s",
            $title, $name, HOSTNAME, __PACKAGE__, $VERSION),"",
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
        HOSTNAME, $0, $^O, $^V, PROJECTNAME, $VERSION, $self->configfile(),
        $$, $self->tms(), dtf("%w, %DD %MON %YYYY %hh:%mm:%ss"),
    );
}

1;

__END__
