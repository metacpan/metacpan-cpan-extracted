use strict;
use Test::More;    # tests => 20;
use Test::Exception;

#use Mock::Quick;
use Bot::ChatBots::Telegram::Keyboard qw< keyboard >;

# forbid empty keyboards
for my $in ([], [[]]) {
   throws_ok { keyboard(@$in) } qr{no input keyboard};
}

my $input = [
   [               # first row of the keyboard
      {
         text   => "Happyness",     # shown in the button
         _value => '/happyness',    # substituted upon call
      },
      {
         text   => "+1",               # shown in the button
         _value => '/happyness +1',    # substituted upon call
      },
      {
         text   => "+2",               # shown in the button
         _value => '/happyness +2',    # substituted upon call
      },
      {
         text   => "+3",               # shown in the button
         _value => '/happyness +3',    # substituted upon call
      },
   ],
   [    # second row of the keyboard. Note that the second, third
          # and fourth button hold the same labels as in the first
          # row... which can be problematic because the label is
          # what Telegram clients send back when the button is hit
      {
         text   => "Relax",     # shown in the button
         _value => '/relax',    # substituted upon call
      },
      {
         text   => "+1",           # shown in the button
         _value => '/relax +1',    # substituted upon call
      },
      {
         text   => "+2",           # shown in the button
         _value => '/relax +2',    # substituted upon call
      },
      {
         text   => "+3",           # shown in the button
         _value => '/relax +3',    # substituted upon call
      },
   ],
   [
      {
         text             => 'Location',    # shown in the button
         request_location => \1,            # flag for Telegram
      },
      {
         text   => 'Help',                  # shown in the button
         _value => '/help',                 # substituted upon call
      }
   ],
];

my $keyboard;
lives_ok { $keyboard = keyboard(keyboard => $input, id => 9) }
'keyboard() lives';

isa_ok $keyboard, 'Bot::ChatBots::Telegram::Keyboard';
is $keyboard->id, 9, 'id set correctly';

my $displayable;
lives_ok { $displayable = $keyboard->displayable } 'displayable() lives';
isa_ok $displayable, 'ARRAY';
is scalar(@$displayable), 3, 'number of rows in the keyboard';
is $displayable->[2][0]{text}, 'Location', 'no change when no _value';
like $displayable->[0][0]{text}, qr{Happyness},
  'text in a button was preserved';

is $input->[0][1]{text}, $input->[1][1]{text}, 'inputs are same...';
isnt $displayable->[0][1]{text}, $displayable->[1][1]{text},
  '... displayable differ';

my $command;
my $input_text    = $displayable->[1][2]{text};
my $input_payload = {text => $input_text};
my $input_record  = {payload => $input_payload};
for my $in ($input_text, $input_payload, $input_record) {
   my $command;
   lives_ok { $command = $keyboard->get_value($in) } 'get_value() lives';
   is $command, '/relax +2', 'command was resolved right';

   my $id;
   lives_ok { $id = $keyboard->get_keyboard_id($in) }
   'get_keyboard_id lives';
   is $id, 9, 'retrieved id is correct';
} ## end for my $in ($input_text...)

for my $in (
   undef, '', 'whatever', {},
   {text    => undef},
   {what    => 'ever'},
   {payload => {}}
  )
{
   my $command;
   lives_ok { $command = $keyboard->get_value($in) } 'get_value() lives';
   is $command, undef, 'no command resulted in undef';
} ## end for my $in (undef, '', ...)

done_testing();
