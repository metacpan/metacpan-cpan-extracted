package Data::Flow;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '1.02';	# The only change 0.09 --> 1.02 is this line ;-)


# Preloaded methods go here.

sub new {
  die "Usage: new Data::Flow \$recipes" unless @_ == 2;
  my $class = shift;
  my $recipes = shift;
  $recipes = bless [$recipes, {}], $class;
  # $recipes->set(@_);
  $recipes;
}

sub set {
  my $self = shift;
  die "Odd number of data given to Data::Flow::set" if @_ % 2;
  my %data = @_;
  @{$self->[1]}{keys %data} = values %data;
}

sub unset {
  my ($self, $f) = shift;
  for $f (@_) {
    delete $self->[1]{$f}
  }
}

sub get {
  my $self = shift;
  my $request = shift;
  $self->request($request);
  $self->[1]->{$request};
}

sub aget {
  my $self = shift;
  [map { $self->request($_); $self->[1]->{$_} } @_]
}

sub already_set {
  my $self = shift;
  my $request = shift;
  exists $self->[1]->{$request};
}

sub request {
  my $self = shift;
  my ($recipes, $data) = @$self;
  my ($recipe, $request);
  for $request (@_) {
    # Bail out if present
    next if exists $data->{$request};
    $recipe = $recipes->{$request};
    # Get prerequisites
    $self->request(@{$recipe->{prerequisites}})
      if exists $recipe->{prerequisites};
    # Check for default value
    if (exists $recipe->{default}) {
      $data->{$request} = $recipe->{default};
      next;
    } elsif (exists $recipe->{process}) { # Let it do the work itself.
      &{$recipe->{process}}($data, $request);
      die "The recipe for processing the request `$request' did not acquire it" 
	unless exists $data->{$request};
    } elsif (exists $recipe->{oo_process}) { # Let it do the work itself.
      &{$recipe->{oo_process}}($self, $request);
      die "The recipe for OO-processing the request `$request' did not acquire it"
       unless exists $data->{$request};
    } elsif (exists $recipe->{output}) { # Keep return value.
      $data->{$request} = &{$recipe->{output}}($data, $request);
    } elsif (exists $recipe->{oo_output}) { # Keep return value.
      $data->{$request} = &{$recipe->{oo_output}}($self, $request);
    } elsif (exists $recipe->{filter}) { # Input comes from $data
      my @arr = @{ $recipe->{filter} };
      my $sub = shift @arr;
      foreach (@arr) { $self->request($_) }
      @arr = map $data->{$_}, @arr;
      $data->{$request} = &$sub( @arr );
    } elsif (exists $recipe->{self_filter}) { # Input comes from $data
      my @arr = @{ $recipe->{self_filter} };
      my $sub = shift @arr;
      foreach (@arr) { $self->request($_) }
      @arr = map $data->{$_}, @arr;
      $data->{$request} = &$sub( $self, @arr );
    } elsif (exists $recipe->{method_filter}) { # Input comes from $data
      my @arr = @{ $recipe->{method_filter} };
      my $method = shift @arr;
      foreach (@arr) { $self->request($_) }
      @arr = map $data->{$_}, @arr;
      my $obj = shift @arr;
      $data->{$request} = $obj->$method( @arr );
    } elsif (exists $recipe->{class_filter}) { # Input comes from $data
      my @arr = @{ $recipe->{class_filter} };
      my $method = shift @arr;
      my $class = shift @arr;
      foreach (@arr) { $self->request($_) }
      @arr = map $data->{$_}, @arr;
      $data->{$request} = $class->$method( @arr );
    } else {
      die "Do not know how to satisfy the request `$request'"
	unless exists $data->{$request};	# 'prerequisites' could set it
    }
  }
}

*TIEHASH  = \&new;
*STORE	  = \&set;
*FETCH	  = \&get;

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Data::Flow - Perl extension for simple-minded recipe-controlled build of data.

=head1 SYNOPSIS

  use Data::Flow;
  $recipes = { path  => { default => './MANIFEST'},
	       contents => { prerequisites => ['path', 'x'] ,
			     process => 
			     sub {
			       my $data = shift; 
			       $data->{ shift() } = `cat $data->{'path'}`
				 x $data->{'x'};
			     }
			   },
	     };

  $request = new Data::Flow $recipes;
  $request->set( x => 1);
  print $request->get('contents');

  tie %request, Data::Flow, $recipes;
  $request{x} = 1;
  print $request{contents};


=head1 DESCRIPTION

The module Data::Flow provides its services via objects. The objects may
be obtained by the usual

  $request = new Data::Flow $recipes;

paradigm. The argument $recipes is a hash reference, which provides
the rules for request processing. The objects support three methods,
set(), get(), aget(), and already_set(). The first one is used to provide input data for
processing, the second one to obtain the output. The third one to obtain a
reference to an array with results of repeated get(), and the last one to query
whether a field is already known.

The unit of requested information is a I<field>. The method set()
takes a pair C<field =E<gt> value>, the methods get() and already_set() take one
argument: the C<field>, and the method aget() takes multiple fields.

Every object is created without any fields filled, but it knows how to
I<construct> fields basing on other fields or some global into. This
knowledge is provided in the argument $recipe of the new()
function. This is a reference to a hash, keyed by I<fields>. The
values of this hash are hash references themselves, which describe how
to acquire the I<field> which is the corresponding key of the initial
hash.

The internal hashes may have the following keys:

=over 8

=item C<default>

describes the default value for the key, if none is provided by
set(). The value becomes the value of the field of the object. No
additional processing is performed. Example:

  default => $Config{installdir}

=item C<prerequisites>

gives the fields which are needed for the construction of the given
field. The corresponding value is an array references. The array
contains the I<required> fields.

If C<defaults> did not satisfy the request for a field, but
C<$recipe-E<gt>{field}{prerequisites}> exists, the I<required>
fields are build before any further processing is done. Example:

  prerequisites => [ qw(prefix arch) ]

=item C<process>

contains the rule to build the field. The value is a reference to a
subroutine taking 2 arguments: the reference to a hash with all the fields
which have been set, and the name of
the required field. It is up to the subroutine to actually fill the
corresponding field of the hash, an error condition is raised if it did
not. Example:

  process => sub { my $data = shift;
                  $data->{time} = localtime(time) } }

=item C<oo_process>

contains the rule to build the field. The value is a reference to a
subroutine taking 2 arguments: the object $request, and the name of
the required field. It is up to the subroutine to actually fill the
corresponding field of $request, an error condition is raised if it did
not. Example:

  oo_process => sub { my $data = shift;
                     $data->set( time => localtime(time) ) }


=item C<output>

the corresponing value has the same meaning as for C<process>, but the
return value of the subroutine is used as the value of the
I<field>. Example:

  output => sub { localtime(time) }

=item C<oo_output>

the corresponing value has the same meaning as for C<process>, but the
return value of the method is used as the value of the
I<field>. Example:

  output => sub { my $self = shift; $self->get('r') . localtime(time) }


=item C<filter>

contains the rule to build the field basing on other fields. The value
is a reference to an array. The first element of the array is a
reference to a subroutine, the rest contains names of the fields. When
the subroutine is called, the arguments are the values of I<fields> of
the object $request which appear in the array (in the same order). The
return value of the subroutine is used as the value of the
I<field>. Example:

  filter => [ sub { shift + shift }, 
	      'first_half', 'second_half' ]

Note that the mentioned field will be automatically marked as
prerequisites.

=item C<self_filter>

is similar to C<filter>, but an extra argument, the object itself, is put in
front of the list of arguments.  Example:

  self_filter => [ sub { my ($self, $first_half = (shift, shift);
			 $first_half *= -$self->get('total')*100
			   if $first_half < 0;	# negative means percentage
			 $first_half + shift }, 
	      'first_half', 'second_half' ]

=item C<class_filter>

is similar to C<filter>, but the first argument is the name of the
method to call, second one is the name of the package to use for the
method invocation. The rest contains names of field to provide as
method arguments. Example:

  class_filter => [ 'new', 'FileHandle', 'filename' ]

=item C<method_filter>

is similar to C<class_filter>, but the second argument is the name of the
field which is used to call the method upon. Example:

  method_filter => [ 'show', 'widget_name', 'current_display' ]

=back

=head2 Tied interface

The access to the same functionality is available via tied hash
interface.

=head1 AUTHOR

Ilya Zakharevich, cpan@ilyaz.org, with multiple additions from
Terrence Monroe Brannon and Radoslav Nedyalkov.

=head1 SEE ALSO

perl(1), make(1).

=cut
