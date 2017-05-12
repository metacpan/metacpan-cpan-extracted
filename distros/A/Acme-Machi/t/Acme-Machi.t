#!perl -T
use v5.16.2;
use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok( 'Acme::Machi' ) || BAIL_OUT();
}
diag( "Testing Acme::Machi $Acme::Machi::VERSION, Perl $], $^X" );

diag(" Test whether all the methods are defined.");
# -----------------------------------------------------------------------------
DEFINED: {
  my $loli = Acme::Machi->new()
    if ok(defined &Acme::Machi::new, 'Acme::Machi::new is defined');
  can_ok($loli, $_) for qw/named learning affectionate search_file_from/;
}
# -----------------------------------------------------------------------------


diag(" Test functionality of Acme::Machi->new() method");
# -----------------------------------------------------------------------------
METHOD_NEW: {;
  my $loli_first = Acme::Machi->new();
  my $loli_second = Acme::Machi->new('Megu');

  # Initial value check
  #############################################################
  isa_ok($loli_first, 'Acme::Machi');
  isa_ok($loli_second, 'Acme::Machi');
  like($loli_first->name(), qr/\bMachi\b/, 'Default \'Name\' is set');
  like($loli_second->name(), qr/\bMegu\b/, 
    'Constructor can modify \'Name\' instance variable');

  open my $fh, '>', \ my $my_string;
  $loli_first->affectionate($fh);
  ok($my_string =~ qr/starving/, 'Default \'Words\' is set');
  like($loli_second->habit(), qr/[DB]FS/, 'Default \'SRCH_Habit\' is set');
  #############################################################

  # Cannot use instance method to construct object
  #############################################################
  {
    local $@;
    isnt(eval{$loli_first->new(); 1}, 1, 'caller test') 
      && like($@, qr/cannot.+?instance method.+/i, 'Die with a pre-defined error msg');
  }
  #############################################################

  # Cannot change one's habit with undefined key word
  #############################################################
  $loli_second->have_the_habit_of('Smily_Search');
  like($loli_second->habit(), qr/[DB]FS/, 
    'Except for \'DFS\' & \'BFS\', the others are ignored.');
  #############################################################

}
# -----------------------------------------------------------------------------


diag(" Test functionality of affectionate() method");
# -----------------------------------------------------------------------------
METHOD_AFFECTIONATE: {;
  my $loli = Acme::Machi->new();

  # Teach her some good words
  #############################################################
  is($loli->learning( ("I'll read a book for you.",
                       "These are field horsetails!",
                       "Have some barley tea")),
                      1+3,
                      'Test return value of learning funcs'
  );
  #############################################################
  
  open my $fh, '>', \ my $my_string;
  # Apply affectionate() method, check outputs are randomly generated
  #############################################################
  my $applying_4_times = join "",
    map {;
      open  $fh, '>', \ $my_string;
      $loli->affectionate($fh);
      $my_string;
  } (1 .. 40);
  isnt($applying_4_times, $my_string x 40, 
    'check randomness on results of affectionate() method'
  );
  #############################################################

  # Chnaging speaker test
  #############################################################
  {
    $loli->named('Megu');
    open  $fh, '>', \ $my_string;
    $loli->affectionate($fh);
    $my_string =~ qr/\A(.+)?:/u;
    is($1,$loli->name(),'Speaker changing test');
  }
  #############################################################
 
}
# -----------------------------------------------------------------------------

diag(" Test functionality of search_file_from() method");
# -----------------------------------------------------------------------------
METHOD_SEARCH_FILE_FROM: {;
  # Search using DFS & BFS should produce the same result.
  #############################################################
  my $loli = Acme::Machi->new();
  $loli->have_the_habit_of('DFS');
  my $result_DFS = $loli->search_file_from((<*>)[0],'.',1);
  $loli->have_the_habit_of('BFS');
  my $result_BFS = $loli->search_file_from((<*>)[0],'.',1);
  ok($result_DFS == $result_BFS, "Stable test");
  #############################################################


  # Produced Tree-like structures should be the same whichever 
  # method you chose to use.
  #############################################################
  open my $fh, '>', \ my $my_string;
  select $fh;
  my $data;

  $loli->have_the_habit_of('DFS');
  $loli->search_file_from((<*>)[0],'.',0);
  $result_DFS = $my_string;
  eval "$result_DFS";
  $result_DFS = $data;

  open $fh, '>', \ $my_string;
  select $fh;
  $loli->have_the_habit_of('BFS');
  $loli->search_file_from((<*>)[0],'.',0);
  $result_BFS = $my_string;
  eval "$result_BFS";
  $result_BFS = $data;
  select STDOUT;

  sub cmp  {
    my $hash_ref1 = $_[0];
    my $hash_ref2 = $_[1];
    foreach my $k (sort keys %$hash_ref1){
      if (ref $$hash_ref1{$k} eq ref {}){ 
        &cmp($$hash_ref1{$k}, $$hash_ref2{$k});
      } elsif (ref $$hash_ref1{$k} eq ref []){ #array
        if($#{$$hash_ref2{$k}} >0){
          (${$$hash_ref2{$k}}[$_] ne ${$$hash_ref2{$k}}[$_]) 
            && (return) for (0 .. $#{$$hash_ref2{$k}});
        }
      } elsif (ref $$hash_ref1{$k} eq ref \undef){ #scalar
        (${$$hash_ref2{$k}} ne ${$$hash_ref2{$k}}) && (return);
      } else {
        if(defined($$hash_ref2{$k})){
          ($$hash_ref2{$k} ne $$hash_ref2{$k}) && (return);
        }
      }
    }
    1;
  }

#-------- sub reference ver. ------------------------------------
#  my $cmp = sub {
#    my $hash_ref1 = $_[0];
#    my $hash_ref2 = $_[1];
#    foreach my $k (sort keys %$hash_ref1){
#      if (ref $$hash_ref1{$k} eq ref {}){ 
#        __SUB__->($$hash_ref1{$k}, $$hash_ref2{$k});
#      } elsif (ref $$hash_ref1{$k} eq ref []){ #array
#        if($#{$$hash_ref2{$k}} >0){
#          (${$$hash_ref2{$k}}[$_] ne ${$$hash_ref2{$k}}[$_]) 
#            && (return) for (0 .. $#{$$hash_ref2{$k}});
#        }
#      } elsif (ref $$hash_ref1{$k} eq ref \undef){ #scalar
#        (${$$hash_ref2{$k}} ne ${$$hash_ref2{$k}}) && (return);
#      } else {
#        if(defined($$hash_ref2{$k})){
#          ($$hash_ref2{$k} ne $$hash_ref2{$k}) && (return);
#        }
#      }
#    }
#    1;
#  };
#-------- sub reference ver. ------------------------------------

  &cmp($$result_DFS,$$result_BFS);
  ok(&cmp,'Compare two data structures!');
  
  #############################################################
}
# -----------------------------------------------------------------------------
done_testing();
