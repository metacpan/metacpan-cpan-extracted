#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::CheckButton;

my $root = mk_window;

my $active;
my $button = Tickit::Widget::CheckButton->new(
   label => "Check button",
   on_toggle => sub { ( undef, $active ) = @_ },
);

is( $button->label, "Check button", '$button->label' );
ok( !$button->is_active, '$button->is_active false initially' );

$button->set_window( $root );

flush_tickit;

is_display( [ [TEXT("[ ]",fg=>15,b=>1), BLANK(2), TEXT("Check button")] ],
            'Display initially' );

pressmouse( press => 1, 0, 7 );

flush_tickit;

is_display( [ [TEXT("[X]",fg=>15,b=>1), BLANK(2), TEXT("Check button",b=>1)] ],
            'Display after click' );

ok( $button->is_active, '$button->is_active true after click' );
ok( $active, 'on_toggle invoked after click' );

pressmouse( press => 1, 0, 7 );

flush_tickit;

is_display( [ [TEXT("[ ]",fg=>15,b=>1), BLANK(2), TEXT("Check button")] ],
            'Display after second click' );

ok( !$button->is_active, '$button->is_active true after second click' );
ok( !$active, 'on_toggle invoked after second click' );

done_testing;
