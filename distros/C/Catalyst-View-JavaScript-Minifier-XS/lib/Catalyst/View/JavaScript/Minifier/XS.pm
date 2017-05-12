package Catalyst::View::JavaScript::Minifier::XS;
$Catalyst::View::JavaScript::Minifier::XS::VERSION = '2.102000';
# ABSTRACT: Minify your served JavaScript files

use autodie;
use Moose;

extends 'Catalyst::View';

use File::stat;
use JavaScript::Minifier::XS qw/minify/;
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
   default => 'js',
);

has js_dir => (
   is      => 'ro',
   default => 'js',
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

   $c->res->content_type('text/javascript');

   push @files, $self->_subinclude($c, $original_stash, @files);

   # the 'root' conf var might not be absolute
   my $abs_root = Path::Class::Dir->new( $c->config->{'root'} )->absolute( $c->path_to );

   my $file_list;
   if ( $self->js_dir || $self->INCLUDE_PATH ) {
      $file_list = $self->_with_js_dir( \@files, $abs_root );
   } else {
      $file_list = $self->_no_js_dir( \@files );
   }

   my $output = $self->_combine_files($c, $file_list);

   $c->res->headers->last_modified( max map stat($_)->mtime, @{$file_list} );
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
      $c->log->debug(q{we can't take js from index as it's too likely to enter an infinite loop!}) if $c->debug;
      return;
   }

   $c->forward('/'.$referer->path);
   $c->log->debug('js taken from referer : '.$referer->path) if $c->debug;

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
      $c->log->debug("loading js file ... $file") if $c->debug;
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

sub _with_js_dir {
   my ( $self, $files, $abs_root ) = @_;

   my $js_dir;
   if ( !ref $self->js_dir ) {
      $js_dir = Path::Class::Dir->new($self->js_dir)->absolute( $abs_root );
   } elsif ( ref $self->js_dir eq 'ARRAY' ) {
      $js_dir = Path::Class::Dir->new(@{$self->js_dir})->absolute( $abs_root );
   }

   # backcompat only
   $js_dir = $self->INCLUDE_PATH->subdir($js_dir) if $self->INCLUDE_PATH;

   my @file_list = map {
      $_ =~ s/\.js$//;  $js_dir->file( "$_.js" )
   } grep { defined $_ && $_ ne '' } @{$files};

   return \@file_list;
}

sub _no_js_dir {
   my ( $self, $files ) = @_;

   my @file_list = grep { defined $_ && $_ ne '' } @{$files};

   return \@file_list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::View::JavaScript::Minifier::XS - Minify your served JavaScript files

=head1 VERSION

version 2.102000

=head1 SYNOPSIS

 # creating MyApp::View::JavaScript
 ./script/myapp_create.pl view JavaScript JavaScript::Minifier::XS

 # in your controller file, as an action
 sub js : Local {
    my ( $self, $c ) = @_;

    # loads root/js/script1.js and root/js/script2.js
    $c->stash->{js} = [qw/script1 script2/];

    $c->forward('View::JavaScript');
 }

 # in your html
 <script type="text/javascript" src="/js"></script>

=head1 DESCRIPTION

Use your minified js files as a separated catalyst request. By default they
are read from C<< $c->stash->{js} >> as array or string.  Also note that this
does not minify the javascript if the server is started in development mode.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{js} >>

=item js_dir

Directory containing your javascript files.  If a relative path is
given, it is taken as relative to your app's root directory.  If a false
value is passed to js_dir then no directory is used.

default : js

=item subinclude

setting this to true will take your js files (stash variable) from your referer
action

 # in your controller
 sub action : Local {
    my ( $self, $c ) = @_;

    # load exclusive.js only when /action is loaded
    $c->stash->{js} = "exclusive";
 }

This could be very dangerous since it's using
C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the
index action!

default : false

=back

=head1 SEE ALSO

L<JavaScript::Minifier::XS>

=head1 AUTHORS

=over 4

=item *

Ivan Drinchev <drinchev (at) gmail (dot) com>

=item *

Arthur Axel "fREW" Schmidt <frioux@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Drinchev <drinchev (at) gmail (dot) com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
