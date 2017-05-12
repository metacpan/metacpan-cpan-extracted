use strict;
use lib "../lib";
use Test::More tests => 3;

BEGIN { use_ok 'App::mgen' }

@ARGV = qw/Application::Module/;

my $mgen = App::mgen->new;
isa_ok $mgen, 'App::mgen';

my @method = qw/generate/;

can_ok $mgen, @method;
