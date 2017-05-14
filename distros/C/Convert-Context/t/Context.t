#!/usr/bin/perl
#
# $Id: Context.t,v 1.23 1998/10/03 21:41:07 martin Exp $
#
# Testfile for Convert::Context
#
# Quite reliable, but not yet really systematically.
#

use Convert::Context;
use strict;

my @test = ( 
   ["test_acmp",     "acmp"],
   ["test_append",   "append"], 
   ["test_attrib",   "attrib"], 
   ["test_charsize", "charsize"], 
   ["test_chunks",   "chunks"], 
   ["test_clone",    "clone"],
   ["test_Ctnew",    "new"],
   ["test_eq_ne",    "eq, ne"],
   ["test_index",    "index"],
   ["test_join",     "join"],
   ["test_lc_uc",    "lc, uc"],
   ["test_length",   "length"],
   ["test_replace",  "replace"], 
   ["test_rindex",   "rindex"],
   ["test_split",    "split"],
   ["test_substr",   "substr"],
   ["test_text",     "text"],
   ["test_tr",       "tr, y"],
   ["test_xcfirst",  "lcfirst, ucfirst"],
);

print "1.." . ($#test+1) . "\n";
print STDERR "\n";

{
   my $max = 0;
   my $len;
   for (0..$#test) { 
      $len = length($test[$_]->[$#{$test[$_]}]);
      $max = $len if $len>$max;
   }
      
   my ($name, $desc);
   my $i=1;
   for (sort {$test[$a]->[$#{$test[$a]}] cmp $test[$b]->[$#{$test[$b]}]} 
        0..$#test
   ) {
      ($name, $desc) = @{$test[$_]};
      $desc = $name if !defined $desc;
      _out($max, $i, $desc); 
      test ($i++, eval "&$name($_, \"$name\")");
   }
}

sub new {
   new Convert::Context (@_);
}

sub _out {
   my $max = shift;
   my $t = sprintf "Test %2d: %s ", @_;
   $t .= "." x (9 + 4 + $max - length($t));
   printf STDERR "$t ";
}

sub test {
   my ($number, $status) = @_;
   if ($status) {
      print STDERR "ok\n";
      print "ok $number\n";
   } else {
      print STDERR "failed!\n";
      print "not ok $number\n";
   }
}

##
##
##

sub test_acmp {
#
# Check a new attribute dyadic compare function. Idea: attrib1 shall equal
# attrib2, if (attrib1 cmp attrib2) is less zero.
#
# Note: this would mean especially, that attrib1 equals *not* attrib1.
# I don't suspect anybody really wanting to use such comparison. Therefore
# I left in the code a check: if same references are compared equal (0) is
# returned.
#
   my $CtA = new ( \"", ["A"] );
   my $Cta = new ( \"", ["A"] );
   my $CtB = new ( \"", ["B"] );
   return 0 if $CtA -> ne ($CtA);
   return 0 if $CtA -> ne ($Cta);
   return 0 if $CtA -> eq ($CtB);
   $CtA -> acmp (
      sub { 
         my $q = (0, -1, 1) [1 + (shift cmp shift)]; 
      }
   );
   return 0 if $CtA -> ne ($CtA); # equal, because same reference
   return 0 if $CtA -> eq ($Cta); # not equal, because of new acmp
   return 0 if $CtA -> ne ($CtB);
1}

sub test_append {
   my $Empty = new ();
   my $Plain = new (\"Plain");
   my $Bold  = new (\"bold", [1]);
   return 0 if new()
      -> append ($Empty)
      -> append ($Plain) 
      -> append (" und ", $Bold, $Empty, " beißt sich.")
      -> ne (
         new( \"Plain und bold beißt sich.", [0,1,0], [0,10,14] )
      )
   ; 
1}

sub test_attrib {
   my $hello = "Hello world!";
   my $Ct = new ( \$hello, [0, 1, 3], [0, 6, 11]);

   # (1) $attrib = $Ct -> attrib ($pos)
   return 0 if $Ct -> attrib  ( 0) ne "0";
   return 0 if $Ct -> attrib  ( 5) ne "0";
   return 0 if $Ct -> attrib  ( 6) ne "1";
   return 0 if $Ct -> attrib  (10) ne "1";
   return 0 if $Ct -> attrib  (11) ne "3";
   return 0 if $Ct -> attrib  (12) ne "3";
   return 0 if $Ct -> attrib (100) ne "3";
   return 0 if $Ct -> attrib  (-1) ne "3";
   return 0 if $Ct -> attrib  (-2) ne "1";
   return 0 if $Ct -> attrib  (-6) ne "1";
   return 0 if $Ct -> attrib  (-7) ne "0";
   return 0 if $Ct -> attrib (-12) ne "0";
   return 0 if defined $Ct->attrib(-13);

   # (1a) $attrib = $Ct -> attrib ($pos, [$attrib])
   return 0 if $Ct -> attrib  (11, ["2"]) ne "2";
   return 0 if $Ct -> attrib  (12) ne "2";

   # (2) ([@attrib], [@offset]) = $Ct -> attrib ($pos, $len)
   return 0 if $Ct->substr(0, 6) -> ne (
      new ( \substr(${$Ct->text}, 0, 6) )
   );
   return 0 if $Ct->substr(0, 7) -> eq (
      new ( \substr(${$Ct->text}, 0, 7) )
   );
   return 0 if $Ct->substr(0, 7) -> ne (
      new ( \substr(${$Ct->text}, 0, 7), $Ct->attrib(0, 7) )
   );
   return 0 if $Ct->substr(5, 7) -> ne (
      new ( \substr(${$Ct->text}, 5, 7), $Ct->attrib(5, 7) )
   );

   # (3) $attrib = $Ct -> attrib ($pos, $len, $attrib)
   return 0 if $Ct -> attrib (0, 12, "7") ne "7";
   return 0 if $Ct -> ne (new($Ct->text, [7]));

   # (4) 1||undef = $Ct -> attrib ($o1, $l1, [@attrib], [@offset])
   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11]);
   return 0 if $Ct -> ne (new ( \$hello, [0, 1, 3], [0, 6, 11]));

   # (5) 1||undef = $Ct -> attrib ($o1, $l1, [@attrib], [@offset], $o2, $l2)
   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11], 0, 6);
   return 0 if $Ct -> ne (new ( \$hello ));

   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11], 6, 5);
   return 0 if $Ct -> ne (new ( \$hello, [1] ));
 
   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11], 10, 1234);
   return 0 if $Ct -> ne (new ( \$hello, [1, 3], [0, 1] ));

   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11]);
   return 0 if !$Ct -> attrib (0, 5, [0, 1, 3], [0, 6, 11], 11, 523);
   return 0 if $Ct -> ne (new ( \$hello, [3,0,1,3], [0,5,6,11]));

   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11]);
   return 0 if !$Ct -> attrib (3, 3, [0, 1, 3], [0, 6, 11], 10, 123);
   return 0 if $Ct -> ne (new ( \$hello, [0,1,3,1,3], [0,3,4,6,11]));

   # Strange, but allowed: extending attrib range wider than text range.
   # Normally this will cause trouble, I suppose. Don't use.
   return 0 if !$Ct -> attrib (0, 12, [0, 1, 3], [0, 6, 11]);
   return 0 if !$Ct -> attrib (11, 1, [0, 1, 3], [0, 6, 11], 0, 2345);
   return 0 if $Ct -> ne (new ( \$hello, [0,1,0,1,3], [0,6,11,17,22]));

   # (6) 1||undef = $Ct1 -> attrib ($o1, $l1, $Ct2)
   my $Ct1 = new ( \$hello, [0, 1, 3], [0, 6, 11]);
   my $Ct2 = new (\("Tachchen!"), [2,0,5,0], [0,1,2,6]);
   return 0 if !$Ct1 -> attrib(5, 6, $Ct2);
   return 0 if $Ct1 -> ne (new (\$hello, [0,2,0,5,3], [0,5,6,7,11]));

   return 0 if !$Ct1 -> attrib (0, 12, [0, 1, 3], [0, 6, 11]);
   return 0 if !$Ct1 -> attrib(12, 0, $Ct2);
   return 0 if $Ct1 -> ne (new (\$hello, [0,1,3], [0,6,11]));

   # (7) 1||undef = $Ct1 -> attrib ($o1, $l1, $Ct2 [,$o2, $l2])
   return 0 if !$Ct1 -> attrib (6, 5, $Ct2, 4, 4);
   return 0 if $Ct1 -> ne (new (\$hello, [0,5,0,3], [0,6,8,11]));

   # Strange attrib extending, once more: Makes buggy data!!
   return 0 if !$Ct1 -> attrib (0, 12, [0, 1, 3], [0, 6, 11]);
   return 0 if !$Ct1 -> attrib (6, 5, $Ct2, 1, 6);
   return 0 if $Ct1 -> ne (new (\$hello, [0,5,0,3], [0,7,11,11]));
1}

sub test_charsize {
   my $One       = new (\"G u t e n   T a g ! ", [2,0], [0, 5*2]);
   my $One_Clone = new (\"G u t e n   T a g ! ", [2,0], [0, 5*2]);
   my $Two       = new (2, \"G u t e n   T a g ! ", [2,0], [0, 5]);
   return 0 if $One -> eq ($Two);
   $One -> charsize(2); return 0 if $One -> ne ($Two);
   $Two -> charsize(1); return 0 if $One -> eq ($Two);
   $One -> charsize(1); return 0 if $One -> ne ($Two);
   return 0 if $One -> ne ($One_Clone);
1}

sub test_chunks {
   {
      #
      # Test 1
      #
      my $Ct1 = new (
         [\"Konger", ["b"]],
         [\" tenker mere på slikt enn på "],
         [\"fredens", ["em"]],
         [\" gagnlige sysler; for dem gjelder det mere hvordan de "],
         [\"med lovlige - eller ulovlige - midler kan vinne "],
         [\"nytt land", ["em"]],
         [\", enn hvordan de best kan styre det landet de allerede har."],
      );
      $Ct1 -> replace ( "Konger", "Manager", "g" );
      $Ct1 -> replace ( 'land\w*', "forretning", "g" );
      my $s = "";
      for ( @{$Ct1->chunks()} ) {
         my ($text, $attrib) = @{$_};
         if ($attrib) {
            $s .= "<$attrib>$text</$attrib>";
         } else {
            $s .= "$text";
         }
      }
      my $s2 = 
         "<b>Manager</b> tenker mere på slikt enn på <em>fredens</em> ".
         "gagnlige sysler; for dem gjelder det mere hvordan de med lovlige - ".
         "eller ulovlige - midler kan vinne <em>nytt forretning</em>, enn ".
         "hvordan de best kan styre det forretning de allerede har."
      ;
      if ($s ne $s2) {
         print "'$s'\n'$s2'\n";
      }
      return 0 if $s ne $s2;
   }
1}

sub test_clone {
   my $First = new ( 
      \("Ich hab nur versucht, Misogynie zu erklärn: ".
       "daß sie in allen steckt die gerne größer und stärker wärn."),
      [ 2,  3,  4,  6,  7,  2,  8,  1,  0],
      [ 0,  8, 11, 22, 31, 55, 60, 78, 101]
   );
   return 0 if $First -> ne ($First -> clone);

   my $Second = new (
      5, \"D    a    s         i    s    t         e    s    ", 
      [0, 2, 0], [0, 4, 8]
   );
   return 0 if $Second -> ne ($Second -> clone);
1} 

sub test_eq_ne {
   # tuple arrays
   my $Base                   = new (\"Test!", [2, 4], [0, 2]);
   my $Base_2                 = new (2, \"Test!", [2, 4], [0, 2]);
   my $Identic                = new (\"Test!", [2, 4], [0, 2]);
   my $Identic_2              = new (2, \"Test!", [2, 4], [0, 2]);
   my $Same_Text_And_Attrib   = new (\"Test!", [2, 4], [0, 4]);
   my $Same_Text_And_Offset   = new (\"Test!", [1, 4], [0, 2]);
   my $Same_Attrib_And_Offset = new (\"Test.", [2, 4], [0, 2]);
   my $Same_Text              = new (\"Test!", [1, 4], [0, 3]);
   
   return 0 if $Base -> ne ($Base);
   return 0 if $Base -> ne ($Identic);
   return 0 if $Base -> eq ($Same_Text_And_Attrib);
   return 0 if $Base -> eq ($Same_Text_And_Offset);
   return 0 if $Base -> eq ($Same_Attrib_And_Offset);
   return 0 if $Base -> eq ($Same_Text);

   return 0 if $Base_2 -> eq ($Base);
   return 0 if $Base_2 -> ne ($Identic_2);

   # singular arrays
   $Base                   = new (\"Test!", [2], [0]);
   $Identic                = new (\"Test!", [2], [0]);
   $Same_Text_And_Offset   = new (\"Test!", [1], [0]);
   $Same_Attrib_And_Offset = new (\"Test.", [2], [0]);
   return 0 if $Base -> ne ($Base);
   return 0 if $Base -> ne ($Identic);
   return 0 if $Base -> eq ($Same_Text_And_Offset);
   return 0 if $Base -> eq ($Same_Attrib_And_Offset);
1}

sub test_index {
   my $cl;
   foreach $cl (1..10) {
      my $Ct = new (
         $cl,
         \( join(
               (" " x ($cl-1)) . (" " x $cl), "a".."z"
            ) . (" " x ($cl-1)) . (" " x $cl)
         ),
         [0..7, 0..7], [map $_*2, 0..15]
      );
      my ($pos, $check);
   
      $pos=-1; $check=1;
      while (($pos = $Ct->index(" ", $pos+1)) > 0) {
         return 0 if $pos != $check; $check+=2;
      }
      $check=0;
      for ("a".."z") {
         return 0 if $Ct->index("$_") != $check; $check+=2;
      }
   }
   my $Ct = new (5, \"Aa___A_b__A__c_A___d");
   return 0 if $Ct -> index("a") >= 0;
   return 0 if $Ct -> index("b") >= 0;
   return 0 if $Ct -> index("c") >= 0;
   return 0 if $Ct -> index("d") >= 0;
   return 0 if $Ct -> index("A") <  0;
1}

sub test_join {
   my @list = ("Aber", "hallo", "was", "ist", "denn", "das?");
   my $txt = join("_", @list);
   my $Txt = Convert::Context->join("_", @list);
   return 0 if new(\$txt)->ne($Txt);

   my $Ct1    = new (\"Eins", [1]);
   my $Ct2    = new (\"zwei", [2]);
   my $Ct3    = new (\"drei", [3]);
   my $Fertig = new (\"fertig", ["ATTRIB_FERTIG"]);
   my $Komma  = new (\", ");
   my $Punkt  = new (\".");

   my $Joined = new ( 
      \"Eins, zwei, drei, fertig.",
      [1, 0, 2,  0,  3,  0, "ATTRIB_FERTIG", 0],
      [0, 4, 6, 10, 12, 16, 18,             24]
   );

   my $Ct = Convert::Context 
      -> join ($Komma, $Ct1, $Ct2, $Ct3, $Fertig)
      -> append ($Punkt)
   ;
   return 0 if $Ct -> ne ($Joined);

   $Ct1 -> join ($Komma, $Ct2, $Ct3, $Fertig) 
      -> append ($Punkt)
   ;
   return 0 if $Ct1 -> ne ($Joined);
1}

sub test_lc_uc {
   my $Ct_big   = new (\"LOWERCASE, ASCII ONLY.");
   my $Ct_small = new (\"lowercase, ascii only.");
   return 0 if $Ct_big->lc   -> ne ($Ct_small);
   return 0 if $Ct_small->uc -> ne ($Ct_big);
1}

sub test_xcfirst {
   my $Ct_big   = new (\"Lowercase");
   my $Ct_small = new (\"lowercase");
   return 0 if $Ct_big->lcfirst   -> ne ($Ct_small);
   return 0 if $Ct_small->ucfirst -> ne ($Ct_big);
1}

sub test_length {
   my $Ct = new (\"");
   my $len = 0;
   for ("aa", "bb", "a".."z", "Guten", "Tag") {
      return 0 if $Ct->length != $len;
      $Ct->append($_); 
      $len+=length($_);
   }
1}

sub test_Ctnew {
   my $Empty        = new ();
   my $Plain        = new (\"Plain text.");
   my $Bold         = new (\"Bold text.", [1]);
   my $Mixed_Joined = new (
      [\"This is plain, "],
      [\"bold", [1]],
      [\", "],
      [\"italic", [2]],
      [\" and finally plain again.\n"]
   );
   return 0 if $Mixed_Joined -> ne ( new(
      \"This is plain, bold, italic and finally plain again.\n",
        [0,             1,  0,2,    0],
        [0,             15, 19,21,  27]
   ));
   my $Test = new(3.14, \"Hallo", [1]);
   return 0 if $Test->charsize != 3.14;
1}

sub test_replace {
   my $str = "Wer das Geld hat hat die Macht.\n".
      "Wer die Macht hat hat das Recht."
   ;
   my $Ct = new (
      [\"Wer das "		],
      [\"Geld",	["G"]		],
      [\" hat hat die "	],
      [\"Macht",	["M"]	],
      [\".\nWer die "		],
      [\"Macht",	["M"]	],
      [\" hat hat das "	],
      [\"Recht",	["R"]	],
      [\"."]
   );
   my $kriegt = new(\"kriegt", ["k"]);
   my $nkriegt = new(\"kriegt", ["nk"]);

   $Ct -> replace ("Macht", "Fracht");
   $str =~ s/Macht/Fracht/;
   return 0 if (${$Ct->text} ne $str);
   
   $Ct -> replace ("hat", "kriegt", "g");
   $str =~ s/hat/kriegt/g;
   return 0 if (${$Ct->text} ne $str);

   $Ct -> replace ("hat", "kriegt", "g");
   $str =~ s/hat/kriegt/g;
   return 0 if (${$Ct->text} ne $str);

   $Ct -> replace ("kriegt kriegt", new()->append("hat ", $kriegt), "g");
   $str =~ s/kriegt kriegt/hat kriegt/g;
   return 0 if (${$Ct->text} ne $str);

   $Ct -> replace ($nkriegt, "will", "g");
   return 0 if (${$Ct->text} ne $str);

   $Ct -> replace ($kriegt, "will", "g");
   $str =~ s/kriegt/will/g;
   return 0 if (${$Ct->text} ne $str);
   return 0 if $Ct->substr(17, 4)->ne (new(\("will"), ["k"]));

   $Ct -> replace (new(\"will", ["k"]), new(\("will")));
   return 0 if $Ct->substr(17, 4)->ne (new(\"will", [0]));

   $Ct -> replace ("die", new(\"die", [1]), "g");
   return 0 if $Ct->substr(17, 4)->ne (new(\"will", [0]));

   $Ct -> replace ("r", \&_replace_mark , "ig");

   $Ct -> replace (new(\"will", ["k"]), new(\"kriegt"), "g");

   return 0 if $Ct -> ne(new(
      \("Wer das Geld hat will die Fracht.\n".
        "Wer die Macht hat kriegt das Recht."
      ),
      [qw(0 1 0 G 0 1 0 M - M 0 1 0 1 0 M 0 - R 0 )], 
      [qw(0 2 3 8 12 22 25 26 27 28 32 36 37 38 41 42 47 63 64 68)]
   ));

   $Ct = new (
      [\"Wer das "		],
      [\"Geld",	["G"]		],
      [\" hat hat "		],
      [\"die", [1]	        ],
      [\" "			],
      [\"Macht",	["M"]	],
      [\".\nWer "		],
      [\"die", [2]		],
      [\" "			],
      [\"Macht",	["m"]	],
      [\" hat hat das "	],
      [\"Recht",	["R"]	],
      [\"."]
   );
   $Ct->replace( 
      [new(\"Geld", ["G"]), new(\"i",[1]), "kriegt",            "hat", "We"], 
      [new(\"Dleg", ["D"]), "()",          new(\"tgeirk", [2]), "tah", "eW"], 
      "g" 
   );
   return 0 if $Ct -> ne(new(
      \"eWr das Dleg tah tah d()e Macht.\neWr die Macht tah tah das Recht.",
      [qw(0 D 0 1 0 M 0 2 0 m 0 R 0)],
      [qw(0 8 12 21 25 26 31 37 40 41 46 59 64)]
   ));

   my $Ct2 = new (
      2, \"R h a b a r b e r ,   R a b a r b e r ! ", [0,1,0],[0,11,19]
   );
   for (0..2) {
      $Ct2->replace("a", "o ", "g");
      return 0 if $Ct2 -> ne ( new(
         2, \"R h o b o r b e r ,   R o b o r b e r ! ", [0,1,0],[0,11,19]
      ));
      $Ct2->replace("o", "a ", "g");
      return 0 if $Ct2 -> ne ( new(
         2, \"R h a b a r b e r ,   R a b a r b e r ! ", [0,1,0],[0,11,19]
      ));
   }
   $Ct2 -> replace ("a b a r b e r ", new(2, \"o s e ", [1]), "g");
   $Ct2 -> replace ("o s e ", "a b a ", "g");
   $Ct2 -> replace ("a b a ", "a b a r b e r ", "g");
   return 0 if $Ct2 -> ne ( new(
      2, \"R h a b a r b e r ,   R a b a r b e r ! ", 
      [0,1,0,1,0], [0,2,9,11,19]
   ));
1}

sub _replace_mark {
   my ($match, $Ct, $pos) = @_;
   if ($Ct->attrib($pos) eq "0") {
      new(\"$match", [1]);
   } else {
      new(\"$match", ["-"]);
   }
}

sub test_rindex {
   my $cl;
   foreach $cl (1..5) {
      my $Ct = new (
         $cl,
         \( join(
               (" " x ($cl-1)) . (" " x $cl), "a".."z"
            ) . (" " x ($cl-1)) . (" " x $cl)
         ),
         [0..7, 0..7], [map $_*2, 0..15]
      );
      my ($pos, $check);
   
      $pos=$Ct->length(); $check=51;
      while (($pos = $Ct->rindex(" ", $pos-1)) >= 0) {
         return 0 if $pos != $check; $check-=2;
      }
   
      $check=50;
      for (reverse("a".."z")) {
         $pos = $Ct->rindex("$_");
         return 0 if $pos != $check; $check-=2;
      }
   }
1}

sub test_split {
   my $text = 
      "		Das  ist ein Text	mit Tabs,    Spaces und\n".
      "so anderem      		    Whitespace   !   \n\n\n   "
   ;
   return 0 if 
      new (\join("_", split(/\s+/, $text))) 
      -> ne (
         Convert::Context -> join("_", new (\$text) -> split('\s+'))
      )
   ;
   my $Ct = new (
      2, 
      \"E i n   T e s t   i s t   d a s . ",
      [0,1,0,2,0], [0,4,8,13,16]
   );
   return 0 if $Ct -> ne (
      Convert::Context -> join(new(2, \"  "), $Ct->split('\s'))
   );
   return 0 if $Ct -> ne (
      Convert::Context -> join(new(1, \"  "), $Ct->split('\s'))
   );
1}

sub test_substr {
   my $Ct = new (
      [\"This is plain, "],
      [\"bold", [1]],
      [\", "],
      [\"italic", [2]],
      [\" and plain again.\n"]
   );
   return 0 if $Ct -> substr (  0, 15) -> ne (new (\"This is plain, "));
   return 0 if $Ct -> substr ( 15,  4) -> ne (new (\"bold", [1]));
   return 0 if $Ct -> substr ( 19,  2) -> ne (new (\", "));
   return 0 if $Ct -> substr ( 21,  6) -> ne (new (\"italic", [2]));
   return 0 if $Ct -> substr ( 27, 18) -> ne (new (\" and plain again.\n"));

   return 0 if $Ct -> substr ( 27)     -> ne (new (\" and plain again.\n"));
   return 0 if $Ct -> substr (-18, 18) -> ne (new (\" and plain again.\n"));
   return 0 if defined ($Ct -> substr (- $Ct->length() -1, 1 ));

   return 0 if $Ct -> substr (12, 13)  -> ne( new(
      \"n, bold, ital", [0,1,0,2], [0,3,7,9]
   ));
 
   # (2)
   $Ct -> substr (15, 4, "fine");
   return 0 if $Ct -> substr ( 15,  4) -> ne (new (\"fine", [1]));

   $Ct -> substr (12, 13, new(
      \"surelike and comfortable son", [3,0,4,0,6], [0,8,13,24,25]
   ));
   return 0 if $Ct -> ne ( new(
      \"This is plaisurelike and comfortable sonic and plain again.\n",
      [0,3,0,4,0,6,2,0], [0,12,20,25,36,37,40,42]
   ));

   $Ct -> substr (12, 28, new(
      \"n, bold, ital", [0,1,0,2], [0,3,7,9]
   ));
   return 0 if $Ct -> ne ( new(
      \"This is plain, bold, italic and plain again.\n",
      [0,1,0,2,0], [0,15,19,21,27]
   ));
      
   $Ct -> substr (15, 4, $Ct, 21, 6);
   return 0 if $Ct -> ne ( new(
      \"This is plain, italic, italic and plain again.\n",
      [0,2,0,2,0], [0,15,21,23,29]
   ));

   $Ct = new ();
   $Ct -> substr(0, 0, new(\"Hallihallo!", [1]));
   return 0 if $Ct -> ne ( new(\"Hallihallo!", [1]));

   $Ct = new (
      2, 
      \"E i n   T e s t   i s t   d a s . ",
      [0,1,0,2,0], [0,4,8,13,16]
   );
   return 0 if $Ct->substr(4, 4)->ne (new(2, \"T e s t ", [1]));
   return 0 if $Ct->substr(4, 5)->ne (new(2, \"T e s t   ", [1,0], [0,4]));
   return 0 if $Ct->substr(3, 5)->ne (new(2, \"  T e s t ", [0,1], [0,1]));
1}

sub test_text {
   my $txt = "Das ist Text.";
   return 0 if $txt ne ${new(\$txt)->text};
1}

sub test_tr {
   my $Ct = new (\"abcdefghijklmnop"); 
   $Ct -> tr ("a-p", "b-pa");
   return 0 if $Ct -> ne (new (\"bcdefghijklmnopa"));

   my $Ct1 = new (2, \"a b c d e f g a1b1c1d1e1f1g1e e a0b0");
   $Ct1 -> tr (["e ", "e1", "a0", "h1"], ["g2", "h3", "i2", "j3"]);
   return 0 if $Ct1 -> ne (new (2, \"a b c d g2f g a1b1c1d1h3f1g1g2g2i2b0"));

   my $Ct2 = new (2, \"a b c d e f g a1b1c1d1e1f1g1e e a0b0");
   $Ct2 -> tr ("e e1a0h1", "g2h3i2j3");
   return 0 if $Ct1 -> ne ($Ct2);
1}

