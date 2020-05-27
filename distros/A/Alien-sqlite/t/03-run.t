use strict;
use warnings;
use Test::More;
#use Config;
use Test::Alien;
use Alien::sqlite;
use Env qw ( @PATH @LD_LIBRARY_PATH @DYLD_LIBRARY_PATH );

alien_ok 'Alien::sqlite';

#if (Alien::sqlite->install_type eq 'share') {
   diag ('bin dir: ' . join (' ', Alien::sqlite->bin_dir));
   my @bin = Alien::sqlite->bin_dir;
   
   #  nasty hack
   unshift @LD_LIBRARY_PATH, Alien::sqlite->dist_dir . '/lib';
   unshift @DYLD_LIBRARY_PATH, Alien::sqlite->dist_dir . '/lib';
   unshift @PATH, @bin;
   
   my $sqlite3_exe = @bin ? "$bin[0]/sqlite3" : 'sqlite3';
   my $version = qx ( $sqlite3_exe -version );
   my $e = $?;
   if ($e == -1) {
       diag "failed to execute: $!\n";
   }
   elsif ($e & 127) {
       diag sprintf "child died with signal %d, %s coredump\n",
           ($? & 127),  ($? & 128) ? 'with' : 'without';
   }
   else {
       diag sprintf "$sqlite3_exe exited with value %d\n", $? >> 8;
       if ($e) {
         objdump($sqlite3_exe);
         diag "===";
         objdump("$bin[0]/libsqlite3-0.dll");
       }
   }
   diag 'sqlite3 -version: ' . $version // '';
   
   #  need a better test
   ok (defined $version && length $version > 5, 'got a defined version');
#}
#else {
#   ok (1, 'no need to test sqlite3 binary for system install');
#}

done_testing();

sub objdump {
   my ($dll) = @_;
   
   my $have_fw = eval 'require File::Which';
   return if !$have_fw;

   if (!-e $dll) {
      warn "$dll does not exist";
      return;
   }
   my $objdump = File::Which::which 'objdump';
   my @contents = `$objdump -p $dll`;
   my @lines = grep {/DLL Name/} @contents;
   diag join ' ', @lines;
   return;
}
