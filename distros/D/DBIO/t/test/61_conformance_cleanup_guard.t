use strict;
use warnings;

use Test::More;

# DBIO::Test::Conformance::_drive (karr k350): conformance_cleanup runs only
# when conformance_namespace came back without an error. Without the mark a
# namespace hands back, cleanup has nothing it may remove.

use DBIO::Test::Conformance;
use DBIO::Test::Conformance::Cases::DDL;
use DBIO::Test::Storage;

{
  package GuardConf;
  use base 'DBIO::Test::Conformance';

  our ($NS_THROWS, @CLEANUP_CALLS, $DISCONNECTS);

  sub conformance_live_available { 1 }

  sub conformance_connect {
    my ($class, $schema_class) = @_;
    $schema_class->storage_type('GuardConf::Storage');
    return $schema_class->connect(sub { });
  }

  sub conformance_namespace {
    my ($class, $schema, $case) = @_;
    die "the database is not empty\n" if $NS_THROWS;
    return "mark-$case->{name}";
  }

  sub conformance_install { }
  sub conformance_cleanup {
    my ($class, $schema, $case, $ns) = @_;
    push @CLEANUP_CALLS, $ns;
  }
  sub conformance_diff_is_empty { 1 }
  sub conformance_count { 1 }

  package GuardConf::Storage;
  use base 'DBIO::Test::Storage';
  sub disconnect { $GuardConf::DISCONNECTS++; $_[0]->next::method(@_[1..$#_]) }
}

my ($case) = grep { $_->{name} eq 'ddl-fk-actions' } @{ GuardConf->cases('DDL') };
$case ||= GuardConf->cases('DDL')->[0];
my $name = $case->{name};

# namespace refused: nothing is removed, the case is not a pass, the
# connection is closed
{
  local $GuardConf::NS_THROWS = 1;
  local @GuardConf::CLEANUP_CALLS;
  local $GuardConf::DISCONNECTS = 0;
  my ($r) = GuardConf->results('DDL', only => [$name]);
  is scalar(@GuardConf::CLEANUP_CALLS), 0,
    'namespace threw: conformance_cleanup is not called';
  isnt $r->{status}, 'pass', 'namespace threw: the case does not pass';
  like $r->{message}, qr/database is not empty/, 'the refusal is reported';
  ok $GuardConf::DISCONNECTS >= 1, 'namespace threw: the connection is closed';
}

# namespace given: cleanup runs with the mark
{
  local $GuardConf::NS_THROWS = 0;
  local @GuardConf::CLEANUP_CALLS;
  my ($r) = GuardConf->results('DDL', only => [$name]);
  is_deeply \@GuardConf::CLEANUP_CALLS, ["mark-$name"],
    'namespace ok: conformance_cleanup is called once with the mark';
}

done_testing;
