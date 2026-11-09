use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
use DBIO::Extension::List;
use TestDBIO::Extension::Deploy;

# ADR 0066 section 3: the protocol runs inside DBIO::Deploy::Base around
# _introspect_current, _build_target_model and diff. An empty list changes
# nothing for any driver.

my %table = (
  age     => 'TestDBIO::Extension::Age',
  postgis => 'TestDBIO::Extension::PostGIS',
);
sub entries {
  return [ DBIO::Extension::List->new(
    declaration => [@_],
    class_table => sub { $table{ $_[0] } ? ($table{ $_[0] }) : () },
    plain_class => 'TestDBIO::Extension::Plain',
  )->entries ];
}

sub source { {
  schemas => { public => 1, g1 => 1 },
  tables  => {
    'public.places' => { columns => { geom => { type => 'geometry(Point,4326)' } } },
    'g1.label'      => { columns => { loc  => { type => 'geometry(Point,4326)' } } },
  },
} }
sub target { {
  schemas => { public => 1 },
  tables  => { 'public.places' => { columns => { geom => { type => 'geometry(Point,3857)' } } } },
} }

sub deploy {
  my ($list, %extra) = @_;
  return TestDBIO::Extension::Deploy->new(
    extension_list => $list,
    source_model   => source(),
    target_model   => target(),
    dbh            => { graphs => [ { name => 'g', namespace => 'g1' } ] },
    %extra,
  );
}

# --- the default is no extensions ---------------------------------------------------
{
  is_deeply(DBIO::Deploy::Base->_extension_list, [], 'default list is empty');
  my $diff = deploy(entries())->diff;
  is_deeply $diff->as_sql, [
    'DROP TABLE g1.label',
    'ALTER TABLE public.places ALTER COLUMN geom TYPE geometry(Point,3857)',
  ], 'no extensions: the diff is built from the two models as they are';
  ok !exists $diff->{extensions}, 'the diff class is not handed a protocol';
  is_deeply $diff->source, source(), 'the source model is untouched';
}

# --- the base hooks refuse silently doing nothing -----------------------------------------
{
  package T::Deploy::Bare;
  use base 'DBIO::Deploy::Base';
  sub new { bless { %{$_[1]} }, $_[0] }
  sub _extension_list { $_[0]{list} }
  sub _introspect_current { { tables => {} } }
  sub _build_target_model { { tables => {} } }
  sub _diff_class { 'TestDBIO::Extension::Deploy::Diff' }
  sub _dbh { {} }
}
{
  my $bare = T::Deploy::Bare->new({ list => [] });
  throws_ok { $bare->_apply_extension_claims({}, [ [ schema => 'x' ] ]) } 'DBIO::Exception',
    'claims without a driver implementation refuse loudly';
  like "$@", qr/_apply_extension_claims/, 'naming the hook';
  throws_ok { $bare->_apply_extension_annotations({}, [ [ [ column => 't', 'c' ], a => 1 ] ]) } 'DBIO::Exception',
    'annotations without a driver implementation refuse loudly';

  my $with_age = T::Deploy::Bare->new({ list => entries('age') });
  # Age claims need its state; a dbh without graphs claims nothing, so nothing to apply.
  lives_ok { $with_age->diff } 'extensions that claim nothing need no driver implementation';
}

# --- the protocol in diff --------------------------------------------------------------------
{
  my $src    = source();
  my $deploy = deploy(entries('postgis', 'age'), source_model => $src);
  my $diff   = $deploy->diff;

  is_deeply $diff->as_sql, [
    'ALTER TABLE public.places ALTER COLUMN geom TYPE geometry(Point,3857) USING ST_Transform(geom, 3857)',
  ], 'AGE claims the graph schema (no drop of its tables), PostGIS answers the SRID change with USING';

  isa_ok $diff->{extensions}, 'DBIO::Extension::Protocol', 'the diff class is handed the protocol';
  ok !$diff->source->{schemas}{g1}, 'claims are applied to the source';
  is $diff->source->{tables}{'public.places'}{columns}{geom}{srid}, 4326, 'annotations on the source';
  is $diff->target->{tables}{'public.places'}{columns}{geom}{srid}, 3857, 'annotations on the target';
  is_deeply $diff->source->{extensions}, { age => { graphs => [ { name => 'g', namespace => 'g1' } ] } },
    'the inspect state is in the model under the extension name';
  is_deeply $diff->target->{extensions}, $diff->source->{extensions}, 'both sides carry the same state';
  throws_ok { $diff->source->{extensions}{age}{graphs} = [] } qr/read-only|restricted|disallowed/i,
    'the state is read-only';
  # Hash::Util::lock_hashref_recurse leaves the arrays of the state writable;
  # the whole state is read-only, arrays and what they hold included.
  throws_ok { push @{ $diff->source->{extensions}{age}{graphs} }, { name => 'x' } } qr/read-only/i,
    'an array in the state is read-only: push';
  throws_ok { $diff->source->{extensions}{age}{graphs}[0] = {} } qr/read-only/i,
    'an array in the state is read-only: element assignment';
  throws_ok { $diff->source->{extensions}{age}{graphs}[0]{name} = 'x' } qr/read-only|restricted|disallowed/i,
    'a hash inside an array in the state is read-only';

  is_deeply $src, source(), 'the introspected model is not changed in place';
}

# --- same result whatever the declaration order ----------------------------------------------------
{
  is_deeply deploy(entries('age', 'postgis'))->diff->as_sql,
            deploy(entries('postgis', 'age'))->diff->as_sql, 'declaration order does not enter';
}

# --- verdict through the deploy, refusal stops apply ------------------------------------------------
{
  my $target = target();
  $target->{tables}{'public.places'}{columns}{geom}{type} = 'geometry(Polygon,4326)';
  my $deploy = deploy(entries('postgis'), target_model => $target);
  my $diff = $deploy->diff;
  is_deeply $diff->as_sql, [ 'DROP TABLE g1.label' ],
    'the refused change is not written';
  throws_ok { $deploy->apply($diff) } 'DBIO::Exception', 'a refusal refuses the diff at apply';
  like "$@", qr/postgis: column geom: geometry type is not converted/, 'naming extension and reason';

  {
    package T::Deploy::Capture;
    our @executed;
    our @ISA = ('TestDBIO::Extension::Deploy');
    sub _execute_ddl { shift; shift; @executed = @_ }
  }
  my $ok = T::Deploy::Capture->new(
    extension_list => entries('postgis', 'age'),
    source_model => source(), target_model => target(),
    dbh => { graphs => [ { name => 'g', namespace => 'g1' } ] },
  );
  ok $ok->apply($ok->diff), 'a diff without refusals applies';
  is scalar(@T::Deploy::Capture::executed), 1, 'and its statements are executed';
  is $ok->_extension_verdict({ kind => 'x' }), undef, 'direct verdict for a change nobody answers';
  is(TestDBIO::Extension::Deploy->new->_extension_verdict({}), undef, 'no extensions, no verdict');
}

# --- lean startup: a plain deploy loads none of the extension machinery ------------------------------
{
  my $probe = q{
    use strict; use warnings;
    use lib "t/lib";
    use DBIO::Deploy::Base;
    require TestDBIO::Extension::Deploy;
    my $d = TestDBIO::Extension::Deploy->new(
      extension_list => [], dbh => {},
      source_model => { tables => {} }, target_model => { tables => {} });
    $d->diff;
    print "loaded=$_\n" for grep { exists $INC{ s{::}{/}gr . ".pm" } }
      qw(DBIO::Extension::Protocol DBIO::Extension::List JSON JSON::MaybeXS Data::Dumper Hash::Util);
  };
  open my $fh, "-|", $^X, (map { "-I$_" } @INC), "-e", $probe or die "probe: $!";
  my @out = <$fh>; close $fh;
  is $?, 0, "the probe ran";
  is_deeply \@out, [], "an empty extension list loads neither the protocol nor JSON nor Data::Dumper"
    or diag @out;
}

done_testing;
