use strict;
use warnings;
use Test::More;
use Test::Exception;

# ADR 0066 section 2.1 / 5.3: DBIO::Extension is the base class with
# do-nothing defaults; the interface version is checked, loudly.

use DBIO::Extension;

{
  package T::Ext::Good;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'good' }
  sub driver { 'T::Driver' }

  package T::Ext::Components;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name { 'components' }
  sub components { 'T::Ext::Result::Geometry' }

  package T::Ext::Future;
  use base 'DBIO::Extension';
  sub extension_interface { 9 }
  sub name { 'future' }

  package T::Ext::Old;
  use base 'DBIO::Extension';
  sub extension_interface { 0 }
  sub name { 'old' }

  package T::Ext::Silent;
  use base 'DBIO::Extension';
  sub name { 'silent' }

  package T::NotAnExtension;
  sub extension_interface { 1 }
}

# --- defaults do nothing -----------------------------------------------------
my $ctx = { peers => {}, self => {} };
is_deeply(T::Ext::Good->claims({}, $ctx), [], 'claims default: no addresses');
is_deeply(T::Ext::Good->annotate({}, $ctx), [], 'annotate default: no triples');
is(T::Ext::Good->verdict({ kind => 'column_type' }, $ctx), undef, 'verdict default: not mine');
is(T::Ext::Good->inspect($ctx), undef, 'inspect default: no state');
is(T::Ext::Good->activation($ctx), undef, 'activation default: nothing');
is(T::Ext::Good->storage_layer, undef, 'storage_layer default: none');
is_deeply [ T::Ext::Good->components ], [], 'components default: the empty list';
is_deeply [ T::Ext::Components->components ], [ 'T::Ext::Result::Geometry' ],
  'an extension names its result components';
is(DBIO::Extension->name, undef, 'name default: undef (the class states it)');
is(DBIO::Extension->driver, undef, 'driver default: undef (no assertion)');
is(DBIO::Extension->extension_interface, undef, 'extension_interface default: not stated');

# --- the supported set -------------------------------------------------------
is_deeply [ DBIO::Extension->interface_versions ], [1],
  'until the first release core accepts exactly the current interface version';
is(DBIO::Extension->interface_current, 1, 'current interface version is 1');

# --- check_interface ---------------------------------------------------------
ok(DBIO::Extension->check_interface('T::Ext::Good'), 'matching version passes');

throws_ok { DBIO::Extension->check_interface('T::Ext::Future') } 'DBIO::Exception',
  'a version newer than core refuses with a DBIO::Exception';
like "$@", qr/T::Ext::Future/, 'names the extension';
like "$@", qr/\b9\b/, 'names its version';
like "$@", qr/supports interface version\(s\) 1\b/, "names core's set";
like "$@", qr/upgrade DBIO core/i, 'says core is the side to upgrade';

throws_ok { DBIO::Extension->check_interface('T::Ext::Old') } 'DBIO::Exception',
  'a version older than the set refuses';
like "$@", qr/upgrade the extension/i, 'says the extension is the side to upgrade';

throws_ok { DBIO::Extension->check_interface('T::Ext::Silent') } 'DBIO::Exception',
  'an extension that states no version refuses';
like "$@", qr/T::Ext::Silent.*extension_interface/s, 'names the missing declaration';

throws_ok { DBIO::Extension->check_interface('T::NotAnExtension') } 'DBIO::Exception',
  'a class not deriving from DBIO::Extension refuses';

# the mechanism: widening the set later changes only the set
{
  local @DBIO::Extension::INTERFACE_VERSIONS = (2, 1);
  ok(DBIO::Extension->check_interface('T::Ext::Good'),
    'with the previous version in the set, version 1 still passes');
  is_deeply [ DBIO::Extension->interface_versions ], [2, 1], 'the set is what the package var says';
}

done_testing;
