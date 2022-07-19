package Mock::LWP::UserAgent;

use 5.006002;

use strict;
use warnings;

use Carp;
use Digest::MD5 ();
use File::Spec;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.155';

our $CANNED_RESPONSE_DIR = File::Spec->catdir(
    qw{ t data Mock-LWP-UserAgent } );

our $LOG_FILE_NAME = $ENV{MOCK_LWP_USERAGENT_LOG_FILE_NAME};

use constant HASH_REF	=> ref {};

$LOG_FILE_NAME
    and eval {
    require Test::More;
    1;
} or $LOG_FILE_NAME = undef;

## my %original = map { $_ => LWP::UserAgent->can( $_ ) } qw{
##     new cookie_jar env_proxy get head post put request
## };

sub import {

    $Astro::SpaceTrack::SPACETRACK_DELAY_SECONDS = 0;

    no warnings qw{ redefine };

    *LWP::UserAgent::new = sub {
	my ( $class ) = @_;
	return bless {
	    json	=> JSON->new()->utf8()->pretty()->canonical(),
	}, ref $class || $class;
    };

    *LWP::UserAgent::cookie_jar = sub {
	my ( $self, $data ) = @_;
	my $old = $self->{cookie_jar};
	if ( $data ) {
	    if ( HASH_REF eq ref $data ) {
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
	return _fetch( $self, GET => $url );
    };

    *LWP::UserAgent::head = sub {
	my ( $self, $url ) = @_;
	return _fetch( $self, HEAD => $url );
    };

    *LWP::UserAgent::post = sub {
	my ( $self, $url ) = @_;
	return _fetch( $self, POST => $url );
    };

    *LWP::UserAgent::put = sub {
	my ( $self, $url ) = @_;
	return _fetch( $self, PUT => $url );
    };

    *LWP::UserAgent::request = sub {
	my ( $self, $rqst ) = @_;
	my $method = $rqst->method();
	my $url = $rqst->url();
	my $path = __file_name_for( $method, $url );
	$LOG_FILE_NAME
	    and Test::More::diag( "Reading $path\n    for $method $url" );
	-f $path
	    or return _fail( $rqst, 404, "File $path not found" );
	local $/ = undef;
	open my $fh, '<:encoding(utf-8)', $path
	    or return _fail( $rqst, 500, "Failed to open $path: $!" );
	my $input = <$fh>;
	close $fh;
	my @data;
	eval {
	    @data = @{ $self->{json}->decode( $input ) };
	    1;
	} or return _fail( $rqst, 500, "Failed to decode content of $path: $@" );
	my $resp = HTTP::Response->new( @data[ 0 .. 3 ] );
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

sub _fetch {
    my ( $self, $method, $url ) = @_;
    my $rqst = HTTP::Request->new( $method, $url );
    return $self->request( $rqst );
}

sub __file_name_for {
    my ( $method, $url ) = @_;
    return File::Spec->catfile(
	$CANNED_RESPONSE_DIR,
	Digest::MD5::md5_hex( "$method-$url" ) . '.json',
    );
}

1;

__END__

=head1 NAME

Mock::LWP::UserAgent - Mock version of Mock::LWP::UserAgent

=head1 SYNOPSIS

 use Mock::LWP::UserAgent;

 my $ua = LWP::UserAgent->new();
 my $resp = $ua->get( $url );

or, to have the support routines but have a working C<LWP::UserAgent>,

 use Mock::LWP::UserAgent ();

=head1 DESCRIPTION

THIS CLASS IS PRIVATE TO THE C<Astro-SpaceTrack> DISTRIBUTION. It may be
modified or revoked at any time, without notice. Documentation is for
the benefit of the author.

In order to work correctly, this module must be imported B<after>
C<Astro::SpaceTrack>.

This class mocks the salient features of the C<Mock::LWP::UserAgent>
interface. But all responses are canned, and based on files.

By default the files are stored in F<inc/mock/LWP/UserAgent/>, but this
can be changed by localizing C<$Mock::LWP::UserAgent::CANNED_RESPONSE_DIR> and
storing the path to the desired directory in it.

The actual canned response files are JSON, and encodes the array of
arguments to C<< HTTP::Response->new() >> to construct the response to
the request. Because of the size of the URLs involved, the base name of
the file cprresponding to any request is the MD5 hash of the string
C<"$method-$url">, with C<'.json'> appended. The substitution variables
are the HTTP method name being used (C<'GET'>, C<'HEAD'>, C<'POST'>, or
C<'PUT'>) and the URL being fetched.

Only the first four elements of the array are used to construct the
response. By convention the fifth element of the array is a hash
containing keys C<{method}> and C<{uri}>, to give the reader of the file
some idea what it is a response to.

Assuming the given file can be opened, read, and decoded to an array
reference, the L<HTTP::Response|HTTP::Response> object that it specifies
will be returned. If an error occurs in processing, an appropriate
L<HTTP::Response|HTTP::Response> object will be returned: a 404 if the
file is not found, or a 500 for any other error.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $ua = Mock::LWP::UserAgent->new();

This static method instantiates the object.

=head2 env_proxy

 $ua->env_proxy();

This method does nothing.

=head2 get

 my $resp = $ua->get( $url );

This method returns the response for a GET request on the given URL.

=head2 head

 my $resp = $ua->head( $url );

This method returns the response for a HEAD request on the given URL.

=head2 post

 my $resp = $ua->post( $url );

This method returns the response for a POST request on the given URL.

=head2 put

 my $resp = $ua->put( $url );

This method returns the response for a PUT request on the given URL.

=head2 request

 my $resp = $ua->request( $rqst );

This method returns the response for the given
L<HTTP::Request|HTTP::Request> object.


=head1 ATTRIBUTES

This class has no public attributes.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
