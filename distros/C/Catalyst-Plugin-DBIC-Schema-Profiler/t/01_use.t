
use Test::More tests => 4;

BEGIN {
    use_ok('Catalyst');
    use_ok('Catalyst::Model::DBIC::Schema');
    use_ok('Catalyst::Plugin::DBIC::Schema::Profiler');
    use_ok('Catalyst::Plugin::DBIC::Schema::Profiler::DebugObj');
}

