use strict;
use warnings;
use Test::More tests => 2;

use Catalyst::Controller;
my $NEW_CALLED;
BEGIN { 
    $NEW_CALLED = 0;
    { no warnings;
      sub Catalyst::Controller::new {
          $NEW_CALLED = 1;
          return shift->next::method(@_);
      }
  }
}

BEGIN { is $NEW_CALLED, 0, 'new not called yet' }

use FindBin qw($Bin);
use lib "$Bin/lib";
use Catalyst::Test qw(TestApp);

is $NEW_CALLED, '1', 'Catalyst::Controller::new does get called';

1;

