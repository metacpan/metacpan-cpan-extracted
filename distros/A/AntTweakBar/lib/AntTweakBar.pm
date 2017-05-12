package AntTweakBar;

use 5.12.0;
use strict;
use warnings;

use Carp;
use Alien::AntTweakBar;

require Exporter;

our @ISA = qw(Exporter);

our @constants =
    qw/
          TW_OPENGL
          TW_OPENGL_CORE
          TW_DIRECT3D9
          TW_DIRECT3D10
          TW_DIRECT3D11
      /;

our %EXPORT_TAGS = (
    'all' => [ qw(init window_size terminate), @constants ],
    'constants' => \@constants,
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.05';

=head1 NAME

AntTweakBar - Perl bindings for AntTweakBar

=head1 SYNOPSIS

  use AntTweakBar qw/:all/;
  use SDL::Events;

  # Setup part: link AntTweakBar with your OpenGL/SDL system

  AntTweakBar::init(TW_OPENGL);
  AntTweakBar::window_size($width, $height);

  # in your main rendering routine
  sub display {
    AntTweakBar::draw;
  }

  sub process_events {
    SDL::Events::pump_events;
    my $event = $self->sdl_event;
    while (SDL::Events::poll_event($event)) {
        ...;
        AntTweakBar::eventSDL($event);
    }
  }


  # define bars with variables
  my $bar = AntTweakBar->new(
    "TweakBar & Perl",
    size  => '200 400',
    color => '96 216 224'
  );
  my $enabled = 0;
  $bar->add_variable(
    mode       => 'rw',
    name       => "Enabled",
    type       => 'bool',
    value      => \$enabled
);


=head1 DESCRIPTION

=for HTML
<p>
  <img src="https://raw.githubusercontent.com/PerlGameDev/AntTweakBar/master/eg/available-properties.png" style="max-width:100%;">
  <img src="https://raw.githubusercontent.com/PerlGameDev/AntTweakBar/master/eg/simple-glut.gif" style="max-width:100%;">
</p>


AntTweakBar (see L<http://anttweakbar.sourceforge.net/>) is nice tiny
GUI library for OpenGL/SDL/DirectX applications.

If you are in hurry to evaluate it then intall AntTweakBar and try
examples from C<eg> directory within the distribution.

To display AntTweakBar in your OpenGL/SDL application you should do the
following:

=over

=item intialize AntTweakBar(s):

  AntTweakBar::init(TW_OPENGL);
  AntTweakBar::window_size($width, $height);

=item draw AntTweakBar(s):

  AntTweakBar::draw;

=item let AntTweakBar(s) respond to user interactions:

  AntTweakBar::eventSDL($event);

=item create AntTweakBar instance(s)

  my $bar = AntTweakBar->new("TweakBar");

=item add variables into the $bar

  my $value = 3.14;
  $bar->add_variable(
    mode       => 'rw',
    name       => "Enabled",
    type       => 'integer',
    value      => \$value
  );

=back

See working examples in the C<eg> directoctory within the distribution.

=head2 EXPORT

Constants only


=head1 CONSTANTS

The following constants let AntTweakBar know which graphic system do
you use, to know how to render itself

=head2 TW_OPENGL

Render using plain old OpenGL

=head2 TW_OPENGL_CORE

Render AntTweakBar using OpenGL core profile, which excludes deprecated
OpenGL functions. See: L<https://en.wikipedia.org/wiki/OpenGL_4#OpenGL_3.2>

=head2 TW_DIRECT3D9 (not implemented)

=head2 TW_DIRECT3D10 (not implemented)

=head2 TW_DIRECT3D11 (not implemented)

=cut

require XSLoader;
XSLoader::load('AntTweakBar', $VERSION);


=head1 METHODS

=head2 new

  my $bar = AntTweakBar->new(
    "TweakBar & Perl",
    size  => '200 400',
    color => '96 216 224'
  );

  my $another_bar = AntTweakBar->new(
    "Misc.",
  );


Creates new AntTweakBar instance. Optionally the list of strings of
bar-related parameters can be provided. See the list of available
at L<http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:twbarparamsyntax>.

=cut

sub new {
    my ($class, $name, %bar_params) = @_;
    croak "AntTweakBar name should be specified"
        unless defined $name;
    my $self = {
        _name    => $name,
        _bar_ptr => _create( $name ),
    };
    bless $self => $class;
    $self->set_bar_params(%bar_params);
    return $self;
}

sub DESTROY {
    my $self = shift;
    _destroy($self->{_bar_ptr});
}


sub _as_definition_string {
    my $d = shift;
    return join(' ', map {
        my $key = $_;
        my $value = $d->{$key};
        $value =~ s/'/\\'/g;
        "$key='$value'";
    } sort keys %$d);
}

=head2 add_button

  $bar->add_button(
    name       => 'my_btn',
    cb         => sub { say "clicked!" },
    definition => "label='Click me!'",    # optional
  );

  $bar->add_button(
    name       => 'my_btn',
    cb         => sub { say "clicked!" },
    definition => { # optional
      label => 'Click me!'
    }
  );


The definition parameters are the same as for variable. See
L<http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:varparamsyntax#parameters>.

=cut


sub add_button {
    my ($self, %args) = @_;

    my $name        = $args{name      };
    my $cb          = $args{cb        };
    my $definition  = $args{definition} // "";

    croak "Button name should be specified"
        unless defined $name;
    croak "Button callback should be specified"
        if(!defined($cb) || ref($cb) ne 'CODE');
    $definition = _as_definition_string($definition)
        if ($definition && ref($definition) eq 'HASH');

    _add_button($self->{_bar_ptr}, $name, $cb, $definition);
}


=head2 add_separator

  $bar->add_separator('separator-name');

=cut

sub add_separator {
    my ($self, $name, $definition) = @_;
    croak "Separator name should be specified"
        unless defined $name;

    $definition //= "";
    $definition = _as_definition_string($definition)
        if ($definition && ref($definition) eq 'HASH');

    _add_separator($self->{_bar_ptr}, $name, $definition);
}


=head2 add_variable

  my $zoom = 1.0;
  $bar->add_variable(
    mode       => 'rw',
    name       => "Zoom",
    type       => 'number',
    value      => \$zoom,
    definition => " min=0.01 max=2.5 step=0.01 help='Bla-bla-bla.' ",
  );

  # the same, but with more perlish style in definition
  $bar->add_variable(
    mode       => 'rw',
    name       => "Zoom",
    type       => 'number',
    value      => \$zoom,
    definition => {
        min     => "0.01",
        max     => "2.5",
        step    => "0.01",
        keyIncr => 'z',
        keyDecr => 'Z',
        help    => 'Scale the object (1=original size).'
    },
  );

  my $bool = undef;
  $bar->add_variable(
    mode       => 'rw',
    name       => "bool_rw_cb",
    type       => 'bool',
    cb_read    => sub { $bool; },
    cb_write   => sub {
        $bool = shift;
        say "writing value $bool";
    }
  );

C<mode>, C<name>, C<type> are mandatory. Either C<value> or C<cb_read>
should be specified. The C<definition> and C<cb_write> are optional.

=head3 mode

The B<mode> can be C<rw> (read/write) or C<ro> (read only). The mode
specified whether the variable value could be modified via AntTweakBar.

=head3 name

Defines the unique variable name at tweakbar. Unless C<label> is
specified via C<defintion>, then C<name> also defines the visual label.
for the variable.

=head3 type

Defines the type of variable. Original types L<http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:twtype>
were reduced to:

=over

=item bool

=item integer

=item number (float)

=item string

=item color3f

variable must be reference to array, consisted of 3 float values: rgb.

=item color4f

variable must be reference to array, consisted of 4 float values: rgba.

=item direction

3D-vector (direction). The variable must be reference to array, consisted of 3 float values.

=item quaternion

4D-vector (3D-object rotation). The variable must be reference to array, consisted of 4 float values.

=item custom type of L<Anttweakbar::Type>

=back

=head3 value

The B<reference> to the variable value. For complex types (e.g. quaternion) it must
also be an B<reference> to array of 3 numbers.

=head3 cb_read

Closure, that returns the actual value of variable.

=head3 cb_write($value)

Closure, that is been invoked when user sets new value to the variable.
If C<cb_write> is undefined, then the variable considered B<readonly>.

=head3 definition

An string or hashref of values that allows additional tuning of
variable in Anttweakbar.
See L<http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:varparamsyntax#parameters>
for possible values.

=cut

sub add_variable {
    my ($self, %args) = @_;

    for (qw/mode name type/) {
        croak "'$_' is mandatory argument for add_variable"
            unless exists $args{$_};
    }

    my $mode       = $args{mode      };
    my $name       = $args{name      };
    my $type       = $args{type      };
    my $value      = $args{value     };
    my $cb_read    = $args{cb_read   };
    my $cb_write   = $args{cb_write  };
    my $definition = $args{definition} // "";

    croak "Either value or callbacks should be specified"
        if ($value && ($cb_read || $cb_write));
    croak "cb_read is mandatory when value isn't specied"
        if (!$value && !$cb_read);
    croak "value should be a reference"
        if ($value && !ref($value));
    $type = $type->name if(ref($type) eq 'AntTweakBar::Type');
    $definition = _as_definition_string($definition)
        if ($definition && ref($definition) eq 'HASH');

    _add_variable($self->{_bar_ptr}, $mode, $name, $type, $value,
                  $cb_read, $cb_write, $definition);
}

=head2 remove_variable($name)

  $bar->remove_variable('Zoom');

=cut

sub remove_variable {
    my ($self, $name) = @_;
    _remove_variable($self->{_bar_ptr}, $name);
}

=head2 refresh

  $bar->refresh;

Tells Anttweakbar that variable values are possibly changed and
should be updated.

=cut

sub refresh {
    my $self = shift;
    _refresh($self->{_bar_ptr});
}

=head2 set_bar_params(%values)

  $bar->set_bar_params(
    size        => '350 700,
    valueswidth => '200'
    visible     => 'false',
  );

Updates bar definition at runtime. See
L<http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:twbarparamsyntax>.

=cut

sub set_bar_params {
    my ($self, %params) = @_;
    while (my ($k, $v) = each(%params)) {
        _set_bar_parameter($self->{_bar_ptr}, $k, $v);
    }
}

=head2 set_variable_params($var_name, $var_definition)

  $bar->set_variable_params('ObjRotation', readonly => 'true');

Updates variable definition at runtime. See
L<http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:varparamsyntax#parameters>

=cut

sub set_variable_params {
    my ($self, $variable, %params) = @_;
    while (my ($k, $v) = each(%params)) {
        _set_variable_parameter($self->{_bar_ptr}, $variable, $k, $v);
    }
}


=head1 INITIALIZATION AND DRAW FUNCTIONS


=head2 init

  AntTweakBar::init(TW_OPENGL);

Initializes AntTweakBar

=head2 terminate

  AntTweakBar::terminate

Uninitializes AntTweakBar

=head2 window_size

  AntTweakBar::window_size(640, 480);

Tell AntTweakBar the actual size of your window

=head2 draw

  AntTweakBar::draw;

Draw AntTweakBar just before the frame buffer is presented (swapped).



=head1 OPENGL EVENT FUNCTIONS


=head2 eventMouseButtonGLUT

  glutMouseFunc(\&AntTweakBar::eventMouseButtonGLUT);

Let AntTweakBar handles mouse button clicks

=head2 eventMouseMotionGLUT

  glutMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
  glutPassiveMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);

Let AntTweakBar handles mouse movements with pressed button(s)
and passive mouse movements

=head2 eventKeyboardGLUT

  glutKeyboardFunc(\&AntTweakBar::eventKeyboardGLUT);

Let AntTweakBar handles key presses

=head2 eventSpecialGLUT

  glutSpecialFunc(\&AntTweakBar::eventSpecialGLUT);

=head2 GLUTModifiersFunc

  AntTweakBar::GLUTModifiersFunc(\&glutGetModifiers);

=head1 SDL EVENT FUNCTION

=head2 eventSDL

If you use SDL than it is more simple to let AntTweakBar process
all input-related events via single call:

  AntTweakBar::eventSDL($sdl_event);


=head1 SEE ALSO


L<Alien::AntTweakBar>, L<SDL>, L<OpenGL>, L<http://anttweakbar.sourceforge.net/>


=head1 AUTHOR

Ivan Baidakou E<lt>dmol@(gmx.com)E<gt>

=head1 CREDITS

=over 2

David Horner

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ivan Baidakou

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
