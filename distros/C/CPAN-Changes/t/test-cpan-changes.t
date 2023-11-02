use Test::More;
use Test::CPAN::Changes;

{
  package FakeBuilder;
  sub new {
    my $class = shift;
    return bless {
      called => [],
    }, $class;
  }
  sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;
    push @{$self->{called}}, [$method, @args];
    return $args[0];
  }
  sub DESTROY {}
}

sub called {
  no warnings 'once';
  my $tester = local $Test::CPAN::Changes::Test = FakeBuilder->new;
  local $Test::CPAN::Changes::Parser = CPAN::Changes::Parser->new(
    _release_class => 'Test::CPAN::Changes::Release',
    version_like => qr/\{\{ \$NEXT \}\}/
  );
  changes_file_ok(@_);
  return $tester->{called};
}

is_deeply called('corpus/test/valid.changes'), [
  [ ok => 1, 'corpus/test/valid.changes is loadable' ],
  [ ok => 1, 'corpus/test/valid.changes contains at least one release' ],
  [ ok => 1, 'corpus/test/valid.changes contains all valid release dates' ],
  [ ok => 1, 'corpus/test/valid.changes contains all valid release versions' ],
], 'fully valid file tests properly';

is_deeply called('corpus/test/no_releases.changes'), [
  [ ok => 1, 'corpus/test/no_releases.changes is loadable' ],
  [ ok => !1, 'corpus/test/no_releases.changes contains at least one release' ],
  [ ok => 1, 'corpus/test/no_releases.changes contains all valid release dates' ],
  [ ok => 1, 'corpus/test/no_releases.changes contains all valid release versions' ],
], 'correct failure for no releases';

is_deeply called('corpus/test/ugly_dates.changes'), [
  [ ok => 1, 'corpus/test/ugly_dates.changes is loadable' ],
  [ ok => 1, 'corpus/test/ugly_dates.changes contains at least one release' ],
  [ note => 'Date "Mon Jul 20 12:26:55 2015" is not in the recommended W3CDTF format, should be "2015-07-20T12:26:55Z" (line 3)'],
  [ ok => 1, 'corpus/test/ugly_dates.changes contains all valid release dates' ],
  [ ok => 1, 'corpus/test/ugly_dates.changes contains all valid release versions' ],
], 'correct note for non-recommended dates';

is_deeply called('corpus/test/bad_versions.changes'), [
  [ ok => 1, 'corpus/test/bad_versions.changes is loadable' ],
  [ ok => 1, 'corpus/test/bad_versions.changes contains at least one release' ],
  [ ok => 1, 'corpus/test/bad_versions.changes contains all valid release dates' ],
  [ ok => !1, 'corpus/test/bad_versions.changes contains all valid release versions' ],
  [ diag => '  ERR: {{ $NEXT }} (line 3)']
], 'correct failure for bad versions';

is_deeply called('corpus/test/bad_dates.changes'), [
  [ ok => 1, 'corpus/test/bad_dates.changes is loadable' ],
  [ ok => 1, 'corpus/test/bad_dates.changes contains at least one release' ],
  [ ok => !1, 'corpus/test/bad_dates.changes contains all valid release dates' ],
  [ diag => '  ERR: No date for version 0.01 (line 3)' ],
  [ ok => 1, 'corpus/test/bad_dates.changes contains all valid release versions' ],
], 'correct failure for bad dates';

is_deeply called('corpus/test/valid.changes', { version => 0.01 }), [
  [ ok => 1, 'corpus/test/valid.changes is loadable' ],
  [ ok => 1, 'corpus/test/valid.changes contains at least one release' ],
  [ ok => 1, 'corpus/test/valid.changes contains all valid release dates' ],
  [ ok => 1, 'corpus/test/valid.changes contains all valid release versions' ],
  [ ok => 1, 'corpus/test/valid.changes has an entry for version 0.01'],
  [ ok => 1, 'corpus/test/valid.changes version 0.01 has content'],
], 'fully valid file tests properly with version';

is_deeply called('corpus/test/valid.changes', { version => 0.02 }), [
  [ ok => 1, 'corpus/test/valid.changes is loadable' ],
  [ ok => 1, 'corpus/test/valid.changes contains at least one release' ],
  [ ok => 1, 'corpus/test/valid.changes contains all valid release dates' ],
  [ ok => 1, 'corpus/test/valid.changes contains all valid release versions' ],
  [ ok => !1, 'corpus/test/valid.changes has an entry for version 0.02'],
  [ skip => 'can\'t check for entries in nonexistant version' ],
], 'correct failure for missing release';

is_deeply called('corpus/test/empty_release.changes', { version => 0.01 }), [
  [ ok => 1, 'corpus/test/empty_release.changes is loadable' ],
  [ ok => 1, 'corpus/test/empty_release.changes contains at least one release' ],
  [ ok => 1, 'corpus/test/empty_release.changes contains all valid release dates' ],
  [ ok => 1, 'corpus/test/empty_release.changes contains all valid release versions' ],
  [ ok => 1, 'corpus/test/empty_release.changes has an entry for version 0.01'],
  [ ok => !1, 'corpus/test/empty_release.changes version 0.01 has content'],
], 'correct failure for empty release';

done_testing;
