package App::MonM::Daemon;
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::Daemon - The daemon class of the MonM

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Daemon;

=head1 DESCRIPTION

The daemon class of the MonM

=head2 new

    my $daemon = App::MonM::Daemon->new('foo', (
        loglevel    => $loglevel,
        forks       => 3,
    ));

=head2 checker

    my $checker = $daemon->checker();

Returns checker object

=head2 cleanup

This is internal method of the CTK::Daemon context

=head2 down

This is internal method of the CTK::Daemon context

=head2 init

This is internal method of the CTK::Daemon context

=head2 notifier

    my $notifier = $daemon->notifier;

Returns the Notifier object

=head2 notify

    $daemon->notify();

Sends notifications

=head2 reload

This is internal method of the CTK::Daemon context

=head2 remind

Performs notification's remind. This is proxy function of the Notifier class

=head2 run

This is internal method of the CTK::Daemon context

=head2 slave

Performs checking. Returns true/false as status

=head2 store

    my $store = $daemon->store();

Returns store object

=head2 trigger

    my @errors = $daemon->trigger();

Runs triggers

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK::App>, L<CTK::Daemon>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut


use vars qw/$VERSION/;
$VERSION = '1.01';

use parent qw/CTK::Daemon/;

use AnyEvent;
use File::Spec;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util qw/ preparedir dformat execute /;

use App::MonM::Const;
use App::MonM::Util qw/
        getBit setBit
        node2anode getCheckitByName
        getExpireOffset getTimeOffset
    /;
use App::MonM::Store;
use App::MonM::Checkit;
use App::MonM::QNotifier;
use App::MonM::Report;

use constant {
    START_DELAY         => 3,
    INTERVAL_CTRL       => 3,  # 3 sec
    INTERVAL_MAIN       => 20, # 20 sec
    INTERVAL_REMIND     => 60, # 1 min
    DAEMONFORKS         => 3,
    EXPIRES             => 24*60*60, # 1 day
};

eval { require App::MonM::Notifier };
my $NOTIFIER_LOADED = 1 unless $@;
$NOTIFIER_LOADED = 0 if $NOTIFIER_LOADED && (App::MonM::Notifier->VERSION * 1) < 1.04;

sub new {
    my $class = shift;
    my $name = shift;
    my %daemon_options = @_;

    # Forks (workers)
    my $forks = tv2int8($daemon_options{forks} || DAEMONFORKS);
    $daemon_options{forks} = $forks < 2 ? 2 : $forks;

    my $self = $class->SUPER::new($name, %daemon_options);

    # Create general properties
    $self->{store} = undef; # Store instance
    $self->{notifier} = undef; # Notifier instance
    $self->{checker} = undef; # Checker instance
    #print _explain($self->ctk->config);

    return $self;
}

sub init {
    my $self = shift;
    my $ctk = $self->get_ctk;
    my $logger = $self->logger; # Logger realy is exists?
    #$logger->log_debug(">> Init handler");

    # Check logger
    unless ($logger && $logger->status) {
        printf STDERR "Can't init logger: %s\n", $logger ? $logger->error : "no logger object";
        return;
    }

    # Check configuration
    my $configobj = $ctk->configobj;
    unless ($configobj->status) {
        print STDERR length($configobj->error)
            ? $configobj->error
            : "Can't load configuration file";
        return;
    }

    #print $self->ctk->datadir, "\n";
    #return $self->interrupt(1);

    return 1;
}
sub down {
    my $self = shift;
    my $logger = $self->logger; # Logger realy is exists?
    #$logger->log_info(">> Down handler");

    # Cleaning DB
    my $expire = getExpireOffset(lvalue($self->ctk->config("expires"))
        || lvalue($self->ctk->config("expire")) || EXPIRES);
    $self->store->clean(period => $expire) or do {
        $logger->log_error("Can't cleanup database: %s", $self->store->error)
            if $self->store->error;
    };

    return 1;
}
sub cleanup {
    my $self = shift;
    my $logger = $self->logger; # Logger realy is exists?

    #$logger->log_info(">> CleanUp handler");

    return 1;
}
sub reload {
    my $self = shift;
    my $logger = $self->logger;

    # Check configuration
    my $configobj = $self->ctk->configobj;
    unless ($configobj->reload->status) {
        print STDERR length($configobj->error)
            ? $configobj->error
            : "Can't reload configuration file";
        return $self->interrupt(1);
    }

    #$logger->log_info(">> Reload handler");
    return 1;
}
sub run {
    my $self = shift;
    my $ctk = $self->get_ctk;
    my $logger = $self->logger;
    my $quit_program = AnyEvent->condvar;
    return 1 unless $self->ok;
    #$logger->log_info(">> Run handler");

    # CTK config
    my $config = $ctk->config;

    # Get checkits and allocation by workers
    my @checkits = getCheckitByName($ctk->config("checkit"));
    my $noc = scalar(@checkits);
    unless ($noc) {
        $logger->log_error("No enabled <Checkit> configuration section found");
        return 0;
    }
    my @checkits_parted = (_allocate($self->{forkers}, [(sort {$a->{name} cmp $b->{name}} @checkits)]));
    my $alloc = $checkits_parted[$self->{workerident} - 1];

    # Store
    my $db_file = File::Spec->catfile($ctk->datadir, App::MonM::Store::DB_FILENAME());
    my $store_conf = $ctk->config("store") || $ctk->config('dbi') || {file => $db_file};
       $store_conf = {file => $db_file} unless is_hash($store_conf);
    my %store_args = %$store_conf;
    $store_args{file} = $db_file unless ($store_args{file} || $store_args{dsn});
    my $store = App::MonM::Store->new(%store_args);
    if ($store->error) {
        $logger->log_error($store->error);
        return 0;
    }
    $self->{store} = $store;

    # Notifier object init
    my %nargs = (config => $ctk->configobj);
    $self->{notifier} = $NOTIFIER_LOADED && lvalue($ctk->config("usemonotifier"))
        ? App::MonM::Notifier->new(%nargs)
        : App::MonM::QNotifier->new(%nargs);

    # Create Checkit object
    $self->{checker} = App::MonM::Checkit->new;

    # Create process timers
    my $ctrl = AnyEvent->timer (after => START_DELAY, interval => INTERVAL_CTRL, cb => sub {
        $quit_program->send(1) unless $self->ok;
    });
    my $interval = int(uv2zero(lvalue($ctk->config("interval"))) || INTERVAL_MAIN); # Time interval. 1 op per n sec
    my $after = (($self->{workerident} - 1) * int($interval / ($self->{forkers} - 1))) || START_DELAY;
    my $timer = AnyEvent->timer (after => $after, interval => $interval, cb => sub {
        $quit_program->send(1) unless $self->ok;
        $self->slave($alloc); # Go!
    });
    my $rmnd = AnyEvent->timer (after => INTERVAL_REMIND+START_DELAY, interval => INTERVAL_REMIND, cb => sub {
        $quit_program->send(1) unless $self->ok;
        $self->remind() if $self->{workerident} == 1;
    });

    # Run!
    $quit_program->recv;

    return 1;
}
sub remind {
    my $self = shift;
    return $self->logger->log_error(($self->notifier->error)) unless $self->notifier->remind;
    return 1;
}
sub slave {
    my $self = shift;
    my $checkits = shift;
    my $ctk = $self->get_ctk;
    my $logger = $self->logger;
    my $worker = $self->{workerident};
    my $store = $self->store;
    #$logger->log_info(">> $$ worker=%d", $worker);

    # Check checkits
    return 1 unless $checkits && is_array($checkits) && isnt_void($checkits);

    # Get Checker object
    my $checker = $self->checker;

    # Get all records from DB
    my %all;
    foreach my $r ($store->getall) { $all{$r->{name}} = $r }
    if ($store->error) {
        $logger->log_error($store->error);
        return 1;
    }

    # Start
    my $curtime = time;
    foreach my $checkit (@$checkits) {
        my $result = 1; # Check result
        my $name = $checkit->{name}; # checkit name
        my $info = $all{$name} || {}; # data from database
        my $id = $info->{id} || 0;
        my $old = $info->{status} || 0;
        my $got = ($old << 1) & 15;
        my $pub = $info->{'time'} || 0;
        my $interval = getTimeOffset(lvalue($checkit, "interval") || 0);

        # Check interval first
        if ($interval) {
            if (($pub + $interval) >= $curtime) {
                $logger->log_debug("SKIP %s (%s)\n", $name,
                    "Too little time has passed before a next check [delay $interval sec]")
                        if $ctk->verbosemode;
                next;
            }
        }

        # Check!
        $result = $checker->check($checkit);
        $got = setBit($got, 0) if $result; # Set first bit if result is PASSED

        # Show resulsts
        if ($ctk->verbosemode) {
            $logger->log_debug("%s %s (%s >>> %s)\n", $result ? "OK" : "FAIL",
                $name, $checker->source, $checker->message);
            $logger->log_error("%s", $checker->error) unless $checker->status;
        }

        # Save data to database
        my %data = (
            id      => $id, # DB record id
            status  => $got, # Result code
            name    => $name, # Checkit name
            type    => $checker->type, # Checkit type
            result  => $result, # Checkit result
            source  => $checker->source, # Source string
            code    => $checker->code, # Checkit code value
            message => $checker->message, # Checkit message string
            note    => $checker->note, # Checkit note string
            subject => sprintf("%s: Available %s [%s]", $result ? 'OK' : 'PROBLEM', $name, HOSTNAME), # Subject
        );
        my $chst = $id ? $store->set(%data) : $store->add(%data);
        unless ($chst) {
            $logger->log_error($store->error) if $store->error;
            next;
        }

        # Triggers and notifications
        # GOT = [0-0-1-1] = 3  -- OK
        # GOT = [1-1-0-0] = 12 -- PROBLEM
        if ($got == 3 or $got == 12) {
            my @errs;
            $data{status} = $checker->status; # Checkit status (NO RESULT!!);
            push @errs, $checker->error if $checker->error; # Checkit error string

            # Run triggers (FIRST)
            push @errs, $self->trigger(%data, trigger => array($checkit, "trigger"));

            # Send message via notifier (SECOND)
            $self->notify(%data, sendto => array($checkit, "sendto"), errors => \@errs);
        }
    }

    return 1;
}

sub store {
    my $self = shift;
    return $self->{store};
}
sub notifier {
    my $self = shift;
    return $self->{notifier};
}
sub checker {
    my $self = shift;
    return $self->{checker};
}

sub trigger {
    my $self = shift;
    my %args = @_;
    my $subject = $args{subject};
    my $message = $args{message} // "";
    my $source = $args{source} // "";
    my $triggers = $args{trigger} || [];
    my $logger = $self->logger;
    my @errs;

    # Execute triggers
    foreach my $trg (@$triggers) {
        next unless $trg;
        my $cmd = dformat($trg, {
            SUBJECT     => $subject,    SUBJ => $subject, SBJ => $subject,
            MESSAGE     => $message,    MSG  => $message,
            SOURCE      => $source,     SRC  => $source,
            NAME        => $args{name} || 'virtual',
            TYPE        => $args{type} // 'http',
            CODE        => $args{code} // '',
            STATUS      => $args{status} ? 'OK' : 'ERROR',
            RESULT      => $args{result} ? 'PASSED' : 'FAILED',
            NOTE        => $args{note} // '',
        });
        my $exe_err = '';
        my $exe_out = execute($cmd, undef, \$exe_err);
        my $exe_stt = ($? >> 8) ? 0 : 1;
        if ($exe_stt) {
            $logger->log_info("# %s", $cmd);
        } else {
            $exe_err //= "unknown error"; chomp($exe_err);
            my $msg = sprintf("Can't execute trigger %s: %s", $cmd, $exe_err);
            $logger->log_error("%s", $msg);
            push @errs, $msg;
        }
    }

    return @errs;
}
sub notify {
    my $self = shift;
    my %args = @_;
    my $name = $args{name} || 'virtual';
    my $errs = $args{errors};
    my $logger = $self->logger;
    my @errors;
    push @errors, @$errs if is_array($errs);

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
    my $report = App::MonM::Report->new(name => $name, configfile => $self->ctk->configfile);
    $report->title($args{result} ? "checking report" : "error report");
    $report->common(@header); # Common information
    $report->summary($args{result} ? "All checks successful" : "Errors occurred while checking"); # Summary
    $report->errors(@errors) if @errors; # List of occurred errors
    $report->footer($self->ctk->tms);

    # Send
    my $notify_status = $self->notifier->notify(
            to      => $args{sendto} || [],
            subject => $args{subject},
            message => $report->as_string,
            before => sub {
                my $this = shift; # App::MonM::QNotifier object (this)
                my $message = shift; # App::MonM::Message object

                # Check internal errors
                $logger->log_error("%s", $this->error) if $this->error;

                return 1;
            },
            after => sub {
                my $this = shift; # App::MonM::QNotifier object (this)
                my $message = shift; # App::MonM::Message object
                my $sent = shift; # Status of sending

                # Check internal errors
                $logger->log_error("%s", $this->error) if $this->error;

                # Check sending status
                if ($sent) {
                    my $msg = $this->channel->error
                        ? sprintf("Message was not sent to %s: %s", $message->recipient, $this->channel->error)
                        : sprintf("Message has been sent to %s", $message->recipient);
                    if ($this->channel->error) {
                        $logger->log_error("%s", $msg);
                    } else {
                        $logger->log_info("%s", $msg);
                    }
                } else {
                    my $err = sprintf("Message was not sent to %s: %s", $message->recipient, $this->channel->error || "unknown error");
                    $logger->log_error("%s", $err);
                }

                return 1;
            },
        );
    $logger->log_error($self->notifier->error) unless $notify_status;

    return 1;
}

# Allocate chekits
sub _allocate { # (3, [qw/a1 a2 a3 a4 a5 a6 a7/]) -> ([a1, a4, a7], [a2, a5], [a3, a6])
    my $forks = shift || 0;
    my $_acts = shift || [];
    my @acts = @$_acts;
    my @res = ();
    while ($forks && @acts) {
        foreach my $f (0..($forks-1)) {
            $res[$f] = [] unless exists $res[$f];
            my $nxt = shift(@acts);
            last unless defined $nxt;
            push @{$res[$f]}, $nxt;
        }
    }
    return @res;
}

1;

__END__
