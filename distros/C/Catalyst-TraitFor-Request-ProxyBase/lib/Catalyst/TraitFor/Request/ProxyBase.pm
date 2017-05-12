package Catalyst::TraitFor::Request::ProxyBase;
use Moose::Role;
use URI ();
use namespace::autoclean;

our $VERSION = '0.000005';
$VERSION = eval $VERSION;

requires qw/
    base
    secure
/;

sub _with_scheme { return $_[0] =~ m/^https?/; }

around 'base' => sub {
    my ($orig, $self, @args) = @_;

	my $isset = $self->meta->find_attribute_by_name('base')->has_value($self);

    if ( $isset && @args == 0 ) {
		return $self->$orig(@args);
    }
    else {
        if (my $base = $self->header('X-Request-Base')) {
            if (_with_scheme($base)) {
                $base .= '/' unless $base =~ m|/$|;
                @args = (URI->new($base));
            }
            else {
                my $proxy_base = $self->$orig(@args)->clone();
                $proxy_base->path( $base . $proxy_base->path() );
                @args = ( $proxy_base );
            }
        }
    }
    $self->$orig(@args);
};

around 'uri' => sub {
    my ($orig, $self, @args) = @_;

	my $isset = $self->meta->find_attribute_by_name('uri')->has_value($self);
	if ( $isset && @args == 0 ) {
		return $self->$orig(@args);
	}

    my $uri = $self->$orig(@args)->clone;

    if ( my $base = $self->header('X-Request-Base') ) {
        if (_with_scheme($base)) {
            my $proxy_uri = URI->new( $base );

            my $proxy_path = $proxy_uri->path;
            my $orig_path  = $uri->path;

            $proxy_path =~ s{/$}{} if $orig_path =~ m{^/};

            $uri->scheme( $proxy_uri->scheme );
            $uri->path( $proxy_path . $orig_path );
        }
        else {
            $uri->path( $base . $uri->path() );
        }
    }

	return $self->$orig( ($uri) );
};

around 'secure' => sub {
    my ($orig, $self, @args) = @_;
    if (my $base = $self->header('X-Request-Base')) {
        if (_with_scheme($base)) {
            return URI->new($base)->scheme eq 'http' ? 0 : 1;
        }
    }
    $self->$orig(@args);
};

1;

__END__

=head1 NAME

Catalyst::TraitFor::Request::ProxyBase - Replace request base with value passed by HTTP proxy

=head1 SYNOPSIS

    package MyApp;
    use Moose;
    use namespace::autoclean;

    use Catalyst;
    use CatalystX::RoleApplicator;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::ProxyBase
    /);

    __PACKAGE__->setup;

=head1 DESCRIPTION

This module is a L<Moose::Role> which allows you more flexibility in your
application's deployment configurations when deployed behind a proxy.

The problem is that there is no standard way for a proxy to tell a backend
server what the original URI for the request was, or if the request was
initially SSL. (Yes, I do know about C<< X-Forwarded-Host >>, but they don't
do enough)

This creates an issue for someone wanting to deploy the same cluster of
application servers behind various URI endpoints.

Using this module, the request base (C<< $c->req->base >>)
is replaced with the contents of the C<< X-Request-Base >> header,
which is expected to be a full URI, for example:

    http://example.com
    https://example.com
    http://other.example.com:81/foo/bar/yourapp

This value will then be used as the base for uris constructed by
C<< $c->uri_for >>.

In addition the request uri (C<< $c->req->uri >>) will reflect the scheme and path specifed in the header.

=head1 REQUIRED METHODS

=over

=item base

=item secure

=back

=head1 WRAPPED METHODS

=over

=item base

=item secure

=back

=head1 APACHE SETUP

On the frontend Proxy Apache, you would want to enable a Virtualhost config
somewhat like this. The backend apache config stays unchanged.

    <Virtualhost *:80>
        ProxyRequests Off

        <Location /preview>
            # You must have mod_headers enabled for that
            # RequestHeader set X-Request-Base /preview
            RequestHeader set X-Request-Base http://www.example.com/preview
        </Location>

        ProxyPass /preview http://my.vpn.host/
        ProxyPassReverse /preview http://my.vpn.host/
    </Virtualhost>

=head1 BUGS

Probably. Patches welcome, please fork from:

    http://github.com/bobtfish/catalyst-traitfor-request-proxybase

and send a pull request.

=head1 AUTHORS

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 CONTRIBUTORS

Klaus Ita (koki) C<< <klaus@worstofall.com> >>

=head1 COPYRIGHT

This module is Copyright (c) 2009 Tomas Doran and is licensed under the same
terms as perl itself.

=cut

