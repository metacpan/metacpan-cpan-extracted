requires 'perl', '5.008001';

requires 'IO::Socket::IP';
requires 'Plack', '0.9920';
requires 'Plack::App::Proxy::Backend::HTTP::Tiny';
requires 'Plack::Middleware::Proxy::Connect::IO';
requires 'Plack::Middleware::Proxy::Requests';
requires 'Starlight', '0.0501';

recommends 'Plack::Middleware::TrafficLog';
recommends 'Thrall', '0.0402';

suggests 'IO::Socket::SSL';
suggests 'Net::SSLeay', '1.49';

on configure => sub {
    requires 'Module::Build';
    requires 'Module::CPANfile';
    requires 'Software::License';
};

on test => sub {
    requires 'Test::More', '0.88';
};

feature fatpack => sub {
    requires 'if';
    requires 'parent';
    requires 'App::FatPacker';
    requires 'Exporter';
    requires 'Clone::PP';
    requires 'HTTP::Date';
    requires 'HTTP::Parser';
    requires 'HTTP::Tiny';
    requires 'Module::Load';
    requires 'Text::Unidecode';
    requires 'Thrall', '0.0402';
    requires 'Time::Local';
    requires 'Try::Tiny';
};

on develop => sub {
    requires 'Devel::Cover';
    requires 'Devel::NYTProf';
    requires 'File::Slurp';
    requires 'Module::Build';
    requires 'Module::Build::Version';
    requires 'Module::Signature';
    requires 'Perl::Critic';
    requires 'Perl::Critic::Community';
    requires 'Perl::Tidy';
    requires 'Pod::Markdown';
    requires 'Pod::Readme';
    requires 'Readonly';
    requires 'Software::License';
    requires 'Test::CheckChanges';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta';
    requires 'Test::DistManifest';
    requires 'Test::Distribution';
    requires 'Test::EOL';
    requires 'Test::Kwalitee';
    requires 'Test::MinimumVersion';
    requires 'Test::More';
    requires 'Test::NoTabs';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::PPPort';
    requires 'Test::Signature';
    requires 'Test::Spelling';
};
