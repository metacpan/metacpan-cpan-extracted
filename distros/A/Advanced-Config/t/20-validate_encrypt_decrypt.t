#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;
use Sys::Hostname;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

my $fish;

# =================================================================
# Tests the encryption/decryption logic.
# =================================================================
# Assumptions about the config files made by this test program:
# If any assumtions are false, you will see test failures.
#   1) No tag appeears in multiple sections for this test.
#   2) All tags starting with "join" are assumed to reference
#      encrypted variables/tags.
# =================================================================

BEGIN {
   $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   DBUG_ENTER_FUNC ();

   use_ok ("Advanced::Config");

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC ();
   # Don't do any tests in the END block ...
   DBUG_VOID_RETURN ();
}

# =================================================================

my %decrypt_callback_tags;
my %encrypt_callback_tags;

sub my_security_callback
{
   DBUG_ENTER_FUNC (@_);
   my $mode     = shift;    # 0 = Decrypt / 1 = Encrypt
   my $tag      = shift;
   my $value    = shift;
   my $file     = shift;
   my $workArea = shift;

   if ( $mode == 0 ) {
      # Decryption ...
      $decrypt_callback_tags{$tag} = 1;
      if ( $value =~ m/^XX(.*)YY$/ ) {
         $value = $1;
      } else {
         $value = "Bogus decryption ...";
      }
   } else {
      # Encryption ...
      $encrypt_callback_tags{$tag} = 1;
      $value = "XX" . $value . "YY";
   }

   DBUG_RETURN ( $value );
}

sub my_source_callback
{
   DBUG_ENTER_FUNC (@_);
   my %opts = ( alias => "20-0-encrypt-decrypt.cfg",
                encrypt_cb => \&my_security_callback );
   DBUG_RETURN ( \%opts, undef );
}

# =================================================================
# Start of the main program!
# =================================================================
{
   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   run_all_tests ( "20-0-encrypt-decrypt.cfg", { encrypt_cb => \&my_security_callback } );

   run_all_tests ( "21-0-encrypt-decrypt.cfg", { encrypt_cb => \&my_security_callback } );

   run_all_tests ( "22-0-encrypt-decrypt.cfg", { assign => ":=:", quote_left => '|', quote_right => '|', encrypt_cb => \&my_security_callback } );

   dbug_ok (1, "-"x30);

   my %rOpts;   $rOpts{source_cb} = \&my_source_callback;

   # This file sources in one of the auto-encrypted files ...
   my $alt_file  = File::Spec->catfile ("t", "config", "25-0-encrypt-decrypt-src.cfg");
   my $acfg = init_cfg_file ( $alt_file, \%rOpts );
   run_alt_tests ($acfg, "aaa", "bBb", "CcC", "DDD", "zzZ");

   # Now lets retest using case insensitive tags!
   dbug_ok (1, "-"x30 . "  A case insensitive tag test. (rOpt tag_case)");
   $rOpts{tag_case} = 1;
   my $acfg2 = init_cfg_file ( $alt_file, \%rOpts );
   run_alt_tests ($acfg2, "AAA", "BBB", "ccc", "dDd", "Zzz");

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# =================================================================

sub run_alt_tests
{
   DBUG_ENTER_FUNC (@_);
   my $cfg = shift;
   my $aTag = shift;
   my $bTag = shift;
   my $cTag = shift;
   my $dTag = shift;
   my $zTag = shift;

   my $aaa = $cfg->get_value($aTag);
   my $bbb = $cfg->get_value($bTag);
   my $ccc = $cfg->get_value($cTag);
   my $ddd = $cfg->get_value($dTag);
   my $zzz = $cfg->get_value($zTag);

   dbug_ok ( 1,            "Validating tag ${aTag}: [$aaa]");
   dbug_cmp_ok ( $bbb, 'eq', $aaa, "Validating tag ${bTag}: [$bbb]");
   dbug_cmp_ok ( $ccc, 'eq', $aaa, "Validating tag ${cTag}: [$ccc]");
   dbug_cmp_ok ( $ddd, 'eq', $aaa, "Validating tag ${dTag}: [$ddd]");
   dbug_cmp_ok ( $zzz, 'eq', $aaa, "Validating tag ${zTag}: [$zzz]");

   DBUG_VOID_RETURN ();
}

# =================================================================

sub run_all_tests
{
   DBUG_ENTER_FUNC (@_);
   my $alias      = shift;
   my $rOpts      = shift;

   dbug_ok (1, "x"x50);
   dbug_ok (1, "?"x10 . " $alias " . "?"x10);

   # my $emptyCfg = Advanced::Config->new (undef, { assign => "?", quote_left => 'x', quote_right => 'x' } );
   my $emptyCfg = Advanced::Config->new (undef, $rOpts);
   dbug_isa_ok ($emptyCfg, 'Advanced::Config');

   # Options to use in decrypting an encrypted file ...
   my %aOpts;
   %aOpts = %{$rOpts}  if ( defined $rOpts );
   $aOpts{alias} = $alias;

   my ($orig_file, $encrypt_file, $file_decrypt, $fail_file);

   $orig_file = $encrypt_file = $file_decrypt = $fail_file =
                         File::Spec->catfile ("t", "config", $alias);

   # Add a prefix ...
   $encrypt_file =~ s/-0-/-1-/;
   $file_decrypt =~ s/-0-/-2-/;
   $fail_file    =~ s/-0-/-3-/;

   # Add a postfix ...
   $encrypt_file =~ s/[.]cfg$/.encrypted.cfg/;
   $file_decrypt =~ s/[.]cfg$/.decrypted.cfg/;
   $fail_file    =~ s/[.]cfg$/.failure.cfg/;

   my $cfg = init_cfg_file ( $orig_file, $rOpts );

   # Encrypting the file ...
   DBUG_PRINT ("====", "%s", "="x50);
   my $status = $emptyCfg->encrypt_config_file ($orig_file, $encrypt_file, $rOpts);
   dbug_is ($status, 1, "Encryption Succeeded!");

   # Reload the encrypted file back into memory ...
   DBUG_PRINT ("====", "%s", "="x50);
   my $ecfg = init_cfg_file ( $encrypt_file, \%aOpts );

   # Saves a list of tags to be decrypted ...
   # Set via the callback function for the encrypt/decrypt logic.
   my %save = %decrypt_callback_tags;

   # Loading using a bad alias ...
   DBUG_PRINT ("====", "%s", "="x50);
   my $ecfg2 = init_cfg_file ( $encrypt_file, $rOpts );

   # Decrypting the file correctly ...
   DBUG_PRINT ("====", "%s", "="x50);
   $status = $emptyCfg->decrypt_config_file ($encrypt_file, $file_decrypt, \%aOpts);
   dbug_is ($status, 1, "Decryption Succeeded!");
   my $dcfg = init_cfg_file ( $file_decrypt, $rOpts );

   # Decrypting the file incorrectly ...
   DBUG_PRINT ("====", "%s", "f"x50);
   $status = $emptyCfg->decrypt_config_file ($encrypt_file, $fail_file, $rOpts);
   dbug_is ($status, 1, "Bad Decryption Succeeded!");
   my $fcfg = init_cfg_file ( $fail_file, $rOpts );

   DBUG_PRINT ("====", "%s", "="x50);


   my @sections = $cfg->find_sections ();
   my $cnt = @sections;
   dbug_ok ($cnt, "The config file has ${cnt} section(s) in it!");
   my %data;

   # Get the stats for the main file ...
   foreach ( @sections ) {
      my %parts;
      my @tag_list = $cfg->get_section ($_)->find_tags ();
      my $tcnt = @tag_list;
      dbug_ok ( $tcnt, "Found ${tcnt} tags in section $_");
      $parts{CNT} = $tcnt;
      $parts{TAGS} = \@tag_list;
      $data{$_} = \%parts;

      # All variables begining with "join..." reference encrypted variables.
      # So put in %save as well.
      foreach my $t ( @tag_list ) {
         $save{$t} = 1   if ( $t =~ m/^join/ );
      }
   }
   DBUG_PRINT ("----", "%s", "-"x50);

   # Validating the encrypted file ...
   compare_cfg ( $cfg, $ecfg, "encrypted", \%data, 0, \%save);
   compare_cfg ( $cfg, $dcfg, "decrypted", \%data, 0, \%save);

   # These compares should fail the decryption process!
   compare_cfg ( $cfg, $ecfg2, "no alias failure", \%data, 1, \%save);
   compare_cfg ( $cfg, $fcfg, "clear failure", \%data, 1, \%save);

   # unlink ($encrypt_file, $file_decrypt, $fail_file);

   DBUG_VOID_RETURN ();
}

# =================================================================

sub compare_cfg
{
   DBUG_ENTER_FUNC (@_);
   my $cfg   = shift;   # The source config file.
   my $dcfg  = shift;   # The config file to comare it to.
   my $lbl   = shift;   # The label to use ...
   my $data  = shift;   # The stats on the source cfg file.
   my $fail  = shift;   # 1-Decrypt should fail.  0-Decrypt should succeed.
   my $which = shift;   # Which tags were decrypted!

   my @sect = $dcfg->find_sections ();
   my $cnt = keys %{$data};
   my $dcnt = @sect;

   dbug_ok (1, "-"x30);
   dbug_is ($cnt, $dcnt, "The ${lbl} config file has the right number of sections.");

   $cnt = 0;
   foreach my $s ( @sect ) {
      unless ( exists $data->{$s} ) {
         dbug_ok (0, "Section '$s' exists in the original config file.");
         next;
      }

      my @tag_list = $dcfg->get_section ($s)->find_tags ();
      my $tcnt = @tag_list;
      ok ( $tcnt == $data->{$s}->{CNT}, "Section '$s' in the ${lbl} cfg file has the right number of tags ($tcnt)" );

      foreach my $t ( @tag_list ) {
         my $stag = $cfg->get_section ($s)->get_value ($t);
         my $dtag = $dcfg->get_section ($s)->get_value ($t);
         unless ( $stag ) {
            dbug_ok (0, "Tag \"${t}\" exists in both config files.");
         } elsif ( ! $which->{$t} ) {
            dbug_cmp_ok ( $stag, 'eq', $dtag, "Tag \"${t}\" has the same value in both config files! ($dtag)" );
         } elsif ( $fail ) {
            dbug_cmp_ok ( $stag, 'ne', $dtag, "Tag \"${t}\" had issues decrypting this value from the config file. ($dtag)" );
         } else {
            dbug_cmp_ok ( $stag, 'eq', $dtag, "Tag \"${t}\" has the same value in both config files. ($dtag)" );
         }
      }
   }

   DBUG_VOID_RETURN ();
}

# =================================================================

sub init_cfg_file
{
   DBUG_ENTER_FUNC (@_);
   my $file  = shift;
   my $rOpts = shift;

   my %empty;

   # Empty out the global hashes ...
   %decrypt_callback_tags = %encrypt_callback_tags = %empty;

   my $cfg;
   eval {
      if ( $rOpts ) {
         $cfg = Advanced::Config->new ( $file, $rOpts );
      } else {
         $cfg = Advanced::Config->new ( $file, { encrypt_cb => \&my_security_callback } );
      }
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   DBUG_RETURN ( $cfg );
}

