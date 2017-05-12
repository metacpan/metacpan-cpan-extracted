package Bot::Cobalt::Error;
$Bot::Cobalt::Error::VERSION = '0.021003';
use v5.10;
use strictures 2;

use Devel::StackTrace;

use overload
  bool     => sub { 1 },
  '""'     => 'string',
  fallback => 1 ;


sub TRACE () { 0 }
sub ARRAY () { 1 }

sub __new_trace {
  Devel::StackTrace->new(
    ignore_class => __PACKAGE__,
    no_refs      => 1,
  )
}

sub new {
  my $class = shift;
  my $trace = $class->__new_trace;
  bless [
    $trace,    ## TRACE
    [ @_ ],    ## ARRAY
  ], ref $class || $class
}

sub trace {
  my ($self) = @_;
  $self->[TRACE]
}

sub _set_trace {
  my ($self, $trace) = @_;
  $self->[TRACE] = $trace;
  $self
}

sub throw {
  my ($self) = @_;
  die $self->_set_trace( $self->__new_trace )
}

sub string {
  join '', map { "$_" } @{ $_[0]->[ARRAY] }
}

sub push {
  my $self = shift;
  push @{ $self->[ARRAY] }, @_;
  $self
}

sub unshift {
  my $self = shift;
  unshift @{ $self->[ARRAY] }, @_;
  $self
}

sub slice {
  my $self = shift;
  $self->new( @{ $self->[ARRAY] }[@_] )
}

sub join {
  my ($self, $delim) = @_;
  $self->new( join($delim //= ' ', map { "$_" } @{ $self->[ARRAY] }) )
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Error - Lightweight error objects

=head1 SYNOPSIS

  package SomePackage;
  
  sub some_method {
    . . .
    
    die Bot::Cobalt::Error->new(
      "Some errors occured:",
      @errors
    )->join("\n");

    ## ... same as:
    die Bot::Cobalt::Error->new(
      "Some errors occured:\n",
      join("\n", @errors)
    );
  }
  
  
  package CallerPackage;
  
  use Try::Tiny;
  
  try {
    SomePackage->some_method();
  } catch {
    ## $error isa Bot::Cobalt::Error
    my $error = $_;
    
    ## Stringifies to the error string:
    warn "$error\n";
  };

=head1 DESCRIPTION

A lightweight exception object for L<Bot::Cobalt>.

B<new()> takes a list of messages used to compose an error string.

The objects themselves stringify to the concatenated stored errors.

A L<Devel::StackTrace> instance is created at construction time; it is 
accessible via L</trace>.

=head2 string

Returns the current error string; this is the same value returned when 
the object is stringified, such as:

  warn "$error\n";

=head2 join

  $error = $error->join("\n");

Returns a new object whose only element is the result of joining the 
stored list of errors with the specified expression.

Defaults to joining with a single space. Does not modify the existing 
object.

=head2 push

  $error = $error->push(@errors);

Appends the specified list to the existing array of errors.

Modifies and returns the existing object.

=head2 slice

  $error = $error->slice(0 .. 2);

Returns a new object whose elements are as specified. Does not modify 
the existing object.

=head2 throw

  my $err = Bot::Cobalt::Error->new;
  $err->push( @errors );
  $err->throw

Throw an exception by calling die() with the current object.
The L<Devel::StackTrace> object is reinstanced from where throw() is 
called (see L</trace>).

=head2 trace

  ## Stack trace as string:
  warn $error->trace->as_string;

A L<Devel::StackTrace> instance; see L<Devel::StackTrace>.

=head2 unshift

  $error = $error->unshift(@errors);

Prepends the specified list to the existing array of errors.

Modifies and returns the existing object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
