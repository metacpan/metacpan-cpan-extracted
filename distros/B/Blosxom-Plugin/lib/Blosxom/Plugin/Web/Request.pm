package Blosxom::Plugin::Web::Request;
use strict;
use warnings;
use CGI;
use Carp qw/carp/;

sub new {
    my $self = bless {}, shift;
    $self->{query} = CGI->new;
    $self;
}

sub path_info { carp 'Not implemented yet' }
sub base      { carp 'Not implemented yet' }

sub header    { shift->{query}->http( @_ )   }
sub is_secure { scalar shift->{query}->https }

sub method       { shift->{query}->request_method   }
sub content_type { shift->{query}->content_type     }
sub referer      { shift->{query}->referer          }
sub remote_host  { shift->{query}->remote_host      }
sub address      { shift->{query}->remote_addr      }
sub user_agent   { shift->{query}->user_agent( @_ ) }
sub protocol     { shift->{query}->server_protocol  }
sub user         { shift->{query}->remote_user      }

sub cookie {
    my $self = shift;
    return $self->{query}->cookie( shift ) if @_;
    $self->{query}->cookie;
}

sub param {
    my $self = shift;
    return $self->{query}->param( shift ) if @_;
    $self->{query}->param;
}

sub upload {
    my ( $self, $field ) = @_;

    $self->{upload} ||= do { 
        require Blosxom::Plugin::Web::Request::Upload;
        my $query = $self->{query};

        my %upload;
        for my $field ( $query->param ) {
            my @uploads;
            for my $fh ( $query->upload($field) ) {
                my $upload = Blosxom::Plugin::Web::Request::Upload->new(
                    fh     => $fh,
                    path   => $query->tmpFileName( $fh ),
                    header => $query->uploadInfo( $fh ),
                );

                push @uploads, $upload;
            }

            $upload{ $field } = \@uploads if @uploads;
        }

        \%upload;
    };

    if ( $field ) {
        if ( my $uploads = $self->{upload}{$field} ) {
            return wantarray ? @{ $uploads } : $uploads->[0];
        }
    }
    else {
        return keys %{ $self->{upload} };
    }

    return;
}

sub DESTROY { CGI::initialize_globals() }

1;

__END__

=head1 NAME

Blosxom::Plugin::Web::Request - Object representing CGI request

=head1 SYNOPSIS

  use Blosxom::Plugin::Web::Request;
  my $request = Blosxom::Plugin::Web::Request->new;
  my $method = $request->method; # GET
  my $page = $request->param( 'page' ); # 12
  my $id = $request->cookie( 'ID' ); # 123456

=head1 DESCRIPTION

Object representing CGI request.

=head2 METHODS

=over 4

=item $request = Blosxom::Plugin::Web::Request->new

Create a Blosxom::Plugin::Web::Request object.

=item $request->base

Not implemented yet.

=item $request->path_info

Not implemented yet.

=item $request->cookie

  my $id = $request->cookie( 'ID' ); # 123456

=item $request->param

  my $value = $request->param( 'foo' );
  my @values = $request->param( 'foo' );
  my @fields = $request->param;

=item $request->method

Returns the method used to access your script, usually one of C<POST>,
C<GET> or C<HEAD>.

=item $request->content_type

Returns the content_type of data submitted in a POST, generally
C<multipart/form-data> or C<application/x-www-form-urlencoded>.

=item $request->referer

Returns the URL of the page the browser was viewing prior to fetching your
script. Not available for all browsers.

=item $request->remote_host

Returns either the remote host name, or IP address if the former
is unavailable.

=item $request->user_agent

Returns the C<HTTP_USER_AGENT> variable. If you give this method a single
argument, it will attempt to pattern match on it, allowing you to do
something like:

  if ( $request->user_agent('Mozilla') ) {
      ...
  }

=item $request->address

Returns the remote host IP address, or C<127.0.0.1> if the address is
unavailable (C<REMOTE_ADDR>).

=item $request->user

Returns the authorization/verification name for user verification,
if this script is protected (C<REMOTE_USER>).

=item $request->protocol

Returns the protocol (HTTP/1.0 or HTTP/1.1) used for the current request.

=item $request->upload

Returns L<Blosxom::Plugin::Web::Request::Upload> objects.

  my $upload = $request->upload( 'field' );
  my @uploads = $request->upload( 'field' );
  my @fields = $request->upload;

=item $request->is_secure

Returns a Boolean value telling whether connection is secure.

=item $request->header

Returns the value of the specified header.

  my $requested_language = $request->header( 'Accept-Language' );

=back

=head1 SEE ALSO

L<Blosxom::Plugin>, L<Plack::Request>

=head1 AUTHOR

Ryo Anazawa

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
