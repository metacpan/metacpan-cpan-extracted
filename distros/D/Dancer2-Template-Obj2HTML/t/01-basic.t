use strict;

use File::Basename;
use Path::Tiny;
use FindBin qw( $Bin );
use HTTP::Request::Common;
use JSON::MaybeXS;
use Module::Load;
use Plack::Test;
use Test::More;
use Test::Mock::LWP::Dispatch;
use URI;

# setup dancer app
{
  package App;
  use Dancer2;

  true;
}

# setup plack
my $app = App->psgi_app;
is( ref $app, 'CODE', 'Got app' );

test_psgi
    app    => $app,
    client => sub {
      my $cb  = shift;
    };

# all done!
done_testing;
