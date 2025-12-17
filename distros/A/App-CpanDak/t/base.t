use Test2::V0;
use Test2::Tools::LoadModule;

my $cpanm = mock 'App::cpanminus::script' => (
    add_constructor => [ new => 'hash' ],
    add => [
        install_module => sub {},
        resolve_name => sub {},
        search_cpanmetadb_history => sub {},
        fetch_module => sub {},
        configure => sub {},
        build => sub {},
        test => sub {},
        install => sub {},
    ],
);
$INC{'App/cpanminus/script.pm'}=__FILE__;

load_module_ok 'App::CpanDak';

ok App::CpanDak->new(), 'should construct';

done_testing;
