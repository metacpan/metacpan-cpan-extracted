
use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use Dash::Html::Components;

my $div = Dash::Html::Components->Div( id => 'my-div' );

isa_ok( $div, 'Dash::Html::Components::Div' );
isa_ok( $div, 'Dash::BaseComponent' );

