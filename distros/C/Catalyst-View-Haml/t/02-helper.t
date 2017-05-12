use strict;
use warnings;
use Test::More tests => 6;

use_ok('Catalyst::Helper::View::Haml');
can_ok('Catalyst::Helper::View::Haml', qw(mk_compclass) );

my $string = 'path=.,..,root vars_as_subs=1 format=html5';
my @args = split /\s+/, $string;

my $res = Catalyst::Helper::View::Haml::_parse_args(@args);

is_deeply($res, 
          {
              path   => [ qw(. .. root) ],
              vars_as_subs => 1,
              format       => 'html5',
          }, 'arguments parsed correctly'
);

$res = Catalyst::Helper::View::Haml::_build_strings($res);

is($res->{path}, $/ . "    default => sub { [ '.', '..', 'root' ] }" . $/,
   'path string rendered properly'
);

is($res->{vars_as_subs}, " default => '1' ",
   'vars_as_subs string rendered properly'
);

is($res->{format}, " default => 'html5' ",
   'format string rendered properly'
);
