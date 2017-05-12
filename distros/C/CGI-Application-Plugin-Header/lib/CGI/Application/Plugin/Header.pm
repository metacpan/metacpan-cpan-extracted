package CGI::Application::Plugin::Header;
use 5.008_009;
use strict;
use warnings;
use parent 'Exporter';
use CGI::Header;
use Carp qw/carp croak/;

our $VERSION = '0.63008';
our @EXPORT  = qw( header header_add header_props );

sub import {
    my ( $class ) = @_;
    my $caller = caller;
    $caller->add_callback( init => \&BUILD );
    $class->export_to_level( 1, @_ );
}

sub BUILD {
    my $self = shift;
    my @args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    while ( my ($key, $value) = splice @args, 0, 2 ) {
        $self->{+__PACKAGE__} = $value if lc $key eq 'header';
    }

    return;
}

sub header {
    my $self = shift;
    return $self->{+__PACKAGE__} = shift if @_;
    $self->{+__PACKAGE__} ||= CGI::Header->new( query => $self->query );
}

sub header_add {
    my $self   = shift;
    my @props  = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my $header = $self->header;

    carp "header_add called while header_type set to 'none'" if $self->header_type eq 'none';
    croak "Odd number of elements passed to header_add" if @props % 2;

    while ( my ($key, $value) = splice @props, 0, 2 ) {
        if ( ref $value eq 'ARRAY' ) {
            if ( $header->exists($key) ) {
                my $existing_value = $header->get( $key ); 
                if ( ref $existing_value eq 'ARRAY' ) {
                    $value = [ @$existing_value, @$value ];
                }
                else {
                    $value = [ $existing_value, @$value ];
                }
            }
            else {
                $value = [ @$value ];
            }
        }

        $header->set( $key => $value );
    }

    return;
}

sub header_props {
    my $self   = shift;
    my @props  = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my $header = $self->header;
    my $props  = $header->header;

    if ( @_ ) {
        carp "header_props called while header_type set to 'none'" if $self->header_type eq 'none';
        croak "Odd number of elements passed to header_props" if @props % 2;
        $header->clear->set(@props); # replace
    }

    map { ( "-$_" => $props->{$_} ) } keys %$props; # 'type' -> '-type'
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Header - Plugin for handling header props.

=head1 SYNOPSIS

  package MyApp;
  use parent 'CGI::Application';
  use CGI::Application::Plugin::Header;

  sub do_something {
      my $self = shift;

      my $header = $self->header; # => CGI::Header object

      # get header props.
      my $type = $header->type; # => "text/plain"

      # set header props.
      $header->type("text/html");

      # compatible with the core methods of CGI::Application
      $self->header_props( type => "text/plain" );
      $self->header_add( type => "text/plain" );

      ...
  }

=head1 DESCRIPTION

This plugin provides you the common syntax to handle CGI.pm-compatible
HTTP header properties.

By using this plugin, your application is capable of the following methods,
where C<$cgiapp> denotes the instance
of your application which inherits from L<CGI::Application>:

=head2 ATTRIBUTES

=over 4

=item $header = $cgiapp->header


Returns a L<CGI::Header> object associated with C<$cgiapp>.
You can use all methods of C<$header>.

  sub cgiapp_postrun {
      my ( $self, $body_ref ) = @_;
      $self->header->set( 'Content-Length' => length $$body_ref );
  }

=item $header = $cgiapp->header( CGI::Header->new(...) )

You can also define your C<header> class which inherits from C<CGI::Header>.
For example,

  package MyApp::Header;
  use parent 'CGI::Header';
  use CGI::Cookie;

  sub cookies {
      my $self    = shift;
      my $cookies = $self->header->{cookies} ||= [];

      return $cookies unless @_;

      if ( ref $_[0] eq 'HASH' ) {
          push @$cookies, map { CGI::Cookie->new($_) } @_;
      }
      else {
          push @$cookies, CGI::Cookie->new( @_ );
      }

      $self;
  }

You can set C<header> as follows:

  # using new()

  my $query  = CGI->new;
  my $header = MyApp::Header->new( query => $query );
  my $app    = MyApp->new( query => $query, header => $header );


  # using header()

  my $app = MyApp->new;

  $app->header( MyApp::Header->new( query => $app->query ) );

=back

=head2 METHODS

This plugin overrides the following methods of L<CGI::Application>:

=over 4

=item %header_props = $cgiapp->header_props

=item %header_props = $cgiapp->header_props( $k1 => $v1, $k2 => $v2, ... )

=item %header_props = $cgiapp->header_props({ $k1 => $v1, $k2 => $v2, ... })

=item %header_props = $cgiapp->header_props({})

Behaves like L<CGI::Application>'s C<header_props> method,
but the return format is modified. C<keys> of C<%header_props>
are lowercased and start with a dash. The following aliases are used:

  '-content-type' -> '-type'
  '-cookie'       -> '-cookies'

It's guaranteed that the keys are unique.

=item $cgiapp->header_add( $k1 => $v1, $k2 => $v2, ... )

=item $cgiapp->header_add({ $k1 => $v1, $k2 => $v2, ... })

Behaves like L<CGI::Application>'s C<header_add> method.

=back

=head2 COMPATIBILITY

Header property names are normalized by C<$header> automatically,
and so this plugin breaks your code which depends on the return value of
C<header_props>:

  my %header_props = $cgiapp->header_props; # => ( -cookies => 'ID=123456' )

  if ( exists $header_props{-cookie} ) {
      ...
  }

Those codes can be rewritten using C<$header> as well as C<header_props>
or C<header_add>:

  if ( $cgiapp->header->exists('-cookie') ) {
      ...
  }

The following plugins are compatible with this module:

=over 4

=item L<CGI::Application::Plugin::Redirect>

=back

The following plugins are roughly compatible with this module:

=over 4

=item L<CGI::Application::Plugin::Stream>

"Setting a custom Content-Length/-Content-Length header" is not supported
by this module. In other words, the C<stream_file> method always overwrites
the C<Content-Length> header.

=item L<CGI::Application::Plugin::Session>

You need to overwrite the C<alias> table of C<CGI::Header>:

  use parent 'CGI::Header';

  sub _build_alias {
      +{
          'cookies'      => 'cookie',
          'content-type' => 'type',
      };
  }

  sub cookies {
      my $self = shift;
      return $self->header->{cookies} unless @_;
      $self->header->{cookies} = shift;
      $self;
  }

  sub cookie {
      my $self = shift;
      $self->cookies(@_);
  }

=back

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

