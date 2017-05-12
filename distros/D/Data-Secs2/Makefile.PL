
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::Data_Secs2 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::Data_Secs2
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/Data/Secs2.t');


WriteMakefile(
    NAME => 'Data::Secs2',
    DISTNAME => 'Data-Secs2',
    VERSION  => '0.09',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'Data::SecsPack' => '0.06',
                  'Data::Str2Num' => '0.05',
                  'Data::Startup' => '0.02'},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'pack, unpack, format, transform between Perl data and SEMI E5-94 SECS-II nested data', ) : ()),
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

