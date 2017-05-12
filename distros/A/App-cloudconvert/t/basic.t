use strict;
use Test::More;
use App::cloudconvert;

my $app = App::cloudconvert->new( apikey => 123 );
isa_ok $app, 'App::cloudconvert';

done_testing;
