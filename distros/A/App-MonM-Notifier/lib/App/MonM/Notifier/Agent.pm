package App::MonM::Notifier::Agent; # $Id: Agent.pm 61 2019-07-14 12:04:03Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Agent - App::MonM::Notifier agent

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Notifier::Agent;

    my $agent = new App::MonM::Notifier::Agent(
        configobj => $app->configobj,
        users => [qw/foo bar/],
    );

=head1 DESCRIPTION

This module provides agent methods.

=head2 new

    my $agent = new App::MonM::Notifier::Agent(
        configobj => $app->configobj,
        users => [qw/foo bar/],
    );

=over 4

=item B<configobj>

CTK config object

=item B<users>

The list of users

=back

=head2 config

    my $configobj = $agent->config;

Returns CTK config object

=head2 create

    $agent->create(
        to => "test",
        subject => $sbj,
        message => $msg,
    ) or die($agent->error);

Creates message and returns status of operation

=head2 error

    my $error = $agent->error;
    my $status = $agent->error( "error text" );

Returns error string if no arguments.
Sets error string also sets status to false (if error string is not false)
or to true (if error string is false) and returns this status

=head2 status

    if ($agent->status) {
        # OK
    } else {
        # ERROR
    }

Returns object's status. 1 - OK, 0 - ERROR

    my $status = $agent->status( 1 );

Sets new status and returns it

=head2 store

    my $store = $agent->store;

Returns current store object

=head2 trysend

    $agent->trysend() or die($agent->error);

Tries to send all active messages

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<App::MonM>

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

use vars qw/$VERSION/;
$VERSION = '1.01';

use File::Spec;
use File::HomeDir;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use App::MonM::Util qw/getExpireOffset/;

use App::MonM::Notifier::Const qw/ :jobs :functions /;
use App::MonM::Notifier::Store;
use App::MonM::Notifier::Util qw/checkPubDate/;
use App::MonM::Notifier::Channel;

sub new {
    my $class = shift;
    my %opts = @_;
    my $configobj = $opts{configobj} || $opts{config};
    my $userreqs = $opts{users} || $opts{user};
    my $notifier_conf = $configobj->conf("notifier") || {};

    # List of required users
    my @ureqs = ();
    if ($userreqs && ref($userreqs) eq 'ARRAY') {
        @ureqs = @$userreqs;
    } elsif ($userreqs && !ref($userreqs)) {
        push @ureqs, $userreqs;
    }

    # Get actual user list
    my $user_conf = $configobj->conf('user') || {};
    my @users = ();
    foreach my $u (keys %$user_conf) {
        if (@ureqs) {
            next unless grep {$_ eq $u} @ureqs;
        }
        push @users, $u;
    }

    # Get expires
    my $expires_def = getExpireOffset($configobj->conf("expires") || $configobj->conf("expire") || 0);
    my $expires = getExpireOffset(value($notifier_conf, "expires") || value($notifier_conf, "expire")) || $expires_def;

    # Get timeout
    my $timeout = getExpireOffset(value($notifier_conf, "timeout") || $configobj->conf("timeout") || 0);

    my %props = (
            error   => '',
            status  => 1,
            store   => undef,
            config  => $configobj,
            users   => [@users],
            datadir => File::HomeDir->my_data,
            expires => $expires,
            timeout => $timeout,
        );

    # DBI object (store)
    my $dbi_file = File::Spec->catfile($props{datadir}, App::MonM::Notifier::Store::DB_FILENAME());
    my $dbi_conf = $notifier_conf->{"dbi"} || {file => $dbi_file};
       $dbi_conf = {file => $dbi_file} unless is_hash($dbi_conf);
    my $store = new App::MonM::Notifier::Store(%$dbi_conf, expires => $expires);
    if ($store->status) {
        $props{store} = $store;
    } else {
        $props{error} = sprintf("Can't create store instance: %s", $store->error);
        $props{status} = 0;
    }

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
sub config {
    my $self = shift;
    $self->{config};
}
sub create {
    my $self = shift;
    my %in = @_;
    my $store = $self->store;
    return $self->error("Can't use undefined store object") unless $store && $store->ping;
    $self->error("");

    my $to = $in{to};
    my $allowed_users = $self->{users};
    foreach my $u (grep {$to ? ($_ eq $to) : 1} @$allowed_users) {
        # Get User node
        my $usernode = node($self->config->conf("user"), $u);
        next unless is_hash($usernode) && keys %$usernode;

        # Get channels
        my $channels = hash($usernode => "channel");
        foreach my $ch_name (keys %$channels) {
            # Create new record
            $store->add(
                to      => $u,
                channel => $ch_name,
                subject => $in{subject},
                message => $in{message},
            ) or do {
                return $self->error($store->error);
            };

        }
    }

    return 1;
}
sub trysend {
    my $self = shift;
    my $store = $self->store;
    return $self->error("Can't use undefined store object") unless $store && $store->ping;
    $self->error("");

    # Channel object
    my $channel = new App::MonM::Notifier::Channel(configobj => $self->config);

    my $allowed_users = $self->{users};
    foreach my $u (@$allowed_users) {
        # Get User node
        my $usernode = node($self->config->conf("user"), $u);
        next unless is_hash($usernode) && keys %$usernode;

        # Get channels
        my $channels = hash($usernode => "channel");
        foreach my $ch_name (keys %$channels) {
            next unless checkPubDate($usernode, $ch_name); # Skip by period checking
            my $ch = hash($channels, $ch_name);

            # Get data to processing
            my %data = $store->getByName($u, $ch_name);
            return $self->error($store->error) unless $store->status;

            # Processing data
            foreach my $rec (values %data) {
                if (fv2zero($rec->{expires}) < time()) { # EXPIRED
                    $store->setStatus($rec->{id}, JOB_EXPIRED) or do {
                        return $self->error($store->error);
                    };
                } else { # TO SEND
                    my $status = $channel->process($rec, $ch);

                    # Set result status
                    if ($status) { # JOB_SENT
                        $store->setStatus($rec->{id}, JOB_SENT) or do {
                            return $self->error($store->error);
                        };
                    } else {
                        $store->setError($rec->{id}, 102, $channel->error) or do {
                            return $self->error($store->error);
                        };
                    }
                }
            }
        }
    }
    return 1;
}

1;

__END__
