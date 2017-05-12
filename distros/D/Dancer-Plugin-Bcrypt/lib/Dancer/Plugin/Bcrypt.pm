package Dancer::Plugin::Bcrypt;

# ABSTRACT: DEPRECATED Bcrypt interface for Dancer

use strict;

use Dancer::Plugin;
use Dancer::Config;

use Crypt::Eksblowfish::Bcrypt qw/en_base64/;
use Crypt::Random::Source;

our $VERSION = '0.4.1';


register bcrypt => \&bcrypt;
register bcrypt_validate_password => \&bcrypt_validate_password;


sub bcrypt {
    my ($plaintext, $bcrypted) = @_;

    return if !$plaintext;

    # Sanity checks, and provide some good defaults.
    my $config = sanity_check();

    # On to the actual work...

    # If you pass a plaintext password and an bcrypted one (from a DB f.ex)
    # we hash the plaintext password using the same method, salt and
    # work factor as the stored version. If the plaintext password matches
    # the stored version then the resulting hashes should be identical.

    if ($bcrypted && $bcrypted =~ /^\$2a\$/) {
        return Crypt::Eksblowfish::Bcrypt::bcrypt($plaintext, $bcrypted);
    }

    # If we have been passed only the plaintext, then we
    # generate the bcrypted version with all new settings

    # Use bcrypt and append with a NULL - The accepted way to do it
    my $method = '$2a';

    # Has to be 2 digits exactly
    my $work_factor = sprintf("%02d", $config->{work_factor});

    # Salt must be exactly 16 octets, base64 encoded.
    my $salt = en_base64( generate_salt( $config->{random_factor} ) );

    # Create the settings string that we will use to bcrypt the plaintext
    # Read the docs of the Crypt:: modules for an explanation of this string
    my $new_settings = join('$', $method, $work_factor, $salt);


    return Crypt::Eksblowfish::Bcrypt::bcrypt($plaintext, $new_settings);
};


sub bcrypt_validate_password {
    my ($plaintext, $bcrypted) = @_;

    if ($plaintext && $bcrypted) {
        return bcrypt($plaintext, $bcrypted) eq $bcrypted;
    } else {
        return;
    }
}


sub sanity_check {
    my $config = plugin_setting;

    # Takes ~0.007 seconds on 2011 hardware
    $config->{work_factor} ||= 4;

    # Uses /dev/urandom - which is pretty good
    $config->{random_factor} ||= 'weak';

    # Work factors higher than 31 aren't supported.
    if ($config->{work_factor} > 31) {
        $config->{work_factor} = 31;
    };

    # Can only specify weak or strong as random_factor
    unless ( grep { $_ eq $config->{random_factor} } ('strong', 'weak') ) {
        $config->{random_factor} = 'weak';
    }

    return {
        work_factor   => $config->{work_factor},
        random_factor => $config->{random_factor},
    };
}


sub generate_salt {
    my ($type) = @_;

    if ($type eq 'strong') {
        return Crypt::Random::Source::get_strong(16);
    } else {
        return Crypt::Random::Source::get_weak(16);
    }
}


register_plugin;

1;


=pod

=head1 NAME

Dancer::Plugin::Bcrypt - DEPRECATED Bcrypt interface for Dancer


=head1 VERSION

version 0.4.1


=head1 DESCRIPTION

PLEASE NOTE THAT WHILE THIS MODULE WORKS, IT IS DEPRECATED, AND NO LONGER MAINTAINED.

I suggest you use the more flexible replacement L<Dancer::Plugin::Passphrase> -
It has all the same functionality as the module, and also allows you to match
against other hashing algorithms as well as brcypt.

Original documentation continues below...

This plugin is a simple interface to the bcrypt algorithm allowing web apps
created by dancer to easily store passwords in a secure way.

It generates a crypographically strong salt for each password, uses the
very strong bcrypts algorithm to hash the password - and does these in a
configurable and portable manner.


=head1 BACKGROUND

See L<http://codahale.com/how-to-safely-store-a-password/>

To safely store passwords in the modern era, you should use bcrypt.
It's that simple

MD5, SHA and their ilk are general purpose hash functions, designed for speed.

An average server can calculate the MD5 hash of every 6 character, alphanumeric
password in about 40 seconds. The beefiest boxen can do the same in ONE second

Bcrypt is an adaptive password hashing algorithm. It uses a work factor
to determine how SLOWLY it hashes a password. This work factor
can be increased to keep up with the ever increasing power of computers.


=head1 KEYWORDS

=head2 bcrypt

Pass it a plaintext password, and it will return a string suitable for
storage, using the settings specified in the app config.

This string contains the bcrypted hash, work factor used, and the salt used
to generate the hash, delimited by a $.

    my $hash = bcrypt($plaintext);

Pass a plaintext password and a stored bcrypted string, it will return a hash
of the plaintext password using the work factor and salt from the stored hash.

You would use this to verify that a password provided by a user matches the
hash you have stored in the database.

    my $hash = bcrypt($plaintext, $stored_hash);

=head2 bcrypt_validate_password

Pass it a plaintext password and the crypted password you have stored, and it
will return a boolean to indicate whether the plaintext password entered is
correct (it hashes to the same has the stored hash).

    if (bcrypt_validate_password($entered_password, $stored_hash)) {
        ...
    }


=head1 USAGE

    package MyWebService;
    use Dancer;
    use Dancer::Plugin::Bcrypt;

    get '/' sub => {

        # Generate a new hashed password - suitable for storing in a DB.
        my $hash = bcrypt( param('password') );

        # [...]

        # Validate password provided by user against stored hash.
        my $stored_hash = ''; # [...] retreive password from the DB.

        if (bcrypt_validate_password(param('password'), $stored_hash)) {
            # Entered password matches
        }

    };


=head1 CONFIGURATION

You can set the work factor and the random-ness of the salt in your config.yml

    plugins:
      bcrypt:
        work_factor: 8
        random_factor: strong


=head1 SEE ALSO

L<Dancer>, L<Crypt::Eksblowfish::Bcrypt>, L<Crypt::Random::Source>,
L<http://codahale.com/how-to-safely-store-a-password/>


=head1 AUTHOR

James Aitken <jaitken@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
