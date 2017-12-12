package App::MonM::Notifier::Daemon; # $Id: Daemon.pm 33 2017-11-23 18:39:59Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Daemon - monotifier daemon worker

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Daemon;

    worker();

=head1 DESCRIPTION

This module provides worker processing.

For internal use only

=head2 FUNCTIONS

=over 8

=item B<worker>

    worker(
        j       => $j, # Worker number (default = 0)
        cfgfile => $cfgfile,
        logfile => $logfile,
        datadir => $datadir,
        ident => $ident, # For syslog
    );

Worker function

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK qw/ :BASE %OPT /;
use CTKx;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util;

use POSIX qw//;

use App::MonM::Notifier::Log;
use App::MonM::Notifier::Agent;
use App::MonM::Notifier::Const;
use App::MonM::Notifier::Util;

use base qw/Exporter/;

use constant {
    PROJECTNAME => 'monotifierd',
    PREFIX      => 'monotifier',
    LOCALHOSTIP => '127.0.0.1',
    LOGOPT      => 'ndelay,pid', # For Sys::Syslog
    SLEEP       => 60,
    STEP        => 1,
    TRIES       => 3,

};

use vars qw/$VERSION @EXPORT/;
$VERSION = '1.00';

@EXPORT = (qw/
        worker
    /);

my $logger;
my $interrupt;
my $exception;
my $hangup;
my $skip;

sub _init {
    %OPT = @_;
    $interrupt = 0;
    $exception = 0;
    $hangup = 0;
    $skip = 0;

    # Singleton object
    my $c = new CTK(
        prefix  => lc(PREFIX),
        cfgfile => $OPT{cfgfile},
        logdir  => syslogdir(),
        logfile => $OPT{logfile},
        datadir => $OPT{datadir},
    );
    if (defined($OPT{datadir})) {
        $c->datadir($OPT{datadir});
    } else {
        $c->datadir(catdir(sharedstatedir(), $c->prefix));
    }

    my $ctkx = CTKx->instance( c => $c );

    return $c;
}
sub _getppid {
    return 0 if isostype('Windows');
    POSIX::getppid();
}

sub worker {
    my %in = @_;
    $in{ppid} = _getppid();
    my $c = _init(%in);
    my $j = $in{j} || 0;
    $logger = new App::MonM::Notifier::Log($OPT{ident} || PROJECTNAME);
    $logger->log_debug("Start worker %s #%s [%d]", PROJECTNAME, $j, $$) if debugmode;
    my $step = $in{step} // STEP; $step = STEP if $step < 0;

    # Signals Trapping for worker-proccess interruption
    my $anon = sub {
        if ($interrupt >= TRIES) {
            $logger->log_crit("Can't terminate worker %s #%s [%d]", PROJECTNAME, $j, $$);
            die("Can't terminate worker $$");
        }
        $interrupt++;
    };
    local $SIG{TERM} = $anon;
    local $SIG{INT} = $anon;
    local $SIG{QUIT} = $anon;
    local $SIG{HUP} = sub {$hangup++};

    #############################################
    # Start worker section MAIN_LOOPS
    #############################################
    #syslog(LOG_INFO, Dumper($config));
    my $agent;
    RELOAD: if ($hangup) {
        $c = _init(%in);
        $logger->log_debug("Reloaded worker %s #%s [%d]", PROJECTNAME, $j, $$) if debugmode;
        #$hangup = 0;
        #$skip = 0;
    }

    # Agent Init
    while (!($exception || $interrupt || $hangup)) {
        $agent = new App::MonM::Notifier::Agent(ident => $j, config => $c->config);
        if ($agent->status) {
            $skip = 0;
            last;
        } else {
            $logger->log_error($agent->error) unless $skip;
            $logger->log_notice("Waiting for next connect try...") if $skip;
            $skip++;
            mysleep SLEEP;
        }
    } continue {
        $exception++ if $in{ppid} != _getppid();
    }

    # Get and run jobs
    my @pool; # Postponed jobs
    while (!($exception || $interrupt || $hangup)) {
        my $config = $c->config;
        # Get new Job
        my %data = $agent->getJob();
        if ($agent->status) {
            push @pool, {%data} if %data;
        } else {
            $logger->log_error($agent->error);
            mysleep SLEEP;
            next;
        }
        foreach my $d (@pool) { # Get one job in list
            next unless is_hash($d);
            my $id = fv2zero($d->{id});
            next unless $id;

            #$logger->log_notice(Dumper($d));

            # Check pubdate
            my $pubdate = fv2zero($d->{pubdate});
            if ($pubdate > time()) {
                # Posponed
                $d->{status} = JBS_POSTPONED;
                next;
            }

            # Check expires
            my $expires = fv2zero($d->{expires});
            if ($expires < time()) {
                # Expired
                $d->{status} = JBS_EXPIRED;
                $agent->closeJob($id, JBS_EXPIRED);
                if ($agent->status) {
                    undef $d;
                } else {
                    $logger->log_error($agent->error);
                    mysleep SLEEP;
                }
                next;
            }

            # Check permissions to run now (See channel's periods in config file)
            #
            # Если с конфигурации видно что время не соответствует разрешенному периоду,
            # то в этом случае вычисляем время согласно правилу работы периодов до значения
            # начала разрешенного периода (если указано что разрешено в воскресенье с двух часов дня)
            # то высчитываем сколько будет time() в воскресенье в два часа дня и это time() время
            # и есть $newpubdate!
            #
            my $username = $d->{to} || 'anonymous';
            my $usernode = node($config => "user", $username);
            unless (checkPubDate($usernode)) {
                my $newpubdate = calcPostponetPubDate($usernode);
                if ($newpubdate) {
                    $logger->log_notice(sprintf("The #%d postponed to %s", $id, scalar(localtime($newpubdate))));
                    $agent->postponeJob($id, $newpubdate); # Обновляем дату публикации
                    if ($agent->status) {
                        undef $d;
                    } else {
                        $logger->log_error($agent->error);
                        mysleep SLEEP;
                    }
                } else { # Error. Close need
                    my $errmsg = sprintf(getErr(101), $username);
                    $agent->closeJob($id, JBS_FAILED, 101, $errmsg);
                    $logger->log_error($errmsg);
                    if ($agent->status) {
                        undef $d;
                    } else {
                        $logger->log_error($agent->error);
                        mysleep SLEEP;
                    }
                }
                next;
            }

            # Processing. Send message!
            $agent->runJob(%$d);
            unless ($agent->status) {
                $logger->log_error($agent->error);
                if ($d->{status} ne JBS_SKIP) { # Try to run only twice
                    $d->{status} = JBS_SKIP;
                    mysleep SLEEP;
                    next;
                }
            }
            my $tmp_status = ($d->{status} eq JBS_SKIP) ? JBS_ERROR : JBS_SENT;
            if ($agent->status) {
                $agent->closeJob($id, $tmp_status);
            } else {
                $agent->closeJob($id, $tmp_status, 102, sprintf(getErr(102), $agent->error));
            }
            if ($agent->status) {
                undef $d;
            } else {
                $logger->log_error($agent->error);
                mysleep SLEEP;
            }

            #Done. Go to next job
        }

        mysleep $step if $step;
    } continue {
        $exception++ if $in{ppid} != _getppid();
    }

    # Exceptions
    if ($exception) {
        $logger->log_crit("Kill master process %s #%s [%d]", PROJECTNAME, $j, $$);
    } elsif ($interrupt) {
        $logger->log_error("Interrupt worker %s #%s [%d]", PROJECTNAME, $j, $$);
    } elsif ($hangup) {
        # Hangup
        $logger->log_info("Reload worker %s #%s [%d]", PROJECTNAME, $j, $$);
        goto RELOAD if $hangup;
    } else {
        $logger->log_debug("Finish worker %s #%s [%d]", PROJECTNAME, $j, $$) if debugmode;
    }

    return 0; # For exit!
}

1;
__END__
