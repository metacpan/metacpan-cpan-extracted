use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
use DBIO::Extension::List;

# ADR 0066 section 1: the list is the declaration, resolved by the driver's
# table. Core knows no driver class.

my %table = (
  age     => [ 'TestDBIO::Extension::Age',     'DBIO-Test-Age' ],
  postgis => [ 'TestDBIO::Extension::PostGIS', 'DBIO-Test-PostGIS' ],
  ghost   => [ 'TestDBIO::Extension::NotInstalled', 'DBIO-Test-Ghost' ],
);
my $lookup = sub { my $e = $table{ $_[0] } or return; return @$e };

sub build {
  my ($declaration, %extra) = @_;
  return DBIO::Extension::List->new(
    declaration => $declaration,
    class_table => $lookup,
    plain_class => 'TestDBIO::Extension::Plain',
    %extra,
  );
}

# --- resolution ----------------------------------------------------------------
my $list = build([ 'postgis' => { schema => 'gis' }, 'age', 'citext' ]);
isa_ok $list, 'DBIO::Extension::List';

my @entries = $list->entries;
is_deeply [ map { $_->{name} } @entries ], [qw(age citext postgis)],
  'entries are sorted by name, whatever the declaration order';
is $entries[0]{class}, 'TestDBIO::Extension::Age', 'a name the driver knows resolves by its table';
is $entries[1]{class}, 'TestDBIO::Extension::Plain', 'an unknown name gets the plain class';
is_deeply $entries[2]{options}, { schema => 'gis' }, 'options are kept';
is_deeply $entries[0]{options}, {}, 'no options is an empty hash';
ok $INC{'TestDBIO/Extension/Age.pm'}, 'the class is loaded when the list is resolved';

is_deeply [ map { $_->{name} } build([qw(postgis age)])->entries ],
  [map { $_->{name} } build([qw(age postgis)])->entries ],
  'declaration order does not enter';

# class option wins over the table
my $own = build([ age => { class => 'TestDBIO::Extension::Plain' } ]);
is(($own->entries)[0]{class}, 'TestDBIO::Extension::Plain', 'class in the declaration wins over the table');

# --- the empty and the odd declaration ------------------------------------------
is_deeply [ build([])->entries ], [], 'an empty declaration is an empty list';
throws_ok { build([ 'age', 'age', { class => 'TestDBIO::Extension::Plain' } ]) }
  'DBIO::Exception', 'two classes for one name refuse';
like "$@", qr/age/, 'names the extension';
like "$@", qr/TestDBIO::Extension::Age/, 'names the first class';
like "$@", qr/TestDBIO::Extension::Plain/, 'names the second class';

is_deeply(((build([ postgis => { schema => 'gis' }, 'postgis', postgis => { version => '3' } ])->entries)[0]{options}),
  { schema => 'gis', version => '3' }, 'repeated declarations merge their options');
throws_ok { build([ postgis => { schema => 'a' }, postgis => { schema => 'b' } ]) }
  'DBIO::Exception', 'an option with two values refuses';
like "$@", qr/postgis.*schema/s, 'names extension and option';

throws_ok { build([ { schema => 'x' } ]) } 'DBIO::Exception', 'options without a name refuse';

throws_ok {
  DBIO::Extension::List->new(declaration => ['citext'], class_table => $lookup)
} 'DBIO::Exception', 'an unknown name without plain class refuses';
like "$@", qr/citext/, 'names the extension';

# --- missing distribution ---------------------------------------------------------
throws_ok { build(['ghost']) } 'DBIO::Exception', 'a class that is not installed refuses';
like "$@", qr/DBIO-Test-Ghost/, 'naming the distribution';
like "$@", qr/ghost/, 'and the extension';

throws_ok { build([ vector => { class => 'TestDBIO::Extension::AlsoMissing' } ]) }
  'DBIO::Exception', 'a missing class named by the declaration refuses';
like "$@", qr/TestDBIO::Extension::AlsoMissing/, 'naming the class where no distribution is known';

# --- interface check at resolution --------------------------------------------------
{
  package T::List::Future;
  use base 'DBIO::Extension';
  sub extension_interface { 7 }
  $INC{'T/List/Future.pm'} = 1;
}
throws_ok { build([ future => { class => 'T::List::Future' } ]) }
  'DBIO::Exception', 'an interface version outside the set refuses when the list is resolved';
like "$@", qr/T::List::Future/, 'names the class';

# --- name assertion ------------------------------------------------------------------
{
  package T::List::Named;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name { 'other' }
  $INC{'T/List/Named.pm'} = 1;
}
throws_ok { build([ mine => { class => 'T::List::Named' } ]) }
  'DBIO::Exception', 'a class stating another engine name than the declaration refuses';
like "$@", qr/mine.*other|other.*mine/s, 'naming both';

# --- driver assertion ------------------------------------------------------------------
lives_ok { $list->check_driver('TestDBIO::Extension::Deploy') } 'matching driver passes';
throws_ok { $list->check_driver('DBIO::MySQL') } 'DBIO::Exception', 'a mismatching driver refuses';
like "$@", qr/TestDBIO::Extension::Deploy/, 'naming the asserted driver';
like "$@", qr/DBIO::MySQL/, 'and the resolved one';
like "$@", qr/age|postgis/, 'and the extension';
{
  package T::List::NoDriver;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  $INC{'T/List/NoDriver.pm'} = 1;
}
lives_ok { build([ x => { class => 'T::List::NoDriver' } ])->check_driver('Whatever') }
  'a class stating no driver asserts nothing';

# --- the list never determines the driver -------------------------------------------------
{
  my @isa_before = @TestDBIO::Extension::Age::ISA;
  build(['age']);
  is_deeply \@TestDBIO::Extension::Age::ISA, \@isa_before, 'building the list changes no @ISA';
  ok !DBIO::Extension::List->can('storage_type'), 'the list has no storage_type';
}

# --- installed state ---------------------------------------------------------------------------
$list->set_installed({
  age     => { installed => 1, version => '1.5', schema => 'ag_catalog' },
  postgis => { installed => 0 },
});
my %by = map { $_->{name} => $_ } $list->entries;
is $by{age}{installed}, 1, 'installed state is attached to the entry';
is $by{age}{version}, '1.5', 'with version';
is $by{age}{schema}, 'ag_catalog', 'and schema';
is $by{postgis}{installed}, 0, 'a declared extension that is not installed says so';
ok !exists $by{citext}{installed} || !$by{citext}{installed}, 'no state for citext is not installed';
throws_ok { $list->set_installed({ nope => { installed => 1 } }) } 'DBIO::Exception',
  'state for an undeclared extension refuses (it is not in the list)';

done_testing;
