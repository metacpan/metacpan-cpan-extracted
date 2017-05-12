use strict;
use warnings;
use Test::More tests => 8;

use_ok('Catalyst::Helper::View::Xslate');
can_ok('Catalyst::Helper::View::Xslate', qw(mk_compclass) );

my $string = 'path=.,..,root cache=2 header=foo.tx function=a=>sub{},b=>sub{} bridge=TT2Like';
my @args = split /\s+/, $string;

my $res = Catalyst::Helper::View::Xslate::_parse_args(@args);

is_deeply($res, 
          {
              path   => [ qw(. .. root) ],
              header => ['foo.tx'],
              function => { data => 'a=>sub{},b=>sub{}' },
              module => [ 'Text::Xslate::Bridge::TT2Like' ],
              cache => 2,
          }, 'arguments parsed correctly'
);

$res = Catalyst::Helper::View::Xslate::_build_strings($res);

is($res->{path}, $/ . "    default => sub { [ '.', '..', 'root' ] }" . $/,
   'path string rendered properly'
);

is($res->{header}, $/ . "    default => sub { [ 'foo.tx' ] }" . $/,
   'header string rendered properly'
);

is($res->{cache}, " default => '2' ",
   'cache string rendered properly'
);

is($res->{function}, $/ . "    default => sub { { a=>sub{},b=>sub{} } }" . $/,
   'function string rendered properly'
);

is($res->{module}, "$/    default => sub { [ 'Text::Xslate::Bridge::TT2Like' ] }$/");

