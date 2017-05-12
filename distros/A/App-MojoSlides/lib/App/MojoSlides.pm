package App::MojoSlides;

use Mojo::Base 'Mojolicious';

our $VERSION = '0.11';
$VERSION = eval $VERSION;

use App::MojoSlides::Slides;

use Mojo::File;

has slides => sub {
  my $self = shift;
  return App::MojoSlides::Slides->new( 
    $self->config->{slides} || ()
  );
};

sub startup {
  my $self = shift;

  $self->plugin( 'InstallablePaths' );

  $self->helper( presentation_file => sub {
    require File::Spec;
    require File::Basename;

    my $file = $ENV{MOJO_SLIDES_PRESENTATION} || 'presentation.pl';
    return $file unless -e $file; # return early if not found

    my $abs = File::Spec->rel2abs($file);
    return File::Basename::fileparse($abs) if wantarray;
    return $abs;
  });

  $self->plugin( Config => {
    file => scalar $self->presentation_file, 
    default => {
      slides    => undef,
      ppi       => undef,
      templates => undef,
      static    => undef,
      bootstrap_theme => undef,
      more_tag_helpers => 1,
      extra_css => undef,
      extra_js => undef,
      header_template => 'ms_header',
      footer_template => 'ms_footer',
      finally => sub {},
    },
  });

  # should this be optional?
  $self->include_data_handle_from_file(scalar $self->presentation_file);

  $self->plugin('App::MojoSlides::MoreTagHelpers') if $self->config->{more_tag_helpers};

  if (my $path = $self->config->{templates}) {
    unshift @{ $self->renderer->paths }, ref $path ? @$path : $path;
  }

  if (my $path = $self->config->{static}) {
    unshift @{ $self->static->paths }, ref $path ? @$path : $path;
  }

  if (my $ppi = $self->config->{ppi}) {
    my $args = {};
    $args->{src_folder} = $ppi if -d $ppi;
    $self->plugin(PPI => $args);
  }

  $self->helper( prev_slide => sub {
    my $c = shift;
    return $c->app->slides->prev($c->stash('slide'));
  });

  $self->helper( next_slide => sub {
    my $c = shift;
    return $c->app->slides->next($c->stash('slide'));
  });

  $self->helper( first_slide => sub { shift->app->slides->first } );
  $self->helper( last_slide  => sub { shift->app->slides->last  } );

  $self->helper( row     => sub { shift->tag( 'div', class => 'row', @_ ) } );
  $self->helper( column  => \&_column );
  $self->helper( overlay => sub { shift->tag( 'div', ms_overlay => shift, @_ ) } );
  $self->helper( vspace  => sub { shift->tag( 'div', style => "min-height: @{[shift]};" => '') } );

  my $r = $self->routes;
  $r->any(
    '/:slide',
    { slide => $self->slides->first },
    [ slide => qr/\b\d+\b/ ],
    \&_action,
  );

  my $finally = $self->config->{finally};
  $self->$finally();
}

sub _action {
  my $c = shift;
  my $slides = $c->app->slides;
  my $slide = $slides->template_for($c->stash('slide'))
    or return $c->render_not_found;
  $c->render($slide, layout => 'basic') || $c->render_not_found;
}

sub _column {
  my $c = shift;
  my $cols = ref $_[0] ? shift : [ shift ];
  my $class = join ' ', map { "col-md-$_" } @$cols;
  return $c->tag( div => class => $class, @_ );
}

# hic sunt dracones
sub include_data_handle_from_file {
  my ($self, $file) = @_;
  require Mojo::Util;
  my $string = Mojo::File->new($file)->slurp;
  open my $handle, '<', \$string;
  while (<$handle>) {
    last if /^__DATA__/; # seek to __DATA__
  }

  state $i = 0;
  my $class = 'App::MojoSlides::TextOfFile' . $i++;
  {
    no strict 'refs';
    *{$class.'::DATA'} = $handle;
  }
  unshift @{ $self->renderer->classes }, $class;
}

1;

__END__

=head1 NAME

App::MojoSlides - DEPRECATED Write your presentations in Perl and Mojolicious!

=head1 SYNOPSIS

 $ mojo_slides mypresentation.pl daemon

=head1 DESCRIPTION

This application lets you write presentations using the simple Perlish syntax that
L<Mojo::Template> provides for L<Mojolicious>. It follows a similar model to LaTeX Beamer
in structure and usage, though it is not nearly as full featured.

=head1 WARNING

This software is in alpha form at best. It may eat baby kittens at any moment.

Indeed it never really got better than this, that's why:

=head1 DEPRECATED

This module is now officially deprecated.
I will give it no further effort.
If someone would like to adopt it, please contact me.

=head1 USAGE

=head2 The Presentation File

Each presentation needs a configuration file.
This file is loaded by the C<mojo_slides> application via L<Mojolicious::Plugin::Config>,
and as such may use any functionality it provides.
Additionally, when the file is loaded one helper C<presentation_file> will have been added
which can be used to reference the file and its path (see more below).

=head3 Configuration Keys

The file must evaluate to a hash reference, as all Mojolicious config files must.
The application will look for several keys which establish the presentation.

=over

=item slides

A hash reference used to create the L<App::MojoSlides::Slides> object which organizes the slide order, etc.
See that module for documentation on how to use it.
Usually this value will be a number, representing the ordinal number of the last slide in the case of numbered templates,
or else an array reference of the names of the templates in display order.

=item ppi

If true, it will load L<Mojolicious::Plugin::PPI> to allow code highlighting using that plugin.
The API for this key is still influx, but that much is probably not going to change.

=item templates

Use this key to specify which directories contain your slides.
Your slides are actually Mojolicious Templates (see L<Mojolicious::Guides::Rendering> and L<Mojo::Template> for more on that).
This key takes a string or arrayref of strings which are prepended to the app's template directories.

=item static

Like C<templates> this, key takes a string or arrayref of strings, which are directories prepended to the app's static files directories.
Use this to allow the inclusion of other style files or javascript that you might need.
Of course you will still have to include them in some template for them to be included.

=item bootstrap_theme

If true, the bootstrap-theme.min.css file will be included in the default layout.

=item more_tag_helpers

If true (by default), wrap lots more html tags into tag helpers from L<App::MojoSlides::MoreTagHelpers>.

=item extra_css

=item extra_js

If desired, these values may contain a string or arrayreference of strings of the full path to any publically available css or javascript file respectively which should be included in the overall template.
Note that the string should start with a leading C</>.

=item header_template

=item footer_template

The name of the template to be included as the header or footer. Defaults to C<ms_header> and C<ms_footer> respectively.
Set to C<undef> to not include any template.

=item finally

A code reference that is called as a method against the application as late as possible in the setup method.
This lets you do any final actions that need to be done after the configuration has been loaded.

=back

=head3 Slides from __DATA__

Emulating L<Mojolicious::Lite>, you may also include slides (templates) in the C<__DATA__> section of your configuration file!

=head2 The Slides (Templates)

As I have said, the slides are just Mojolicious Templates, and such they have certain structure.
If you don't understand that, go read about it in the L<Mojolicious::Guides>.

The basic layout uses the standard C<title> helper to set both the webpage title and a centered C<h1> at the top of the page.
Other helpers are provided, such as:

=head3 Helpers

=over

=item next_slide

=item prev_slide

=item first_slide

=item last_slide

Each returns the slide number for the slide in question.
C<prev> and C<next> are smart enough to not leave the expected bounds of C<first> and C<last>.

=item row

 %= row begin
   row contents
 % end

Creates a div with the Bootstrap C<row> class.
Takes a string or template block like Mojolicious' C<tag> helper does, though you probably mean block.

=item column

 %= column 6 => begin
   column contents
 % end

 %= column [3, 'offset-3'] => begin
   column contents
 % end


Creates a div of a given width (a number out of 12, see Bootstrap).
Takes that width and a string or template block, though again, you probably mean block.
To give more than one class, pass an array reference.
Each class is prepended by C<col-md->.

=item overlay

 %= overlay '2-4' => begin
  Stuff to show only on increments 2 through 4
 % end

Creates a div with the attribute C<ms_overlay> which the css/js bits of the system use for incrementing slides.
The syntax of the specification follows LaTeX Beamer, which is like C<2-> to show an item from increment 2 onwards and so on.

N.B. adding C<ms_overlay="2-4"> to nearly any HTML tag will work as expect too!

=item vspace

 %= vspace '50px'
 <div style="min-height: 50px;"></div>

Adds a section of vertical space of a given height.

=back

Plus the tag helpers from L<App::MojoSlides::MoreTagHelpers> if the configuration option is true.

=head1 TECHNOLOGIES USED

=over 

=item L<Mojolicious|http://mojolicio.us>

=item L<Bootstrap|http://getbootstrap.com>

=item L<jQuery|http://jquery.com>

=item L<PPI>

- if desired for Perl code highlighting

=item L<Mousetrap|http://craig.is/killing/mice>

- simple javascript keybinding library

=back

=head1 DEDICATION

This module is dedicated to the organizers and attendees of YAPC::Brazil 2013.
They were kind enough to invite me as their keynote speaker and in turn I wrote this application to present that talk, so I owe them a debt of thanks on both accounts.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/App-MojoSlides> 

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

