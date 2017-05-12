
package API::Plesk;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use HTTP::Request;
use LWP::UserAgent;
use XML::Fast;
use version;

use API::Plesk::Response;

our $VERSION = '2.03';

# creates accessors to components
# can support old interface of API::Plesk
init_components(
    # new
    customer           => [['1.6.3.0', 'Customer']],
    webspace           => [['1.6.3.0', 'Webspace']],
    site               => [['1.6.3.0', 'Site']],
    subdomain          => [['1.6.3.0', 'Subdomain']],
    site_alias         => [['1.6.3.0', 'SiteAlias']],
    sitebuilder        => [['1.6.3.0', 'SiteBuilder']],
    ftp_user           => [['1.6.3.0', 'FTPUser']],
    service_plan       => [['1.6.3.0', 'ServicePlan']],
    service_plan_addon => [['1.6.3.0', 'ServicePlanAddon']],
    database           => [['1.6.3.0', 'Database']],
    webuser            => [['1.6.3.0', 'WebUser']],
    dns                => [['1.6.3.0', 'DNS']],
    mail               => [['1.6.3.0', 'Mail']],
    user               => [['1.6.3.0', 'User']],

    # old
    Accounts => [['1.5.0.0', 'Accounts']],
    Domains  => [['1.5.0.0', 'Domains']],
);

# constructor
sub new {
    my $class = shift;
    $class = ref ($class) || $class;

    my $self = {
        username    => '',
        password    => '',
        secret_key  => '',
        url         => '',
        api_version => '1.6.3.1',
        debug       => 0,
        timeout     => 30,
        (@_)
    };

    if (!$self->{secret_key}) {
        confess "Required username!" unless $self->{username};
        confess "Required password!" unless $self->{password};
    }
    confess "Required url!"      unless $self->{url};

    return bless $self, $class;
}

# sends request to Plesk API
sub send {
    my ( $self, $operator, $operation, $data, %params ) = @_;

    confess "Wrong request data!" unless $data && ref $data;

    my $xml = { $operator => { $operation => $data } };

    $xml = $self->render_xml($xml);

    warn "REQUEST $operator => $operation\n$xml" if $self->{debug};

    my ($response, $error) = $self->xml_http_req($xml);

    warn "RESPONSE $operator => $operation => $error\n$response" if $self->{debug};

    unless ( $error ) {
        $response = xml2hash $response, array => [$operation, 'result', 'property'];
    }

    return API::Plesk::Response->new(
        operator  => $operator,
        operation => $operation,
        response  => $response,
        error     => $error,
    );
}

sub bulk_send { confess "Not implemented!" }

# Send xml request to plesk api
sub xml_http_req {
    my ($self, $xml) = @_;

    # HTTP::Request undestends only bytes
    utf8::encode($xml) if utf8::is_utf8($xml);

    my $ua = new LWP::UserAgent( parse_head => 0 );
    my $req = new HTTP::Request POST => $self->{url};

    if ($self->{secret_key}) {
        $req->push_header(':KEY',  $self->{secret_key});
    } else {
        $req->push_header(':HTTP_AUTH_LOGIN',  $self->{username});
        $req->push_header(':HTTP_AUTH_PASSWD', $self->{password});
    }
    $req->content_type('text/xml; charset=UTF-8');
    $req->content($xml);

    # LWP6 hack to prevent verification of hostname
    $ua->ssl_opts(verify_hostname => 0) if $ua->can('ssl_opts');

    warn $req->as_string   if defined $self->{debug}  &&  $self->{debug} > 1;

    my $res = eval {
        local $SIG{ALRM} = sub { die "connection timeout" };
        alarm $self->{timeout};
        $ua->request($req);
    };
    alarm 0;

    warn $res->as_string   if defined $self->{debug}  &&  $self->{debug} > 1;

    return ('', 'connection timeout')
        if !$res || $@ || ref $res && $res->status_line =~ /connection timeout/;

    return $res->is_success() ?
        ($res->content(), '') :
        ('', $res->status_line);
}


# renders xml packet for request
sub render_xml {
    my ($self, $hash) = @_;

    my $xml = _render_xml($hash);

    $xml = qq|<?xml version="1.0" encoding="UTF-8"?><packet version="$self->{api_version}">$xml</packet>|;

    $xml;
}

# renders xml from hash
sub _render_xml {
    my ( $hash ) = @_;

    return $hash unless ref $hash;

    my $xml = '';

    for my $tag ( keys %$hash ) {
        my $value = $hash->{$tag};
        if ( ref $value eq 'HASH' ) {
            $value = _render_xml($value);
        }
        elsif ( ref $value eq 'ARRAY' ) {
            my $tmp;
            $tmp .= _render_xml($_) for ( @$value );
            $value = $tmp;
        }
        elsif ( ref $value eq 'CODE' ) {
            $value = _render_xml(&$value);
        }

        if ( !defined $value or $value eq '' ) {
            $xml .= "<$tag/>";
        }
        else {
            $xml .= "<$tag>$value</$tag>";
        }
    }

    $xml;
}


# initialize components
sub init_components {
    my ( %c ) = @_;
    my $caller = caller;

    for my $alias (  keys %c ) {

        my $classes = $c{$alias};

        my $sub = sub {
            my( $self ) = @_;
            $self->{"_$alias"} ||= $self->load_component($classes);
            return $self->{"_$alias"} || confess "Not implemented!";
        };

        no strict 'refs';

        *{"$caller\::$alias"} = $sub;


    }

}

# loads component package and creates object
sub load_component {
    my ( $self, $classes ) = @_;
    my $version = version->parse($self->{api_version});

    for my $item ( @$classes ) {

        # select compitable version of component
        if ( $version >= $item->[0] ) {

            my $pkg = 'API::Plesk::' . $item->[1];

            my $module = "$pkg.pm";
               $module =~ s/::/\//g;

            local $@;
            eval { require $module };
            if ( $@ ) {
                confess "Failed to load $pkg: $@";
            }

            return $pkg->new(plesk => $self);

        }

    }

}

1;

__END__

=head1 NAME

API::Plesk - OO interface to the Plesk XML API (http://www.parallels.com/en/products/plesk/).

=head1 SYNOPSIS

    use API::Plesk;

    my $api = API::Plesk->new(
        username    => 'user', # required
        password    => 'pass', # required
        url         => 'https://127.0.0.1:8443/enterprise/control/agent.php', # required
        api_version => '1.6.3.1',
        debug       => 0,
        timeout     => 30,
    );

    my $res = $api->customer->get();

    if ($res->is_success) {
        for ( @{$res->data} ) {
            print "login: $_->{login}\n";
        }
    }
    else {
        print $res->error;
    }

=head1 DESCRIPTION

At present the module provides interaction with Plesk 10.1 (API 1.6.3.1).
Distribution was completely rewritten and become more friendly for developers.
Naming of packages and methods become similar to the same operators and operations of Plesk XML API.

Partially implemented:

API::Plesk::Customer

API::Plesk::Database

API::Plesk::DNS

API:Plesk::FTPUser

API:Plesk::Mail

API::Plesk::ServicePlan

API::Plesk::ServicePlanAddon

API::Plesk::Site

API::Plesk::SiteAlias

API::Plesk::SiteBuilder

API::Plesk::Webspace

API::Plesk::WebUser

API::Plesk::User

=head1 COMPATIBILITY WITH VERSION 1.*

This is develover release. Comapatibility with Plesk::API 1.* is not implemented yet.

=head1 METHODS

=over 3

=item new(%params)

Create new class instance.

Required params:
username
password
url

Additional params:
api_version - default 1.6.3.1
debug       - default 0
timeout     - default 30 sec.

=item send($operator, $operation, $data, %params)

This method prepare and sends request to Plesk API.

Returns API::Plesk::Response object.

$operator - name of operator XML section of Plesk API.

$operation - mane of operation XML section of Plesk API.

$data - data hash that is converted to XML and is sended to plesk server.

=item xml_http_req( $xml )

Internal method. it implements real request sending to Plesk API.

Returns array ( $response_xml, $error ).

=back

=head1 SEE ALSO

Plesk XML RPC API  http://www.parallels.com/en/products/plesk/docs/

=head1 AUTHORS

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>

Ivan Sokolov E<lt>ivsokolov[at]cpan.orgE<gt>

B<Thanks for contribution:>

Nikolay Shulyakovskiy E<lt>shulyakovskiy[at]rambler.ruE<gt>

bgmilne

Eugeny Zavarykin

Eugen Konkov

Ivan Shamal

Akzhan Abdulin

Jari Turkia

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ivan Sokolov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
