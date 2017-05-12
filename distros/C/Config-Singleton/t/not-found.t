#!perl -T

use File::Spec;
use Test::More tests => 3;

require_ok('Config::Singleton');

{
  package ThisApp::Config;
  Config::Singleton->import( -setup => {
    path     => [ 'etc' ],
    template => { foo => 1 },
  });
}

eval { ThisApp::Config->new('missing.yml'); };
like($@, qr/not found in path/, "exception if file not found in path");

my $abs_fn = File::Spec->rel2abs('etc/missing.yml');
eval { ThisApp::Config->new($abs_fn); };
like($@, qr/not found/, "exception if file not found in abs location");
