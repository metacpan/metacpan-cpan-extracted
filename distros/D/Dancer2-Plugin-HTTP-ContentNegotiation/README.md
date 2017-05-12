Dancer2::Plugin::HTTP::ContentNegotiation
=========================================

A Dancer2 plugin that does the right thing when it comes to Acceptable MIME-types and RFCs

Synopsis
========

    use Dancer2;
    
    use Dancer2::Plugin::HTTP::ContentNegotiation;
    
    get '/greetings' => sub {
        http_choose_language (
            'en'    => sub { 'Hello World' },
            'en-GB' => sub { 'Hello London' },
            'en-US' => sub { 'Hello Washington' },
            'nl'    => sub { 'Hallo Amsterdam' },
            'de'    => sub { 'Hallo Berlin' },
            # default is first in the list
        );
    };
    
    get '/choose/:id' => sub {
        my $data = SomeResource->find(param('id'));
        http_choose_media_type (
            'application/json'  => sub { to_json $data },
            'application/xml '  => sub { to_xml $data },
            { default => undef }, # default is 406: Not Acceptable
        );
    };
    
    get '/thumbnail/:id' => sub {
        http_choose_media_type (
            [ 'image/png', 'image/gif', 'image/jpeg' ]
                => sub { Thumbnail->new( param('id') )->to(http_chosen->type) },
            { default => 'image/png' }, # must be one listed above
        );
    };
    
    dance;

Description
===========
A web server should be capable of content negotiation.
This plugin goes way beyond the `Dancer2::Serializer::Mutable`
which picks a wrong approach on deciding what the requested type is.
Also, this plugin is easy to extend with different 'serializers'
for example `application/pdf` or `image/jpg`.

`Dancer2::Plugin::HTTP::ContentNegotiation` will produce all the correct status
message described in the latest RFCs.

Dancer2 Keywords
================
* `http_choose_media_type`
use the HTTP Accept header field to choose from a list of provide media-types.
* `http_choose_language`
* `http_choose_charset`
* `http_choose_encoding`
* `http_choose`
name compatebility

* `http_chosen_media_type`
holds the value of the chosen HTTP Accept header-field
* `http_chosen_language`
* `http_chosen_charset`
* `http_chosen_encoding`
* `http_chosen`

Release Note
============
This is only for demonstration purpose.

- It should get an option to define what the default MIME-type should be
  when none is given.
- Not yet implemented: Statuscode `300 "Multiple Choices"`
  when the request is not disambigues
- There is a bug in `HTTP::Headers::ActionPack`
  that allows values to pass throug with q=0.0
