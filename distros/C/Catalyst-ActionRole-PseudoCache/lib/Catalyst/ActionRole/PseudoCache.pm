package Catalyst::ActionRole::PseudoCache;
{
  $Catalyst::ActionRole::PseudoCache::VERSION = '1.000003';
}

# ABSTRACT: Super simple caching for Catalyst actions

use Moose::Role;
use autodie;
use File::Spec;
use Carp qw(carp croak);

has true_cache => (
   is      => 'rw',
   isa     => 'Bool',
   default => undef,
);

has key => (
   is      => 'ro',
   isa     => 'Str',
   builder => '_build_key',
   lazy    => 1,
);

has is_cached => (
   is      => 'rw',
   isa     => 'Bool',
   default => undef,
);

has path => (
   is      => 'ro',
   isa     => 'Str',
   builder => '_build_path',
   lazy    => 1,
);

has url => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

sub _build_key {
   my $self = shift;
   return $self->class . '/' . $self->name;
}

sub _build_path {
   my $self = shift;
   my $url = $self->url;
   return File::Spec->catfile(split qr{/}, $url);
}

around BUILDARGS => sub {
   my $orig  = shift;
   my $class = shift;
   my ($args) = @_;
   if (my $attr = $args->{attributes}) {
      my @args;
      if ($attr->{PCTrueCache}) {
         @args = (
            true_cache => 1,
            ($attr->{PCKey}
               ? ( key => $attr->{PCKey}->[0] )
               : ()
            ),
            %{$args}
         );
         croak 'you must not set attributes that are not supported (PCUrl or PCPath) in true cache mode!'
            if $attr->{PCUrl} || $attr->{PCPath};
      } else {
         @args = (
            ($attr->{PCUrl}
               ? ( url => $attr->{PCUrl}->[0] )
               : ()
            ),
            ($attr->{PCPath}
               ? ( path => $attr->{PCPath}->[0] )
               : ()
            ),
            %{$args}
         );
         croak q(if you don't use true cache mode you must set PCUrl!)
            unless $attr->{PCUrl};

         carp 'you are not using true cache mode, which is pretty sucky, and more importantly, deprecated'
      }

      return $class->$orig( @args );
   } else {
      return $class->$orig(@_);
   }
};

around execute => sub {
   my $orig               = shift;
   my $self               = shift;
   my ( $controller, $c ) = @_;

   # do nothing if debug
   return $self->$orig(@_)
      if ($c->debug);

   if ($self->true_cache) {
      $self->_true_cache($orig,@_);
   } else {
       # backup method (for back compat)
      $self->_pseudo_cache($orig,@_);
   }
};

sub _true_cache {
   my ($self, $orig, $controller, $c, @rest) = @_;

   my $cache = $c->cache;

   if (my $body = $cache->get($self->key)){
      $c->response->body($body);
   } else {
      $self->$orig($controller, $c, @rest);
      $cache->set($self->key, $c->response->body);
   }
}

sub _pseudo_cache {
   my ($self, $orig, $controller, $c, @rest) = @_;

   if (!$self->is_cached) {
      my $filename = File::Spec->catfile($c->path_to('root'), $self->path);

      unlink $filename if stat $filename;
      open my $js_fh, '>', $filename;

      $self->$orig($controller, $c, @rest);

      print {$js_fh} $c->response->body;
      close $js_fh;

      $self->is_cached(1);
   } else {
      $c->response->redirect($self->url, 300);
   }
}

1;

__END__

=pod

=head1 NAME

Catalyst::ActionRole::PseudoCache - Super simple caching for Catalyst actions

=head1 VERSION

version 1.000003

=head1 SYNOPSIS

 package MyApp::Controller::Root;

 use Moose;
 BEGIN { extends 'Catalyst::Controller::ActionRole' };

 # used with Catalyst::Plugin::Cache
 sub cache_js :Local Does(PseudoCache) PCTrueCache(1) {
   my ($self, $c) = @_;
   # Long running action to be cached
 }

 # used with Catalyst::Plugin::Cache and the optional key attr
 sub cache_with_key :Local Does(PseudoCache) PCTrueCache(1) PCKey('rememberme'){
   my ($self, $c) = @_;
   # Long running action to be cached
 }

=head1 DESCRIPTION

This module was originally made to take the output of
L<Catalyst::View::JavaScript::Minifier::XS> and store it in a file so that after
the server booted we would not need to generate it again and could let the
static web server serve up the static file.  Obviously it can be
used for much more than javascript, but it's mostly made with large, purely
javascript sites in mind.  It does not cache the output of the action when the
server is run in development mode.

=head1 ATTRIBUTES

=head2 PCTrueCache

Setting PCTrueCache will use L<Catalyst::Plugin::Cache> and allow a real
cache backend to do the work.  After version 2 of this module this will no
longer need to be set and the old mode of this plugin will be removed entirely.

=head2 PCKey

PCKey is an optional way of providing a different key for the cache backend.
The default key is C<Controller::Name/action>.

The two attributes below are B<DEPRECATED> and provided for back compat only. They
might disappear in the future. Using C<PCTrueCache> and L<Catalyst::Plugin::Cache>
is highly recommended.

=head2 PCUrl

Required when not using L</PCTrueCache>.

After the action runs once it will redirect to C<$PCUrl>.

=head2 PCPath

When the action gets run the first time it will write it's output to C<$PCPath>.

Defaults to C<< $c->path_to('root') . $PCUrl >>

So using the example given above for the C<all_js> action, the path will be

 $MyAppLocation/root/static/js/all.js

=head1 THANKS

Thanks to Geoffrey Darling for writing all the code for the modern true cache
mode

=head1 SEE ALSO

L<Catalyst::Plugin::Cache>

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
