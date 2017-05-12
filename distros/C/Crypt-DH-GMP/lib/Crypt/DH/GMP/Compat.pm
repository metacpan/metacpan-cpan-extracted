# $Id: /mirror/coderepos/lang/perl/Crypt-DH-GMP/trunk/lib/Crypt/DH/GMP/Compat.pm 50370 2008-04-15T05:54:58.881985Z daisuke  $

package Crypt::DH::GMP::Compat;

package # hide from PAUSE
    Crypt::DH;
use strict;
use warnings;
no warnings 'redefine';
use vars qw(@ISA);

# Add Crypt::DH::GMP as Crypt::DH's parent, and redefine all methods
BEGIN
{
    unshift @ISA, 'Crypt::DH::GMP';

    *Crypt::DH::new = sub { shift->SUPER::new(@_) };
    *Crypt::DH::g = sub {
        my $self = shift;
        if (@_) {
            $_[0] = ref $_[0] ? $_[0]->bstr : $_[0];
        }
        return Math::BigInt->new( $self->SUPER::g(@_) );
    };
    *Crypt::DH::p = sub { 
        my $self = shift;
        if (@_) {
            $_[0] = ref $_[0] ? $_[0]->bstr : $_[0];
        }
        return Math::BigInt->new($self->SUPER::p(@_))
    };
    *Crypt::DH::pub_key = sub { Math::BigInt->new(shift->SUPER::pub_key(@_)) };
    *Crypt::DH::priv_key = sub { Math::BigInt->new(shift->SUPER::priv_key(@_)) };
    *Crypt::DH::generate_keys = \&Crypt::DH::GMP::generate_keys;
    *Crypt::DH::compute_key = \&Crypt::DH::GMP::compute_key;
    *Crypt::DH::compute_secret = \&Crypt::DH::compute_key;
}

1;

__END__

=head1 NAME

Crypt::DH::GMP::Compat - Compatibility Mode For Crypt::DH

=head1 SYNOPSIS

  use Crypt::DH;
  use Crypt::DH::GMP qw(-compat);

=head1 DESCRIPTION

Crypt::DH::GMP::Compat is a very invasive module that rewrites Crypt::DH's
@ISA and method names so that it uses Crypt::DH::GMP

=cut
