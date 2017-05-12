package Data::Rand::Obscure;

use warnings;
use strict;

=head1 NAME

Data::Rand::Obscure - Generate (fairly) random strings easily.

=head1 VERSION

Version 0.021

=cut

our $VERSION = '0.021';

=head1 SYNOPSIS

    use Data::Rand::Obscure qw/create create_b64/;

    # Some random hexadecimal string value.
    $value = create;

    ...

    # Random base64 value:
    $value = create_b64;

    # Random binary value:
    $value = create_bin;

    # Random hexadecimal value:
    $value = create_hex;

    ...

    # A random value containing only hexadecimal characters and 103 characters in length:
    $value = create_hex(length => 103);

    # Object-orientated

    my $generator = Data::Rand::Obscure->new(seeder => sub { ... # My special seeding algorithm # },
        digester => sub { return $my_favorite_digester; });

    $value = $generator->create;

    $value = $generator->create_hex(length => 32);

=head1 DESCRIPTION

Data::Rand::Obscure provides a method for generating random hexadecimal, binary, and base64 strings of varying length.
To do this, it first generates a pseudo-random "seed" and hashes it using a SHA-1, SHA-256, or MD5 digesting algorithm.

Currently, the seed generator is:

    join("", <an increasing counter>, time, rand, $$, {})

You can use the output to make obscure "one-shot" identifiers for cookie data, "secret" values, etc.

Values are not GUARANTEED to be unique (see L<Data::UUID> for that), but should be sufficient for most purposes.

This package was inspired by (and contains code taken from) the L<Catalyst::Plugin::Session> package by Yuval Kogman

=cut

use Digest;
use Carp::Clan;

my $SINGLETON; # Could be cute and keep this untouchable, but why bother.
sub singleton() {
    return $SINGLETON ||= __PACKAGE__->new;
}

=head1 METHODS

=head2 Data::Rand::Obscure->new([ seeder => <seeder>, digester => <digester> ])

Returns a Data::Rand::Obscure::Generator with the following methods:

    create
    create_hex
    create_bin
    create_b64

You may optionally supply a seeder subroutine, which is called everytime a new value is to be generated.
It should return some seed value that will be digested.

You may also optionally supply a digester subroutine, which is also called everytime a new value is to be generated.
It should return a L<Digest> object of some kind (which will be used to take the digest of the seed value).

=cut

sub new {
    use Data::Rand::Obscure::Generator; # Long enough? :(
    my $class = shift;
    croak "You should extend Data::Rand::Obscure::Generator instead" unless $class eq __PACKAGE__;
    return Data::Rand::Obscure::Generator->new(@_);
}

=head1 EXPORTS 

=cut

use vars qw/@ISA @EXPORT_OK/; use Exporter(); @ISA = qw/Exporter/;
@EXPORT_OK = qw/create create_hex create_bin create_b64/;

=head2 $value = create([ length => <length> ])

=head2 $value = create_hex([ length => <length> ])

Create a random hexadecimal value and return it. If <length> is specificied, then the string will be <length> characters long.

If <length> is specified and not a multiple of 2, then $value will technically not be a valid hexadecimal value.

=head2 $value = create_bin([ length => <length> ])

Create a random binary value and return it. If <length> is specificied, then the value will be <length> bytes long.

=head2 $value = create_b64([ length => <length> ])

Create a random base64 value and return it. If <length> is specificied, then the value will be <length> bytes long.

If <length> is specified, then $value is (technically) not guaranteed to be a "legal" b64 value (since padding may be off, etc).

=cut

sub create {
    return singleton->create_hex(@_);
}

for my $name (map { "create_$_" } qw/hex bin b64/) {
    no strict 'refs';
    *$name = sub {
        return singleton->$name(@_);
    };
}

=head1 FUNCTIONS

=head2 singleton

Returns the Data::Rand::Obscure::Generator used in the above exported functions
You probably don't need to use this.

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-rand-obscure at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Rand-Obscure>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Rand::Obscure


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Rand-Obscure>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Rand-Obscure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Rand-Obscure>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Rand-Obscure>

=back


=head1 ACKNOWLEDGEMENTS

This package was inspired by (and contains code taken from) the L<Catalyst::Plugin::Session> package by Yuval Kogman

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Data::Rand::Obscure

__END__
