use strict;
use warnings;

use App::Lorem::Tickit::TextWidget;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $widget = App::Lorem::Tickit::TextWidget->new;
isa_ok($widget, 'App::Lorem::Tickit::TextWidget');
