use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 5;
use Clustericious::Config;

create_config_ok Foo => <<'EOF';
---
something : {
      hello : there,
      this : is,
      some : yaml,
      and : this,
      is : another,
      element : bye,
}
four : {
      <%= "score" =%> : and,
      seven : [ "years", "ago" ],
}
EOF

my $c = Clustericious::Config->new('Foo');

ok defined( $c->something );
is $c->something->hello,   'there', 'yaml key';
is $c->something->element, 'bye',   'yaml key';
is_deeply [ $c->four->seven ], [qw/years ago/], 'array';
