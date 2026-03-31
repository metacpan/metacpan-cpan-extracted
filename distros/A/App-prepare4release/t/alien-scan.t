#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

my $d = tempdir( CLEANUP => 1 );
{
	open my $fh, '>:encoding(UTF-8)', File::Spec->catfile( $d, 'Makefile.PL' )
		or die $!;
	print {$fh} "use Alien::Foo::Bar;\n";
	close $fh;
}

my @a = App::prepare4release->scan_files_for_alien_hints($d);
ok( ( grep { $_ eq 'Foo::Bar' } @a ), 'Alien::Foo::Bar detected' );

done_testing;
