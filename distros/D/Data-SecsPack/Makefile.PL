
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Data_SecsPack 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Data_SecsPack
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Data/SecsPack.t','t/Data/SecsPackStress.t');


WriteMakefile(
    NAME => 'Data::SecsPack',
    DISTNAME => 'Data-SecsPack',
    VERSION  => '0.06',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => { 
                  'Math::BigInt' => '1.50',
                  'Math::BigFloat' => '1.39',
                  'Data::Startup' => '0.02',
                  'Data::Str2Num' => '0.05'},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'pack and unpack numbers in accordance with SEMI E5-94', ) : ()),
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

