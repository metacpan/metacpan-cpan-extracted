requires 'perl', '5.018';

requires 'Data::Dumper';
requires 'HTML::LinkExtor';
requires 'HTML::TableExtract';
requires 'HTML::TokeParser';
requires 'HTTP::Request::Common';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'List::AllUtils';
requires 'Moo';
requires 'strictures';

feature 'server', 'Web API server' => sub {
    requires 'File::Share';
    requires 'IO::String';
    requires 'JSON';
    requires 'JSON::XS';
    requires 'Path::Tiny';
    requires 'Plack::App::File';
    requires 'Plack::Middleware::ReverseProxy';
    requires 'Plack::Middleware::CrossOrigin';
    requires 'Server::Starter';
    requires 'Starlet';
    requires 'Text::CSV';
    requires 'Web::Simple';
};

on test => sub {
    requires 'Test::More', '0.88';
};

on develop => sub {
    requires 'FindBin';
    requires 'JSON';
    requires 'Path::Tiny';
    requires 'Test::Deep';
    requires 'Test::LongString';
};
