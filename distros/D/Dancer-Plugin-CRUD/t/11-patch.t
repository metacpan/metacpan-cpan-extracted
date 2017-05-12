use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];
use Try::Tiny;

# Dancer::Test had a bug in version previous 1.3059_01 that prevent this test
# from running correctly.
my $dancer_version = eval "\$Dancer::VERSION";
$dancer_version =~ s/_//g;
plan skip_all =>
  "Dancer 1.3059_01 is needed for this test (you have $dancer_version)"
  if $dancer_version < 1.305901;

try {
    require Validate::Tiny;
}
catch {
    plan skip_all => "Validate::Tiny is needed for this test";
};

#plan tests => 1;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;
    use Test::More import => ['!pass'];

    set serialzier => 'JSON';

    resource foo => patch => sub {
        return scalar captures;
      },
      ;
}

use Dancer::Test;
use Data::Dumper;

plan tests => 1;

my $r;

$r = dancer_response( PATCH => '/foo/123' );
is_deeply $r->{content}, { foo_id => 123 }, 'patch foo ok';

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{ read_logs() };

done_testing;
