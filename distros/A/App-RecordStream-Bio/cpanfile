requires 'perl', '5.010';

# minimum base version, just to start somewhere known.
requires 'App::RecordStream::Operation' => '4.0.0';

requires 'Bio::GFF3::LowLevel';

on test => sub {
    requires 'Test::More', '0.88';
    requires 'App::RecordStream::Test::Tester'          => '4.0.0';
    requires 'App::RecordStream::Test::OperationHelper' => '4.0.0';
    requires 'File::Temp';
    requires 'JSON';
};

on develop => sub {
    requires 'Dist::Zilla::Plugin::Run::BeforeBuild';
};
