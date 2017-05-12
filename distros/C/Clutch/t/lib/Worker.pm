package Worker;
use strict;
use warnings;
use Clutch::Worker;
use Test::More;
use Data::Dumper;

register_function(
    'function_name' => sub {
        my $args = shift;
        my $res = +{response => $args};
        note $res;
        $res;
    }
);

register_function(
    'function_rand' => sub {
        my $args = shift;
        my $sleep = int(rand(3));
        note explain +{pid => $$, sleep => $sleep, args => $args};
        sleep($sleep);
        my $res = +{response => $args};
        note explain $res;
        $res;
    }
);

register_function(
    'foo' => sub {
        my $args = shift;
        note 'execute';
        return;
    }
);

register_function(
    'cascade_root' => sub {
        my $args = shift;
        my $res = cascade('cascade_sub', $args);
        return $res;
    }
);

register_function(
    'cascade_sub' => sub {
        my $args = shift;
        return 'cascaded';
    }
);

1;

