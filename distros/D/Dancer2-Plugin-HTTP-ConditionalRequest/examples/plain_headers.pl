use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::ConditionalRequest;

get '/etag' => sub {
    http_etag '2d5730a4c92b1061';
    "duno, but you have an eTag set";
};

get '/http-date' => sub {
    http_last_modified("Tue, 15 Nov 1994 12:45:26 GMT"); 
    "it must have been a lovely day";
};

dance;