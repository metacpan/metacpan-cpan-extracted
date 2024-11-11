use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Data::FastPack::JPacker',
    VERSION_FROM      => 'lib/Data/FastPack/JPacker.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    ###################################
    # BUILD_REQUIRES    => {          #
    #   "File::ShareDir::Install"=>0, #
    # },                              #
    # CONFIGURE_REQUIRES    => {      #
    #   "File::ShareDir::Install"=>0, #
    # },                              #
    ###################################
    PREREQ_PM         => {
      "constant::more" => 0,
      "Data::FastPack"=>0,
      "Data::JPack"=>0

    }, # e.g., Module::Name => 1.1
    EXE_FILES         => ['script/fastpack-split'],
    ABSTRACT_FROM     => 'lib/Data/FastPack/JPacker.pm', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_ADD => {
      "meta-spec" => {
        version => 2
      },
      resources=> {
        repository =>{
          type => "git",
          url => "git://github.com/drclaw1394/perl-data-fastpack-jpacker.git",
          web => "https://github.com/drclaw1394/perl-data-fastpack-jpacker",
        }
      }
    }
);
