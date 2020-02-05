#!perl

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
    requires 'File::ShareDir::Install';
};

on runtime => sub {
    requires 'perl', '5.010';
    requires 'strict';
    requires 'warnings';
    requires 'DBI'            => 0;
    requires 'Exporter::Tidy' => 0;
    requires 'File::ShareDir' => '1.116';
    requires 'Log::Any'       => 0;
    requires 'Path::Tiny'     => 0;

    feature 'pretty-xdump' => sub {
        requires 'Text::Table::Tiny';
    };
};

on develop => sub {
    requires 'App::githook::perltidy';
};

on test => sub {
    requires 'File::chdir'    => 0;
    requires 'Test::Database' => 0;
    requires 'Test::Fatal'    => 0;
    requires 'Test::More'     => 0;
};
