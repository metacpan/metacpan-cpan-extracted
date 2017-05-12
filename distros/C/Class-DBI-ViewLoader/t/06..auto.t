package AutoTest;

use strict;
use warnings;

use Test::More tests => 13;

use lib qw( t/lib );

use Class::DBI::Mock;

unless (exists $Class::DBI::ViewLoader::handlers{'Mock'}) {
    # Module::Pluggable doesn't look in non-blib dirs under -Mblib
    require Class::DBI::ViewLoader::Mock;
    $Class::DBI::ViewLoader::handlers{'Mock'} = 'Class::DBI::ViewLoader::Mock';
}

BEGIN { use_ok('Class::DBI::ViewLoader::Auto') }

my $dsn = 'dbi:Mock:';
my @views;

@AutoTest::ISA = qw( Class::DBI::Mock );

@AutoTest::Vanilla::ISA = qw( AutoTest );
AutoTest::Vanilla->connection($dsn);
@views = AutoTest::Vanilla->load_views();

is(@views, 2, 'load_views');
is($views[0], 'AutoTest::Vanilla::TestView');
is($views[1], 'AutoTest::Vanilla::ViewTwo');

@AutoTest::Pattern::ISA = qw( AutoTest );
AutoTest::Pattern->connection($dsn);
@views = AutoTest::Pattern->load_views(qr/^test_/);
is(@views, 1);
is($views[0], 'AutoTest::Pattern::TestView');

@AutoTest::Ref::ISA = qw( AutoTest );
AutoTest::Ref->connection($dsn);
@views = AutoTest::Ref->load_views({namespace => 'AutoTest::Ref::View'});
is(@views, 2);
is($views[0], 'AutoTest::Ref::View::TestView');
is($views[1], 'AutoTest::Ref::View::ViewTwo');

@AutoTest::Hash::ISA = qw( AutoTest );
AutoTest::Hash->connection($dsn);
@views = AutoTest::Hash->load_views({namespace => 'AutoTest::Hash::View'});
is(@views, 2);
is($views[0], 'AutoTest::Hash::View::TestView');
is($views[1], 'AutoTest::Hash::View::ViewTwo');

@AutoTest::Connect::ISA = qw( AutoTest );
eval { @views = AutoTest::Connect->load_views() };
like($@, qr(^AutoTest::Connect has no connection));

{
    # complete test coverage.
    $SIG{__WARN__} = sub {};
    eval { Class::DBI::ViewLoader::Auto::load_views };
}

__END__


vim: ft=perl
