# -*- perl -*-

requires 'File::BaseDir';
requires 'File::ShareDir';
requires 'IO::Compress::Xz';
requires 'IPC::Run';
requires 'IPC::System::Simple';
requires 'JSON::MaybeXS';
requires 'List::SomeUtils';
requires 'Perl6::Slurp';
requires 'Template';

on 'test' => sub {
    requires 'Capture::Tiny';
    requires 'File::Copy::Recursive';
    suggests 'Devel::Cover';
    suggests 'Perl::Critic::Freenode';
    suggests 'Test::MinimumVersion';
    suggests 'Test::Perl::Critic';
    suggests 'Test::Pod';
    suggests 'Test::Pod::Coverage';
    suggests 'Test::Strict';
    suggests 'Test::Synopsis';
};
