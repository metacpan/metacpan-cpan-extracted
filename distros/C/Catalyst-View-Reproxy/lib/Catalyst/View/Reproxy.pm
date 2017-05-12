package Catalyst::View::Reproxy;

use strict;
use warnings;

use base qw/Catalyst::View/;

use Fcntl;
use File::MimeInfo qw//;
use File::MMagic;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use NEXT;

__PACKAGE__->mk_accessors(qw/mmagic/);

=head1 NAME

Catalyst::View::Reproxy - Reproxing View for lighty and perlbal.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

In your view class

	package MyApp::View::MyReproxy;

  use base qw/Catalyst::View::Reproxy/;

  __PACKAGE__->config(
    perlbal => 1
  );

In your controller class

  sub index: Private {
    my ($self, $c) = @_;

    $c->forward('View::MyReproxy', {});
  }

=head1 METHODS

=head2 new($c, $arguments)

Constructor

=over 2

=item config, arguments

=over 2

=item lighttpd

If the frontend web server is lighttpd, the value would be 1. (default 0)

=item perlbal

If the frontend web server is perlbal, the value would be 1. (default 0)

=item mime_magic

Using mime magic. (depend on L<File::MMagic>)

=item mime_magic_file

Using external magic file (see L<File::MMagic>)

=item timeout

Emulating "X-REPROXY-URL" without using perlbal, 
L<LWP::UserAgent>'s timeout setting. (see L<LWP::UserAgent>)

=back

=back

=cut

sub new {
    my ( $class, $c, $arguments ) = @_;

    my $config = {
        lighttpd        => 0,
        perlbal         => 0,
        mime_magic      => 0,
        mime_magic_file => undef,
        timeout         => 0
    };

    $config =
      $class->merge_config_hashes( $config, $arguments, $class->config );
    $class->config($config);

    my $self = $class->NEXT::new( $c, $config );

    if (   $config->{mime_magic}
        && $config->{mime_magic_file}
        && -e $config->{mime_magic_file} )
    {
        $self->mmagic( File::MMagic->new( $config->{mime_magic_file} ) );
    }

    $c->log->debug("$class config parameters");

    return $self;
}

=head2 process($c, $arguments)

Override L<Catalyst::View> process method.

Using 'X-REPROXY-FILE' or 'X-Sendfile' header,

  sub index: Private {
    my ($self, $c) = @_;

    $c->forward('View::MyReproxy', [reproxy_file => '/path/to/file'])
  }

Using 'X-REPROXY-URL',

  sub index: Private {
    my ($self, $c) = @_;

		$c->view('MyReproxy')->process($c, 
			'reproxy_file' => $c->path_to('DUMMY')
		);
  }

The url or path can be substituted to $c->stash instead of arguments,

  sub index: Private {
    my ($self, $c) = @_;

    $c->stash->{reproxy_file} = '/path/to/file';
    $c->forward('View::MyReproxy');
  }

=cut

sub process {
    my ( $self, $c, %arguments ) = @_;

    my $file = $arguments{file}
      || $arguments{reproxy_file}
      || $c->stash->{reproxy_file};
    my $url = $arguments{url}
      || $arguments{reproxy_url}
      || $c->stash->{reproxy_url};

    if ($file) {
        $self->process_file( $c, $file, \%arguments );
    }
    elsif ($url) {
        $url = [ split( / /, $url ) ] unless ( ref $url eq "ARRAY" );
        $self->process_url( $c, $url, \%arguments );
    }
    else {
        $c->response->status(403);
        $c->log->error("No setting file or url");
    }
}

=head2 process_file($c, $file, $arguments)

processing file.

=cut

sub process_file {
    my ( $self, $c, $file, $arguments ) = @_;

    if ( $self->config->{perlbal} || $self->config->{lighttpd} ) {
        if ( $self->config->{perlbal} ) {
            $c->response->header( 'X-REPROXY-FILE', $file );

            my $expected_size =
              ( -e $file ) ? ( -s $file ) : $c->stash->{reproxy_expected_size};

            if ( defined $expected_size ) {
                $c->response->header( 'X-REPROXY-EXPECTED-SIZE',
                    $expected_size );
            }
        }
        else {
            $c->response->header( 'X-Sendfile', $file );
        }
    }
    else {
        unless ( -e $file ) {
            $c->response->status(404);
            $c->log->error("File not found");
            return;
        }

        my $content;
        my $content_length = -s $file;

        sysopen( SENDFILE, $file, O_RDONLY );
        sysread( SENDFILE, $content, -s $file );

        unless ( $c->response->content_type ) {
            if ( $self->mmagic ) {
                $c->response->content_type(
                    $self->mmagic->checktype_contents($content) );
            }
            else {
                $c->response->content_type(
                    File::MimeInfo::mimetype(*SENDFILE) );
            }
        }

        close(SENDFILE);

        $c->response->content_length( -s $file );
        $c->response->body($content);
    }

    $self->process_extra_headers( $c, $arguments );
}

=head2 process_url($c, $url, $arguments)

processing urls.

=cut

sub process_url {
    my ( $self, $c, $url, $arguments ) = @_;

    if ( $self->config->{perlbal} ) {
        $c->response->header( 'X-REPROXY-URL', join( " ", @$url ) );

        my $expected_size = $c->stash->{reproxy_expected_size};

        if ( defined $expected_size ) {
            $c->response->header( 'X-REPROXY_EXPECTED_SIZE', $expected_size );
        }
    }
    else {
        my $rand_url = $url->[ int( rand( scalar @{$url} ) ) ];

        my $ua = LWP::UserAgent->new;
        $ua->timeout( int $self->config->{timeout} )
          if ( $self->config->{timeout} );

        my $req = HTTP::Request->new( GET => $rand_url );
        $req->header( 'Accept' => '*' );
        my $res = $ua->request($req);

        if ( $res->is_success ) {
            my $content = $res->content;

            unless ( $c->response->content_type ) {
                if ( $self->mmagic ) {
                    $c->response->content_type(
                        $self->mmagic->checktype_contents($content) );
                }
                else {
                    $c->response->content_type( $res->header('Content-Type') );
                }
            }

            $c->response->content_length( $res->header('Content-Length') );
            $c->response->body( $res->content );
        }
        else {
            $c->response->status(403);
            $c->log->error("Request $url is not success");
            return;
        }
    }

    $self->process_extra_headers( $c, $arguments );
}

=head2 header_name($header)

Translating http header name.

=cut

sub header_name {
    my ( $self, $header ) = @_;

    my $header_name = $header;
    $header_name =~ s/_/-/g;
    $header_name =
      join( "-" => map { ucfirst lc $_ } split( /-/, $header_name ) );

    return $header_name;
}

=head2 process_extra_headers($c, $arguments)

Setting extra http response headers.

=cut

sub process_extra_headers {
    my ( $self, $c, $arguments ) = @_;

    if ( $arguments->{extra_headers} ) {
        foreach my $header ( keys %{ $arguments->{extra_headers} } ) {
            $c->response->header( $self->header_name($header),
                $arguments->{extra_headers}->{$header} );
        }
    }
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-view-reproxy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Reproxy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::Reproxy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Reproxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Reproxy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Reproxy>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Reproxy>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::View::Reproxy
