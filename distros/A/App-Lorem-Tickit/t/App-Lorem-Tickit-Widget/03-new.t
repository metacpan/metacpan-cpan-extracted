use strict;
use warnings;

use App::Lorem::Tickit::Widget;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $widget = App::Lorem::Tickit::Widget->new('version' => '0.01');
isa_ok($widget, 'App::Lorem::Tickit::Widget');
isa_ok($widget->{'_choice'}, 'Tickit::Widget::Choice');
isa_ok($widget->{'_scrollbox'}, 'Tickit::Widget::ScrollBox');
isa_ok($widget->{'_text_widget'}, 'App::Lorem::Tickit::TextWidget');
is($widget->{'_choice'}->chosen_value, 'paragraphs', 'Default generator.');
is($widget->{'_counts'}->{'paragraphs'}, 3, 'Default paragraph count.');
is($widget->{'_counts'}->{'sentences'}, 8, 'Default sentence count.');
is($widget->{'_counts'}->{'words'}, 50, 'Default word count.');

# Test.
$widget->_next_choice;
is($widget->{'_choice'}->chosen_value, 'sentences', 'Choice changed to sentences.');

# Test.
$widget->_next_choice;
is($widget->{'_choice'}->chosen_value, 'words', 'Choice changed to words.');

# Test.
$widget->_change_count(1);
is($widget->{'_counts'}->{'words'}, 51, 'Word count increased.');
