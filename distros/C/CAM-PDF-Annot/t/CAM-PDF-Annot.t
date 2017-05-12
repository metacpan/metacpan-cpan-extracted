use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More tests => 8;
use CAM::PDF::Annot;

my $dir = tempdir( CLEANUP => 1 );
# testing for a single page doc

my $pdf1 = CAM::PDF::Annot->new( 't/pdf1.pdf' );
ok($pdf1, 'Open PDF 1 test');
my $pdf2 = CAM::PDF::Annot->new( 't/pdf2.pdf' );
ok($pdf2, 'Open PDF 2 test');
ok( &testAppend, 'Appending annot test'	);
eval { $pdf2->cleanoutput( "$dir/merged_pdf.pdf" ) };
my $pdf3 = CAM::PDF::Annot->new( "$dir/merged_pdf.pdf" );
ok($pdf3, 'Opening merged file test');

# testing for multipage now

ok($pdf1 = CAM::PDF::Annot->new( 't/pdf1multi.pdf' ), 'Open PDF 1 MULTIPAGE test');
ok($pdf2 = CAM::PDF::Annot->new( 't/pdf2multi.pdf' ), 'Open PDF 2 MULTIPAGE test');
ok( &testAppend, 'Appending MULTIPAGE annot test'	);
eval { $pdf2->cleanoutput( "$dir/merged_multi_pdf.pdf" ) };
ok($pdf3 = CAM::PDF::Annot->new( "$dir/merged_multi_pdf.pdf" ), 'Opening merged MULTIPAGE file test');

undef $pdf1;
undef $pdf2;
undef $pdf3;

sub testAppend {
	eval {
		for my $page ( 1 .. $pdf1->numPages() ) {
			my %refs;
			for my $annotRef ( @{$pdf1->getAnnotations( $page )} ) {
				$pdf2->appendAnnotation( $page, $pdf1, $annotRef, \%refs );
			}
		}
	};
	return 0 if ( $@ );
	1;
}

