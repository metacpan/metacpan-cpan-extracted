package Circle::Common;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
use URL::Encode qw(url_encode_utf8);
use LWP::UserAgent;
use HTTP::Request;
use Slurp;
use Try::Tiny;
use YAML;
use JSON;
use Carp;
use File::Share ':all';

our @EXPORT_OK = qw(
  load_config
  build_url_template
  http_json_post
  http_json_get
);

our $VERSION = '0.02';

my $config = undef;

sub load_config {
    if ($config) {
        return $config;
    }

    my $config = {};
    my $config_path = dist_file('Circle-Common', 'config.yml');
    try {
        my $content = slurp($config_path);
        $config = Load($content);
    }
    catch {
        carp "cannot load config, error: $_";
    };
    return $config;
}

sub get_session_key {
    my $config       = load_config();
    my $user         = $config->{user};
    my $home         = $ENV{HOME};
    my $session_path = $user->{sessionPath};
    my $file_path    = "${home}/${session_path}";
    my $session_key;
    try {
        my @lines        = slurp($file_path);
        my @session_keys = grep { chomp($_); $_ =~ /^sessionKey/; } @lines;
        if ( @session_keys > 0 ) {
            my $session_key = $session_keys[0];
            $session_key =~ s/sessionKey=//;
        }
    }
    catch {
        carp "cannot read $session_path, error: $_";
    };

    return $session_key;
}

sub http_json_post {
    my ( $url, $data ) = @_;
    my $config      = load_config();
    my $http        = $config->{http};
    my $session_key = get_session_key();
    my $ua          = LWP::UserAgent->new();
    $ua->timeout( $http->{timeoutWrite} );
    my $header;
    if ($session_key) {
        $header = [
            'AuthorizationV2' => $session_key,
            'Content-Type'    => 'application/json; charset=UTF-8'
        ];
    }
    else {
        $header = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
    }
    my $request  = HTTP::Request->new( 'POST', $url, $header, encode_json($data) );
    my $response = $ua->request($request);
    if ( $response->is_success ) {
        return decode_json( $response->decoded_content );
    }
    else {
        carp 'http_json_post' . $response->status_line ? $response->status_line : 'unknown';
        return {
            status  => $response->status_line,
            message => $response->decoded_content,
        };
    }
}

sub http_json_get {
    my ($url)       = @_;
    my $config      = load_config();
    my $http        = $config->{http};
    my $session_key = get_session_key();
    my $ua          = LWP::UserAgent->new();
    $ua->timeout( $http->{timeoutRead} );
    my $header;
    if ($session_key) {
        $header = [
            'AuthorizationV2' => $session_key,
            'Content-Type'    => 'application/json; charset=UTF-8'
        ];
    }
    else {
        $header = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
    }
    my $request  = HTTP::Request->new( 'GET', $url, $header );
    my $response = $ua->request($request);
    if ( $response->is_success ) {
        return decode_json( $response->decoded_content );
    }
    else {
        carp 'http_json_get' . $response->status_line ? $response->status_line : 'unknown';
        return {
            status  => $response->status_line,
            message => $response->decoded_content,
        };
    }
}

sub get_host {
    my $config   = load_config();
    my $http     = $config->{http};
    my $protocol = $http->{protocol};
    my $host     = $http->{host};
    return "$protocol://$host";
}

sub build_url_template {
    my ( $buz, $path, $params_for ) = @_;
    my $config     = load_config();
    my $block_path = $config->{$buz}->{path};
    my $base_uri   = $block_path->{$path};
    my $host       = get_host();
    my $url        = "${host}${base_uri}";

    # print "base url: $url, params:\n" . Dump($params_for) . "\n";
    my @params;
    if ($params_for) {
        @params = map {
            my $value = $params_for->{$_};
            $value = url_encode_utf8($value);
            "$_=$value";
        } ( keys %{$params_for} );

        # print "params:\n" . Dump( \@params ) . "\n";
    }
    if ( @params > 0 ) {
        $url = $url . '?' . join( '&', @params );
    }

    # print "final url: $url\n";
    return $url;
}

1;

__END__

=head1 NAME

Circle::Common - the common module for Circle::Chain SDK

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Circle::Common;
    my $url = build_url_template('user', 'getBlockHashList', {
      baseHeight => 0,
    });
    my $response = http_json_get($url);
    if ($response->{status} == 200) {
      my $data = $response->{data};
      # process data here.
    }

    my $logout_url = build_url_template('user', 'logout', {});
    $response = http_json_post($logout_url);
    if ($response->{status} == 200) {
      my $data = $response->{data};
      # check the logout success here.
    }

=head1 DESCRIPTION

The L<Circle::Common> is common module which provides common functions: http restful api get, http restful api post and build url template etc.

=head1 METHODS

=head2 build_url_template

    my $url = build_url_template('user', 'getBlockHashList', {
      baseHeight => 10,
    });

  Builds user's getBlockHashList url.

    my $url = build_url_template($buz, $path, $params_for);

  $buz stands for: 'user', 'block', 'wallet' business modules.
  $path stands for the key of the variant urls.
  $params_for stands for the request query map.

=head2 load_config

    my $config = load_config();
    # process the config data here.

=head2 get_session_key

    my $session_key = get_session_key();
    # process the session key here.

In fact, you needn't set session key when you post apis. In SDK we set the session key in the post/get headers after you logged successfully.

=head2 http_json_get

    my $response = http_json_get($url);

Invokes the http json get request to circle chain server. the response data contains three fields: status, message and data:

    my $response = http_json_get($url);
    if ($response->{status} == 200) {
      my $data = $response->{data};
      # process you data here.
    }


=head2 http_json_post

    my $response = http_json_post($url, $body);

Invokes the http json post request to circle chain server. the response data contains three fields: status, message and data:

    my $body = {
      ...
    };
    my $response = http_json_post($url, $body);
    if ($response->{status} == 200) {
      my $data = $response->{data};
      # process your data here.
    }

=head1 SEE ALSO

See L<Circle::User> for circle user module.

See L<Circle::Wallet> for circle wallet module.

See L<Circle::Block> for circle block module.


=head1 COPYRIGHT AND LICENSE

Copyright 2024-2030 Charles li

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
