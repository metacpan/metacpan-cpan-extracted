use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BitTorrent::Simple',
    VERSION_FROM      => 'lib/BitTorrent/Simple.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'threads'=> 0, 'threads::shared' => 0, 'LWP::UserAgent' => 0, 'IO::Socket::INET' => 0, 'IO::Select' => 0, 'Digest::SHA' => 0, 'URI::Escape' => 0, 'File::Path' => 0, 'File::Basename' => 0, 'POSIX' => 0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/BitTorrent/Simple.pm', # retrieve abstract from module
    AUTHOR            => 'Rajkumar Reddy',
    EXE_FILES         => ['script/torrent'],
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
