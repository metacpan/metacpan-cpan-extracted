package Catalyst::View::CSS::Minifier::XS;
{
  $Catalyst::View::CSS::Minifier::XS::VERSION = '2.000002';
}

# ABSTRACT: Minify your served CSS files

use autodie;
use Moose;

extends 'Catalyst::View';

use CSS::Minifier::XS qw/minify/;
use File::stat;
use List::Util 'max';
use Moose::Util::TypeConstraints;
use MooseX::Aliases;
use Path::Class::Dir;
use URI;

my $dir_type = __PACKAGE__.'::Dir';
subtype $dir_type => as class_type('Path::Class::Dir');
coerce $dir_type,
    from 'Str',      via { Path::Class::Dir->new($_)  },
    from 'ArrayRef', via { Path::Class::Dir->new(@$_) };

has stash_variable => (
   is => 'ro',
   isa => 'Str',
   default => 'css',
);

has css_dir => (
   is      => 'ro',
   isa     => $dir_type,
   coerce  => 1,
   default => 'css',
   alias   => 'path',
);

has subinclude => (
   is => 'ro',
   isa => 'Bool',
   default => undef,
);

# for backcompat. don't use this.
has 'INCLUDE_PATH' => (
    is     => 'ro',
    isa    => $dir_type,
    coerce => 1,
   );

sub process {
   my ($self,$c) = @_;

   my $original_stash = $c->stash->{$self->stash_variable};
   my @files = $self->_expand_stash($original_stash);

   $c->res->content_type('text/css');

   push @files, $self->_subinclude($c, $original_stash, @files);

   # the 'root' conf var might not be absolute
   my $abs_root = Path::Class::Dir->new( $c->config->{'root'} )->absolute( $c->path_to );
   my $dir   = $self->css_dir->absolute( $abs_root );

   # backcompat only
   $dir = $self->INCLUDE_PATH->subdir($dir) if $self->INCLUDE_PATH;

   @files = map {
      $_ =~ s/\.css$//;  $dir->file( "$_.css" )
   } grep { defined $_ && $_ ne '' } @files;

   my $output = $self->_combine_files($c, \@files);

   $c->res->headers->last_modified( max map stat($_)->mtime, @files );
   $c->res->body( $self->_minify($c, $output) );
}

sub _subinclude {
   my ( $self, $c, $original_stash, @files ) = @_;

   return unless $self->subinclude && $c->request->headers->referer;

   unless ( $c->request->headers->referer ) {
      $c->log->debug('javascripts called from no referer sending blank') if $c->debug;
      $c->res->body( q{ } );
      $c->detach();
   }

   my $referer = URI->new($c->request->headers->referer);

   if ( $referer->path eq '/' ) {
      $c->log->debug(q{we can't take css from index as it's too likely to enter an infinite loop!}) if $c->debug;
      return;
   }

   $c->forward('/'.$referer->path);
   $c->log->debug('css taken from referer : '.$referer->path) if $c->debug;

   return $self->_expand_stash($c->stash->{$self->stash_variable})
      if $c->stash->{$self->stash_variable} ne $original_stash;
}

sub _minify {
   my ( $self, $c, $output ) = @_;

   if ( @{$output} ) {
      return $c->debug
         ? join "\n", @{$output}
         : minify(join q{ }, @{$output} )
   } else {
      return q{ };
   }
}

sub _combine_files {
   my ( $self, $c, $files ) = @_;

   my @output;
   for my $file (@{$files}) {
      $c->log->debug("loading css file ... $file") if $c->debug;
      open my $in, '<', $file;
      local $/;
      push @output, scalar <$in>;
   }
   return \@output;
}

sub _expand_stash {
   my ( $self, $stash_var ) = @_;

   if ( $stash_var ) {
      return ref $stash_var eq 'ARRAY'
         ? @{ $stash_var }
         : split /\s+/, $stash_var;
   }

}



1;

__END__

=pod

=head1 NAME

Catalyst::View::CSS::Minifier::XS - Minify your served CSS files

=head1 VERSION

version 2.000002

=head1 SYNOPSIS

 # creating MyApp::View::CSS
 ./script/myapp_create.pl view CSS CSS::Minifier::XS

 # in your controller file, as an action
 sub css : Local {
    my ( $self, $c ) = @_;

    # load root/css/style1.css and root/css/style2.css
    $c->stash->{css} = [qw/style1 style2/];

    $c->forward("View::CSS");
 }

 # in your html template use
 <link rel="stylesheet" type="text/css" media="screen" href="/css" />

=head1 DESCRIPTION

Use your minified css files as a separated catalyst request. By default they
are read from C<< $c->stash->{css} >> as array or string.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{css} >>

=item css_dir

Directory containing your css files.  If a relative path is
given, it is taken as relative to your app's root directory.

default : css

=item subinclude

setting this to true will take your css files (stash variable) from your referer
action

 # in your controller
 sub action : Local {
    my ( $self, $c ) = @_;

    # load exclusive.css only when /action is loaded
    $c->stash->{css} = "exclusive";
 }

This could be very dangerous since it's using
C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the
index action!

default : false

=back

=head1 SEE ALSO

L<Catalyst> , L<Catalyst::View>, L<CSS::Minifier::XS>

=head1 AUTHORS

=over 4

=item *

Ivan Drinchev <drinchev (at) gmail (dot) com>

=item *

Arthur Axel "fREW" Schmidt <frioux@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Drinchev <drinchev (at) gmail (dot) com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
