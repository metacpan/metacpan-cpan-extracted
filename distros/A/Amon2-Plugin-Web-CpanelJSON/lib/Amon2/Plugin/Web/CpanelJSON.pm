package Amon2::Plugin::Web::CpanelJSON;
use strict;
use warnings;

use Amon2::Util ();
use Cpanel::JSON::XS ();
use Scalar::Util qw(blessed);
use HTTP::SecureHeaders;

our $VERSION = "0.01";

my %DEFAULT_CONFIG = (
    name => 'render_json',

    # for security
    # refs https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html#security-headers
    secure_headers => {
        content_security_policy           => "default-src 'none'",
        strict_transport_security         => 'max-age=631138519',
        x_content_type_options            => 'nosniff',
        x_download_options                => undef,
        x_frame_options                   => 'DENY',
        x_permitted_cross_domain_policies => 'none',
        x_xss_protection                  => '1; mode=block',
        referrer_policy                   => 'no-referrer',
    },

    json_escape_filter => {
        # Ref: https://cheatsheetseries.owasp.org/cheatsheets/XSS_Filter_Evasion_Cheat_Sheet.html
        # Ref: (Japanese) http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html
        '+' => '\\u002b', # do not eval as UTF-7
        '<' => '\\u003c', # do not eval as HTML
        '>' => '\\u003e', # ditto.
    },

    # JSON config
    json => {
        ascii => !!1, # for security
    },

    # for convenience
    unbless_object    => undef,
    status_code_field => undef,

    # for compatibility options
    defence_json_hijacking_for_legacy_browser => !!0,
);


sub init {
    my ($class, $c, $conf) = @_;

    $conf = do {
        $conf ||= {};

        for my $key (qw/secure_headers json_escape_filter json/) {
            if (exists $conf->{$key} && !defined $conf->{$key}) {
                $conf->{$key} = undef;
            }
            else {
                $conf->{$key} = {
                    %{ $DEFAULT_CONFIG{$key} },
                    %{ $conf->{$key} || {} },
                }
            }
        }

        +{ %DEFAULT_CONFIG, %{$conf} };
    };

    my $name = $conf->{name};

    unless ($c->can($name)) {
        my $render_json = _generate_render_json($conf);
        Amon2::Util::add_method($c, $name, $render_json)
    }
}

sub _generate_render_json {
    my $conf = shift;

    my $encoder = _generate_json_encoder($conf);
    my $validator = _generate_req_validator($conf);

    my $secure_headers;
    if ($conf->{secure_headers}) {
        $secure_headers = HTTP::SecureHeaders->new(%{ $conf->{secure_headers} });
    }

    return sub {
        my ($c, $data, $spec, $status) = @_;
        $status //= 200;

        if (my $error = $validator->($c)) {
            return $error;
        }

        my $output = $encoder->($data, $spec);

        my $res = do {
            my $res = $c->create_response($status);

            my $encoding = $c->encoding();
            $encoding = lc($encoding->mime_name) if ref $encoding;

            $res->content_type("application/json; charset=$encoding");
            $res->content_length(length($output));
            $res->body($output);

            if ($secure_headers) {
                $secure_headers->apply($res->headers);
            }

            # X-API-Status
            # (Japanese) http://web.archive.org/web/20190503111531/http://blog.yappo.jp/yappo/archives/000829.html
            if (my $status_code_field =  $conf->{status_code_field}) {
                if (exists $data->{$status_code_field}) {
                    $res->header('X-API-Status' => $data->{$status_code_field})
                }
            }

            $res
        };

        return $res;
    }
}

sub _generate_json_encoder {
    my $conf = shift;

    my $json = Cpanel::JSON::XS->new;
    if (my $json_args = $conf->{json}) {
        for my $key (keys %{$json_args}) {
            $json->$key($json_args->{$key})
        }
    }

    my $escape_filter = $conf->{json_escape_filter} || {};
    my $escape_target = '';
    for my $key (keys %{$escape_filter}) {
        if ($escape_filter->{$key}) {
            $escape_target .= $key
        }
    }

    return sub {
        my ($data, $spec) = @_;

        if (my $unbless_object = $conf->{unbless_object}) {
            if (blessed($data)) {
                $data = $unbless_object->($data, $spec);
            }
        }

        my $output = $json->encode($data, $spec);

        if ($escape_target && $escape_filter) {
            $output =~ s!([$escape_target])!$escape_filter->{$1}!g;
        }

        return $output;
    }
}

sub _generate_req_validator {
    my $conf = shift;

    return sub {
        my ($c) = @_;

        # defense from JSON hijacking
        if ($conf->{defence_json_hijacking_for_legacy_browser}) {
            my $user_agent = $c->req->user_agent || '';

            if (
                (!$c->req->header('X-Requested-With')) &&
                $user_agent =~ /android/i &&
                defined $c->req->header('Cookie') &&
                ($c->req->method||'GET') eq 'GET'
            ) {
                return _error_response($c);
            }
        }
    }
}

sub _error_response {
    my $c = shift;

    my $res = $c->create_response(403);
    $res->content_type('text/plain');
    $res->content("invalid JSON request");
    $res->content_length(length $res->content);
    return $res;
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::CpanelJSON - Cpanel::JSON::XS plugin

=head1 SYNOPSIS

    use Amon2::Lite;
    use Cpanel::JSON::XS::Type;
    use HTTP::Status qw(:constants);

    __PACKAGE__->load_plugins(qw/Web::CpanelJSON/);

    use constant HelloWorld => {
        message => JSON_TYPE_STRING,
    };

    get '/' => sub {
        my $c = shift;
        return $c->render_json(+{ message => 'HELLO!' }, HelloWorld, HTTP_OK);
    };

    __PACKAGE__->to_app();

=head1 DESCRIPTION

This is a JSON plugin for Amon2.
The differences from Amon2::Plugin::Web::JSON are as follows.

* Cpanel::JSON::XS::Type is available

* HTTP status code can be specified

* Flexible Configurations

=head1 METHODS

=over 4

=item C<< $c->render_json($data, $json_spec, $status=200); >>

Generate JSON C<< $data >> and C<< $json_spec >> and returns instance of L<Plack::Response>.
C<< $json_spec >> is a structure for JSON encoding defined in L<Cpanel::JSON::XS::Type>.

=back

=head1 CONFIGURATION

=over 4

=item json

Parameters of L<Cpanel::JSON::XS>. Default is as follows:

    ascii => !!1,

Any parameters can be set:

     __PACKAGE__->load_plugins(
        'Web::CpanelJSON' => {
            json => {
                ascii     => 0,
                utf8      => 1,
                canonical => 1,
            }
        }
    );

=item secure_headers

Parameters of L<HTTP::SecureHeaders>. Default is as follows:

    content_security_policy           => "default-src 'none'",
    strict_transport_security         => 'max-age=631138519',
    x_content_type_options            => 'nosniff',
    x_download_options                => undef,
    x_frame_options                   => 'DENY',
    x_permitted_cross_domain_policies => 'none',
    x_xss_protection                  => '1; mode=block',
    referrer_policy                   => 'no-referrer',


=item json_escape_filter

Escapes JSON to prevent XSS. Default is as follows:

    '+' => '\\u002b',
    '<' => '\\u003c',
    '>' => '\\u003e',

=item name

Name of method. Default: 'render_json'

=item unbless_object

Default: undef

This option is preprocessing coderef encoding an blessed object in JSON.
For example, the code using L<Object::UnblessWithJSONSpec> is as follows:

    use Object::UnblessWithJSONSpec ();

    __PACKAGE__->load_plugins(
        'Web::CpanelJSON' => {
            unbless_object => \&Object::UnblessWithJSONSpec::unbless_with_json_spec,
        }
    );

    ...

    package Some::Object {
        use Mouse;

        has message => (
            is => 'ro',
        );
    }

    my $object = Some::Object->new(message => 'HELLO');
    $c->render_json($object, { message => JSON_TYPE_STRING })
    # => {"message":"HELLO"}

=item status_code_field

Default: undef

It specify the field name of JSON to be embedded in the C<< X-API-Status >> header.
Default is C<< undef >>. If you set the C<< undef >> to disable this C<< X-API-Status >> header.

    __PACKAGE__->load_plugins(
        'Web::CpanelJSON' => { status_code_field => 'status' }
    );

    ...

    $c->render_json({ status => 200, message => 'ok' })
    # send response header 'X-API-Status: 200'

In general JSON API error code embed in a JSON by JSON API Response body.
But can not be logging the error code of JSON for the access log of a general Web Servers.
You can possible by using the C<< X-API-Status >> header.

=item defence_json_hijacking_for_legacy_browser

Default: false

=back

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

