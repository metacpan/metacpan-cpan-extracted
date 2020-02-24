requires 'App::Wallflower';
requires 'Dancer2';
requires 'File::Find::Rule';
requires 'File::Slurp';
requires 'File::Temp';
requires 'Getopt::Long::Subcommand';
requires 'IPC::System::Simple';
requires 'Import::Into';
requires 'JSON';
requires 'Plack::Builder';
requires 'Plack::Middleware::DirIndex';
requires 'Plack::Runner';
requires 'Pod::Usage';
requires 'Syntax::Highlight::Engine::Kate';
requires 'Test::More';
requires 'Text::FrontMatter::YAML';
requires 'Text::MultiMarkdown';
requires 'autodie';
requires 'feature';
requires 'parent';
requires 'perl', '5.010001';
requires 'vars::i', '1.10';
requires 'version', '0.77';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Minilla';
    requires 'Version::Next';
};
