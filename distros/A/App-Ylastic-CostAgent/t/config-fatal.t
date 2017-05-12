use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;
use File::Spec::Functions qw/catfile/;

use App::Ylastic::CostAgent;

my @cases = (
  {
    label => 'Missing config_file', 
    error => qr/config_file/,
    file => 'doesnotexist.ini',
  },
  {
    label => 'Ylastic ID missing', 
    error => qr/does not define 'ylastic_id'/,
    file => 'no-ylastic-id.ini',
  },
);

for my $c ( @cases ) {
  my $file = catfile( 't', 'data', $c->{file} );
  like(
    exception { App::Ylastic::CostAgent->new(config_file => $file) },
    $c->{error},
    $c->{label}
  );
}

done_testing;

