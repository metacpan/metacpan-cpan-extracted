package Dancer::Plugin::REST;
BEGIN {
  $Dancer::Plugin::REST::AUTHORITY = 'cpan:SUKRIA';
}
# ABSTRACT: A plugin for writing RESTful apps with Dancer
$Dancer::Plugin::REST::VERSION = '0.11';
use strict;
use warnings;

use Carp 'croak';
use Dancer ':syntax';
use Dancer::Plugin;

my $content_types = {
    json => 'application/json',
    yml  => 'text/x-yaml',
    xml  => 'application/xml',
};

our $default_serializer;

register prepare_serializer_for_format => sub {
    my $conf        = plugin_setting;
    my $serializers = (
        ($conf && exists $conf->{serializers})
        ? $conf->{serializers}
        : { 'json' => 'JSON',
            'yml'  => 'YAML',
            'xml'  => 'XML',
            'dump' => 'Dumper',
        }
    );

    hook 'before' => sub {
        # remember what was there before
        $default_serializer ||= setting 'serializer';

        my $format = params->{'format'} or return;

        my $serializer = $serializers->{$format}
            or return halt(
                Dancer::Error->new(
                    code    => 404,
                    title   => "unsupported format requested",
                    message => "unsupported format requested: " . $format
                )->render
            );

        set serializer => $serializer;

        # check if we were supposed to deserialize the request
        Dancer::Serializer->process_request(
            Dancer::SharedData->request
        );

        content_type $content_types->{$format} || setting('content_type');
    };

    hook after => sub {
        # put it back the way it was
        set serializer => $default_serializer;
    }
};

my %triggers_map = (
    get    => \&get,
    update => \&put,
    create => \&post,
    delete => \&del,
);

register resource => sub {
    croak "resource invoked without arguments" unless @_;

    my ($resource, %triggers) = @_;

    while( my( $t, $sub ) = each %triggers ) {
        my $method = $triggers_map{$t}
            or croak "action '$t' not recognized";

        if ( $t eq 'create' ) {
            $method->( "/${resource}" => $triggers{$t} );
            $method->( "/${resource}.:format" => $triggers{$t} );
        }
        else {
            for my $ext ( '.:format', '' ) {
                $method->( "/${resource}/:id$ext" => $triggers{$t} );
            }
        }
    }

};

register send_entity => sub {
    # entity, status_code
    status($_[1] || 200);
    $_[0];
};

my %http_codes = (

    # 1xx
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',

    # 2xx
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',
    210 => 'Content Different',

    # 3xx
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    310 => 'Too many Redirect',

    # 4xx
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Time-out',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested range unsatisfiable',
    417 => 'Expectation failed',
    418 => 'Teapot',
    422 => 'Unprocessable entity',
    423 => 'Locked',
    424 => 'Method failure',
    425 => 'Unordered Collection',
    426 => 'Upgrade Required',
    449 => 'Retry With',
    450 => 'Parental Controls',

    # 5xx
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Time-out',
    505 => 'HTTP Version not supported',
    507 => 'Insufficient storage',
    509 => 'Bandwidth Limit Exceeded',
);

for my $code (keys %http_codes) {
    my $helper_name = lc($http_codes{$code});
    $helper_name =~ s/[^\w]+/_/gms;
    $helper_name = "status_${helper_name}";

    register $helper_name => sub {
        if ($code >= 400) {
            send_entity({error => $_[0]}, $code);
        }
        else {
            send_entity($_[0], $code);
        }
    };
}

register_plugin;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::REST - A plugin for writing RESTful apps with Dancer

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This plugin helps you write a RESTful webservice with Dancer.

=head1 SYNOPSYS

    package MyWebService;

    use Dancer;
    use Dancer::Plugin::REST;

    prepare_serializer_for_format;

    get '/user/:id.:format' => sub {
        User->find(params->{id});
    };

    # curl http://mywebservice/user/42.json
    { "id": 42, "name": "John Foo", email: "john.foo@example.com"}

    # curl http://mywebservice/user/42.yml
    --
    id: 42
    name: "John Foo"
    email: "john.foo@example.com"

=head1 KEYWORDS

=head2 prepare_serializer_for_format

When this pragma is used, a before filter is set by the plugin to automatically
change the serializer when a format is detected in the URI.

That means that each route you define with a B<:format> token will trigger a
serializer definition, if the format is known.

This lets you define all the REST actions you like as regular Dancer route
handlers, without explicitly handling the outgoing data format.

=head2 resource

This keyword lets you declare a resource your application will handle.

    resource user =>
        get    => sub { # return user where id = params->{id}   },
        create => sub { # create a new user with params->{user} },
        delete => sub { # delete user where id = params->{id}   },
        update => sub { # update user with params->{user}       };

    # this defines the following routes:
    # GET /user/:id
    # GET /user/:id.:format
    # POST /user
    # POST /user.:format
    # DELETE /user/:id
    # DELETE /user/:id.:format
    # PUT /user/:id
    # PUT /user/:id.:format

=head2 helpers

Some helpers are available. This helper will set an appropriate HTTP status for you.

=head3 status_ok

    status_ok({users => {...}});

Set the HTTP status to 200

=head3 status_created

    status_created({users => {...}});

Set the HTTP status to 201

=head3 status_accepted

    status_accepted({users => {...}});

Set the HTTP status to 202

=head3 status_bad_request

    status_bad_request("user foo can't be found");

Set the HTTP status to 400. This function as for argument a scalar that will be used under the key B<error>.

=head3 status_not_found

    status_not_found("users doesn't exists");

Set the HTTP status to 404. This function as for argument a scalar that will be used under the key B<error>.

=head1 LICENCE

This module is released under the same terms as Perl itself.

=head1 AUTHORS

This module has been written by Alexis Sukrieh C<< <sukria@sukria.net> >> and Franck
Cuny.

=head1 SEE ALSO

L<Dancer> L<http://en.wikipedia.org/wiki/Representational_State_Transfer>

=head1 AUTHORS

=over 4

=item *

Alexis Sukrieh <sukria@sukria.net>

=item *

Franck Cuny <franckc@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
