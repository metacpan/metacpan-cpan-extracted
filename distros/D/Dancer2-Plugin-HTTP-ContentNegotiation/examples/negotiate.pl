use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::ContentNegotiation;

get '/text' => sub { "Hello World" };

our $html = <<"EOT";
<HTML>
<HEAD>
    <TITLE>Hello WWW</TITLE>
</HEAD>
<BODY>
    <H1>Hello World Wide Web</H1>
</BODY>
</HTML>
EOT

my $data = {
    users => [
        {   name    => "John",
            age     => "42",
            country => "Canada",
        },
        {   name    => "Mary",
            age     => "46",
            country => "United Kingdom",
        },
    ]
};

get '/html' => sub {
    http_choose (
        'text/html' => sub { $html },
    );
};

get '/choose' => sub {
    http_choose_media_type (
        'text/html'         => sub { $html },
        'application/json'  => sub { to_json $data },
        'application/xml '  => sub { to_xml $data },
        # default is 406: Not Acceptable
        { default => undef },
    );
};

get '/image' => sub {
    http_choose_media_type (
        [ 'image/png', 'image/jpeg', 'image/*' ]
            => sub { "Can't do images of type '" . http_chosen . "' yet" },
        # default is specified below, which must be one listed above
#       { default => 'image/tiff' },
        { default => 'image/jpeg' },
    );
};

get '/greetings' => sub {
    http_choose_language (
        'nl'    => sub { 'Hallo Amsterdam' },
        'de'    => sub { 'Hallo Berlin' },
        'en'    => sub { 'Hello World' }, # any other english if acceptable
        'en-GB' => sub { 'Hello London' },
        'en-US' => sub { 'Hello Washington' },
        # default is first in the list
    );
};

dance;
