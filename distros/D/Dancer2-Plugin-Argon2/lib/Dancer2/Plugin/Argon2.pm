package Dancer2::Plugin::Argon2;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use Dancer2::Plugin;
use Dancer2::Plugin::Argon2::Passphrase;

has cost => (
    is          => 'ro',
    from_config => sub { 3 },
);
has factor => (
    is          => 'ro',
    from_config => sub { '32M' },
);
has parallelism => (
    is          => 'ro',
    from_config => sub { 1 },
);
has size => (
    is          => 'ro',
    from_config => sub { 16 },
);

plugin_keywords(qw( passphrase ));

sub passphrase {
    my ( $plugin, $password ) = @_;
    croak 'Please provide password argument' unless defined $password;
    my $passphrase_settings = { password => $password };
    $passphrase_settings->{$_} = $plugin->$_ for (qw( cost factor parallelism size ));
    return Dancer2::Plugin::Argon2::Passphrase->new($passphrase_settings);
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Argon2 - Handling Argon2 passwords in Dancer2

=head1 SYNOPSIS

    use Dancer2::Plugin::Argon2;

    my $passphrase = passphrase($password)->encoded;
    if ( passphrase($password2)->matches($passphrase) ) { ... }

=head1 DESCRIPTION

Dancer2::Plugin::Argon2 is a plugin for Dancer2 to manage passwords using Argon2.

=head1 CONFIGURATION

The module can be used with the default configuration.
But it is possible to change it if necessary.
The default configuration may present like this:

    plugins:
        Argon2:
            cost: 3
            factor: '32M'
            parallelism: 1
            size: 16

=head1 USAGE

    package SomeWebApplication;
    use Dancer2;
    use Dancer2::Plugin::Argon2;

    post '/signup' => sub {
        my $passphrase = passphrase( body_parameters->get('password') )->encoded;
        # and store $passphrase for use later
    };

    post '/login' => sub {
        # retrieve stored passphrase into $passphrase
        if ( passphrase( body_parameters->get('password') )->matches($passphrase) ) {
            # passphrase matches
        }
    };

=head1 SEE ALSO

L<Dancer2::Plugin::Argon2::Passphrase>,
L<Crypt::Argon2>,
L<https://github.com/p-h-c/phc-winner-argon2>

=head1 LICENSE

Copyright (C) Sergiy Borodych.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sergiy Borodych C<< <bor at cpan.org> >>

=cut

