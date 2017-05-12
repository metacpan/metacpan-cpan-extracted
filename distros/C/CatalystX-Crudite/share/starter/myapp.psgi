use strict;
use warnings;
use <% dist_module %>;
use Plack::Builder;
my $app = <% dist_module %>->apply_default_middlewares(<% dist_module %>->psgi_app);
builder {
    enable 'Debug', panels => [
        qw(
          CatalystLog DBIC::QueryLog
          DBITrace Memory Timer Parameters
          Session Response
          )
      ]
      if $ENV{PLACK_DEBUG};
    $app;
};
