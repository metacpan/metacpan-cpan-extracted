package Array::PseudoScalar;

use 5.006;
use strict;
use warnings;

our $VERSION = "1.02";

# subclass constructor
sub subclass {
  my ($class, $sep) = @_;
  $sep or die $class . '->subclass(..): missing a nonempty separator string';

  my $subclass = join '::', $class, $sep;

  # deactivate strict refs because we'll be playing with symbol tables
  no strict 'refs';

  # build the subclass on the fly, if not already present
  @{$subclass.'::ISA'} = ($class) unless @{$subclass.'::ISA'};

  return $subclass;
}

# instance constructor
sub new {
  my $class = shift;
  $class ne __PACKAGE__
    or die "can't call ->new(..) on $class; call ->subclass(..) first";
  bless [@_], $class;
}

# stringification method
sub _stringify {
  my $self = shift;
  my $class = ref $self;
  my @class_path = split /::/, $class;
  @class_path > 2 or die "$class: you forgot to call ->subclass(..)";
  my $sep = $class_path[-1];
  return join $sep, @$self;
}

# overload API
use overload
  '""'     => \&_stringify,   # stringification
  fallback => 1,              # all other operators will be derived from '""'
  ;

# be treated like an plain array by JSON::to_json()
sub TO_JSON  {my $self = shift; return [@$self]}

# additional methods for Template Toolkit, if present on this system
if (eval "use Template; 1") {
  require Template::Stash;

  # deactivate strict refs because we'll be playing with symbol tables
  no strict 'refs';

  # method for being treated as a list by Template::Iterator
  *as_list = sub {my $self = shift; return $self};

  # import vmethods from Template::Stash, to be treated as a scalar
  foreach my $meth_name (keys %$Template::Stash::SCALAR_OPS) {

    # won't shadow list vmethods
    next if exists $Template::Stash::LIST_OPS->{$meth_name}; 

    *$meth_name = $Template::Stash::SCALAR_OPS->{$meth_name};
  }
}


1; # End of Array::PseudoScalar

__END__

=head1 NAME

Array::PseudoScalar - Arrays that behave like scalars

=head1 SYNOPSIS

  use Array::PseudoScalar;

  my $subclass      = Array::PseudoScalar->subclass(';');
  my $schizophrenic = $subclass->new(qw/this is a pseudoscalar/);

  use 5.010;  # just for "say" below
  say "i'm an array" if @$schizophrenic;            # treated as an arrayref
  say "i'm a scalar" if length $schizophrenic;      # treated as a scalar
  say "i'm a pseudo" if $schizophrenic =~ /pseudo/; # treated as a scalar
  say $schizophrenic;          # "this;is;a;pseudoscalar"
  say @$schizophrenic;         # "thisisapseudoscalar"

  @$schizophrenic = sort @$schizophrenic;            # still a blessed object
  say $schizophrenic;          # "a;is;pseudoscalar;this"

  $schizophrenic =~ s/pseudo/plain /;                # no longer an object
  !eval{@$schizophrenic} and say "see, i'm no longer an array";

=head1 DESCRIPTION

=head2 Motivation

Sometimes lists of values need to be alternatively treated as arrays
or as scalars (joined by a separator character), depending on the
context.  This is often the case for example with parameters of an
HTTP query, or with "varray" columns in a database.  Code dealing with
such data is usually full of calls to L<join|perlfunc/join> or 
L<split|perlfunc/split>.

The present module provides a uniform interface for treating the same
data both as an arrayref and as a scalar, implicitly joined on some
separator: usual array and string operations are both available.

=head2 Caveat

If a string modification is applied (regex substitution, C<.=>
operator, etc.), the result is a new string copy, which is no longer
an object and can no longer be treated like an arrayref. On the
contrary, array modifications can be applied (L<push|perlfunc/push>,
L<shift|perlfunc/shift>, L<splice|perlfunc/splice>, etc.), and do
preserve the object status (see the C<sort> example in the synopsis
above).

=head2 Interaction with Template Toolkit

Pseudoscalars from this module are stored internally as blessed
arrayrefs.  Since they are objects, the L<Template Toolkit|Template>
doesn't treat them as raw data, which in this case is rather
inconvenient. Therefore, some proxy methods are imported from the
Template Toolkit, so that our pseudoscalars can also be used as list
or as scalars within templates :

  My name is [% schizophenic.replace("scalar", "array") %].
  [% FOREACH item IN schizophrenic %]
     Here is a member item : [% item %]
  [% END; # FOREACH %]

=head2 Interaction with JSON

Likewise, L<JSON/to_json> only exports objects who possess a C<TO_JSON()>
method; so such a method is also implemented here. JSON is really
reluctant to emit any object data, so some additional calls are
needed to make it work :

  my $converter = JSON->new->allow_blessed->convert_blessed;
  print $converter->to_json($schizophrenic); # ["FOO","BAR","BUZ"]


=head1 PUBLIC METHODS

=head2 subclass

  my $subclass = Array::PseudoScalar->subclass(';');

Takes a separator string as argument, and automatically generates a
new subclass of C<Array::PseudoScalar>, for building objects
with that separator string. If the subclass was already generated by
a previous call, it merely returns the class name.

=head2 new

  my $pseudoscalar = $subclass->new(@array);

Pseudoscalar constructor, taking an initial array as argument.
Calling the C<new> method on the parent class C<Array::PseudoScalar>
is an error: you have to L</subclass> first to tell which separator
string will be used.

=head1 INTERNAL METHODS

=head2 _stringify

This is the internal implementation of the overloaded stringification
operator C<'""'>.

=head2 TO_JSON

Returns a copy of the internal array, so that it can be emitted by JSON.

=head2 as_list, replace, search, remove, etc.

Methods imported from L<Template::Stash>, so that pseudoscalars 
can be naturally used within templates, both as scalars and arrays.


=head1 SEE ALSO

L<overload>, L<Array::Autojoin>.


=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-array-pseudoscalar at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-PseudoScalar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Array::PseudoScalar


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-PseudoScalar>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Array-PseudoScalar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Array-PseudoScalar>

=item * Search CPAN

L<http://search.cpan.org/dist/Array-PseudoScalar/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


