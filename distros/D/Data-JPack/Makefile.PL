use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist=>"share";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::JPack',
    VERSION_FROM      => 'lib/Data/JPack.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    EXE_FILES         =>  ['script/jpack-app'],
    BUILD_REQUIRES    => {
      "File::ShareDir::Install"=>0,
    },
    CONFIGURE_REQUIRES    => {
      "File::ShareDir::Install"=>0,
    },
    PREREQ_PM         => {
      "Export::These"=>0,
      "constant::more"=>0,
      "File::ShareDir"=>0,
      "IO::Compress::RawDeflate"=>0,
      "IO::Uncompress::RawInflate"=>0,

    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Data/JPack.pod', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_ADD => {
      "meta-spec" => {
        version => 2
      },
      resources=> {
        repository =>{
          type => "git",
          url => "git://github.com/drclaw1394/perl-data-jpack.git",
          web => "https://github.com/drclaw1394/perl-data-jpack",
        }
      }
    }
);

package MY;
use File::ShareDir::Install qw(postamble);
