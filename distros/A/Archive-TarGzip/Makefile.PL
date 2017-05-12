
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Archive_TarGzip 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Archive_TarGzip
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Archive/TarGzip.t');


WriteMakefile(
    NAME => 'Archive::TarGzip',
    DISTNAME => 'Archive-TarGzip',
    VERSION  => '0.03',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'Tie::Gzip' => '0.01',
                  'File::AnySpec' => '1.11',
                  'Data::Startup' => '0.02',
                  'File::Package' => '0.00',
                  'File::Where' => '0.00',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'tar and gzip or untar and gunzip with a small memory footprint', ) : ()),
);



use File::Spec;
use File::Spec::Unix;
sub unix2os
{
   my @file = ();
   foreach my $file (@_) {
       my (undef, $dir, $file_unix) = File::Spec::Unix->splitpath( $file );
       my @dir = File::Spec::Unix->splitdir( $dir );
       push @file, File::Spec->catfile( @dir, $file_unix);
   }
   @file;
}

