
use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use Dash::Html::ComponentsFunctions;

my $div = Div( id => 'my-div' );

isa_ok( $div, 'Dash::Html::Components::Div' );
isa_ok( $div, 'Dash::BaseComponent' );

