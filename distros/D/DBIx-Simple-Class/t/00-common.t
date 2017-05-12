#!perl

use Test::More tests => 12;

BEGIN {
  use_ok('DBIx::Simple::Class') || print "Bail out!\n";
  use File::Basename 'dirname';
  use Cwd;
  use lib (Cwd::abs_path(dirname(__FILE__) . '/..') . '/examples/lib');
}
use My;
use My::User;

note(
  "Testing DBIx::Simple::Class database agnostic functionality$DBIx::Simple::Class::VERSION, Perl $], $^X"
);
local $Params::Check::VERBOSE = 0;

#Suppress some warnings from DBIx::Simple::Class during tests.
local $SIG{__WARN__} = sub {
  warn $_[0] if $_[0] !~ /(generated accessors|is not such field)/;
};


my $DSC = 'DBIx::Simple::Class';
is($DSC->DEBUG,    0);
is($DSC->DEBUG(1), 1);
is($DSC->DEBUG(0), 0);

#DSC abstract properties and methods
like((eval { $DSC->TABLE },   $@), qr/table-name for your class/);
like((eval { $DSC->COLUMNS }, $@), qr/fields for your class/);
like((eval { $DSC->CHECKS },  $@), qr/define your CHECKS subroutine/);
is(ref($DSC->WHERE), 'HASH');

#My::User
is(My::User->TABLE, 'users');
is_deeply(My::User->COLUMNS, [qw(id group_id login_name login_password disabled)]);
is(ref(My::User->WHERE), 'HASH');
is_deeply(My::User->WHERE, {disabled => 1});
