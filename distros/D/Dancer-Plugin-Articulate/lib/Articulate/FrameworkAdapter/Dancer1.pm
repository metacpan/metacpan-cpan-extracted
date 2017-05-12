package Articulate::FrameworkAdapter::Dancer1;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';
use Dancer
  qw(:syntax !after !before !session !status !send_file !content_type !upload);
use IO::All ();

=head1 NAME

Articulate::FramwworkAdapter::Dancer1 - Access Dancer1 features though
a common interface

=head1 SYNOPSIS

  # declare it in your config
  plugins:
    Articulate:
      components:
        framework: Articulate::FramwworkAdapter::Dancer1

  # then use it in your other components
  my $appdir = $component->framework->appdir

=head1 METHODS

The following methods are implemented:

=head3 user_id

=head3 appdir

=head3 session

=head3 status

=head3 template_process

=head3 declare_route

=head1 SEE ALSO

=over

=item * L<Dancer::Plugin::Articulate>

=item * L<Dancer::Plugins>

=item * L<Dancer::Config>

=item * L<Articulate::FrameworkAdapter::Dancer2>

=back

=cut

sub user_id {
  my $self = shift;
  Dancer::session( 'user_id', @_ );
}

sub appdir {
  my $self = shift;
  config->{appdir};
}

sub session {
  my $self = shift;
  Dancer::session(@_);
}

sub upload {
  my $self = shift;
  return (
    map {
      $_->file_handle->binmode(':raw');
      Articulate::File->new(
        {
          content_type => $_->type,
          headers      => $_->headers,
          filename     => $_->filename,
          io           => $_->file_handle,
        }
        )
    } Dancer::upload(@_)
  )[0];
}

sub set_content_type {
  my $self = shift;
  Dancer::content_type(@_);
}

sub send_file {
  my $self = shift;
  Dancer::send_file(@_);
}

sub status {
  my $self = shift;
  Dancer::status(@_);
}

sub template_process {
  my $self = shift;
  my $view = shift() . '.tt'; # parens else 5.10 complains
  template( $view, @_ );
}

sub declare_route {
  my ( $self, $verb, $path, $code ) = @_;
  if ( $verb =~ s/^(get|put|post|patch|del|any|options)$/'Dancer::'.lc $1;/ge )
  {
    {
      no strict 'refs';
      &$verb( $path, $code );
    }
  }
  else {
    die( 'Unknown HTTP verb ' . $verb );
  }
}

1;
