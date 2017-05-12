package App::MojoSlides::Slides;

use Mojo::Base -base;

has first => 1;

has last  => sub {
  my $self = shift;
  my $slides = $self->list or return 1;
  return @$slides;
};

has 'list';

sub new {
  my $class = shift;
  my $args;
  if (@_==1) {
    $args = { last => $_[0] } unless ref $_[0];
    $args = { list => $_[0] } if ref $_[0] eq 'ARRAY';
  }
  return $class->SUPER::new($args ? $args : @_);
}

sub prev {
  my ($self, $current) = @_;
  return $current == $self->first ? $current : $current - 1;
}

sub next {
  my ($self, $current) = @_;
  return $current == $self->last ? $current : $current + 1;
}

sub template_for {
  my ($self, $num) = @_;
  return "$num" unless my $list = $self->list;
  return $list->[$num-1];
}

1;

__END__

=head1 NAME

App::MojoSlides::Slides - Slide organizer for App::MojoSlides

=head1 SYNOPSIS

 my $slides = App::MojoSlides::Slides->new(
   list => ['beginning', 'middle', 'end'],
 );

  -- or --

 my $slides = App::MojoSlides::Slides->new(
   last => 10,
 );

=head1 DESCRIPTION

This little class eases some of the organization of slides for L<App::MojoSlides>.
You probably don't need to invoke this directly.
However, your presentation configuration will contain a C<slides> key, so you might still want to know about it.

Specifically, you will likely need either C<list> or C<last> attributes.
If you provide a C<list>, these are the template names which map to slide C<n+1> when C<n> is the index in the arraref.
If you instead provide a C<last> attribute, it will assume your templates are named C<1..last>.

=head1 CONSTRUCTOR

 App::MojoSlides::Slides->new(2)->last # 2
 App::MojoSlides::Slides->new($arrayref)->list # $arrayref

Since nearly every instance of this class will need either a C<last> or C<list> initialization,
the constructor will take a single scalar or arrayrefence as inialization of those attributes respectively.

=head1 ATTRIBUTES

=over 

=item first

The ordinal number of the first slide. Defaults to 1, as it should.

=item last

The ordinal number of the last slide. Defaults to the number of items in C<list> or else 1.

=item last

An arrayref of slide names in order. Optional.
If missing your slides should be numbered numerically from C<first> to C<last>.

=back

=head1 METHODS

These methods are used in the MojoSlide system and you probably don't need to use them.
Still they exist.

=over

=item prev

Called with the current slide number and returns the slide number before it, or else C<first> if you are at it.

=item next

Called with the current slide number and returns the slide number after it, or else C<last> if you are at it.

=item template_for

Takes an ordinal number (C<n>) and if C<list> is defined, returns the C<n-1>th item, or else it returns the stringified number you passed in.

=back
