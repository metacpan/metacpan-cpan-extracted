use strict;
use warnings;
use utf8;

use Test::More   tests => 14;
use Test::Exception;
use Test::Files;

use Csound::Composition;
use Csound::Instrument;

my $composition = Csound::Composition->new();

my $tempo = $composition->t(90);

isa_ok($composition, 'Csound::Composition', 'composition is a Csound::Composition');

my $instr_1 = Csound::Instrument -> new({definition =>'
  asig oscili 5000, i_freq, @FUNCTABLE(10, 8192, 1, 0.8, 0.6, 0.4)
  outs asig, asig
'});
my $instr_2 = Csound::Instrument -> new({
    composition=>$composition,
    no_note=>1,
    definition=>'

  asig oscili 2000, 440, @FUNCTABLE(10, 4096, 1)
  outs asig, asig
    
'});

isa_ok($instr_1, 'Csound::Instrument', 'isntr_1 is a Csound::Instrument');
isa_ok($instr_2, 'Csound::Instrument', 'isntr_1 is a Csound::Instrument');

is(scalar keys %{$composition->{score}->{orchestra}->{instruments}}, 0, "No instruments in orchestra");


my $t = 0;                                              is(scalar @{$composition->{score}->{i_stmts}}, 0, "nof i_stmts: 0");
$composition->play($instr_1, $t++ * 0.25, 0.25, 'c6' ); is(scalar @{$composition->{score}->{i_stmts}}, 1, "nof i_stmts: 1"); is(scalar keys %{$composition->{orchestra}->{instruments}}, 1, "One instrument in orchestra");
$composition->play($instr_1, $t++ * 0.25, 0.25, 'c♯6');                                                                      is(scalar keys %{$composition->{orchestra}->{instruments}}, 1, "One instrument in orchestra");
$composition->play($instr_1, $t++ * 0.25, 0.25, 'd6' );
$composition->play($instr_1, $t++ * 0.25, 0.25, 'e♭6');
$composition->play($instr_1, $t++ * 0.25, 0.25, 'e6' );
$composition->play($instr_1, $t++ * 0.25, 0.25, 'f6' );
$composition->play($instr_1, $t++ * 0.25, 0.25, 'g♭6');
$tempo->tempo($t, 120);
$composition->play($instr_1, $t++ * 0.25, 0.25, 'g6' );
$composition->play($instr_1, $t++ * 0.25, 0.25, 'g♯6');
$composition->play($instr_1, $t++ * 0.25, 0.25, 'a6' );
$composition->play($instr_1, $t++ * 0.25, 0.25, 'b6' );
$composition->play($instr_1, $t++ * 0.25, 0.25, 'c7' ); is(scalar @{$composition->{score}->{i_stmts}}, 12, "nof i_stmts: 12");



throws_ok
   { $composition->play($instr_1, 999, 999, 'NoNote') } 
   qr /instrument plays a note, but NoNote is none/,
   '$instrument must play a note';

throws_ok
   { $composition->play($instr_1, 999, 999) } 
   qr /instrument plays a note, but none was given/,
   '$instrument must play a note';

# $composition->play($instr_2, 0, 1);
# $composition->play($instr_2, 2, 1);
$instr_2->play(0, 1);
$instr_2->play(2, 1);
is(scalar keys %{$composition->{orchestra}->{instruments}}, 2, "Two instruments in orchestra");


$composition->write('t/005-Composition-gotten');

compare_ok('t/005-Composition-gotten.orc', 't/005-Composition-expected.orc', '005-Composition-*.orc should be equal');
compare_ok('t/005-Composition-gotten.sco', 't/005-Composition-expected.sco', '005-Composition-*.sco should be equal');
