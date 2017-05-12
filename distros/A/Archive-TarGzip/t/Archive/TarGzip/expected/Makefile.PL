
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Data_Str2Num 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Data_Str2Num
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Data/Str2Num.t');


WriteMakefile(
    NAME => 'Data::Str2Num',
    DISTNAME => 'Data-Str2Num',
    VERSION  => '0.02',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'File::TestPath' => '1.1',
                  'File::SmartNL' => '1.1',
                  'File::Package' => '1.1',
                  'Test::Tech' => '1.08',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'convert a scalar string to an integer', ) : ()),
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

