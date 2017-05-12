#!perl -T

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use File::Spec;
use Cwd;


(my $test_dir)       = $Bin;
(my $dist_dir)       = Cwd::realpath( File::Spec->catfile($Bin, '..') );

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to run.';
    plan( skip_all => $msg );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;

open( my $exclude_fh, q{<}, File::Spec->catfile( $dist_dir, 'ignore.txt' ) )
  or die "couldn't open ignore.txt: $!";

my @exclude_files = map{
  chomp;
  /\*/ ?
    glob( File::Spec->catfile( $dist_dir, $_ ) ) :
    File::Spec->catfile( $dist_dir, $_ )
} ( <$exclude_fh> );

ok_manifest({ exclude => [ @exclude_files,
			   glob( $dist_dir . 't/data/*.db' ),
			 ],
	      filter  => [qr/\.svn/,
			  qr/\.git/,
			  qr/^.*~$/,
			 ],
	      bool    => 'or',
	    });

done_testing();
