use ExtUtils::MakeMaker;

use File::ShareDir::Install;
install_share dist=>"share";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::FastPack',
    VERSION_FROM      => 'lib/Data/FastPack.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    BUILD_REQUIRES    => {
      "File::ShareDir::Install"=>0,
    },
    CONFIGURE_REQUIRES    => {
      "File::ShareDir::Install"=>0,
    },
    PREREQ_PM         => {
      "Export::These"=>0,
      "constant::more"=>0,
      "Cpanel::JSON::XS"=>0,
      "Data::MessagePack"=>0,
      "File::ShareDir"=>0,
    },
    ABSTRACT_FROM     => 'lib/Data/FastPack.pod', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_ADD => {
      "meta-spec" => {
        version => 2
      },
      resources=> {
        repository =>{
          type => "git",
          url => "git://github.com/drclaw1394/perl-data-fastpack.git",
          web => "https://github.com/drclaw1394/perl-data-fastpack",
        }
      }
    }


);

package MY;
use File::ShareDir::Install qw(postamble);

