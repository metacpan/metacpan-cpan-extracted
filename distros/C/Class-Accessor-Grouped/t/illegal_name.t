use Test::More;
use Test::Exception;
use strict;
use warnings;
use lib 't/lib';

use AccessorGroupsSubclass;

{
  my $warned = 0;
  local $SIG{__WARN__} = sub {
    $_[0] =~ /unwise/ ? $warned++ : warn(@_)
  };

  for (qw/DESTROY AUTOLOAD CLONE/) {
    AccessorGroupsSubclass->mk_group_accessors(warnings => $_);
  }

  is($warned, 3, 'Correct amount of unise warnings');
}

if (eval { require Sub::Name } ) {
  my $warned = 0;
  local $SIG{__WARN__} = sub {
    $_[0] =~ /Installing illegal accessor/ ? $warned++ : warn(@_)
  };

  for (qw/666_one 666_two/) {
    no warnings qw/once/;
    no strict 'refs';

    local $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1;
    AccessorGroupsSubclass->mk_group_accessors(warnings => $_);
  }

  is($warned, 1, 'Correct amount of illegal installation warnings');
};

throws_ok { AccessorGroupsSubclass->mk_group_accessors(simple => '2wrvwrv;') }
  qr/Illegal accessor name/;

throws_ok {
  local $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1;
  AccessorGroupsSubclass->mk_group_accessors(simple => "2wr\0vwrv;")
} qr/nulls should never appear/;

done_testing;
