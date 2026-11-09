use strict;
use warnings;

use Test::More;
use File::Temp ();

use DBIO::Test;
use DBIO::Util qw(assert_class_name);
use DBIO::Replicated::Storage;
use DBIO::Replicated::Pool;

# A class name is a class name: Perl identifiers joined by '::'. Everything that
# turns a string into a loaded class (ensure_class_loaded, load_optional_class,
# result_class, cursor_class, the Replicated type attributes) holds to that, so
# a string that names a file is refused before any file is looked at.

our $LOADED = 0;

my $dir = File::Temp->newdir;
my $file = "$dir/nameplate.pm";
{
  open my $fh, '>', $file or die "$file: $!";
  print $fh "package nameplate; BEGIN { \$main::LOADED++ } 1;\n";
}

my @not_class_names = (
  [ 'absolute path'   => "$dir/nameplate" ],
  [ 'dot-dot path'    => '../../etc/passwd' ],
  [ 'embedded space'  => 'Foo Bar' ],
  [ 'leading digit'   => '1Foo::Bar' ],
  [ 'single colon'    => 'Foo:Bar' ],
  [ 'trailing colons' => 'Foo::' ],
  [ 'newline'         => "Foo::Bar\n" ],
  [ 'empty'           => '' ],
);

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

for my $case (@not_class_names) {
  my ($what, $name) = @$case;

  eval { $schema->ensure_class_loaded($name) };
  like $@, qr/is not a class name/, "ensure_class_loaded refuses $what";

  eval { $schema->load_optional_class($name) };
  like $@, qr/is not a class name/, "load_optional_class refuses $what";

  eval { assert_class_name($name) };
  like $@, qr/is not a class name/, "assert_class_name refuses $what";

  # an empty result_class means "none given", as always
  if (length $name) {
    eval { $schema->resultset('Artist')->search(undef, { result_class => $name })->all };
    like $@, qr/is not a class name/, "result_class refuses $what";
  }

  eval { $storage->cursor_class($name); $storage->cursor_class };
  like $@, qr/is not a class name/, "cursor_class refuses $what";
  $storage->cursor_class('DBIO::Storage::DBI::Cursor');
}

ok !$main::LOADED, 'no file named by a refused string was loaded';

eval { $schema->ensure_class_loaded(undef) };
like $@, qr/is not a class name/, 'undef is not a class name';

# what names a class keeps loading
is eval { assert_class_name('Foo::Bar_2') }, 'Foo::Bar_2', 'assert_class_name returns the name';
is eval { $schema->ensure_class_loaded('DBIO::Test::FakeComponent'); 1 }, 1,
  'an installed class loads' or diag $@;
ok eval { $schema->load_optional_class('DBIO::Test::OptionalComponent') },
  'load_optional_class loads an installed class';
ok !$schema->load_optional_class('Not::Installed::Anywhere'),
  'load_optional_class answers false for an absent class';

{
  package TestPlus::Comp;
  $INC{'TestPlus/Comp.pm'} = __FILE__;
  sub plus_comp_method { 'plus' }
  package TestPlus::Host;
  use base 'DBIO::Base';
}
TestPlus::Host->load_components('+TestPlus::Comp');
ok(TestPlus::Host->can('plus_comp_method'), "'+Foo::Bar' components resolve and load");

# result_class and cursor_class with a real class keep working
my @rows = $schema->resultset('Artist')->search(undef, { result_class => 'DBIO::ResultClass::HashRefInflator' })->all;
pass 'result_class accepts an installed class';
is $storage->cursor_class, 'DBIO::Storage::DBI::Cursor', 'cursor_class resolves';

# Replicated types are subclasses of what they replace
{
  my $rep = DBIO::Replicated::Storage->new($schema);

  $rep->pool_type('DBIO::Test::Schema');
  eval { $rep->create_pool };
  like $@, qr/pool_type.*DBIO::Replicated::Pool/, 'pool_type must be a DBIO::Replicated::Pool';

  $rep->balancer_type('DBIO::Test::Schema');
  eval { $rep->create_balancer };
  like $@, qr/balancer_type.*DBIO::Replicated::Balancer/, 'balancer_type must be a DBIO::Replicated::Balancer';

  $rep->backend_storage_class('DBIO::Test::Schema');
  eval { $rep->master };
  like $@, qr/backend_storage_class.*DBIO::Storage::DBI/, 'backend_storage_class must be a DBIO::Storage::DBI';

  $rep->pool_type("$dir/nameplate");
  eval { $rep->create_pool };
  like $@, qr/is not a class name/, 'pool_type refuses a path';

  my $pool = DBIO::Replicated::Pool->new(storage_class => 'DBIO::Test::Schema');
  eval { $pool->connect_replicant($schema, ['dbi:Pg:']) };
  like $@, qr/storage_class.*DBIO::Storage::DBI/, 'storage_class must be a DBIO::Storage::DBI';

  $pool = DBIO::Replicated::Pool->new(replicant_type => 'DBIO::Test::Schema', storage_class => ref $storage);
  eval { $pool->connect_replicant($schema, ['dbi:Pg:']) };
  like $@, qr/replicant_type.*DBIO::Replicated::Backend::Replicant/, 'replicant_type must be a Backend::Replicant';

  my $ok = DBIO::Replicated::Storage->new($schema);
  isa_ok eval { $ok->create_pool }, 'DBIO::Replicated::Pool', 'default pool_type';
  isa_ok eval { $ok->create_balancer(pool => DBIO::Replicated::Pool->new, master => 1) }, 'DBIO::Replicated::Balancer', 'default balancer_type'
    or diag $@;
}

ok !$main::LOADED, 'still nothing loaded from a path';

done_testing;
