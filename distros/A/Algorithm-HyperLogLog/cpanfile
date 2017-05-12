#!perl
requires 'perl' => '5.008008';
requires 'XSLoader';
requires 'Carp';
requires 'Digest::MurmurHash3::PurePerl' => '>=0.02';

on 'configure' => sub {
    requires 'Module::Build::XSUtil'    => '>=0.09';
};

on 'build' => sub {
    requires 'Test::More'  => '0.98';
    requires 'Test::Fatal' => '0.008';
    requires 'File::Temp';
};

on 'develop' => sub {
    requires 'Test::Spellunker';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Software::License';
};

