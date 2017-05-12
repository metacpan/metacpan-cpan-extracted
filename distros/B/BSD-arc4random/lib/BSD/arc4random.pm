# $MirOS: contrib/hosted/tg/code/BSD::arc4random/lib/BSD/arc4random.pm,v 1.10 2011/06/05 23:19:04 tg Exp $
#-
# Copyright (c) 2008, 2009, 2010, 2011
#	Thorsten Glaser <tg@mirbsd.org>
# Copyright (c) 2009
#	Benny Siegert <bsiegert@mirbsd.org>
#
# Provided that these terms and disclaimer and all copyright notices
# are retained or reproduced in an accompanying document, permission
# is granted to deal in this work without restriction, including un-
# limited rights to use, publicly perform, distribute, sell, modify,
# merge, give away, or sublicence.
#
# This work is provided "AS IS" and WITHOUT WARRANTY of any kind, to
# the utmost extent permitted by applicable law, neither express nor
# implied; without malicious intent or gross negligence. In no event
# may a licensor, author or contributor be held liable for indirect,
# direct, other damage, loss, or other issues arising in any way out
# of dealing in the work, even if advised of the possibility of such
# damage or existence of a defect, except proven that it results out
# of said person's immediate fault when using the work as intended.

package BSD::arc4random;

use strict;
use warnings;

BEGIN {
	require Exporter;
	require DynaLoader;
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION = "1.50";
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw();
	@EXPORT_OK = qw(
		$RANDOM
		&arc4random
		&arc4random_addrandom
		&arc4random_bytes
		&arc4random_pushb
		&arc4random_pushk
		&arc4random_stir
		&arc4random_uniform
	);
	%EXPORT_TAGS = (
		all => [ @EXPORT_OK ],
	);
}

use vars qw($RANDOM);		# public tied integer variable
sub have_kintf() {}		# public constant function, prototyped

my $have_threadlock = 1;
my $arcfour_lock;
eval { require threads::shared; };
if ($@) {
	$have_threadlock = 0;	# module not available
} else {
	# private thread lock
	threads::shared::share($arcfour_lock);
};

bootstrap BSD::arc4random $BSD::arc4random::VERSION;

# public thread-safe functions
sub
arc4random()
{
	lock($arcfour_lock) if $have_threadlock;
	return &arc4random_xs();
}

sub
arc4random_addrandom($)
{
	my $buf = shift;

	lock($arcfour_lock) if $have_threadlock;
	return &arc4random_addrandom_xs($buf);
}

sub
arc4random_pushb($)
{
	my $buf = shift;

	lock($arcfour_lock) if $have_threadlock;
	return &arc4random_pushb_xs($buf);
}

sub
arc4random_pushk($)
{
	my $buf = shift;

	lock($arcfour_lock) if $have_threadlock;
	return &arc4random_pushk_xs($buf);
}

sub
arc4random_stir()
{
	lock($arcfour_lock) if $have_threadlock;
	&arc4random_stir_xs();
	return;
}

sub
arc4random_bytes($;$)
{
	my ($len, $buf) = @_;
	my $val;
	my $vleft = 0;
	my $rv = '';
	my $idx = 0;

	if (defined($buf)) {
		$val = arc4random_pushb($buf);
		$vleft = 4;
	}
	while (($len - $idx) >= 4) {
		if ($vleft < 4) {
			$val = arc4random();
			$vleft = 4;
		}
		vec($rv, $idx / 4, 32) = $val;
		$idx += 4;
		$vleft = 0;
	}
	while ($idx < $len) {
		if ($vleft == 0) {
			$val = arc4random();
			$vleft = 4;
		}
		vec($rv, $idx, 8) = $val & 0xFF;
		$idx++;
		$val >>= 8;
		$vleft--;
	}
	return $rv;
}

# Perl implementation of arc4random_uniform(3)
# C implementation contributed by djm@openbsd.org, Jinmei_Tatuya@isc.org
#
# Calculate a uniformly distributed random number less than upper_bound
# avoiding "modulo bias".
#
# Uniformity is achieved by generating new random numbers until the one
# returned is outside the range [0, 2**32 % upper_bound).  This
# guarantees the selected random number will be inside
# [2**32 % upper_bound, 2**32) which maps back to [0, upper_bound)
# after reduction modulo upper_bound.

sub
arc4random_uniform($)
{
	my $upper_bound = shift;
	my $r;
	my $min;

	return 0 unless defined($upper_bound);
	# convert upper_bound to 32-bit UV (unsigned integer value)
	$upper_bound &= 0xFFFFFFFF;
	return 0 if $upper_bound < 2 || $upper_bound > 0xFFFFFFFF;

	# Calculate (2**32 % upper_bound) avoiding 64-bit math
	if ($upper_bound > 0x80000000) {
		# 2**32 - upper_bound (only one "value area")
		$min = 1 + (~$upper_bound & 0xFFFFFFFF);
	} else {
		# (2**32 - x) % x == 2**32 % x when x <= 2**31
		$min = (0xFFFFFFFF - $upper_bound + 1) % $upper_bound;
	}

	# This could theoretically loop forever but each retry has
	# p > 0.5 (worst case, usually far better) of selecting a
	# number inside the range we need, so it should rarely need
	# to re-roll.
	while (1) {
		$r = arc4random();
		last if $r >= $min;
	}

	return ($r % $upper_bound);
}

# private implementation for a tied $RANDOM variable
sub
TIESCALAR
{
	my $class = shift;
	my $max = shift;

	if (!defined($max) || ($max = int($max)) > 0xFFFFFFFE || $max < 0) {
		$max = 0;
	}

	return bless \$max, $class;
}

sub
FETCH
{
	my $self = shift;

	return ($$self == 0 ? arc4random() : arc4random_uniform($$self + 1));
}

sub
STORE
{
	my $self = shift;
	my $value = shift;

	arc4random_pushb($value);
}

# tie the public $RANDOM variable to an mksh-style implementation
tie $RANDOM, 'BSD::arc4random', 0x7FFF;

# we are nice and re-seed perl's internal PRNG as well
srand(arc4random_pushb(pack("F*", rand(), rand(), rand(), rand())));

1;
__END__

=head1 NAME

BSD::arc4random - Perl interface to the arc4 random number generator

=head1 SYNOPSIS

  use BSD::arc4random qw(:all);
  $v = arc4random();
  $v = arc4random_uniform($hz);
  if (!BSD::arc4random::have_kintf()) {
    $v = arc4random_addrandom("entropy to pass to the system");
  } else {
    $v = arc4random_pushb("entropy to pass to the system");
    $v = arc4random_pushk("entropy to pass to the kernel");
  }
  $s = arc4random_bytes(16, "entropy to pass to libc");
  arc4random_stir();
  $s = arc4random_bytes(16);
  print $RANDOM;

=head1 DESCRIPTION

This set of functions maps the L<arc4random(3)> family of libc functions
into Perl code.
All functions listed below are ithreads-safe.
The internal XS functions are not, but you are not supposed
to call them, either.

On module load, perl's internal PRNG is re-seeded, as a bonus, using
B<srand> with an argument calculated from using B<arc4random_pushb>
on some entropy returned from B<rand>'s previous state.

=head2 LOW-LEVEL FUNCTIONS

=over 4

=item B<arc4random>()

This function returns an unsigned 32-bit integer random value.

=item B<arc4random_addrandom>(I<pbuf>)

This function adds the entropy from I<pbuf> into the libc pool and
returns an unsigned 32-bit integer random value from it.

=item B<arc4random_pushb>(I<pbuf>)

This function first pushes the I<pbuf> argument to the kernel if possible,
then the entropy returned by the kernel into the libc pool, then
returns an unsigned 32-bit integer random value from it.

=item B<arc4random_pushk>(I<pbuf>)

This function first pushes the I<pbuf> argument to the kernel if possible,
then returns an unsigned 32-bit integer random value from the kernel.

This function is deprecated. Use B<arc4random_pushb> instead.

=item B<arc4random_stir>()

This procedure attempts to retrieve new entropy from the kernel and add
it to the libc pool.
Usually, this means you must have access to the L<urandom(4)> device;
create it inside L<chroot(2)> jails first if you use them.

=item B<have_kintf>()

This constant function returns 1 if B<arc4random_pushb> and/or
B<arc4random_pushk> actually call the kernel interfaces, 0 if
they merely map to B<arc4random_addrandom> instead.

=back

=head2 HIGH-LEVEL FUNCTIONS

=over 4

=item B<arc4random_bytes>(I<num>[, I<pbuf>])

This function returns a string containing as many random bytes as
requested by the integral argument I<num>.
An optional I<pbuf> argument is passed to the system first.

=item B<arc4random_uniform>(I<upper_bound>)

Calculate a uniformly distributed random number less than upper_bound
avoiding "modulo bias".

=back

=head2 PACKAGE VARIABLES

=over 4

=item B<$RANDOM>

The B<$RANDOM> returns a random value in the range S<[0; 32767]> on
each read attempt and pushes any value it is assigned to the kernel.
It is tied at module load time.

=item tie I<variable>, 'BSD::arc4random'[, I<max>]

You can tie any scalar variable to this package; the I<max> argument
is the maximum number returned; if undefined, 0 or S<E<62>= 0xFFFFFFFF>,
no bound is used, and values in the range S<[0; 2**32-1]> are returned.
They will behave like B<$RANDOM>.

=back

=head1 AUTHOR

Thorsten Glaser E<lt>tg@mirbsd.deE<gt>

=head1 SEE ALSO

The L<arc4random(3)> manual page, available online at:
L<https://www.mirbsd.org/man/arc4random.3>

Perl's L<rand> and L<srand> functions via L<perlfunc> and L<perlfaq4>.

The B<randex.pl> plugin for Irssi, implementing the MirOS RANDEX
protocol (entropy exchange over IRC), with CVSweb at:
L<http://cvs.mirbsd.de/ports/net/irssi/files/randex.pl>

L<https://www.mirbsd.org/a4rp5bsd.htm> when it's done being written.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, 2009, 2010, 2011 Thorsten "mirabilos" Glaser
Copyright (c) 2009 Benny Siegert
Credits to Sebastian "Vutral" Schwarz

This module is covered by the MirOS Licence:
L<http://mirbsd.de/MirOS-Licence>

The original C implementation of arc4random_uniform was contributed by
Damien Miller from OpenBSD, with simplifications by Jinmei Tatuya.

=cut
