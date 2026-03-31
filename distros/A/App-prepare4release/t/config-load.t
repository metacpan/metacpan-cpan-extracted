#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

my $root = tempdir( CLEANUP => 1 );

for my $content ( '', "  \n\t  " ) {
	my $path = File::Spec->catfile( $root, 'prepare4release.json' );
	open my $fh, '>:encoding(UTF-8)', $path or die $!;
	print {$fh} $content;
	close $fh;

	my $cfg = App::prepare4release->load_config_file($path);
	ok( ref $cfg eq 'HASH', 'load_config_file accepts empty-ish JSON file' );
	is( scalar keys %$cfg, 0, 'empty file yields empty object' );
}

done_testing;
