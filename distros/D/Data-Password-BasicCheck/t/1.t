# $Id: 1.t,v 1.3 2003-09-18 20:38:12 bronto Exp $

use Test::More qw(no_plan) ;

use strict ;

BEGIN { use_ok('Data::Password::BasicCheck') };

my @userinfo = (qw(bronto Marco Marongiu),'San Gavino') ;
my $ok = Data::Password::BasicCheck->OK ;



# Test with limits 5-8 and psym = 2/3
{
  my $dpbc58 ;
  eval { $dpbc58 = Data::Password::BasicCheck->new(5,8) } ;
  is($@,'','Object created ok') ;

  my $good = 'c0m&c@z%' ;
  my @passwords = ('shrt',       # too short
		   'waytoolong', # too long
		   'pitbull',    # doesn't contain digits/symbols
		   '!@#$%^&',    # doesn't contain digits/alphas
		   '12345678',   # doesn't contain symbols/alphas
		   'pitbul1',    # doesn't contain symbols
		   'pitbull@',   # doesn't contain digits
		   '!@#$1234',   # doesn't contain alphas
		  ) ;
  is($ok,$dpbc58->check($good,@userinfo),"$good is good") ;

  foreach (@passwords) {
    my $check = $dpbc58->check($_,@userinfo) ;
    isnt($ok,$check,"$_: $check") ;
  }

}


# Now lower psym and check for repetitions
{
  my $dpbc58 ;
  eval { $dpbc58 = Data::Password::BasicCheck->new(5,8,.5) } ;
  is($@,'','Object created ok') ;

  my @passwords = (
		   '$1marco',    # matches user's name
		   'nto1bro%',   # stripped rot. password matches username
		   'oc$ra1m;',   # stripped reversed password matches name
		   "comar1\$",   # stripped rot. password matches name
		   'ma0$ron',    # stripped rot. password matches surname
		   '!gavian0',   # stripped rot. password and city match
		  ) ;

  foreach (@passwords) {
    my $check = $dpbc58->check($_,@userinfo) ;
    isnt($ok,$check,"$_: $check") ;
  }
}

# Weak at first check, good at deep checks
{
  my $dpbc58 ;
  eval { $dpbc58 = Data::Password::BasicCheck->new(5,8) } ;
  is($@,'','Object created ok') ;

  # These passwords won't pass the first check for the reason given.
  # By the way, they have a substring of $minlen length that is a
  # valid password; so, they are considere valid.
  my @passwords = (
		   'x1$$x11x',   # not enough symbols (should be at least 5)
		   't1c&t1c&',   # password matches itself after rotations
		   'sang@v1n',   # stripped rot. password matches city
		  ) ;

  foreach (@passwords) {
    my $check = $dpbc58->check($_,@userinfo) ;
    is($ok,$check,"$_: $check") ;
  }
}

