package Data::Password::BasicCheck;

use 5.006;
use strict;
use warnings;

our $VERSION = '2.03';

# Object parameters
use constant MIN => 0 ;
use constant MAX => 1 ;
use constant SYM => 2 ;

# Return values
use constant OK    => 0 ; # password ok
use constant SHORT => 1 ; # password is too short
use constant LONG  => 2 ; # password is too long
use constant A1SYM => 3 ; # password must contain alphas, digits and symbols
use constant NOSYM => 4 ; # not enough different symbols in password
use constant ROT   => 5 ; # password matches itself after some rotation
use constant PINFO => 6 ; # password matches personal information
use constant WEAK  => 127 ; # password too weak (generic)


# Other constants
use constant DEBUG => 0 ;

sub new {
  my $class = shift ;

  die "Not an object method" if ref $class ;
  my ($minlen,$maxlen,$psym) = @_ ;

  # Avoid bothering about uninitialized values...
  no warnings ;
  return undef unless $minlen =~ /^\d+$/ and $minlen >= 0 ;
  return undef unless $maxlen =~ /^\d+$/ and $maxlen >= $minlen ;
  $psym = 2/3  unless $psym > 0 ;

  return bless [$minlen,$maxlen,$psym],$class ;
}

sub minlen { return $_[0]->[MIN] }
sub maxlen { return $_[0]->[MAX] }
sub psym   { return $_[0]->[SYM] }
sub _parms { return @{$_[0]}     }

sub check {
  my $self = shift ;
  my ($password,@userinfo) = @_ ;

  die "Not a class method!"
    unless ref $self and eval { $self->isa('Data::Password::BasicCheck') } ;

  my ($minlen,$maxlen,$psym) = $self->_parms ;
  my $plen                   = length $password ;
  # Check length
  {
    return SHORT if $plen < $minlen ;
    return LONG  if $plen > $maxlen ;
  }

  my $result = $self->_docheck(@_) ;
  return $result if $result eq OK ;

  # Try shorter segments...
  my $segments = $plen - $minlen ;
  return $result unless $segments > 1 ;
  foreach (my $i = 0 ; $i <= $segments; $i++) {
    my $segment = substr $password,$i,$minlen ;
    print STDERR "DEBUG: Trying $segment\n" if DEBUG ;
    $result = $self->_docheck($segment,@userinfo) ;
    return $result if $result eq OK ;
  }
  return WEAK ;
}

sub _docheck {
  my ($self,$password,@userinfo) = @_ ;

  my ($minlen,$maxlen,$psym) = $self->_parms ;
  my $plen                   = length $password ;
  # Password contains alphas, digits and non-alpha-digits
  {
    local $_ = $password ;
    return A1SYM
      unless /[a-z]/i and /\d/ and /[^a-z0-9]/i ;
  }

  # Check unique characters
  {
    my @chars = split //,$password ;
    my %unique ;
    foreach my $char (@chars) {
      $unique{$char}++;
    }
    ;
    return NOSYM
      unless scalar keys %unique >= sprintf "%.0f",$psym * $plen ;
  }

  # rotations of the password don't match it
  {
    foreach my $rot (_rotations($password)) {
      return ROT
	if $rot eq $password ;
    }
  }

  # Check password against user data.Some of user data could be
  # composed, like "Alan Louis", or "Di Cioccio" or
  # "Los Angeles", so we have to treat each chunk separately.  But we
  # should also check for passwords like "alanlouis", or "dicioccio"
  # or "losangeles". So we must add them, too.
  {
    # Prepare password rotations; check reverse password and reverse
    # password rotations, too
    my $pclean                    = lc $password ;
    $pclean =~ s/[^a-z]//g ;
    my $rpclean = reverse $pclean ;
    my @prots = ($pclean, _rotations($pclean),
		 $rpclean,_rotations($rpclean)) ;

    # Prepare personal information to match @prots against
    @userinfo = map lc,@userinfo  ;
    my @chunks = split(/\s+/,join(" ",@userinfo)) ;
    foreach (@userinfo) {
      if (/\s/) {
	s/\s// ;
	push @chunks,$_ ;
      }
    }

    my $idx ;
    foreach my $chunk (@chunks) {
      my $chunklen = length $chunk ;
      foreach my $rot (@prots) {
	my $cutrot = substr $rot,0,$minlen ;
	$idx = $chunklen >= $minlen?
	  index $chunk,$cutrot:
	  index $cutrot,$chunk;
	unless ($idx == -1) {
	  return PINFO ;
	}
      }
    }
  }

  return OK ;
}


sub _rotations {
  my $string = shift ;
  my $n      = length $string ;
  my @result ;

  # note: $i < $n, since the n-th permutation is the password again 
  for (my $i = 1 ; $i < $n ; $i++) {
    $string = chop($string).$string ;
    push @result,$string ;
  }
  return @result ;
}

1;
__END__

=head1 NAME

Data::Password::BasicCheck - Basic password checking

=head1 SYNOPSIS

  use Data::Password::BasicCheck;

  # Create a password checker object. We require that passwords
  # are at least 6 characters long, and no more than 8. We also
  # require that there are at least L/2 different symbols in the
  # password, where L is the password length. So, for a 6 caracter
  # long password, we require at least 3 different symbols, for
  # 8 characters long password we require at least 4 different
  # symbols, for 7 characters long password we again require
  # 4 symbols, since 7 *.5 = 3.5, which rounds to 4.

  my $pwcheck = Data::Password::BasicCheck->new(6, # minimal length
                                                8, # maximum length
                                                .5) ; # symbol factor

  my $ok = $pwcheck->OK ;
  my $check = $pwcheck->check('My!Pass1','bronto',
                              'Marco', 'Marongiu',
                              'Los Angeles','1971 03 17') ;

  unless ($check eq $ok) { die "Please choose a better password" }
  print "Greetings! Your password was good :-)\n\n" ;

=head1 ABSTRACT

This class is used to build basic password checkers. They don't match
password against dictionaries, nor they do complex elaborations. They
just check that minimal security conditions are verified.

If you need a more accurate check, e.g. against a dictionary, you
should consider using a different module, like Data::Password.

=head1 DESCRIPTION

Data::Password::BasicCheck objects will do the following checks on the
given passwords:

=over 4

=item *

password length is in a defined range that is estabilished at object
creation; 

=item *

there are at least pL symbols in password, where L is password length
and p is 0 < p =< 1. If not specified at object creation we assume
p =  2/3 (that is: 0.66666...)

=item *

password contains alphabetic characters, digits and non-alphanumeric
characters; 

=item *

rotations of the password don't match it (e.g.: the password a1&a1&
matches itself after three rotations)

=item *

after cleaning away digits and symbols, the password, its reverse and
all possible rotations don't match any personal information given
(name, surname, city, username)

=back


=head1 METHODS

=head2 new

creates a password checker object. Takes two mandatory arguments and
an optional third argument. The are: minimal and maximal password
length and a symbol factor, which defaults to 2/3 (0.6666....). A
symbol factor is a number p such that 0 < p <= 1. Given p, a password
of length L must contain at least round(p*L) characters. For example,
a 6-character long password must contain at least 4 different symbols
by default.

=head2 minlen

returns the minimal password length as defined upon object creation.

=head2 maxlen

returns the maximal password length as defined upon object creation.

=head2 psym

returns the symbol factor as defined upon object creation, or the
default one otherwise.

=head2 check

Takes a password to check as first argument, and an arbitrary length
list of personal data (e.g.: user's ID, name, surname, city,
birthdate...) It first checks that the password in itself is good; if
it isn't, checks to see if there exists at least a segment of minimal
length that could be considered secure. It returns an
integer value, starting from 0, whose meaning is:

=over 4

=item '0'

password ok

=item 1

password too short

=item 2

password too long

=item 3

password must contain alphabetic characters, digits and
non-alphanumeric symbols; 

=item 4

not enough different symbols in password

=item 5

password matches itself after some rotations

=item 6

password matches personal information

=item 127

password too weak: security checks have failed on the
password and on all minimal length segments of it

=back

=head1 WHY WE FALL BACK TO MINIMAL LENGTH SUBPASSWORDS

If you establish that passwords should have a minimal length of 5
characters and a maximal length of 20, you should consider that your
system's security depends on password having at least a 5 character
long segment that can be considered secure. Since it was hard for me
to understand it at first, I'll explain this by example to make it
clear. 

So, let's suppose that we want passwords from 5 to 15 characters long,
with a psym factor of 2/3. The password C<1pas;> could be considered
secure (it has numbers, symbols and alphabetic characters, and each
character is unique). What about the password C<1pas;aaaaaaaaaa>? 
Well, it won't pass the test for repeated characters (it has 11 a's
for an overall length of 15); but you surely noticed that it is
exactly the previous password padded with a's to the maximum
length. Since the first password was considered secure, we can't
consider the second less secure than it, the same way we don't make
our car less secure if, besides the normal locks, we add a steering
wheel locker (in fact, it should be more secure).

Therefore, if the full length password can be considered secure,
that's good. If it's not, but a minimal length segment is, that
segment is good, and the rest of the password is added noise, which
makes it more secure and not easier to guess.

=head1 TO DO

=over 4

=item *

Implement more advanced techniques with Quantum::Superpositions, as
suggested by larsen <http://perlmonks.org/index.pl?node=larsen>

=back

=head1 SEE ALSO

The book I<Essential System Administration>, by Aeleen Frisch, printed
by O'Reilly and Associates;

The PerlMonks web site, L<http://www.perlmonks.org/>, where the ideas
behind this module have been largely discussed.

Many people among the Italian Perl Mongers, which you can find on IRC
on the channel #nordest.pm on slashnet

=head1 AUTHOR

Marco Marongiu, E<lt>bronto@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Marco Marongiu

This program is free software; you can redistribute it
and/or modify it under the terms of the GNU General
Public License as published by the Free Software
Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General
Public License along with this program; if not, write
to the Free Software Foundation, Inc., 59 Temple Place
- Suite 330, Boston, MA 02111-1307, USA.


=cut
