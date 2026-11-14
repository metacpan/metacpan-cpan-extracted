use strict;
use warnings;
use Test::More;

use lib 't/lib';
use DBIO::Extension;
use DBIO::Test::ExtensionSet qw(extension_set_ok extension_set_violations extension_set_orders);
use TestDBIO::Extension::Deploy;
use TestDBIO::Extension::Age;
use TestDBIO::Extension::PostGIS;

# ADR 0066 section 2.4: the commutativity test. Positive cases are the two
# mock extensions of the ADR's example; every negative case must turn it red.

my $source = {
  schemas => { public => 1, g1 => 1 },
  tables  => {
    'public.places' => { columns => { geom => { type => 'geometry(Point,4326)' } } },
    'g1.label'      => { columns => { loc  => { type => 'geometry(Point,4326)' } } },
  },
};
my $target = {
  schemas => { public => 1 },
  tables  => { 'public.places' => { columns => { geom => { type => 'geometry(Point,3857)' } } } },
};
my %base = (
  driver => 'TestDBIO::Extension::Deploy',
  source => $source,
  target => $target,
  dbh    => { graphs => [ { name => 'g', namespace => 'g1' } ] },
  changes => [ {
    kind => 'column_type', table => 'public.places', column_name => 'geom',
    old_info => { base_type => 'geometry', geometry_type => 'Point', srid => 4326 },
    new_info => { base_type => 'geometry', geometry_type => 'Point', srid => 3857 },
  } ],
);

# --- the orders ---------------------------------------------------------------------------------
is scalar(extension_set_orders(qw(a b c))), 6, 'three extensions: every permutation';
is scalar(extension_set_orders(qw(a b c d e))), 120, 'five extensions: every permutation';
my @six = extension_set_orders(qw(a b c d e f));
is scalar(@six), 12, 'six extensions: every rotation and the rotations of the reverse';
is_deeply $six[0], [qw(a b c d e f)], 'the name order is among them';
is_deeply [ grep { join('', @$_) eq 'fedcba' } @six ], [ [qw(f e d c b a)] ], 'and its reverse';
is scalar(extension_set_orders('a')), 1, 'one extension, one order';

# --- the ADR example: AGE and PostGIS in both orders ----------------------------------------------
my @ok = extension_set_violations(%base,
  extensions => [qw(TestDBIO::Extension::Age TestDBIO::Extension::PostGIS)]);
is_deeply \@ok, [], 'AGE-like and PostGIS-like extensions are order independent' or diag explain \@ok;
is_deeply [ extension_set_violations(%base, extensions => [qw(TestDBIO::Extension::PostGIS TestDBIO::Extension::Age)]) ],
  [], 'also declared in the other order';
is_deeply [ extension_set_violations(%base, extensions => []) ], [], 'an empty set is trivially fine';

extension_set_ok(%base, name => 'extension_set_ok on the ADR example',
  extensions => [qw(TestDBIO::Extension::Age TestDBIO::Extension::PostGIS)]);

# --- negative cases -----------------------------------------------------------------------------------
sub mk {
  my ($name, %methods) = @_;
  our $n; my $class = "T::Set::\u$name" . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Extension');
  *{"${class}::extension_interface"} = sub { 1 };
  *{"${class}::name"} = sub { $name };
  *{"${class}::$_"} = $methods{$_} for keys %methods;
  return $class;
}
sub violations { return [ extension_set_violations(%base, extensions => \@_) ] }
sub mentions { my ($v, $re, $what) = @_; ok(scalar(grep { /$re/ } @$v), $what) or diag explain $v }

# an extension that changes its input
{
  my $bad = mk(mutator => claims => sub { $_[1]{schemas}{injected} = 1; [] });
  my $v = violations($bad, 'TestDBIO::Extension::Age');
  ok scalar(@$v), 'an extension that mutates its input turns the test red';
  mentions $v, qr/mutator.*changed its input/s, 'and is named';
}
# an extension that changes its context
{
  my $bad = mk(ctxmut => claims => sub { $_[2]{self}{state} = 'tampered'; [] });
  my $v = violations($bad);
  mentions $v, qr/ctxmut.*changed its context/s, 'a changed context is caught as well';
}
# an extension that keeps state between calls
{
  my $n = 0;
  my $bad = mk(counter => annotate => sub { [ [ [ column => 'public.places', 'geom' ], seq => ++$n ] ] });
  my $v = violations($bad);
  ok scalar(@$v), 'an extension that keeps state between calls turns the test red';
  mentions $v, qr/counter/, 'and is named';
}
# an extension that answers depending on what ran before
{
  our $LAST = 'none';
  my $dependent = mk(dependent => claims => sub { my $seen = $LAST; $LAST = 'dependent'; [ [ schema => "after_$seen" ] ] });
  my $other     = mk(other     => claims => sub { $LAST = 'other'; [] });
  my $v = violations($dependent, $other);
  ok scalar(@$v), 'an extension whose answer depends on the order turns the test red';
  mentions $v, qr/dependent|model|claims/, 'and says what differs';
}
# conflicts of the merges
{
  my $one = mk(one => annotate => sub { [ [ [ column => 'public.places', 'geom' ], srid => 1 ] ] });
  my $two = mk(two => annotate => sub { [ [ [ column => 'public.places', 'geom' ], srid => 2 ] ] });
  my $v = violations($one, $two);
  mentions $v, qr/one.*two|two.*one/s, 'an annotate conflict is reported, naming both extensions';
}
{
  my $u1 = mk(u1 => verdict => sub { { using => 'f(x)' } });
  my $u2 = mk(u2 => verdict => sub { { using => 'g(x)' } });
  my $v = violations($u1, $u2);
  ok scalar(@$v), 'a verdict conflict does not pass silently' or diag explain $v;
}
{
  my $one = mk(one => verdict => sub { { refuse => 'never' } });
  my $v = violations($one);
  is_deeply $v, [], 'a plain refusal is a legitimate, order independent answer, not a violation';
}
# the interface
{
  my $future = mk(future => );
  { no strict 'refs'; no warnings 'redefine'; *{"${future}::extension_interface"} = sub { 9 }; }
  my $v = violations($future);
  mentions $v, qr/interface version 9/, 'a wrong interface version is a violation';
}
{
  my $nameless = 'T::Set::Nameless';
  { no strict 'refs'; @{"${nameless}::ISA"} = ('DBIO::Extension'); *{"${nameless}::extension_interface"} = sub { 1 }; }
  my $v = violations($nameless);
  mentions $v, qr/Nameless.*name/s, 'an extension without a name cannot be put in a set';
}
# a driver that cannot apply what the extensions claim
{
  my $v = [ extension_set_violations(%base, driver => 'DBIO::Deploy::Base',
    extensions => ['TestDBIO::Extension::Age']) ];
  mentions $v, qr/_apply_extension_claims/, 'the driver seams are exercised';
}

# --- extension_set_ok reports violations ---------------------------------------------------------------------
{
  my $bad = mk(mutator2 => claims => sub { $_[1]{x} = 1; [] });
  my $tb = Test::Builder->create;
  $tb->output(\my $out);
  $tb->failure_output(\my $err);
  $tb->plan('no_plan');
  my $res = extension_set_ok(%base, builder => $tb, name => 'bad set', extensions => [$bad]);
  ok !$res, 'extension_set_ok returns false for a violating set';
  like $out, qr/^not ok 1 - bad set/m, 'and fails the test';
  like $err, qr/mutator2.*changed its input/s, 'with the violation as diagnostics';
}

# --- results holding a code reference or a regexp are compared, not frozen ----------
{
  my %ext = (extensions => [qw(TestDBIO::Extension::Age TestDBIO::Extension::PostGIS)]);
  my $sub = sub { 1 };
  is_deeply [ extension_set_violations(%base, %ext, diff => sub { [ $sub, qr/a/i ] }) ], [],
    'the same code reference and an equal regexp in every result are no violation';

  my $n = 0;
  my @bad = extension_set_violations(%base, %ext, diff => sub { [ $n++ % 2 ? qr/a/ : qr/b/ ] });
  ok scalar(@bad), 'a regexp that differs between runs is a violation';
  like $bad[0], qr/differs from .* in statements/, 'in the statements';

  my @subs = extension_set_violations(%base, %ext, diff => sub { my $m = $n++; [ sub { $m } ] });
  ok scalar(@subs), 'a code reference that differs between runs is a violation';
}

done_testing;
