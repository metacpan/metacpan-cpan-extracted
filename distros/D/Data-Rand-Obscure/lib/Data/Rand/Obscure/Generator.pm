package Data::Rand::Obscure::Generator;

use warnings;
use strict;

=head1 SYNOPSIS

    use Data::Rand::Obscure::Generator;

    my $generator = Data::Rand::Obscure::Generator->new;

    # Some random hexadecimal string value.
    $value = $generator->create;

    ...

    # Random base64 value:
    $value = $generator->create_b64;

    # Random binary value:
    $value = $generator->create_bin;

    # Random hexadecimal value:
    $value = $generator->create_hex;

    ...

    # A random value containing only hexadecimal characters and 103 characters in length:
    $value = $generator->create_hex(length => 103);

=head1 DESCRIPTION

An objectified version of L<Data::Rand::Obscure> functionality

This is the actual workhorse of the distribution, L<Data::Rand::Obscure> contains function wrappers around a singleton object.

=cut

use Digest;
use Carp::Clan;
use Object::Tiny qw/seeder digester/;
use vars qw/$_default_seeder $_default_digester/;

=head1 METHODS

=head2 $generator = Data::Rand::Obscure::Generator->new([ seeder => <seeder>, digester => <digester> ])

Returns a Data::Rand::Obscure::Generator with the following methods:

    create
    create_hex
    create_bin
    create_b64

You may optionally supply a seeder subroutine, which is called everytime a new value is to be generated.
It should return some seed value that will be digested.

You may also optionally supply a digester subroutine, which is also called everytime a new value is to be generated.
It should return a L<Digest> object of some kind (which will be used to take the digest of the seed value).

=head2 $generator->seeder

Returns the seeding code reference for $generator

=head2 $generator->digester

Returns the L<Digest>-generating code reference for $generator

=cut

sub new {
    my $self = bless {}, shift;
    local %_ = @_;

    croak "You supplied a seeder but it's undefined" if exists $_{seeder} && ! $_{seeder};
    croak "You supplied a digester but it's undefined" if exists $_{digester} && ! $_{digester};
    
    my $seeder = $self->{seeder} = $_{seeder} || $_default_seeder;
    my $digester = $self->{digester} = $_{digester} || $_default_digester;

    croak "The given seeder ($seeder) is not a code reference" unless ref $seeder eq "CODE";
    croak "The given digester ($digester) is not a code reference" unless ref $digester eq "CODE";

    return $self;
}

sub _create {
    my $self = shift;

    my $digest = $self->digester->();
    my $seed = $self->seeder->();
    $digest->add($seed);
    return $digest;
}

sub _create_to_length {
    my $self = shift;
    my $method = shift;
    my $length = shift;
    $length > 0 or croak "You need to specify a length greater than 0";

    my $result = "";
    while (length($result) < $length) {
        $result .= $self->$method;
    }

    return substr $result, 0, $length;
}

sub _create_bin {
    my $self = shift;
    return $self->_create->digest;
}

sub _create_hex {
    my $self = shift;
    return $self->_create->hexdigest;
}

sub _create_b64 {
    my $self = shift;
    return $self->_create->b64digest;
}

=head1 METHODS 

=head2 $value = $generator->create([ length => <length> ])

=head2 $value = $generator->create_hex([ length => <length> ])

Create a random hexadecimal value and return it. If <length> is specificied, then the string will be <length> characters long.

If <length> is specified and not a multiple of 2, then $value will technically not be a valid hexadecimal value.

=head2 $value = $generator->create_bin([ length => <length> ])

Create a random binary value and return it. If <length> is specificied, then the value will be <length> bytes long.

=head2 $value = $generator->create_b64([ length => <length> ])

Create a random base64 value and return it. If <length> is specificied, then the value will be <length> bytes long.

If <length> is specified, then $value is (technically) not guaranteed to be a "legal" b64 value (since padding may be off, etc).

=cut

sub create {
    my $self = shift;
    return $self->create_hex(@_);
}

for my $name (map { "create_$_" } qw/hex bin b64/) {
    no strict 'refs';
    my $method = "_$name";
    *$name = sub {
        my $self = shift;
        return $self->$method unless @_;
        local %_ = @_;
        return $self->_create_to_length($method, $_{length}) if exists $_{length};
        croak "Don't know what you want to do: length wasn't specified, but \@_ was non-empty.";
    };
}

# HoD not required. :)
my $default_seeder_counter = 0;
$_default_seeder = sub {
    return join("", ++$default_seeder_counter, time, rand, $$, overload::StrVal({}));
};

my $digest_algorithm;
sub _find_digester() {
    unless ($digest_algorithm) {
        foreach my $algorithm (qw/SHA-1 SHA-256 MD5/) {
            if ( eval { Digest->new($algorithm) } ) {
                $digest_algorithm = $algorithm;
                last;
            }
        }
        die "Could not find a suitable Digest module. Please install "
              . "Digest::SHA1, Digest::SHA, or Digest::MD5"
            unless $digest_algorithm;
    }

    return Digest->new($digest_algorithm);
}

$_default_digester = sub {
    return _find_digester();
};

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
