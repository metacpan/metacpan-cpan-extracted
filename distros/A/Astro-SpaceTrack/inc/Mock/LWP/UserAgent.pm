package Mock::LWP::UserAgent;

use 5.006002;

use strict;
use warnings;

use Carp;
use Errno qw{ ENOENT };
use File::Spec;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.166';

our $CANNED_RESPONSE_FILE;

use constant REF_HASH	=> ref {};

sub install_mock {

    $Astro::SpaceTrack::SPACETRACK_DELAY_SECONDS = 0;

    no warnings qw{ redefine };

    *LWP::UserAgent::new = sub {
	my ( $class, @arg ) = @_;
	### my $self = $class->SUPER::new( @arg );
	my $self = bless {}, $class;
	$self->{ +__PACKAGE__ } = __load_data();
	return $self;
    };

    *LWP::UserAgent::cookie_jar = sub {
	my ( $self, $data ) = @_;
	my $old = $self->{cookie_jar};
	if ( $data ) {
	    if ( REF_HASH eq ref $data ) {
		require HTTP::Cookies;
		$data = HTTP::Cookies->new( %{ $data } );
	    }
	    $self->{cookie_jar} = $data;
	}
	return $old;
    };

    *LWP::UserAgent::env_proxy = sub {
	return;
    };

    *LWP::UserAgent::get = sub {
	my ( $self, $url ) = @_;
	return $self->request( HTTP::Request->new( GET => $url ) );
    };

    *LWP::UserAgent::head = sub {
	my ( $self, $url ) = @_;
	return $self->request( HTTP::Request->new( HEAD => $url ) );
    };

    *LWP::UserAgent::post = sub {
	my ( $self, $url ) = @_;
	return $self->request( HTTP::Request->new( POST => $url ) );
    };

    *LWP::UserAgent::put = sub {
	my ( $self, $url ) = @_;
	return $self->request( HTTP::Request->new( PUT => $url ) );
    };

    *LWP::UserAgent::request = sub {
	my ( $self, $rqst ) = @_;
	my $method = $rqst->method();
	my $url = $rqst->url();

	my $data = $self->{ +__PACKAGE__ }{data}{$url}{$method}
	    or return _fail( $rqst, 404, "$method $url not found" );
	my $resp = HTTP::Response->new( @{ $data } );

	$resp->request( $rqst );
	if ( my $jar = $self->cookie_jar() ) {
	    $jar->extract_cookies( $resp );
	}
	return $resp;
    };
}

sub _fail {
    my ( $rqst, $code, $msg ) = @_;
    my $resp = HTTP::Response->new( $code, $msg );
    $resp->request( $rqst );
    return $resp;
}

sub __load_data {
    my ( %arg ) = @_;
    my $path = defined $CANNED_RESPONSE_FILE ?
	$CANNED_RESPONSE_FILE :
	File::Spec->catfile( qw{ t data Mock-LWP-UserAgent resp.json } );
    my $json = JSON->new();
    my $data;
    if ( open my $fh, '<:encoding(utf-8)', $path ) {
	local $/ = undef;	# Slurp mode
	$data = $json->decode( scalar <$fh> );
	close $fh;
    } elsif ( $arg{optional} && $! == ENOENT ) {
	$data = {};
    } else {
	croak "Failed to open $path: $!";
    }
    return +{
	path	=> $path,
	data	=> $data,
    };
}

sub __modify_data {
    my ( $data, $url, $method, $resp ) = @_;
    $data->{data}{$url}{$method} = $resp;
    my $path = $data->{path};
    my $json = JSON->new()->pretty()->canonical();
    open my $fh, '>:encoding(utf-8)', $path
	or croak "Unable to modify $path: $!";
    print { $fh } $json->encode( $data->{data} );
    close $fh;
    return;
}

1;

__END__

=head1 NAME

Mock::LWP::UserAgent - Mock version of Mock::LWP::UserAgent

=head1 SYNOPSIS

 use Mock::LWP::UserAgent;
 Mock::LWP::UserAgent->install_mock();

 my $ua = LWP::UserAgent->new();
 my $resp = $ua->get( $url );	# From the mock object's database.

or, to have the support routines but have a working C<LWP::UserAgent>,

 use Mock::LWP::UserAgent;

=head1 DESCRIPTION

THIS CLASS IS PRIVATE TO THE C<Astro-SpaceTrack> DISTRIBUTION. It may be
modified or revoked at any time, without notice. Documentation is for
the benefit of the author.

If L<install_mock()|/install_mock> is called, this class mocks the
salient features of the L<LWP::UserAgent|LWP::UserAgent> interface. But
all responses are canned.

By default the responses are stored in
F<t/data/Mock-LWP-UserAgent/resp.json>, but this can be changed by
localizing C<$Mock::LWP::UserAgent::CANNED_RESPONSE_FILE> and storing
the path to the desired file in it B<before> instantiating
L<LWP::UserAgent|LWP::UserAgent>.

The canned response file is a JSON representaton of a hash keyed by URL
and, within URL, by HTTP method (C<GET>, C<POST>, and so on). The actual
responses are four-element arrays that constitute the arguments to
C<< HTTP::Response->new() >>.

Assuming the given file can be opened, read, and decoded, any request
will be satisfied by an L<HTTP::Response|HTTP::Response> object
generated from the data in the file. If the URL and method do not appear
in the file, a 404 response is generated.

=head1 METHODS

This class supports the following public method:

=head2 install_mock

This static method sets C<$Astro::SpaceTrack::SPACETRACK_DELAY_SECONDS>
to zero. It also hot-patches the following
L<LWP::UserAgent|LWP::UserAgent> methods:

=head3 new

 my $ua = LWP::UserAgent->new();

This static method instantiates the object.

It calls subroutine (B<not> method) L<__load_data()|/__load_data> to
populate the canned data.

=head3 env_proxy

 $ua->env_proxy();

This method does nothing.

=head3 get

 my $resp = $ua->get( $url );

This method returns the response for a GET request on the given URL.
The heavy lifting is done by L<request()|/request>.

=head3 head

 my $resp = $ua->head( $url );

This method returns the response for a HEAD request on the given URL.
The heavy lifting is done by L<request()|/request>.

=head3 post

 my $resp = $ua->post( $url );

This method returns the response for a POST request on the given URL.
The heavy lifting is done by L<request()|/request>.

=head3 put

 my $resp = $ua->put( $url );

This method returns the response for a PUT request on the given URL.
The heavy lifting is done by L<request()|/request>.

=head3 request

 my $resp = $ua->request( $rqst );

This method returns the response for the given
L<HTTP::Request|HTTP::Request> object from the data loaded by
L<__load_data()|/__load_data>. If the given URL and method are not
found, the response is a 404 error.

=head1 ATTRIBUTES

This class has no public attributes.

=head1 SUBROUTINES

This class also has a couple old-school subroutines to manage its data.
These are unsupported, and documented solely for the convenience of the
author.

=head2 __load_data

This subroutine loads data from a JSON file and returns a reference to a
two-element hash. Key C<{path}> contains the path to the file, and key
C<{data}> contains the data in the file, after it has been decoded from
JSON.

The path to the file comes from
C<$Mock::LWP::UserAgent::CANNED_DATA_FILE>. If that is C<undef> (which
it is by default), F<t/data/Mock-LWP-UserAgent/resp.json> is read.

Optional arguments can be specified as name/value pairs. The following
arguments are supported:

=over

=item optional

If this Boolean argument is true, the file need not exist, and if it
does not the returned data hash will be empty.

If this Boolean argument is false, or is not specified, a missing file
is an error.

=back

All other arguments are unsupported, and behavior if specified may
change without notice.

=head2 __modify_data

This subroutine takes four arguments. These are:

=over

=item 1) The data returned by L<__load_data()|/__load_data>;

=item 2) The URL being recorded;

=item 3) The method by which the URL was fetched

=item 4) An array reference containing the desired arguments to C<new()> to construct the response.

=back

The response is stored in the data, which are then rewritten to the
file.

=head1 SEE ALSO

L<LWP::UserAgent|LWP::UserAgent>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
