#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::VBox;
use Tickit::Widget::RadioButton;

my $root = mk_window;

push my @buttons, Tickit::Widget::RadioButton->new(
   label => "Radio 1",
   value => 1,
);

push @buttons, Tickit::Widget::RadioButton->new(
   label => "Radio $_",
   value => $_,
   group => $buttons[0]->group
) for 2 .. 4;

my $radio2_active;
$buttons[1]->set_on_toggle(
   sub { ( undef, $radio2_active ) = @_ }
);

my $active_value;
$buttons[0]->group->set_on_changed(
   sub { ( undef, $active_value ) = @_ }
);

is( $buttons[2]->label, "Radio 3", '$button->label' );

my $vbox = Tickit::Widget::VBox->new;
$vbox->add( $_ ) for @buttons;

$vbox->set_window( $root );

flush_tickit;

is_display( [ [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 1")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 2")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 3")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 4")] ],
            'Display initially' );

ok( !$radio2_active, '$radio2_active false initially' );

pressmouse( press => 1, 1, 10 );

flush_tickit;

is_display( [ [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 1")],
              [TEXT("(*)",fg=>15,b=>1), BLANK(2), TEXT("Radio 2",b=>1)],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 3")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 4")] ],
            'Display after click 2' );

ok( $buttons[1]->is_active, 'Radio 2 is active' );
ok( $radio2_active, '$radio2_active after click 2' );
is( $active_value, 2, 'active ->value is 2 after click 2' );

pressmouse( press => 1, 3, 10 );

flush_tickit;

is_display( [ [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 1")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 2")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 3")],
              [TEXT("(*)",fg=>15,b=>1), BLANK(2), TEXT("Radio 4",b=>1)] ],
            'Display after click 4' );

ok( !$buttons[1]->is_active, 'Radio 2 no longer active' );
ok( $buttons[3]->is_active, 'Radio 4 is active' );
ok( !$radio2_active, '$radio2_active false after click 4' );
is( $active_value, 4, 'active ->value is 4 after click 4' );

$buttons[0]->set_label( "First radio" );

flush_tickit;

is_display( [ [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("First radio")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 2")],
              [TEXT("( )",fg=>15,b=>1), BLANK(2), TEXT("Radio 3")],
              [TEXT("(*)",fg=>15,b=>1), BLANK(2), TEXT("Radio 4",b=>1)] ],
            'Display after ->set_label' );

{
   my $button = Tickit::Widget::RadioButton->new(
      fg => 3,
      u  => 1,
   );

   is_deeply( { $button->pen->getattrs },
              { fg => 3, u => 1 },
              'Constructor pen attributes still sets widget pen' );
}

done_testing;
