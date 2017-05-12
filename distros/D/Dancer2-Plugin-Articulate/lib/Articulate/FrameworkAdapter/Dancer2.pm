package Articulate::FrameworkAdapter::Dancer2;
use strict;
use warnings;

use Moo;

with 'Articulate::Role::Component';
require Dancer2;

=head1 NAME

Articulate::FramwworkAdapter::Dancer1 - Access Dancer1 features though a common interface

=head1 SYNOPSIS

  # declare it in your config
  plugins:
    Articulate:
      components:
        framework:
          Articulate::FramwworkAdapter::Dancer2
            appname: MyApp


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

=item * L<Dancer2::Plugin::Articulate>

=item * L<Dancer2::Plugins>

=item * L<Dancer2::Config>

=item * L<Articulate::FrameworkAdapter::Dancer1>

=back

=cut

has appname =>
  is => 'rw',
  default => sub { undef };

has d2app =>
  is      => 'rw',
  lazy    => 1,
  default => sub {
    my $self = shift;
    Dancer2->import ( appname => $self->appname );
    my @apps = grep { $_->name eq $self->appname } @{ Dancer2::runner()->apps };
    return $apps[0];
  }
;
sub user_id {
  my $self = shift;
  Dancer2::Core::DSL::session( $self->d2app, user_id => @_ );
}

sub appdir {
  my $self = shift;
  Dancer2::config()->{appdir};
}

sub session {
  my $self = shift;
  Dancer2::Core::DSL::session( $self->d2app, @_ );
}

sub set_content_type {
  my $self = shift;
  Dancer2::Core::DSL::content_type( $self->d2app, @_ );
}

sub send_file {
  my $self = shift;
  Dancer2::Core::DSL::send_file( $self->d2app, @_ );
}

sub upload {
  my $self = shift;
  return (map {
    $_->file_handle->binmode(':raw');
    Articulate::File->new ( {
      content_type => $_->type,
      headers      => $_->headers,
      filename     => $_->filename,
      io           => $_->file_handle,
    } )
  } Dancer2::Core::DSL::upload( $self->d2app, @_) )[0];
}

sub status {
  my $self = shift;
  Dancer2::Core::DSL::status( $self->d2app, @_ );
}

sub template_process {
  my $self = shift;
  $self->d2app->template_engine->process( @_ );
}

sub declare_route {
  my ($self, $verb, $path, $code) = @_;
  $self->d2app;
  if ($verb =~ m/^(get|put|post|patch|del|any|options)$/) {#'Dancer2::Core::DSL::'.lc $1;/ge) {
    {
      no strict 'refs';
      $self->d2app->add_route( method => $verb, regexp => $path, code => $code );
    }
  }
  else {
    die ('Unknown HTTP verb '.$verb);
  }
}

1;
