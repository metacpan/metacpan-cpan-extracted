package Clustericious::Plugin::AutodataHandler;

use strict;
use warnings;
use base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Clustericious::Log;
use PerlX::Maybe qw( maybe );
use Path::Class qw( dir );

# ABSTRACT: Handle data types automatically
our $VERSION = '1.29'; # VERSION


sub _default_coders
{
  my %coders =
    map { $_ => 1 }
    map { $_ =~ s/\.pm$//; $_ }
    map { $_->basename }
    grep { ! $_->is_dir }
    map { $_->children( no_hidden => 1 ) }
    grep { -d $_ }
    map { dir $_, 'Clustericious', 'Coder' } @INC;
  [ keys %coders ];
}

sub register
{
  my ($self, $app, $conf) = @_;

  my @coders = $app->isa('Clustericious::App')
    ? $app->config->coders( default => __PACKAGE__->_default_coders )
    : @{ $conf->{coders} // __PACKAGE__->_default_coders };
  
  my %types = (
    'application/x-www-form-urlencoded' => {
      decode => sub { my ($data, $c) = @_; $c->req->params->to_hash }
    }
  );
  my %formats;
  
  foreach my $coder (@coders)
  {
    require join('/', qw( Clustericious Coder ), "$coder.pm");
    my $coder = join('::', qw( Clustericious Coder ), $coder)->coder;
    $types{$coder->{type}} = {
      maybe encode => $coder->{encode},
      maybe decode => $coder->{decode},
    },
    $formats{$coder->{format}} = $coder->{type}
      if $coder->{format};
  }

  my $default_decode = $conf->{default_decode} // 'application/x-www-form-urlencoded';
  my $default_encode = $conf->{default_encode} // 'application/json'; # TODO: not used

  my $find_type = sub {
    my ($c) = @_;

    my $headers = $c->tx->req->content->headers;

    foreach my $type (map { /^([^;]*)/ } # get only stuff before ;
                      split(',', $headers->header('Accept') || ''),
                      $headers->content_type || '')
    {
        return $type if $types{$type} and $types{$type}->{encode};
    }

    my $format = $c->stash->{format} // 'json';
    $format = 'json' unless $formats{$format};

    $formats{$format};
  };


  $app->renderer->add_handler('autodata' => sub {
    my ($r, $c, $output, $data) = @_;

    my $type = $find_type->($c);
    LOGDIE "no encoder for $type" unless $types{$type}->{encode};
    $$output = $types{$type}->{encode}->($c->stash("autodata"));
    $c->tx->res->headers->content_type($type);
  });

  my $parse_autodata = sub {
    my ($c) = @_;

    my $content_type = $c->req->headers->content_type || $default_decode;
    if ($content_type =~ /^([^;]+);/) {
        # strip charset
        $content_type = $1;
    }
    my $entry = $types{$content_type} || $types{$default_decode};

    # TODO: avoid passing $c in, only used by
    # application/x-www-form-urlencoded above
    $c->stash->{autodata} = $entry->{decode}->($c->req->body, $c);
  };

  $app->plugins->on( parse_autodata => $parse_autodata );

  $app->plugins->on( add_autodata_type => sub {
    my($plugins, $args) = @_;

    LOGDIE "No extension provided" unless defined $args->{extension};
    my $ext  = $args->{extension};
    my $mime = $args->{mime_type} // 'application/x-' . $ext;

    $formats{$ext} = $mime;
    
    if(defined $args->{encode}) {
        $types{$mime}->{encode} = $args->{encode};
    }
    
    if(defined $args->{decode}) {
        $types{$mime}->{decode} = $args->{decode};
    }
  });

  $app->helper( parse_autodata => $parse_autodata );
    
  $app->hook(before_render => sub {
    my($c, $args) = @_;
    $c->stash->{handler} = "autodata" if exists($c->stash->{autodata}) || exists($args->{autodata});
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Plugin::AutodataHandler - Handle data types automatically

=head1 VERSION

version 1.29

=head1 SYNOPSIS

 package YourApp::Routes;
 
 use Clustericious::RouteBuilder;
 
 get '/some/route' => sub {
   my $c = shift;
   $c->stash->{autodata} = { x => 1, y => 'hello, z => [1,2,3] };
 };

=head1 DESCRIPTION

Adds a renderer that automatically serializes that "autodata" in the
stash into a format based on HTTP Accept and Content-Type headers.
Also adds a helper called C<parse_autodata> that handles incoming data by
Content-Type.

Supports application/json, text/x-yaml and
application/x-www-form-urlencoded (in-bound only).

When C<parse_autodata> is called from within a route like this:

 $self->parse_autodata;

POST data is parsed according to the type in the 'Content-Type'
header with the data left in stash->{autodata}.  It is also
returned by the above call.

If a route leaves data in stash->{autodata}, it is rendered by this
handler, which chooses the type with the first acceptable type listed
in the Accept header, the Content-Type header, or the default.  (By
default, the default is application/json, but you can override that
too).

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
