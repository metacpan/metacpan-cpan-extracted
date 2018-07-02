# t/002-make-api-call.t
use 5.14.0;
use warnings;
use CPAN::Cpanorg::Auxiliary;
use Carp;
use Cwd;
use Test::More;
use lib ('./t/testlib');
use Helpers qw(basic_test_setup);

unless ($ENV{PERL_ALLOW_NETWORK_TESTING}) {
    plan skip_all => "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests";
}
else {
    plan tests => 12;
}

my $cwd = cwd();

{
    my $tdir = basic_test_setup($cwd);

    my $self = CPAN::Cpanorg::Auxiliary->new({ path => $tdir });
    ok(defined $self, "new: returned defined value");
    isa_ok($self, 'CPAN::Cpanorg::Auxiliary');

    my $cpan_json = $self->make_api_call;
    ok(defined $cpan_json, "make_api_call: returned defined value");
    ok(length($cpan_json), "make_api_call: returned non-zero-length string");
}

