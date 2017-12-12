package App::MonM::Notifier::Agent; # $Id: Agent.pm 41 2017-11-30 11:26:30Z abalama $
use strict;
use utf8;

=head1 NAME

App::MonM::Notifier::Agent - monotifier agent

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Agent;

    my $agent = new App::MonM::Notifier::Agent(
        ident => $j,
        config => $c->config
    );

=head1 DESCRIPTION

This module provides agent methods.

For internal use only

=head2 METHODS

=over 8

=item B<new>

Constructor

    my $agent = new App::MonM::Notifier::Agent(
        ident => $j,
        config => $c->config
    );

ident - number of the worker; config - CTK config structure

=item B<status>

    if ($agent->status) {
        # OK
    } else {
        # ERROR
    }

Returns object's status. 1 - OK, 0 - ERROR

    my $status = $agent->status( 1 );

Sets new status and returns it

=item B<error>

    my $error = $agent->error;
    my $status = $agent->error( "error text" );

Returns error string if no arguments.
Sets error string also sets status to false (if error string is not false)
or to true (if error string is false) and returns this status

=item B<store>

    my $store = $agent->store;

Returns current store object

=item B<logger>

    my $logger = $agent->logger;

Returns current logger object

=item B<getJob>

    my %data = $agent->getJob();

This method gets record as job from store for processing

=item B<closeJob>

    $agent->closeJob($id, JBS_FAILED, 101, $errmsg);

This method marks record as closed job and sets error's code and message.
Returns status

=item B<postponeJob>

    $agent->postponeJob($id, $newpubdate);

This method postpone job on future. Sets the new pupdate integer value

=item B<runJob>

    $agent->runJob(%$d);

This method runs all channels for job data and returns summary status

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

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util;

use App::MonM::Notifier::Const qw/ :jobs :reasons :functions /;
use App::MonM::Notifier::Store;
use App::MonM::Notifier::Util;
use App::MonM::Notifier::Log;
use App::MonM::Notifier::Channel;

use constant {
    LOCALHOSTIP => '127.0.0.1',
};

use vars qw/$VERSION/;
$VERSION = '1.00';

sub new {
    my $class = shift;
    my %opts = @_;

    my $logger = new App::MonM::Notifier::Log(sprintf("monotifierd_agent%s", $opts{ident} || 0));
    my %props = (
            error   => '',
            status  => 1,
            store   => undef,
            ident   => $opts{ident},
            config  => $opts{config},
            logger  => $logger,
        );

    # Store
    my $store = new App::MonM::Notifier::Store;
    if ($store->status) {
        $props{store} = $store;
    } else {
        $props{error} = sprintf("Can't create store instance: %s", $store->error);
    }

    $props{status} = 0 if $props{error};
    return bless { %props }, $class;
}
sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    return $self->status;
}
sub store {
    my $self = shift;
    $self->{store};
}
sub logger {
    my $self = shift;
    $self->{logger};
}
sub getJob { # Get job for processing
    my $self = shift;
    my $ident = $self->{ident};

    my $store = $self->store;
    my %data = $store->getJob($ident);
    if ($store->status) {
        $self->error("");
    } else {
        $self->error(sprintf("Can't get record: %s", $store->error));
        return ();
    }

    return %data;
}
sub closeJob { # Close job after processing
    my $self = shift;
    my $id = shift;
    my $status = shift;
    my $errcode = shift;
    my $errmsg = shift;
    my $ident = $self->{ident};

    my $store = $self->store;
    $store->setJob(
            id      => $id,
            status  => $status,
            errcode => $errcode,
            errmsg  => $errmsg,
            comment => sprintf("Closed by Worker #%s at %s", $ident, scalar(localtime(time()))),
        );
    if ($store->status) {
        $self->error("");
    } else {
        $self->error(sprintf("Can't close job: %s", $store->error));
    }

    return 1;
}
sub postponeJob { # Postpone job (time shifting)
    my $self = shift;
    my $id = shift;
    my $pubdate = shift || 0;
    my $ident = $self->{ident};

    unless ($pubdate) {
        $self->error("Pubdate incorrect");
        return 0;
    }

    my $store = $self->store;
    $store->setJob(
            id      => $id,
            pubdate => $pubdate,
            status  => JBS_POSTPONED,
            comment => sprintf("Postponed by Worker #%s at %s to %s", $ident, scalar(localtime(time())), scalar(localtime($pubdate))),
        );
    if ($store->status) {
        $self->error("");
    } else {
        $self->error(sprintf("Can't postpone job: %s", $store->error));
    }

    return 1;
}
sub runJob { # Run job! Send message
    my $self = shift;
    my %data = @_;
    my $config = $self->{config};
    $self->error("");

    # - данные должны быть!
    unless (keys(%data)) {
        return $self->error("No data for sending");
    }

    # - валидируем данные: id, from, to, subject, message, host, ident, level
    my $id      = uv2zero($data{id});
    return $self->error("Incorrect ID") unless is_int($id);
    my $from    = uv2null($data{from});
    my $to      = uv2null($data{to});
    return $self->error("Incorrect receiver (To)") unless length($to);
    my $subject = uv2null($data{subject});
    my $message = uv2null($data{message});
    return $self->error("No content of the message") unless length($message);
    my $host    = uv2null($data{host});
    my $ident   = uv2null($data{ident});
    my $level   = uv2zero($data{level});
    return $self->error("Incorrect level") unless is_int8($level);

    # Debugging
    $self->logger->log_info(sprintf(
            "Accepted %s-message #%s [Host: %s; Ident: %s]. From: %s; To: %s; Subject: %s",
            getLevelName($level), $id, $host, $ident, $from, $to, $subject
        ));

    # - смотрим чтобы user был в конфигурации
    my $username = $to || 'anonymous';
    my $usernode = node($config => "user", $username);
    return $self->error("No user's configuration section. See <User \"username\">...</User> section")
        unless is_hash($usernode) && keys %$usernode;

    # - получаем каналы и пробегаемся по ним
    my $channels = hash($usernode => "channel");
    my $channel = new App::MonM::Notifier::Channel(
        timeout => value($config => "user", $username, "timeout") || undef, # Default: 300
    );
    my $summary = 0;
    my @pool;
    my $reason = []; # [ CHNAME, RSN_DEFAULT, GOT, EXPECTED ]
    foreach my $chname (keys %$channels) {
        $chname //= 'NONE';
        my $ch = hash($channels => $chname);
        $reason = [$chname, RSN_CHANNEL];
        next unless $ch && keys %$ch;
        #$self->logger->log_notice(Dumper($ch));
        my $type = value($ch => "type");

        # - смотрим чтобы канал был доступен
        $reason = [$chname, RSN_TYPE];
        #$self->logger->log_notice(Dumper([$channel]));
        next unless $type && $channel->channels($type);

        # - смотрим чтобы канал был включенным - on
        $reason = [$chname, RSN_DISABLED];
        next unless value($ch => "enable");

        # - смотрим чтобы канал был актуалным (checkPubDate(node($config => "user/test"), "MySMS"))
        $reason = [$chname, RSN_PUBDATE];
        next unless checkPubDate($usernode, $chname);
        #$self->logger->log_notice(sprintf("%s> %s", $chname, "OK"));

        # - смотрим чтобы уровень level для отдадки проходил по одному из двух типов критериев
        my $cfglvl = value($ch => "level");
        if ($cfglvl) {
            $reason = [$chname, RSN_LEVEL, $cfglvl, getLevelName($level)];
            next unless checkLevel($cfglvl, $level);
            #$self->logger->log_notice(sprintf("%s> %s; Level=%s [%d]", $chname, "Ok.", getLevelName($level), $level));
        }

        # - смотрим чтобы хватало всех данных для выполнения канала
        my %setopts = _set_opts(hash($ch => "options"));
        #$self->logger->log_info(Dumper([$ch, {%setopts}]));

        #
        # PROCESSING
        #
        if ($channel->send(lc($type),
            { # Data
                id      => $id,
                to      => _set_real_to($to, $ch),
                from    => _set_real_from($from, $ch),
                subject => $subject,
                message => $message,
                host    => $host,
                ident   => $ident,
            },
            { %setopts }, # Options
        )) {
            # Ok
        } else {
            # Error
            $reason = [$chname, RSN_ERROR, $channel->error];
            next;
        }

        $reason = undef; # if ok
        $summary++; # if ok
    } continue {
        if ($reason) {
            my $nm = uv2null(shift(@$reason));
            my $rsn = uv2zero(shift(@$reason));
            my $got = uv2null(shift(@$reason));
            my $exp = uv2null(shift(@$reason));
            my $pfx = sprintf("%s=%d: %s", $nm, $rsn, REASONS->{$rsn});
            my $sfx = "";
            if ($exp) {
                $sfx = sprintf("Got=%s; Exp=%s", $got, $exp);
            } elsif ($got) {
                $sfx = sprintf("%s", $got);
            }
            if ($sfx) {
                push @pool, sprintf("%s [%s]", $pfx, $sfx);
            } else {
                push @pool, $pfx;
            }
        }
    }

    # - Если выполнилось хоть один канал - SENT (return 1)
    # - Если НЕ выполнилось ни один канал - ERROR (return 0) с предварительной фиксацией стека ошиюбок
    if ($summary) {
        $self->logger->log_info(sprintf(
            "Sent %s-message #%s [Host: %s; Ident: %s]",
            getLevelName($level), $id, $host, $ident
        ));
    } else {
        $self->error(join("; ", @pool));
        $self->logger->log_error(sprintf(
            "Failed %s-message #%s [Host: %s; Ident: %s] %s",
            getLevelName($level), $id, $host, $ident, $self->error
        ));
        return 0;
    }

    #Done!
    #mysleep 3;
    return 1;
}

sub _set_opts {
    my $in = shift;
    my %defs = ();
    if (is_hash($in)) {
        %defs = %$in;
    }
    my $attr = array($in => "set");
    foreach (@$attr) {
        $defs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    delete $defs{set};
    return %defs;
}
sub _set_real_to {
    my $to = shift;
    my $in = shift;
    return $to unless $in && is_hash($in);
    return value($in => "to") || $to;
}
sub _set_real_from {
    my $from = shift;
    my $in = shift;
    return $from unless $in && is_hash($in);
    return value($in => "from") || $from;
}


1;
__END__
