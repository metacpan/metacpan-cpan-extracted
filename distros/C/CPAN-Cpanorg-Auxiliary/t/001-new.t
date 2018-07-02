# t/001-new.t
use 5.14.0;
use warnings;
use CPAN::Cpanorg::Auxiliary;
use Carp;
use Cwd;
use File::Temp qw(tempdir);
use Test::More;
use lib ('./t/testlib');
use Helpers qw(basic_test_setup);

my ($self);
my $cwd = cwd();

##### BAD ARGUMENTS #####

{
    local $@ = undef;
    eval { $self = CPAN::Cpanorg::Auxiliary->new(); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for non-hashref argument");
}

{
    local $@ = undef;
    eval { $self = CPAN::Cpanorg::Auxiliary->new([]); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for non-hashref argument");
}

{
    local $@ = undef;
    eval { $self = CPAN::Cpanorg::Auxiliary->new({ foo => 1, bar => 2 }); };
    like($@, qr/Invalid elements passed to constructor:/,
        "new: Got expected error message for invalid arguments");
    like($@, qr/foo/, "new: Got expected error message for invalid arguments");
    like($@, qr/bar/, "new: Got expected error message for invalid arguments");
}

{
    local $@ = undef;
    my $missing_arg = 'path';
    eval { $self = CPAN::Cpanorg::Auxiliary->new({}); };
    like($@, qr/'$missing_arg' not found in elements passed to constructor/,
        "new: Got expected error message for absence of '$missing_arg' element");
}

{
    local $@ = undef;
    my $bad_path = '/tmp/foo/bar/baz/' . time;
    eval { $self = CPAN::Cpanorg::Auxiliary->new({
        path => $bad_path,
    }); };
    like($@, qr/Could not locate directory '$bad_path'/,
        "new: Got expected error message for non-existent directory '$bad_path'");
}

{
    my $tdir = tempdir(CLEANUP => 1);
    local $@ = undef;
    eval { $self = CPAN::Cpanorg::Auxiliary->new({ path => $tdir }); };
    like($@, qr/Could not locate required directories:/s,
        "new: Got expected error message for missing subdirectories");
    like($@, qr|CPAN/authors/id|s,
        "new: Got expected error message for missing subdirectories");
}

##### GOOD ARGUMENTS #####

{
    my $tdir = basic_test_setup($cwd);

    $self = CPAN::Cpanorg::Auxiliary->new({ path => $tdir });
    ok(defined $self, "new: returned defined value");
    isa_ok($self, 'CPAN::Cpanorg::Auxiliary');
    ok(length($self->{versions_json}),
        "Attribute 'versions_json' has non-zero-length string '$self->{versions_json}' for value");
    ok(length($self->{search_api_url}),
        "Attribute 'search_api_url' has non-zero-length string '$self->{search_api_url}' for value");
    ok(length($self->{five_url}),
        "Attribute 'five_url' has non-zero-length string '$self->{five_url}' for value");
    is($self->{cwd}, $cwd,
        "Current working directory at time of construction stored in object");
}

{
    note("Demonstrate that certain values can be passed to constructor");
    my $tdir = basic_test_setup($cwd);

    $self = CPAN::Cpanorg::Auxiliary->new({
        path => $tdir,
        versions_json => 'perl_version_all.json',
        search_api_url => 'http://search.cpan.org/api/dist/perl',
    });
    ok(defined $self, "new: returned defined value");
    isa_ok($self, 'CPAN::Cpanorg::Auxiliary');
}

done_testing;
