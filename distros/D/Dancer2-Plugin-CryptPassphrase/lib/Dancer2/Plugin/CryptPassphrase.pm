package Dancer2::Plugin::CryptPassphrase;
use strict;
use warnings;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

use Dancer2::Plugin;
use Crypt::Passphrase;
use Types::Standard qw(
  ArrayRef
  HashRef
  InstanceOf
  Str
);

# CONFIG

has encoder => (
    is          => 'ro',
    isa         => HashRef | Str,
    from_config => sub {'Argon2'},
);

has validators => (
    is          => 'ro',
    isa         => ArrayRef [ HashRef | Str ],
    from_config => sub { [] },
);

# KEYWORDS

has crypt_passphrase => (
    is      => 'ro',
    isa     => InstanceOf ['Crypt::Passphrase'],
    lazy    => 1,
    default => sub {
        my $plugin = shift;
        return Crypt::Passphrase->new(
            encoder    => $plugin->encoder,
            validators => $plugin->validators,
        );
    },
    handles => {
        hash_password         => 'hash_password',
        password_needs_rehash => 'needs_rehash',
        verify_password       => 'verify_password',
    },
);

plugin_keywords qw(
  crypt_passphrase
  hash_password
  password_needs_rehash
  verify_password
);

1;

=head1 NAME

Dancer2::Plugin::CryptPassphrase - use Crypt::Passphrase with Dancer2

=head1 SYNOPSIS

    package My::App;
    use Dancer2;
    use Dancer2::Plugin::CryptPassphrase;

    post '/login' => sub {
        my $username = body_parameters->get('username');
        my $password = body_parameters->get('password');
        my $hash     = my_get_hash_function($username);

        if ( verify_password( $password, $hash ) ) {
            # login success

            if ( password_needs_rehash($hash) ) {
                # upgrade hash in storage
                my_update_hash_function( $username, hash_password($pasword) );
            }

            # ... do stuff
        }
        else {
            # login failed

            # ... do stuff
        }
    };

=head1 DESCRIPTION

This plugin integrates L<Crypt::Passphrase> with your L<Dancer2> app,

=head1 KEYWORDS

=head2 crypt_passphrase

Returns the C<Crypt::Passphrase> instance.

=head2 hash_password $password

Returns a new hash for the given C<$password>.

See also L<Crypt::Password/hash_password>.

=head2 password_needs_rehash $hash

Returns a true value if C<$hash> should be upgraded to use the current
L</encoder>.

See also L<Crypt::Password/needs_rehash>.

=head2 verify_password $password, $hash

Returns a true value if the C<$password> matches the given C<$hash>,
otherwise returns a false value.

See also L<Crypt::Password/verify_password>.

=head1 CONFIGURATION

Example:

    plugins:
      CryptPassphrase:
        encoder:
          module: Argon2
          parallelism: 2
        validators:
          - +My::Old::Passphrase::Module
          - Bcrypt

Configuration options are used as the arguments for L<Crypt::Passphrase/new>,
as follows:

=head2 encoder

Default: C<Argon2> with defaults from L<Crypt::Passphrase::Argon2>.

This can be one of two different things:

=over

=item * A simple string

The name of the encoder class. If the value starts with a C<+>, the C<+> will
be removed and the remainder will be taken as a fully-qualified package name.
Otherwise, C<Crypt::Passphrase::> will be prepended to the value.

The class will be loaded, and constructed without arguments.

=item * A hash

The C<module> entry will be used to load a new L<Crypt::Passphrase> module as
described above, the other arguments will be passed to the constructor. This
is the recommended option, as it gives you full control over the password
parameters.

=back

B<NOTE:> If you wish to use an encoder other than C<Argon2>, then you
need to install the appropriate C<Crypt::Passphrase::> module.

=head2 validators

Defaults to an empty list.

This is a list of additional validators for passwords. These values can each
be the same an L/<encoder> value.

The L</encoder> is always considered as a validator and thus doesn't need to be
explicitly specified.

=head1 SEE ALSO

L<Crypt::Passphrase>, L<Crypt::Passphrase::Argon2>.

=head1 AUTHOR

Peter Mottram (SysPete) <peter@sysnix.com>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2022 the Catalyst::Plugin::CryptPassphrase L</AUTHOR>
and L</CONTRIBUTORS> as listed above.

The initial L</CONFIGURATION> documentation was taken from L<Crypt::Passphrase>
which is copyright (c) 2021 by Leon Timmermans <leont@cpan.org>.

=head1 LICENSE
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
