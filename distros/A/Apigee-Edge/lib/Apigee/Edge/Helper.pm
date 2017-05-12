package Apigee::Edge::Helper;

use strict;
use warnings;
our $VERSION = '0.08';    ## VERSION

use Carp;
use base 'Apigee::Edge';
use URI::Split qw(uri_split);

use vars qw/$errstr/;
sub errstr { return $errstr || Apigee::Edge->errstr }

sub get_top_developer_app {
    my ($self, $email) = @_;

    my $apps = $self->get_developer_apps($email, {expand => 'true'});
    return unless ($apps and $apps->{app} and scalar(@{$apps->{app}}));

    my $my_app = $apps->{app}->[0];

    # flatten attrs into $my_app
    my %attrs = map { $_->{name} => $_->{value} } @{$my_app->{attributes}};
    $my_app = {%$my_app, %attrs};

    $my_app->{display_name} = $attrs{DisplayName} || $my_app->{name};    # shortcut

    return $my_app;
}

sub refresh_developer_app {                                              ## no critic (ArgUnpacking)
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;

    my $name = $params{name};
    if (!$name) {
        $errstr = 'Application Name must be provided.';
        return;
    } elsif ($name !~ /^[\w\s-]{5,30}$/) {                               # restrict to only 5-30 alphanumerics or spaces.
        $errstr = 'Application Name data is invalid.';
        return;
    }
    my $callback_url = $params{callbackUrl};
    if (!$callback_url) {
        $errstr = 'Callback URL must be provided.';
        return;
    } elsif ($callback_url =~ /['"<>]/) {                                # rule out quotes or anglebrackets.
        $errstr = 'Callback URL data is invalid.';
        return;
    } else {
        my ($scheme, $host, $path) = uri_split($callback_url);
        # in theory a uri can be almost anything; but for sanity insist on at least this much..
        unless ($scheme && $host && $path) {
            $errstr = 'Callback URL format is invalid. ';
            return;
        }
    }

    my $email  = $params{email};
    my $my_app = $params{app};
    unless (exists $params{app}) {
        $my_app = $self->get_top_developer_app($email);
    }

    if ($my_app) {
        # update app
        $self->update_developer_app(
            $email,
            $my_app->{name},
            {
                attributes => [{
                        name  => 'DisplayName',
                        value => $name,
                    }
                ],
                callbackUrl => $callback_url,
            });
        $my_app->{display_name} = $name;
        $my_app->{callbackUrl}  = $callback_url;
        $errstr                 = 'Update successful';
    } else {
        my $developer = $self->get_developer($email);
        unless ($developer and $developer->{developerId}) {    # create on demand
            $developer = $self->create_developer(
                "email"     => $email,
                "firstName" => $params{firstName},
                "lastName"  => $params{lastName},
                "userName"  => $params{userName},
            );
        }

        $my_app = $self->create_developer_app(
            $email,
            {
                name        => $name,
                callbackUrl => $callback_url,
                $params{apiProducts} ? (apiProducts => $params{apiProducts}) : (),
            });
        if ($my_app->{message}) {
            $errstr = $my_app->{message};
            return;
        }
        $my_app->{display_name} = $name;
        $errstr = "$name has been registered. New OAuth credentials are available";
    }

    return $my_app;
}

sub get_all_clients {
    my ($self) = @_;

    my $apps = $self->get_apps(
        expand      => 'true',
        includeCred => 'true'
    ) or croak "Apigee::Edge failure: " . $self->errstr;
    my $CLIENTS = {};
    for my $app (@{$apps->{app}}) {
        next unless $app->{status} eq 'approved';
        my $consumerKey = eval {
            my $credentials = $app->{credentials};
            $credentials->[0]->{consumerKey};
        } || next;
        if (my $attrs = $app->{attributes}) {
            my %attrs = map { $_->{name} => $_->{value} } @$attrs;
            $app->{name} = $attrs{DisplayName} if $attrs{DisplayName};
        }
        $CLIENTS->{$consumerKey} = $app->{name};
    }
    return $CLIENTS;
}

1;
__END__

=encoding utf-8

=head1 NAME

Apigee::Edge::Helper - Helpers for Apigee::Edge

=head1 SYNOPSIS

  use Apigee::Edge::Helper;

  my $apigee = Apigee::Edge::Helper->new(
    org => 'apigee_org',
    usr => 'your_email',
    pwd => 'your_password'
  );

=head1 DESCRIPTION

it builts top on L<Apigee::Edge> with same useful helpers.

=head1 METHODS

=head2 get_top_developer_app

    my $app = $apigee->get_top_developer_app($email);

get the first app belongs to developer ($email) and flatten attrs into app

=head2 refresh_developer_app

    my $app = $apigee->refresh_developer_app(
        app         => $old_app, # optional, app hashref, can be from get_top_developer_app
        email       => $client_email,
        name        => $name,
        callbackUrl => $callback_url,
        apiProducts => ['ProductName'], # optional
        firstName   => $first_name,
        lastName    => $last_name,
        userName    => $loginid,
    );
    warn $apigee->errstr;

when param B<app> is provided, we'll update the $old_app to $app with name to be a DisplayName attr and callbackUrl updated..

when param B<app> is not provided, we'll first call get_top_developer_app to find the app to update. if app is not created yet, we'll create a new developer on the fly with email/firstName/lastName/userName and created related developer_app with name/callbackUrl and apiProducts.

=head2 get_all_clients

    my $clients = $apigee->get_all_clients();

with consumerKey as key and DisplayName || name as the value.

=head2 errstr

=head1 GITHUB

L<https://github.com/binary-com/perl-Apigee-Edge>

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
