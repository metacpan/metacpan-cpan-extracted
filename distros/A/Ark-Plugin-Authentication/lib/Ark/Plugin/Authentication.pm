package Ark::Plugin::Authentication;
use 5.008001;
use strict;
use warnings;

our $VERSION = 0.01;

use Ark::Plugin;

has auth => (
    is      => 'rw',
    isa     => 'Ark::Plugin::Authentication::Backend',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $conf = $self->app->config->{'Plugin::Authentication'} || {};

        $self->app->ensure_class_loaded('Ark::Plugin::Authentication::Backend');
        my $class = $self->app->class_wrapper(
            name => 'Auth',
            base => 'Ark::Plugin::Authentication::Backend',
        );

        $class->new(
            app => $self->app,
            %$conf,
        );
    },
    handles => [qw/user authenticate logout/],
);

1;
__END__

=encoding utf-8

=head1 NAME

Ark::Plugin::Authentication - Ark plugins for authentications

=head1 SYNOPSIS

    use Ark;
    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory

        Authentication
        Authentication::Credential::Password
        Authentication::Store::Minimal
    /;
    conf 'Plugin::Authentication::Store::Minimal' => {
        users => {
            user1 => { username => 'user1', password => 'pass1', },
            user2 => { username => 'user2', password => 'pass2', },
        },
    };

=head1 DESCRIPTION

Ark::Plugin::Authentication is Ark plugins for Authentications.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
