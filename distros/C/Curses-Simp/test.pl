#!/usr/bin/perl -w
# 37K2jPD - test.pl created by Pip@CPAN.Org to validate Curses::Simp functionality. This test.pl mimics that of Term::Screen by Mark Kaehny.
#   Before `make install' is performed this script should be run with `make test'. After `make install' it should work as `perl test.pl'.
use Test; BEGIN { plan tests => 1 }
use Curses::Simp;            ok(1);
my @text; my $simp = tie(@text, 'Curses::Simp', 'flagaudr' => 0);
push(@text, 'Test series for Simp.pm module for perl5');                                  # test                      output
$simp->Prnt('ycrs' => 2, 'xcrs' => 3, '1. Should be at row 2 col 3 (upper left is 0,0)'); # test cursor   movement && output  together
my $rowe = $simp->YCrs(); my $colm = $simp->XCrs();
$simp->Prnt('ycrs' => 3, 'xcrs' => 0, "2. Last position $rowe $colm -- should be 2 50."); # test current  position    update
$simp->Prnt('ycrs' => 4, 'xcrs' => 0, "3. Screen size: " . $simp->Hite() . " rows and " .
                                                           $simp->Widt() . " columns." ); # test rows     && cols
$simp->Move(6, 0); $simp->Prnt('4. Testing reverse');                                     # test standout && normal   text    #       no more reverse
$simp->Prnt('fclr' => 'wwwwwwwWWWWwwwwwww',                                               # bold is done with uc() in Curses::Simp
                      ' mode, bold mode, ');
$simp->Prnt(#'fclr' => 'bWWWWWWWWwwwwwwwww',                                                                                  # still no      reverse though
                      'and both together.');
my $line = "0---------10--------20--------30--------40--------50--------60--------70------- "; # test clreol ... so first put some stuff up
$simp->Prnt('ycrs' => 7, 'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b', '5. Testing clreol - ' . 
                                       '   The next 2 lines should end at col 20 and 30.');
for( 8..10){ $simp->Prnt('ycrs' => $_,  'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b', $line); }
substr($text[8], 20, length($line) - 20, '');
substr($text[9], 30, length($line) - 30, ''); $simp->Draw();
for(11..20){ $simp->Prnt('ycrs' => $_,  'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b', $line); }   # test clreos
$simp->Prnt('ycrs' => 11, 'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b',
                                   '6. Clreos - Hit a key to clear all right and below:');
$simp->Prnt($simp->GetK(31));
substr($text[$simp->YCrs()], $simp->XCrs(), length($text[$simp->YCrs()]) - $simp->XCrs(), '');
while(@text > ($simp->YCrs() + 1)){ splice(@text, $simp->YCrs() + 1, 1); } $simp->Draw();
$simp->Prnt('ycrs' => 12, 'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b',                           # test insert line and delete line
            '7. Test insert and delete line - 15 deleted, and ...');
for(13..16){ $simp->Prnt('ycrs' => $_,  'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b',
                                   $_ . substr($line, 2)); }
splice(@text, 15, 1);                                                                          # delete line
splice(@text, 14, 0, '... this is where line 14 was');                     $simp->Draw();      # insert line
$simp->Prnt('ycrs' => 18,  'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b',                          # test key_pressed
            "8. Key_pressed - Don't Hit a key in the next  5 seconds: ");
if($simp->GetK( 5) ne '-1'){ $simp->Prnt('HEY A KEY WAS HIT' ); }
else                       { $simp->Prnt('GOOD - NO KEY HIT!'); }
$simp->Prnt('ycrs' => 19,  'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b', 
                                   'Hit a key in the next 15 seconds: ');
if($simp->GetK(15) ne '-1'){ $simp->Prnt(          'KEY HIT!'); }
else                       { $simp->Prnt(       'NO KEY HIT' ); }
$simp->GetK() for(0..127);                                                                     # test getch ... clear buffer out
$simp->Prnt('ycrs' => 21,  'xcrs' => 0, 'fclr' => 'w', 'bclr' => 'b',
                     'Testing getch, Enter Key (q to quit): ');
$simp->Move(21, 40); my $char = '';
while(($char = $simp->GetK(31)) ne 'q' && $char ne '-1'){ $text[21] = substr($text[8], 0, 50);
  if(length($char) == 1){ $simp->Prnt('ycrs' => 21,  'xcrs' => 50, 'fclr' => 'w', 'bclr' => 'b', 'ord of char is: ' . ord($char) . '    '); }
  else                  { $simp->Prnt('ycrs' => 21,  'xcrs' => 50, 'fclr' => 'w', 'bclr' => 'b', "function value: $char   "              ); }
  $simp->Move(21, 40);
} $simp->Move(22,  0);
