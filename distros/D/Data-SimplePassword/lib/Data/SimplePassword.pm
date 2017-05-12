#

package Data::SimplePassword;

use Moo;
use MooX::ClassAttribute;

use Carp;
use UNIVERSAL::require;
use Crypt::Random ();

# ABSTRACT: Simple random password generator

our $VERSION = '0.11';

class_has 'class' => (
    is => 'rw',
    default => sub {
	Math::Random::MT->use
	    ? "Math::Random::MT"
	    : Math::Random::MT::Perl->use
		? "Math::Random::MT::Perl"
		: "Data::SimplePassword::exception";
    },
);

has 'seed_num' => (
    is => 'rw',
    default => 1,    # now internal use only, up to 624
);

has 'provider' => (
    is => 'rw',
    trigger => sub {
	my $self = shift;
	my ($provider) = @_;

	$self->is_available_provider( $provider )
	    or croak "RNG provider '$_[0]' is not available on this machine.";
    },
);

has '_default_chars' => (
    is => 'ro',
    default => sub { [ 0..9, 'a'..'z', 'A'..'Z' ] },
);

sub chars {
    my $self = shift;

    if( scalar @_ > 0 ){
	croak "each chars must be a letter or an integer."
	    if scalar grep { length( $_ ) != 1 } @_;

	$self->{_chars} = [ @_ ];
    }

    return wantarray ? @{ $self->{_chars} } : $self->{_chars};
}

sub is_available_provider {
    my $self = shift;
    my ($provider) = @_;

    if( defined $provider and $provider ne '' ){
	my $pkg = sprintf "Crypt::Random::Provider::%s", $provider;
	return eval "use $pkg; $pkg->available()";
    }

    return;
}

sub make_password {
    my $self = shift;
    my $len = shift || 8;

    croak "length must be an integer."
	unless $len =~ /^\d+$/o;

    my @chars = defined $self->chars && ref $self->chars eq 'ARRAY'
	? @{ $self->chars }
	: @{ $self->_default_chars };

    my $gen = $self->class->new(
	map { Crypt::Random::makerandom( Size => 32, Strength => 1, Provider => $self->provider ) } 1 .. $self->seed_num
    );

    my $password;
    while( $len-- ){
	$password .= $chars[ $gen->rand( scalar @chars ) ];
    }

    return $password;
}

{    package    # hide from PAUSE
	Data::SimplePassword::exception;

    use strict;
    use Carp;

    AUTOLOAD { croak "couldn't find any suitable MT classes." }
}

1;

__END__

=encoding utf-8

=head1 NAME

Data::SimplePassword - Simple random password generator

=head1 SYNOPSIS

 use Data::SimplePassword;

 my $sp = Data::SimplePassword->new;
 $sp->chars( 0..9, 'a'..'z', 'A'..'Z' );    # optional

 my $password = $sp->make_password( 8 );    # length

=head1 DESCRIPTION

YA very easy-to-use but a bit strong random password generator.

=head1 METHODS

=over 4

=item B<new>

 my $sp = Data::SimplePassword->new;

Makes a Data::SimplePassword object.

=item B<chars>

 $sp->chars( 0..9, 'a'..'z', 'A'..'Z' );    # default
 $sp->chars( 0..9, 'a'..'z', 'A'..'Z', qw(+ /) );    # b64-like
 $sp->chars( 0..9 );
 my @c = $sp->chars;    # returns the current values

Sets an array of characters you want to use as your password string.

=item B<make_password>

 my $password = $sp->make_password( 8 );    # default
 my $password = $sp->make_password( 1024 );

Makes password string and just returns it. You can set the byte length as an integer.

=back

=head1 EXTRA METHODS

=over 4

=item B<provider>

 $sp->provider("devurandom");    # optional

Sets a type of random number generator, see Crypt::Random::Provider::* for details.

=item B<is_available_provider>

 $sp->is_available_provider("devurandom");

Returns true when the type is available.

=item B<seed_num>

  $sp->seed_num( 32 );    # up to 624

Sets initial seed number (internal use only).

=back

=head1 COMMAND-LINE TOOL

A useful command named rndpassword(1) will be also installed. Type B<man rndpassword> for details.

=head1 DEPENDENCY

Moo, UNIVERSAL::require, Crypt::Random, Math::Random::MT (or Math::Random::MT::Perl),

=head1 SEE ALSO

Crypt::GeneratePassword, Crypt::RandPasswd, String::MkPasswd, Data::Random::String, String::Random, Crypt::XkcdPassword, Session::Token

http://en.wikipedia.org/wiki//dev/random

=head1 REPOSITORY

https://github.com/ryochin/p5-data-simplepassword

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
