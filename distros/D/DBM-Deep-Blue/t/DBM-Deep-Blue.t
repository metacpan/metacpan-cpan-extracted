#!perl -w -I../blib -I../blib/arch -I../lib

  use DBM::Deep::Blue;
  use Test::More;

   {my $m = DBM::Deep::Blue::file('memory.data');
    my $h = $m->allocGlobalHash;                   
       $h->{a}[1]{b}[2]{c}[3] =  'a1b2c2';
   }

  # A later execution ...

   {my $m = DBM::Deep::Blue::file('memory.data');
    my $h = $m->allocGlobalHash;                   
    is $h->{a}[1]{b}[2]{c}[3],   'a1b2c2';
   }

  done_testing;

