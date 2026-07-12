use strict;
use warnings;
use Test::More;

use File::Temp ();
use DBIO::Util qw(dir_path file_path mkpath write_file);

use DBIO::Test;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Test::Storage;

# future_io adapter resolution: present-but-UNLOADABLE vs genuinely ABSENT.
#
# The convention walk in DBIO::Storage::DBI::_async_storage probes <pkg>::Async
# at each MRO rung via load_optional_class. That helper only returns false (->
# "keep walking / skip") when the candidate's OWN .pm is missing from @INC.
# When the .pm FILE exists but its compilation FAILS -- e.g. the driver ships
# <pkg>::Async (real: DBIO::MySQL::Storage::Async) but the separate async dist
# whose class it `use base`s (real: DBIO::Async) is NOT installed -- the old
# code let load_optional_class THROW the raw "Base class package ... is empty /
# Can't locate ... Compilation failed in require at Class/C3/Componentised.pm"
# stack straight at the user. That is the ONLY signal a user got that they
# needed to install the async dist, and it named neither the adapter nor a
# remedy.
#
# _try_load_async_class now distinguishes three outcomes -- LOADED / genuinely
# ABSENT / PRESENT-but-UNLOADABLE -- and on the unloadable case fails loud with
# a clear, correctly-attributed message: it names the missing MODULE only when
# Perl actually reports one, and surfaces a genuine syntax error in an installed
# adapter honestly, never misreported as a missing dependency.
#
# Mock only (DBIO::Test::Storage, no real DBD, no event loop): these drive the
# pure CLASS resolution path. The "present" adapters are written as real .pm
# files into a throwaway @INC dir so that load_optional_class's on-disk require
# path (the one that actually misbehaved) is exercised, not a pre-loaded inline
# package.

# ---------------------------------------------------------------------------
# A throwaway @INC dir holding the "present on disk" adapter fixtures. One is
# present-but-unloadable because its base class is not installed; one is present
# but has a genuine syntax error (NOT a missing dependency).
# ---------------------------------------------------------------------------
my $tmplib = File::Temp->newdir;

# T::Unl::MissingDep::Storage::Async -- file EXISTS, but its base class dist is
# not installed (mirrors DBIO::MySQL::Storage::Async when DBIO::Async is absent).
my $missing_dir = dir_path("$tmplib", qw(T Unl MissingDep Storage));
mkpath($missing_dir);
write_file(file_path($missing_dir, 'Async.pm'), <<'EOF');
package T::Unl::MissingDep::Storage::Async;
use strict; use warnings;
use base 'DBIO::Async::NotInstalled::Storage';   # not installed -> compile dies
1;
EOF

# T::Unl::Syntax::Storage::Async -- file EXISTS, installs fine on disk, but has a
# genuine syntax error. Must NOT be misreported as a missing dependency.
my $syntax_dir = dir_path("$tmplib", qw(T Unl Syntax Storage));
mkpath($syntax_dir);
write_file(file_path($syntax_dir, 'Async.pm'), <<'EOF');
package T::Unl::Syntax::Storage::Async;
use strict; use warnings;
this is not valid perl $#@!;
1;
EOF

# T::Unl::Layer::Async -- convention sibling of a storage LAYER, present on disk
# but unloadable (missing base class). Exercises the layer-composition call site.
my $layer_dir = dir_path("$tmplib", qw(T Unl Layer));
mkpath($layer_dir);
write_file(file_path($layer_dir, 'Async.pm'), <<'EOF');
package T::Unl::Layer::Async;
use strict; use warnings;
use base 'DBIO::Async::NotInstalled::LayerBase';   # not installed -> compile dies
1;
EOF

unshift @INC, "$tmplib";

# ---------------------------------------------------------------------------
# Driver storage classes (inline; isa DBIO::Test::Storage). The ::Async siblings
# for the first two live on disk in $tmplib; the "absent" one has none anywhere.
# ---------------------------------------------------------------------------
{
  package T::Unl::MissingDep::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package T::Unl::Syntax::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package T::Unl::Absent::Storage;    # no ::Async anywhere in its MRO
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}

# Build a driver storage of $class in future_io mode bound to a live schema,
# matching t/test/17's helper. Returns ($storage, $schema); keep $schema in
# scope (storage weakens its schema back-reference).
sub driver_storage {
  my ($class) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $storage = $class->new($schema);
  $storage->_async_mode('future_io');
  delete $storage->{_async_storage_obj};
  $storage->_connect_info([ { host => 'localhost' } ]);
  return ($storage, $schema);
}

# ---------------------------------------------------------------------------
# (a) Genuinely NO adapter anywhere: the existing friendly "no adapter found"
#     croak still fires unchanged (regression guard for the untouched path).
# ---------------------------------------------------------------------------
{
  my ($storage, $schema) = driver_storage('T::Unl::Absent::Storage');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err, 'absent adapter still croaks';
  like $err, qr/does not support future_io/,
    'absent: existing future_io croak wording preserved';
  like $err, qr/no \QT::Unl::Absent::Storage::Async\E adapter found/,
    'absent: existing "no <class>::Async adapter found" wording preserved';
  unlike $err, qr/is not installed|present but/,
    'absent: not mistaken for a present-but-unloadable adapter';
}

# ---------------------------------------------------------------------------
# (b) Adapter file PRESENT but its own dependency is not installed: a clear,
#     actionable message naming the adapter AND the missing module -- not a raw
#     compile trace, and not the generic "no adapter found" (absent) wording.
# ---------------------------------------------------------------------------
{
  my ($storage, $schema) = driver_storage('T::Unl::MissingDep::Storage');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err, 'present-but-unloadable adapter croaks';
  like $err, qr/\QT::Unl::MissingDep::Storage::Async\E/,
    'present-but-unloadable: message names the adapter that could not load';
  like $err, qr/\QDBIO::Async::NotInstalled::Storage\E/,
    'present-but-unloadable: message names the actual missing module';
  like $err, qr/is not installed/,
    'present-but-unloadable: message says the dependency is not installed';
  like $err, qr/Install the distribution/,
    'present-but-unloadable: message gives an actionable install hint';

  # It must NOT be misreported as "no adapter found" -- the adapter IS present.
  unlike $err, qr/no \S+ adapter found/,
    'present-but-unloadable: NOT misreported as a genuinely-absent adapter';

  # The underlying cause is surfaced, not swallowed...
  like $err, qr/Underlying error:/,
    'present-but-unloadable: the underlying cause is surfaced, not swallowed';
  # ...but wrapped in our framing, not left as a bare Componentised stack.
  like $err, qr/present but cannot be loaded/,
    'present-but-unloadable: wrapped in our framing, not a bare compile stack';
}

# ---------------------------------------------------------------------------
# (c) Adapter file PRESENT but with a genuine syntax error (NOT a missing
#     dependency): surfaced honestly and attributed to the adapter, NEVER
#     misreported as a missing dependency we cannot actually identify.
# ---------------------------------------------------------------------------
{
  my ($storage, $schema) = driver_storage('T::Unl::Syntax::Storage');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err, 'syntax-broken adapter croaks';
  like $err, qr/\QT::Unl::Syntax::Storage::Async\E/,
    'syntax-broken: message names the adapter that could not load';
  like $err, qr/present but failed to load/,
    'syntax-broken: falls to the honest generic wording';
  like $err, qr/Underlying error:/,
    'syntax-broken: the real compile error is surfaced';

  # The honesty guarantee: a genuine bug in an installed adapter must NOT be
  # dressed up as "some dependency is not installed".
  unlike $err, qr/is not installed/,
    'syntax-broken: NOT misattributed as a missing dependency';
  unlike $err, qr/Install the distribution/,
    'syntax-broken: no bogus install-this-module hint';
}

# ---------------------------------------------------------------------------
# (d) The layer-composition call site shares the same helper: a storage layer
#     whose convention ::Async sibling is present-but-unloadable fails loud with
#     the same clear message -- never silently skipped (that would be a silent
#     feature loss) and never a raw compile stack.
# ---------------------------------------------------------------------------
{
  # A minimal, valid future_io convention transport so resolution reaches the
  # layer-mirror loop; we croak inside that loop before it is ever constructed.
  package T::Unl::LayerHost::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::Unl::LayerHost::Storage::Async;  use base 'DBIO::Storage::Async'; use mro 'c3';

  package T::Unl::Layer;   # sync layer; its ::Async sibling is the broken on-disk file
}

{
  my $schema  = DBIO::Test->init_schema;
  $schema->register_storage_layer('T::Unl::Layer');
  my $storage = T::Unl::LayerHost::Storage->new($schema);
  $storage->_async_mode('future_io');
  delete $storage->{_async_storage_obj};
  $storage->_connect_info([ { host => 'localhost' } ]);

  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err,
    'layer path: a present-but-unloadable layer ::Async sibling croaks';
  like $err, qr/\QT::Unl::Layer::Async\E/,
    'layer path: message names the unloadable layer async class';
  like $err, qr/\QDBIO::Async::NotInstalled::LayerBase\E/,
    'layer path: message names the actual missing module';
  like $err, qr/is not installed/,
    'layer path: message says the dependency is not installed';
}

done_testing;
