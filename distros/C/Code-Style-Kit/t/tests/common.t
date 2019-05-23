use Test2::V0;
use lib 't/lib';
use TestHelper;

my $pkg = make_pkg({
    requires => [qw(Try::Tiny Carp namespace::autoclean true Log::Any)],
    parts => [qw(Common)],
    body => <<'EOBODY',
sub use_undef { 0+undef }
sub use_log { $log->info('foo') }
sub use_croak { croak 'boom' }
sub use_try { return try { die "boom\n" } catch { return $_ } }
EOBODY
});

ok(!$pkg->can('try'),'the namespace should be autocleaned');

is($pkg->use_try,"boom\n",'Try::Tiny should be imported');

eval { $pkg->use_undef };
like($@,qr{\buninitialized value\b},'warning should be fatal');

eval { $pkg->use_croak };
like($@,qr{\bboom at t/tests/common\.t\b},'Carp should be imported');

done_testing;
