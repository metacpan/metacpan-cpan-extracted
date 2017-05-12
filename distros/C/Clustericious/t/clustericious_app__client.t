use strict;
use warnings;
use Test::More tests => 4;
use Test::Clustericious::Cluster;

Test::Clustericious::Cluster->extract_data_section;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Foo Foo Bar Baz ));
my $t = $cluster->t;

subtest isa => sub {
  plan tests => 6;
  isa_ok $cluster->apps->[0]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[1]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[2]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[2]->client, 'Bar::Client';
  isa_ok $cluster->apps->[3]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[3]->client, 'Baz::Client';
};

note "url[0] = @{[ $cluster->apps->[0]->client->config->url ]}";
note "url[1] = @{[ $cluster->apps->[1]->client->config->url ]}";
note "url[2] = @{[ $cluster->apps->[2]->client->config->url ]}";

subtest 'sans client class' => sub {
  plan tests => 6;

  $t->get_ok("@{[ $cluster->urls->[0] ]}/status")
    ->status_is(200)
    ->json_is('/server_version', '1.23');

  note $t->tx->res->to_string;

  my $client = $cluster->apps->[0]->client;
  is $client->status->{server_version}, '1.23';
  
  is $cluster->apps->[0]->client->config->index, 0;
  is $cluster->apps->[1]->client->config->index, 1;

};

subtest 'with client class' => sub {
  plan tests => 4;

  $t->get_ok("@{[ $cluster->urls->[2] ]}/status")
    ->status_is(200)
    ->json_is('/server_version', '4.56');

  note $t->tx->res->to_string;
 
  my $client = $cluster->apps->[2]->client;
  is $client->status->{server_version}, '4.56';
};

__DATA__

@@ etc/Foo.conf
---
url: <%= cluster->url %>
index: <%= cluster->index %>


@@ lib/Foo.pm
package Foo;

our $VERSION = '1.23';

use strict;
use warnings;
use base qw( Clustericious::App );

1;



@@ etc/Bar.conf
---
url: <%= cluster->url %>


@@ lib/Bar.pm
package Bar;

our $VERSION = '4.56';

use strict;
use warnings;
use base qw( Clustericious::App );

1;


@@ lib/Bar/Client.pm
package Bar::Client;

use strict;
use warnings;
use Clustericious::Client;

1;


@@ etc/Baz.conf
---
url: <%= cluster->url %>


@@ lib/Baz.pm
package Baz;

our $VERSION = '7.89';

use strict;
use warnings;
use base qw( Clustericious::App );

package Baz::Client;

use Clustericious::Client;

1;
