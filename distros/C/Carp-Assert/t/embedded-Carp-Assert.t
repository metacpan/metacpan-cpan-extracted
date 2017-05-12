#!/usr/local/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
	my($class, $var) = @_;
	return bless { var => $var }, $class;
}

sub PRINT  {
	my($self) = shift;
	${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'lib/Carp/Assert.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 115 lib/Carp/Assert.pm

BEGIN {
    local %ENV = %ENV;
    delete @ENV{qw(PERL_NDEBUG NDEBUG)};
    require Carp::Assert;
    Carp::Assert->import;
}

local %ENV = %ENV;
delete @ENV{qw(PERL_NDEBUG NDEBUG)};


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 218 lib/Carp/Assert.pm
my $life = 'Whimper!';
ok( eval { assert( $life =~ /!$/ ); 1 },   'life ends with a bang' );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 238 lib/Carp/Assert.pm
{
  package Some::Other;
  no Carp::Assert;
  ::ok( eval { assert(0) if DEBUG; 1 } );
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 249 lib/Carp/Assert.pm
ok( eval { assert(1); 1 } );
ok( !eval { assert(0); 1 } );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 259 lib/Carp/Assert.pm
eval { assert(0) };
like( $@, '/^Assertion failed!/',       'error format' );
like( $@, '/Carp::Assert::assert\(0\) called at/',      '  with stack trace' );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 274 lib/Carp/Assert.pm
eval { assert( Dogs->isa('People'), 'Dogs are people, too!' ); };
like( $@, '/^Assertion \(Dogs are people, too!\) failed!/', 'names' );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 311 lib/Carp/Assert.pm
my $foo = 1;  my $bar = 2;
eval { affirm { $foo == $bar } };
like( $@, '/\$foo == \$bar/' );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 150 lib/Carp/Assert.pm

    # Take the square root of a number.
    sub my_sqrt {
        my($num) = shift;

        # the square root of a negative number is imaginary.
        assert($num >= 0);

        return sqrt $num;
    }




;

  }
};
is($@, '', "example from line 150");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 150 lib/Carp/Assert.pm

    # Take the square root of a number.
    sub my_sqrt {
        my($num) = shift;

        # the square root of a negative number is imaginary.
        assert($num >= 0);

        return sqrt $num;
    }




is( my_sqrt(4),  2,            'my_sqrt example with good input' );
ok( !eval{ my_sqrt(-1); 1 },   '  and pukes on bad' );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 301 lib/Carp/Assert.pm

    affirm {
        my $customer = Customer->new($customerid);
        my @cards = $customer->credit_cards;
        grep { $_->is_active } @cards;
    } "Our customer has an active credit card";

;

  }
};
is($@, '', "example from line 301");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

