# -*- perl -*-

requires 'Date::Parse';
requires 'File::BaseDir';
requires 'File::ShareDir';
requires 'Git::Repository';
requires 'Image::Size';
requires 'IO::Compress::Xz';
requires 'IO::Uncompress::Gunzip';
requires 'IPC::Run';
requires 'IPC::System::Simple';
requires 'JSON::MaybeXS';
requires 'Kwalify';
requires 'List::SomeUtils', '0.07';
requires 'Perl6::Slurp';
requires 'Pod::Thread', '3.00';
requires 'Template';
requires 'YAML::XS', '0.81';

on 'test' => sub {
    requires 'Capture::Tiny';
    requires 'File::Copy::Recursive';
    suggests 'Devel::Cover';
    suggests 'Perl::Critic::Freenode';
    suggests 'Test::CPAN::Changes';
    suggests 'Test::MinimumVersion';
    suggests 'Test::Perl::Critic';
    suggests 'Test::Pod';
    suggests 'Test::Pod::Coverage';
    suggests 'Test::Strict';
    suggests 'Test::Synopsis';
};
