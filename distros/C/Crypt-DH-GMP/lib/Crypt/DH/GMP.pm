package Crypt::DH::GMP;
use 5.0080001;
use strict;
use warnings;
use vars qw($VERSION @ISA);
$VERSION = '0.00012';

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap($VERSION);
};

sub import
{
    my $class = shift;
    if (grep { $_ eq '-compat' } @_) {
        require Crypt::DH::GMP::Compat;
    }
}

sub new
{
    my $class = shift;
    my %args  = @_;
    $class->_xs_create($args{p} || "0", $args{g} || "0", $args{priv_key} || '');
}

*compute_secret = \&compute_key;

1;

__END__

=head1 NAME

Crypt::DH::GMP - Crypt::DH Using GMP Directly

=head1 SYNOPSIS

  use Crypt::DH::GMP;

  my $dh = Crypt::DH::GMP->new(p => $p, g => $g);
  my $val = $dh->compute_secret();

  # If you want compatibility with Crypt::DH (it uses Math::BigInt)
  # then use this flag
  # You /think/ you're using Crypt::DH, but...
  use Crypt::DH::GMP qw(-compat);

  my $dh = Crypt::DH->new(p => $p, g => $g);
  my $val = $dh->compute_secret(); 

=head1 DESCRIPTION

Crypt::DH::GMP is a (somewhat) portable replacement to Crypt::DH, implemented
mostly in C.

=head1 RATIONALE

In the beginning, there was C<Crypt::DH>. However, C<Crypt::DH> suffers
from a couple of problems:

=over 4

=item GMP/Pari libraries are almost always required

C<Crypt::DH> works with a plain C<Math::BigInt>, but if you want to use
it in production, you almost always need to install C<Math::BigInt::GMP>
or C<Math::BigInt::Pari> because without them, the computation that is
required by C<Crypt::DH> makes the module pretty much unusable.

Because of this, C<Crypt::DH> might as well make C<Math::BigInt::GMP> a
hard requirement.

=item Crypt::DH suffers from having Math::BigInt in between GMP

With or without C<Math::BigInt::GMP> or C<Math::BigInt::Pari>, C<Crypt::DH>
makes several round trip conversions between Perl scalars, Math::BigInt objects,
and finally its C representation (if GMP/Pari are installed).

Instantiating an object comes with a relatively high cost, and if you make
many computations in one go, your program will suffer dramatically because
of this. 

=back

These problems quickly become apparent when you use modules such as 
C<Net::OpenID::Consumer>, which requires to make a few calls to C<Crypt::DH>.

C<Crypt::DH::GMP> attempts to alleviate these problems by providing a 
C<Crypt::DH>-compatible layer, which, instead of doing calculations via
Math::BigInt, directly works with libgmp in C.

This means that we've essentially eliminated 2 call stacks worth of 
expensive Perl method calls and we also only load 1 (Crypt::DH::GMP) module
instead of 3 (Crypt::DH + Math::BigInt + Math::BigInt::GMP).

These add up to a fairly significant increase in performance.

=head1 COMPATIBILITY WITH Crypt::DH

Crypt::DH::GMP absolutely refuses to consider using anything other than
strings as its parameters and/or return values therefore if you would like
to use Math::BigInt objects as your return values, you can not use 
Crypt::DH::GMP directly. Instead, you need to be explicit about it:

  use Crypt::DH;
  use Crypt::DH::GMP qw(-compat); # must be loaded AFTER Crypt::DH

Specifying -compat invokes a very nasty hack that overwrites Crypt::DH's
symbol table -- this then forces Crypt::DH users to use Crypt::DH::GMP
instead, even if you are writing

  my $dh = Crypt::DH->new(...);
  $dh->compute_key();

=head1 BENCHMARK

By NO MEANS is this an exhaustive benchmark, but here's what I get on my
MacBook (OS X 10.5.8, 2.4 GHz Core 2 Duo, 4GB RAM)

  Benchmarking instatiation cost...
         Rate   pp  gmp
  pp   9488/s   -- -79%
  gmp 45455/s 379%   --

  Benchmarking key generation cost...
        Rate gmp  pp
  gmp 6.46/s  -- -0%
  pp  6.46/s  0%  --

  Benchmarking compute_key cost...
          Rate    pp   gmp
  pp   12925/s    --  -96%
  gmp 365854/s 2730%    --

=head1 METHODS

=head2 new

=head2 p

=head2 g

=head2 compute_key

=head2 compute_secret

=head2 generate_keys

=head2 pub_key

=head2 priv_key

=head2 compute_key_twoc

Computes the key, and returns a string that is byte-padded two's compliment
in binary form.

=head2 pub_key_twoc

Returns the pub_key as a string that is byte-padded two's compliment
in binary form.

=head2 clone

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >> 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
