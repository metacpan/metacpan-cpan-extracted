use strict;
use warnings;

use App::Lorem::Tickit::TextWidget;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Lorem::Tickit::TextWidget::VERSION, 0.01, 'Version.');
