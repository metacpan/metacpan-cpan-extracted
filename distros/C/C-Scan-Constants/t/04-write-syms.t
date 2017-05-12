# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 04-write-syms.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Scalar::Util qw( reftype );
use List::MoreUtils qw( any );
use File::Path;
use Cwd;
use Test::More tests => 5;
BEGIN { use_ok('C::Scan::Constants') };                        # 1

#########################

my @h_files = qw( t/include/defines.h
                  t/include/enums.h );

# Arrange for running directly from this directory
if (!-d "t/include") {
    @h_files = qw( include/defines.h
                   include/enums.h );
}

my @constants = C::Scan::Constants::extract_constants_from( @h_files );

my $out_snips_file = "test04_snippets_out.txt";
open STDERR, ">", $out_snips_file,
    or die "Could not open redirected STDERR file for writing: $!";
write_constants_module( "C::Scan::Constants", @constants );
close STDERR;

open my $snippets_help_fh, "<", "$out_snips_file",
    or die "Could not open $out_snips_file for reading: $!";
my @contents = <$snippets_help_fh>;

my $any_snippet = any { $_ =~ /start of [.]pm snippet/ } @contents;
ok( $any_snippet,
    "Our helpful hints print as a by-product of writing." );   # 2
close $snippets_help_fh;
unlink $out_snips_file;

my $top_sub_dir = getcwd() . '/lib/C/Scan/Constants';
my $sym_mod_name = sprintf "%s/Constants/C/Symbols.pm", $top_sub_dir;

ok( -f "$sym_mod_name",
    "Symbols.pm module file was created as expected." );       # 3

rmtree( "$top_sub_dir" );

ok( -f "const-c.inc",
    "const-c.inc file was created as expected." );             # 4

ok( -f "const-xs.inc",
    "const-xs.inc file was created as expected." );            # 5
