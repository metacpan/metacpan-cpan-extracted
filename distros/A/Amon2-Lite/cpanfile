requires 'perl', '5.008008';

requires 'Amon2', '3.25';
requires 'Amon2::Config::Simple';
requires 'Amon2::Setup::Flavor';
requires 'Amon2::Web';
requires 'Amon2::Plugin::Web::CSRFDefender';
requires 'Data::Section::Simple', '0.03';
requires 'parent';
requires 'Plack::App::File';
requires 'Plack::Middleware::Session';
requires 'Plack::Session::State::Cookie';
requires 'Router::Simple', '0.13';
requires 'Text::Xslate', '2.0010'; # 2.0010+ gets Perl 5.18+ compatibility
requires 'Text::Xslate::Bridge::TT2Like', '0.00010';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';

    requires 'App::Prove';
    requires 'File::Temp';
    requires 'HTTP::Message::PSGI';
    requires 'HTTP::Request::Common';
    requires 'HTTP::Response';
    requires 'Plack::Test';
    requires 'Plack::Util';
    requires 'Test::WWW::Mechanize';
    requires 'Tiffany';
};
