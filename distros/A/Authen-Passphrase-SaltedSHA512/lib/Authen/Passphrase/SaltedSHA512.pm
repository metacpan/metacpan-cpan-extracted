## no critic (RCS,VERSION)
package Authen::Passphrase::SaltedSHA512;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.07';

# $VERSION = eval $VERSION;    ## no critic (eval)

use Exporter;
use Authen::Passphrase::SaltedDigest;
use Bytes::Random::Secure qw( random_bytes_hex );

our @ISA = qw( Exporter Authen::Passphrase::SaltedDigest );   ## no critic (ISA)
our @EXPORT_OK = qw( generate_salted_sha512 validate_salted_sha512 );

use constant NUM_BYTES => 64;    ## no critic (constant)

sub new {
    my ( $class, %args ) = @_;
    $args{algorithm} = 'SHA-512';

    # We're doing our own random salt generation.
    delete $args{salt_random};

    # If there is no hash supplied, and a passphrase is supplied, this must be
    # a passphrase hash/salt generation object.
    if (   !exists $args{hash}
        && !exists $args{hash_hex}
        && exists $args{passphrase} )
    {

        # Generate a 512 bit random salt using a secure random generator.
        # 64 bytes is 512 bits, or 128 hex characters.
        my $salt = random_bytes_hex(NUM_BYTES);

        # We're generating our own salt.  Don't accept others.
        delete $args{$_} for qw( salt salt_hash );

        $args{salt_hex} = $salt;
    }

    # Let the super-class instantiate and handle our preprocessed args.
    return $class->SUPER::new(%args);
}

sub generate_salted_sha512 {
    my $password = shift;
    my $gen = __PACKAGE__->new( passphrase => $password );
    return ( $gen->salt_hex, $gen->hash_hex );
}

sub validate_salted_sha512 {
    my ( $password, $salt_hex, $hash_hex ) = @_;
    my $auth = __PACKAGE__->new(
        salt_hex => $salt_hex,
        hash_hex => $hash_hex
    );
    return $auth->match($password);
}

1;    # End of Authen::Passphrase::SaltedSHA512

__END__

=head1 NAME

Authen::Passphrase::SaltedSHA512 - Safe, Sane, and Simple passphrase salting,
hashing and authentication.

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

This module is a subclass of
L<Authen::Passphrase::SaltedDigest|http://search.cpan.org/perldoc?Authen::Passphrase::SaltedDigest>.
It adds two features to make your life a little easier and safer.  First, it
simplifies the user interface by selecting reasonable (and secure) defaults.
Second, in generating salt, it uses the high quality, CSPRNG provided by
L<Bytes::Random::Secure|http://search.cpan.org/perldoc?Bytes::Random::Secure>.

Some examples:

    use Authen::Passphrase::SaltedSHA512;

    # Generate a salt and hash from a passphrase.
    my $gen = Authen::Passphrase::SaltedSHA512->new( passphrase => 'Sneaky!' );
    my $hash = $gen->hash_hex;
    my $salt = $gen->salt_hex;
    # Store the hash and the salt in your user database.


    # Later....
    # Challenge a passphrase to authenticate a user login.
    # First, retrieve the user's hash and salt from your user database.
    # Then generate a challenge object:
    my $challenge = Authen::Passphrase::SaltedSHA512->new(
        salt_hex    => $salt,
        hash_hex    => $hash
    );

    # And challenge the passphrase supplied for the current session's login.
    if( $challenge->match( 'Sneaky!' ) ) {
        print "You are a winner!\n";
    }

    # Or for the ultimate in ease and simplicity:
    use Authen::Passphrase::SaltedSHA512 qw(
        generate_salted_sha512      validate_salted_sha512
    );
    my ( $salt_hex, $hash_hex ) = generate_salted_sha512( $passphrase );
    my $is_valid = validate_salted_sha512( $passphrase, $salt_hex, $hash_hex );



=head1 DESCRIPTION

Authen::Passhprase::SaltedSHA512 is designed to simplify the process of
generating random salt for, and a salted hash of a user supplied passphrase.

It is also designed to easily authenticate a user supplied passphrase against
a given salt and hash.

The presumed use-case is for user authentication where a salt and a password
hash will be stored in a database of user logins.  The simple interface should
fit into a broad range of authentication systems with minimal clutter.

Authen::Passphrase::SaltedSHA512 is a subclass of
L<Authen::Passphrase::SaltedDigest|http://search.cpan.org/perldoc?Authen::Passphrase::SaltedDigest>
that overrides the constructor to provide reasonable defaults so that you
don't have to spend a week reading articles on which algorithm to use, and how
to generate a good salt.

The hashing algorithm chosen is the SHA-512 hash function from the SHA-2
family.  Currently SHA-512 is a leading edge standard in strong hashing.

The salt generated when creating authentication credentials is a 512 bit
random string.  The random number generating algorithm used comes from
L<Bytes::Random::Secure|http://search.cpan.org/perldoc?Bytes::Random::Secure>.
That module uses Math::Random::ISAAC, "I<...a cryptographically-strong random
number generator with no known serious weaknesses.>"  Bytes::Random::Secure
obtains its seed using Crypt::Random::Seed.  The reason that
Bytes::Random::Secure was chosen over other random number generators is because
that module has a light-weight dependency chain, a cryptographically strong
random number generator, strong seeding (the hardest part of the CSPRNG problem)
across a wide variety of platforms, and useful hex output.

By using a 512 bit random salt, a maximum degree of entropy is achieved in the
hashes generated by the SHA-512 algorithm.  Every time the constructor is
called you will get a new random salt, so every user has his own salt.  The
advantage of using a fresh random salt for each user is that it eliminates the
rainbow table attack vector, by guaranteeing that if one user's password is
compromised through brute force (or cosmic good luck) all of your other users
with their own random salts are still secure.

By selecting secure defaults for hashing algorithm, random number generation,
and salt bit-length, much of the guesswork can be eliminated from devising
an authentication scheme, and a simpler user interface results.

=head1 EXPORT

This is primarily an Object Oriented Interface module.  However, for even
greater simplicity, a standard functions interface is provided upon request.
Nothing is exported by default.  By supplying an export list, the following
subroutines are available:

=over 4

=item * generate_salted_sha512

=item * validate_salted_sha512

=back



=head1 SUBROUTINES/METHODS

=head2 METHODS

The following section describes the methods available through the module's
Object Oriented interface.

=head3 new

B<The constructor> will create an object that can either be used to generate
a salt and a hash for later use, or to challenge a supplied salt and hash
by a passphrase supplied to C<match>.

Instantiate a salt and hash generator object.

    my $auth_gen = Authen::Passphrase::SaltedSHA512->new(
        passphrase => 'All your base are belong to us.'
    );

Instantiate a challenge object.

    my $challenger = Authen::Passphrase::SaltedSHA512->new(
        salt_hex    => $retrieved_salt,
        hash_hex    => $retrieved_hash
    );


=head4 Constructor Parameters

For passphrase hash and salt generation, you must supply the C<passphrase>
parameter.  For validation, you must supply either a raw or a hex salt, using
the C<salt> or C<salt_hex> parameters, and either a raw or a hex hash, using
the C<hash> or C<hash_hex> parameters.  These are described below.

=over

=item B<salt>

The salt, as a raw string of bytes.  Defaults to the empty string,
yielding an unsalted scheme.

=item B<salt_hex>

The salt, as a string of hexadecimal digits.  Defaults to the empty
string, yielding an unsalted scheme.

=item B<hash>

The hash, as a string of bytes.

=item B<hash_hex>

The hash, as a string of hexadecimal digits.

=item B<passphrase>

A passphrase that will be accepted.

=back

You must supply either a C<passphrase>, or a C<salt> and a C<hash>.  The
C<salt> and the C<hash> may either be supplied as C<< salt => $raw_string >>
and C<< hash => $raw_string >> or as C<< salt_hex => $hex_digits >> and
C<< hash_hex => $hex_digits >>.  Both the salt and the hash will be 512 bits
long, or 128 hex digits.

If a C<passphrase> is suppled, a generator object will be created.  If some
form of C<salt> and C<hash> are supplied, a challenge object will be created.

=head3 salt

Returns the 512 bit salt, in raw form (64 bytes).

    my $salt = $auth_gen->salt;

=head3 salt_hex

Returns the salt, as a string of 128 hexidecimal digits.

    my $salt_hash = $auth_gen->salt_hash;
    
=head3 hash

Returns the 512 bit hash, in raw form.

    my $hash = $auth_gen->hash;

=head3 hash_hex

Returns the hash, as a string of 128 hexidecimal digits.

    my $hash_hex = $auth_gen->hash;

=head3 match

Returns true if C<$passphrase> matches against the salt and hash supplied to
the constructor, and false otherwise.

    if( $challenge->match( $passphrase ) ) {
        print "Your passphrase has been authenticated.\n";
    }
    else {
        print "Invalid passphrase.\n",
              "You have 1.34e154 more tries before exhausing all possible guesses.\n",
              "Happy hunting!\n";
    }

=head3 algorithm

Returns the digest algorithm, which will always be C<SHA-512>.


=head2 SUBROUTINES

This section describes the subroutines used in this module's
standard (non-OO) interface.

=head3 generate_salted_sha512

Accepts a C<$passphrase> parameter, and returns a list containing a hex
representation of a random salt, and of the hash.

    my( $salt_hex, $hash_hex ) = generate_salted_sha512( 'Groovy Password' );

=head3 validate_salted_sha512

Accepts parameters of C<$passphrase>, C<$salt_hex>, and C<$hash_hex>, and
returns true if C<$passphrase> authenticates against the given salt and hash.

    my $is_valid = validate_salted_sha512(
        'Groovy Password',
        $salt_hex,
        $hash_hex
    );



=head1 IMPLEMENTATION DETAILS

While the choice of the SHA-2 SHA-512 function was an easy one, selecting a
random number generator for building cryptographically useful salt proved more
difficult.  Some modules are using one of the Math::Random::MT modules, yet
the POD for Math::Random::MT states, "This algorithm has a very uniform
distribution and is good for modelling purposes but do not use it for
cryptography."

Authen::Passphrase::SaltedDigest could generate random salt, but relies on
Data::Entropy to do so.  Data::Entropy::Algorithm, by default seems to be
constrained by the quality of Perl's C<seed>, which is probably not as secure
of a source as should be used.  That leads to a search for a better solution.

The list of other possibilities is long, and while many of them might turn out
to be reasonable choices,
L<Math::Random::Secure|http://search.cpan.org/perldoc?Math::Random::Secure>
seemed to offer a solution that is secure today, and should continue to follow
I<Best Practices> as new trends emerge.  The disadvantage is that it is heavy
on dependencies.  This seems to be the price one has to pay for a really good
random source.

=head1 COMPATIBILITY

Because Authen::Passphrase::SaltedSHA512 is a subclass of
L<Authen::Passphrase::SaltedDigest|http://search.cpan.org/perldoc?Authen::Passphrase::SaltedDigest>,
the hash and salt generated can also be challenged using
Authen::Passphrase::SaltedDigest in place of this module simply by supplying
the appropriate defaults to the constructor:

    my $apsd = Authen::Passphrase::SaltedDigest->new(
        algorithm   => 'SHA-512',
        salt        => $salt,
        hash        => $hash
    );
    print "You win!\n" if $apsd->match( $passphrase );

By the same token, Authen::Passphrase::SaltedDigest generated hashes are
compatible with Authen::Passphrase::SaltedSHA512, if they are generated using
the C<< algorithm => 'SHA-512' >> setting:

    my $apss = Authen::Passphrase::SaltedSHA512->new(
        salt    => $salt,
        hash    => $hash,
    );
    print "Bingo!\n" if $apss->match( $passphrase );

So if you want a drop-in replacement for Authen::Passphrase::SaltedDigest that
defaults to SHA-512 hashing with automatic generation of salts composed of
512 securely-random bits, the changes to your code will be simple.

However, the C<as_rfc2307> method from Authen::Passphrase::SaltedDigest
shouldn't and can't be used within Authen::Passphrase::SaltedSHA512.  See
the B<INCOMPATIBILITIES> section below for details.

This module should install and run on any system that supports Perl from
v5.8.0 to the present, and fits easily into authentication plugins such as
Mojolicious::Plugin::Authentication.


=head1 INCOMPATIBILITIES

The C<as_rfc2307> method of Authen::Passphrase::SaltedDigest
doesn't allow for hard coded defaults, and thus, is meaningless in the context
of this module.  Furthermore, this module doesn't consider the
C<algorithm> and C<random_salt> directives in its constructor; it already sets
a SHA-512 default and always generates a 512-bit random salt.

One of the module's dependencies that inherited through Authen::Passphrase
may fail to pass its test suite on some Windows systems.  The part that fails
relates to the random number generator used by Authen::Passphrase.  This
module uses a different random number generator -- not the one from
Authen::Passphrase.  You may decide that if a failure to install traces back
to a random number generation module for Authen::Passphrase a forced install
could still be appropriate.

=head1 DEPENDENCIES

This module has the following non-core immediate dependencies:

=over 4

=item Authen::Passphrase (which provides Authen::Passphrase::SaltedDigest)

=item L<Bytes::Random::Secure|http://search.cpan.org/perldoc?Bytes::Random::Secure>

=back

Each of these has its own list of non-core dependencies as well.  But it's a
well-tested set of dependencies, with broad portability demonstrated by the
smoke tests.  Most important, we're using not only a cryptographically strong
random number generator, but also a strong source to seed the generator.

=head1 CONFIGURATION AND ENVIRONMENT

This module should be installable on most platforms via the traditional CPAN
installers, or by unpacking the tarball and repeating the well-known mantra:

    make
    make test
    make install


=head1 DIAGNOSTICS

As this module subclasses Authen::Passphrase::SaltedDigest, all of the
warnings and diagnostic messages produced by that module will be present in
this module.

=head1 SEE ALSO

=over 4

=item * Additional examples are provided in the C<examples/> folder within
the module's build directory.

=item * L<Authen::Passphrase|http://search.cpan.org/perldoc?Authen::Passphrase>

=item * L<Authen::Passphrase::SaltedDigest|http://search.cpan.org/perldoc?Authen::Passphrase::SaltedDigest>

=item * L<Bytes::Random::Secure|http://search.cpan.org/perldoc?Bytes::Random::Secure>

=item * L<Wikipedia article on SHA-2 (SHA-512)|http://en.wikipedia.org/wiki/SHA-2>

=back

=head1 AUTHOR

David Oswald, C<< <davido at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-authen-passphrase-saltedsha512 at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-Passphrase-SaltedSHA512>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Password protection and authentication is an arms race of sorts.  For now,
SHA-512 hasn't been broken, and for now, the random number generator used
to generate random salt is considered cryptographically sound.  However,
this module is only one element in what necessarily must be a system-wide
approach to robust security.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::Passphrase::SaltedSHA512


You can also look for information at:

=over 4

=item * This module's GitHub repository

L<http://github.com/daoswald/Authen-Passphrase-SaltedSHA512>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-Passphrase-SaltedSHA512>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-Passphrase-SaltedSHA512>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-Passphrase-SaltedSHA512>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-Passphrase-SaltedSHA512/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks go to the following individuals for providing input, suggestions, or
code:

=over 4

=item * Matt S. Trout -- Suggested the Authen::Passphrase family as a nice
foundation upon which this module could be easily constructed.

=item * M. Aaron Bossert -- Provided some module suggestions that, while
ultimately weren't used, started me on path that combined with further
research arrived at this destination.

=item * Andrew Main (Zefram) -- Creator of the excellent Authen::Passphrase
distribution which this module subclasses.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
