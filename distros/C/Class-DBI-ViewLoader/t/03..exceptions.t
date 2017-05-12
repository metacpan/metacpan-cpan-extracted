use strict;
use warnings;

use Test::More tests => 31;
use Class::DBI;

use lib qw( t/lib );

BEGIN {
    use_ok("Class::DBI::ViewLoader");
}

# Module::Pluggable doesn't look in non-blib dirs under -Mblib
unless (exists $Class::DBI::ViewLoader::handlers{'Bad'}) {
    require Class::DBI::ViewLoader::Bad;
    $Class::DBI::ViewLoader::handlers{'Bad'} = 'Class::DBI::ViewLoader::Bad';
}
unless (exists $Class::DBI::ViewLoader::handlers{'Mock'}) {
    require Class::DBI::ViewLoader::Mock;
    $Class::DBI::ViewLoader::handlers{'Mock'} = 'Class::DBI::ViewLoader::Mock';
}

eval { new Class::DBI::ViewLoader ( foo => 'bar' ) };
like($@, qr(^Unrecognised arguments in new\b), 'new with bad args dies');

eval { new Class::DBI::ViewLoader ( dsn => 'dbi:Foo:whatever' ) };
like($@, qr(^No handler for driver\b), "new with bad dsn dies");

eval { new Class::DBI::ViewLoader ( dsn => 'DBI:Mock:whatever' ) };
ok(!$@, 'captitalised "DBI:" in dsn lives') or diag $@;

eval { new Class::DBI::ViewLoader ( dsn => 'DbI:invalid' ) };
like($@, qr(^Invalid dsn), 'invalid dsn');

eval { new Class::DBI::ViewLoader->set_dsn() };
like($@, qr(^No dsn), 'absent dsn');

# abstract method tests
my $loader = new Class::DBI::ViewLoader;
my @abstract = @Class::DBI::ViewLoader::driver_methods;
for my $method (@abstract) {
    eval { $loader->$method };
    like($@, qr(^No handler loaded\b), "$method on object with no driver");
}

$loader->set_dsn('dbi:Bad:badbad');
for my $method (@abstract) {
    eval { $loader->$method };
    like($@, qr(^$method not overridden\b), "$method on object with bad driver");
}

eval { $loader->completely_invalid_method };
like($@, qr(^Can't locate object method), "Invalid method still dies");

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    # set up a view with no columns:

    local $Class::DBI::ViewLoader::Mock::db{empty} = [];

    my @classes = eval { $loader->set_dsn('dbi:Mock:')->load_views };
    ok(!$@, 'load_views succeeded') or diag $@;
    my $expected = keys(%Class::DBI::ViewLoader::Mock::db) - 1;

    is(@classes, $expected, "load_views skipped empty view");
    is(@warnings, 1, "1 warning generated") or diag @warnings;
    like($warnings[0], qr(^No columns found\b), "\"No columns found\"");
}

for my $field (qw( username password )) {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $setter = "set_$field";
    my $getter = "get_$field";

    $loader->$setter();
    is(@warnings, 0, 'set_username with no args gives no warning');
    is($loader->$getter, undef, 'get_username returns undef')
}

# Test import from non-Exporter
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @classes = eval {
	Class::DBI::ViewLoader->new
	    ->set_dsn('dbi:Mock:foo')
	    ->set_namespace('ImportTest')
	    ->set_import_classes(qw(Class::DBI::NullBase))
	    ->load_views;
    };
    ok(!$@, 'non-Exporter in import_classes lives');
    is(@warnings, @classes, '1 warning per class loaded')
	or diag join("\n", @warnings);

    like($warnings[0], qr(^Class::DBI::NullBase has no import function\b), 'as expected');
}

eval { $loader->set_include({}) };
like($@, qr(^Regexp or string required), "set_include with hashref");

$Class::DBI::ViewLoader::handlers{'ReallyBad'} = 'ReallyBad';
eval { new Class::DBI::ViewLoader ( dsn => 'dbi:ReallyBad:reallybad' ) };
like($@, qr(^ReallyBad is not a [\w:]+ subclass\b), 'attempt to rebless to non-subclass');

{
    # We're not interested in testing the warnings.
    local $SIG{__WARN__} = sub {};
    my($l, $dbh, $driver);

    $driver = DBI->install_driver('Mock');

    $l = Class::DBI::ViewLoader->new->set_dsn('dbi:Mock:');
    $dbh =
    eval { $l->_get_dbi_handle } or diag $@;
    ok($dbh, "_get_dbi_handle");

    is($l->_get_dbi_handle, $dbh, 'second call returns same object');

    $l = Class::DBI::ViewLoader->new->set_dsn('dbi:Mock:');
    $driver->{mock_connect_fail} = 1;
    eval { $l->_get_dbi_handle };
    like($@, qr(^Couldn't connect to database\b), "Simulated dbi failure");
}

# edge case: a module has import defined but can't be found (shouldn't really
# happen, but hey..
sub Not::Valid::Class::import {}
eval {
    $loader = new Class::DBI::ViewLoader (
        dsn => 'dbi:Mock:',
        import_classes => 'Not::Valid::Class',
        namespace => 'Import::Fail'
    );

    $loader->load_views;
};
ok($@, 'load invalid base class failed');
like($@, qr(^Message: Can't locate Not/Valid/Class\.pm)m,
        'error message as expected');

__END__

vim: ft=perl
