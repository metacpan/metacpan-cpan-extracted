use 5.010001;
use strict;
use warnings;

package App::Filite::Client;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

use Carp qw( croak );
use File::XDG;
use Getopt::Long qw( GetOptionsFromArray );
use HTTP::Tiny;
use HTTP::Tiny::Multipart;
use JSON::PP qw( encode_json decode_json );
use MIME::Base64 qw( encode_base64 );
use Path::Tiny qw( path );

use Class::Tiny {
	password   => sub { croak "Missing option: password" },
	server     => sub { croak "Missing option: server" },
	useragent  => sub { shift->_build_useragent },
	errors     => sub { 0 },
};

use namespace::autoclean;

sub new_from_config {
	my ( $class ) = ( shift );
	
	state $xdg = File::XDG->new( name => 'filite-client', api => 1 );
	my $config_file = $ENV{FILITE_CLIENT_CONFIG} // $xdg->config_home->child( 'config.json' );
	if ( not ref $config_file ) {
		$config_file = path( $config_file );
	}
	croak "Expected config file: $config_file" unless $config_file->is_file;
	
	my $args = decode_json( $config_file->slurp_utf8 );
	my $self = $class->new( %$args );
	return $self;
}

sub _build_useragent {
	my ( $self ) = ( shift );
	my $auth = encode_base64( sprintf( 'admin:%s', $self->password ) );
	chomp $auth;
	return HTTP::Tiny->new(
		agent => sprintf( '%s/%s ', __PACKAGE__, $VERSION ),
		default_headers => { 'Authorization' => "Basic $auth" },
	);
}

sub _parse_opts {
	my ( $self, $args ) = ( shift, @_ );
	
	my $opts = {};
	GetOptionsFromArray(
		$args => $opts,
		'text|T',
		'file|F',
		'link|L',
		'highlight|H',
		'help|usage',
	);
	return $opts;
}

## no Test::Tabs
sub _print_usage {
	print <<"STDERR"; return 0;
filite-client: share via a filite server

Usage:
  filite-client -T [filename]
  filite-client -F [filename]
  filite-client -L [url]
  cat blah | filite-client [options]

Options:
  --text, -T         Share as text
  --file, -F         Share as file
  --link, -L         Share as link
  --highlight, -H    Syntax highligh text
  --help, --usage    Show this usage information

STDERR
}
## use Test::Tabs

sub execute {
	my ( $self, $args ) = ( shift, @_ );
	$args //= [ @ARGV ];
	my $opts = $self->_parse_opts( $args );
	$args = [ '-' ] unless @$args;
	
	if ( $opts->{help} ) {
		return $self->_print_usage;
	}
	
	for my $file ( @$args ) {
		my $url = $self->share( $file, $opts );
		print "$url\n";
	}
	
	$self->errors;
}

sub _guess_mode {
	my ( $self, $file, $opts ) = ( shift, @_ );
	return 'link' if $opts->{link};
	return 'text' if $opts->{text};
	return 'file' if $opts->{file};
	return 'link' if $file =~ m{\Ahttps?://\S+\z}is;
	return 'text' if $opts->{highlight};
	return 'text' if $file eq '-';
	return 'file' if -B $file;
	return 'text';
}

sub share {
	my ( $self, $file, $opts ) = ( shift, @_ );
	$opts //= {};
	my $mode = $self->_guess_mode( $file, $opts );
	my $method = "share_$mode";
	return $self->$method( $file, $opts );
}

sub _get_endpoint {
	my ( $self, $mode ) = ( shift, @_ );
	my $server = $self->server;
	$server = "http://$server" unless $server =~ m{https?:}i;
	$server .= '/' unless $server =~ m{/$};
	return sprintf( '%s%s', $server, lc( substr( $mode, 0, 1 ) ) );
}

sub _handle_response {
	my ( $self, $response ) = ( shift, @_ );
	if ( $response->{success} ) {
		return $response->{content};
	}
	my $errs = $self->errors;
	++$errs;
	$self->errors( $errs );
	warn sprintf( "ERROR: %s %s\n", $response->{status}, $response->{reason} );
	return "-";
}

sub share_file {
	my ( $self, $file, $opts ) = ( shift, @_ );
	$opts //= {};
	
	my ( $filename, $content );
	if ( $file eq '-' ) {
		$filename = 'file.data';
		local $/;
		$content = <STDIN>;
	}
	else {
		my $pt = path( $file );
		$filename = $pt->basename;
		$content  = $pt->slurp;
	}
	
	my $endpoint = $self->_get_endpoint( 'file' );
	my $response = $self->useragent->post_multipart(
		$endpoint => {
			file => {
				filename     => $filename,
				content      => $content,
				content_type => 'application/octet-stream',
			},
		},
	);
	
	return sprintf( '%s/%s', $endpoint, $self->_handle_response( $response ) );
}

sub share_text {
	my ( $self, $file, $opts ) = ( shift, @_ );
	$opts //= {};
	
	my $content;
	if ( $file eq '-' ) {
		local $/;
		$content = <STDIN>;
	}
	else {
		$content = path( $file )->slurp;
	}
	
	my $json = encode_json( {
		contents   => $content,
		highlight  => $opts->{highlight} ? \1 : \0,
	} );
	
	my $endpoint = $self->_get_endpoint( 'text' );
	my $response = $self->useragent->post(
		$endpoint => {
			content => $json,
			headers => { 'Content-Type' => 'application/json' },
		},
	);
	
	return sprintf( '%s/%s', $endpoint, $self->_handle_response( $response ) );
}

sub share_link {
	my ( $self, $file, $opts ) = ( shift, @_ );
	$opts //= {};
	
	my $forward;
	if ( $file eq '-' ) {
		local $/;
		$forward = <>;
	}
	else {
		$forward = $file;
	}
	
	chomp $forward;
	
	my $json = encode_json( {
		forward => $forward,
	} );
	
	my $endpoint = $self->_get_endpoint( 'link' );
	my $response = $self->useragent->post(
		$endpoint => {
			content => $json,
			headers => { 'Content-Type' => 'application/json' },
		},
	);
	
	return sprintf( '%s/%s', $endpoint, $self->_handle_response( $response ) );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Filite::Client - client library for Filite servers

=head1 SYNOPSIS

  my $client = App::Filite::Client->new_from_config;
  my $url = $client->share( 'path/to/file.txt' );
  print "Shared to $url\n";

=head1 DESCRIPTION

Share a file, chunk of text, or link via a Filite server.

Filite is a URL shortner, file sharer, and pastebin that you can self-host.

=head2 Config File

Configuration is via a JSON-formatted file usually named
F<< ~/.config/filite-client/config.json >> (see also L<File::XDG>),
though this can be overridden using the C<< FILITE_CLIENT_CONFIG >>
environment variable.

=head2 Constructors

=over

=item C<< new( %attrs ) >>

Moose-like constructor.

=item C<< new_from_config() >>

Load C<< %attrs >> from the config instead of as parameters.

=back

=head2 Attributes

All attributes are read-write.

=over

=item C<< server >> B<< Str >>

The filite server to share things via. This will typically be a URL
like "https://example.com/" or "http://example.net:8080".

=item C<< password >> B<< Str >>

Filite is a single user system so has a password but no username.

=item C<< useragent >> B<< Object >>

Can be set to a custom L<HTTP::Tiny> instance. Cannot be specified in
the config file.

=item C<< errors >> B<< Int >>

The number of errors which have been seen so far. It makes little
sense to set this in the constructor or config file.

=back

=head2 Methods

=over

=item C<< share( $filename, \%opts ) >>

Accepts C<text>, C<file>, C<link>, and C<highlight> options. All of these
options are booleans.

C<< $filename >> may be "-" to read from STDIN.

=item C<< share_text( $filename, \%opts ) >>

Accepts a C<highlight> option, which is a boolean.

C<< $filename >> may be "-" to read from STDIN.

=item C<< share_file( $filename, \%opts ) >>

The options are ignored.

C<< $filename >> may be "-" to read from STDIN.

=item C<< share_link( $url, \%opts ) >>

The options are ignored.

C<< $url >> may be "-" to read a URL from STDIN.

=item C<< execute( \@argv ) >>

Reads options and input filenames/URLs from C<< @argv >>, like processing
a command-line. If C<< @argv >> isn't given, then uses the global C<< @ARGV >>.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-app-filite-client/issues>.

=head1 SEE ALSO

L<https://github.com/raftario/filite>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

