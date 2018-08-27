use 5.020;
use Panda::Install;

my $inst_map = {'include' => '/'};
Panda::Install::_process_map($inst_map, '*.h *.hpp *.ipp');

write_makefile(
    NAME          => 'CPP::Boost::Mini',
    VERSION_FROM  => 'lib/CPP/Boost/Mini.pm',
    ABSTRACT_FROM => 'lib/CPP/Boost/Mini.pod',
    BIN_SHARE => {
        CPLUS    => 1,
        INCLUDE  => $inst_map,
    },
);
