package Data::Reach;
use strict;
use warnings;
use Carp         qw/carp croak/;
use Scalar::Util qw/blessed reftype/;
use overload;

our $VERSION    = '1.00';

# main entry point
sub reach ($@) {
  my ($root, @path) = @_;

  # loop until either @path or the datastructure under $root is exhausted
  while (1) {

    # exit conditions
    return undef             if !defined $root;
    return $root             if !@path;
    my $path0 = shift @path;
    return undef             if !defined $path0;

    # otherwise, walk down one step into the datastructure and loop again
    $root = blessed $root ? _step_down_obj($root, $path0)
                          : _step_down_raw($root, $path0);
  }
}

# get inner data within a raw datastructure
sub _step_down_raw {
  my ($data, $key) = @_;

  my $reftype = reftype $data || '';

  if ($reftype eq 'HASH') {
    return $data->{$key};
  }
  elsif ($reftype eq 'ARRAY') {
    if ($key =~ /^-?\d+$/) {
      return $data->[$key];
    }
    else {
      croak "cannot reach index '$key' within an array";
    }
  }
  else {
    my $kind = $reftype          ? "${reftype}REF"
             : defined ref $data ? "SCALAR"
             :                     "undef";
    my $article = $kind =~ /^[aeiou]/i ? "an" : "a";
    croak "cannot reach '$key' within $article $kind";
  }
}


# get inner data within an object
sub _step_down_obj {
  my ($obj, $key) = @_;

  # pragmata that may modify our algorithm -- see L<perlpragma>
  my $hint_hash = (caller(1))[10];
  my $use_overloads = $hint_hash->{'Data::Reach::use_overloads'} // 1; # default
  my $peek_blessed  = $hint_hash->{'Data::Reach::peek_blessed'}  // 1; # default

  # choice 1 : call named method in object
  my @call_method = split $;, $hint_hash->{'Data::Reach::call_method'} || '';
 METH_NAME:
  foreach my $meth_name (@call_method) {
    my $meth =$obj->can($meth_name)
      or next METH_NAME;
    return $obj->$meth($key);
  }

  # choice 2 : use overloaded methods -- active by default
  if ($use_overloads) {
    return $obj->[$key] if overload::Method($obj, '@{}')
                        && $key =~ /^-?\d+$/;
    return $obj->{$key} if overload::Method($obj, '%{}');
  }

  # choice 3 : use the object's internal representation -- active by default
  if ($peek_blessed) {
    return _step_down_raw($obj, $key);
  }
  else {
    croak "cannot reach '$key' within an object of class " . ref $obj;
  }
}



# the 'import' method does 2 things : a) export the 'reach' function,
# like the regular Exporter, but possibly with a change of name;
# b) implement optional changes to the algorithm, lexically scoped
# through the %^H hint hash (see L<perlpragma>).

my %seen_pkg; # remember which packages we already exported into

sub import {
  my $class = shift;
  my $pkg = caller;
  my $export_as;

  # cheap parsing of import parameters -- I wish I could implement that
  # with given/when, but unfortunately those constructs were dropped in v5.18.
  while (my $option = shift) {
    if ($option eq 'reach') {
      $export_as = 'reach';
    }
    elsif ($option eq 'as') {
      $export_as = shift;
      defined $export_as
        or croak "use Data::Reach : no export name after 'as'";
    }
    elsif ($option eq 'call_method') {
      my $methods = shift
        or croak "use Data::Reach : no method name after 'call_method'";
      $methods = join $;, @$methods if (ref $methods || '') eq 'ARRAY';
      $^H{"Data::Reach::call_method"} = $methods;
    }
    elsif ($option eq 'peek_blessed') {
      $^H{"Data::Reach::peek_blessed"} = 1;
    }
    elsif ($option eq 'use_overloads') {
      $^H{"Data::Reach::use_overloads"} = 1;
    }
    else {
      croak "use Data::Reach : unknown option : $option";
    }
  }

  # export the 'reach' function into caller's package, under name $export_as
  if (! exists $seen_pkg{$pkg}) {
    $export_as //= 'reach'; # default export name
    if ($export_as) {       # because it could be an empty string
      no strict 'refs';
      *{$pkg . "::" . $export_as} = \&reach;
    }
    $seen_pkg{$pkg} = $export_as;
  }
  elsif ($export_as && $export_as ne $seen_pkg{$pkg}) {
    carp "ignored request to import Data::Reach::reach as '$export_as' into "
       . "package $pkg, because it was already imported as '$seen_pkg{$pkg}'!";
  }
}


sub unimport {
  my $class = shift;
  while (my $option = shift) {
    $^H{"Data::Reach::$option"} = '';
    # NOTE : mark with a false value, instead of deleting from the
    # hint hash, in order to distinguish options explicitly turned off
    # from default options
  }
}


1;


__END__

=head1 NAME

Data::Reach - Walk down a datastructure, without autovivification

=head1 SYNOPSIS

    # regular use
    use Data::Reach;
    my $node = reach $data_tree, @path;

    # import under a different name
    use Data::Reach as => 'walk_down';
    my $node = walk_down $data_tree, @path;

    # optional changes of algorithm, lexically scoped
    { no Data::Reach  qw/peek_blessed use_overloads/;
      use Data::Reach call_method => [qw/foo bar/];
      my $node = reach $object_tree, @path;
    }
    # after end of scope, back to the regular algorithm

=head1 DESCRIPTION

The C<reach> function walks down a nested datastructure of hashrefs
and arrayrefs, choosing the next subnode at each step according to the
next key supplied in C<@path>. If there is no such sequence of
subnodes, C<undef> is returned. No autovivification nor any writing
into the datastructure is ever performed. Missing data merely returns
C<undef>, while wrong use of data (for example looking into an
arrayref with a non-numerical index) generates an exception.  Blessed
objects within the datastructure are generally treated just like raw,
unblessed datastructures; however that behaviour can be changed
through pragma options.

B<Note>: this code doesn't do much, actually; but after having copy-pasted
similar stuff into several of my applications, I finally decided that
it was worth a CPAN distribution on its own. The L</"SEE ALSO"> section
below discusses some alternative implementations.


=head1 FUNCTIONS

=head2 reach

  my $node = reach $data_tree, @path;

Tries to find a node under root C<$data_tree>, walking down
the tree and choosing subnodes according to values given in
C<@path> (which should be a list of scalar values). At each step :

=over

=item *

if the root is C<undef>, then C<undef> is returned (even if
there are remaining items in C<@path>)

=item *

if C<@path> is empty, then the root C<$data_tree> is returned

=item *

if the first item in C<@path> is C<undef>, then 
C<undef> is returned (even if there are remaining items in C<@path>).

=item *

if C<$data_tree> is a hashref or can behave as a hashref, then
C<< $data_tree->{$path[0]} >> becomes the new root,
and the first item from C<@path> is removed.
No distinction is made between a missing or an undefined
C<< $data_tree->{$path[0]} >> : in both cases the result
will be C<undef>.

=item *

if C<$data_tree> is an arrayref or can behave as an arrayref, then
C<< $data_tree->[$path[0]] >> becomes the new root,
and the first item from C<@path> is removed.
The value in C<< $path[0] >> must be an integer; otherwise
it is improper as an array index and an error is generated.
No distinction is made between a missing or an undefined
C<< $data_tree->[$path[0]] >> : in both cases the result
will be C<undef>.

=item *

if C<$data_tree> is any other kind of data (scalar, reference
to a scalar, reference to a reference, etc.), an error is generated.

=back

By default, blessed objects are treated just like raw, unblessed
datastructures; however that behaviour can be changed through
pragma options, as described below.


=head1 IMPORT INTERFACE

=head2 Exporting the 'reach' function

The 'reach' function is exported by default when C<use>ing this module,
as in :

  use Data::Reach;
  use Data::Reach qw/reach/; # equivalent to the line above

However the exported name can be changed through the C<as> option :

  use Data::Reach as => 'walk_down';
  my $node = walk_down $data, @path;

The same can be done with an empty string in order to prevent any export.
In that case, the fully qualified name must be used to call the
C<reach> function :

  use Data::Reach as => '';      # equivalent to "use Data::Reach ();"
  my $node = Data::Reach::reach $data, @path;


=head2 Pragma options for reaching within objects

Arguments to the import method may also change the algorithm used to
C<reach> within objects. These options can be turned on or off as
lexical pragmata; this means that the effect of change of algorithm
is valid until the end of the current scope (see L<perlfunc/use>,
L<perlfunc/no> and L<perlpragma>).

=over

=item C<call_method>

  use Data::Reach call_method => 'foo';         # just one method
  use Data::Reach call_method => [qw/foo bar/]; # an ordered list of methods

If the target object possesses a method corresponding to the
name(s) specified, that method will be called, with a single
argument corresponding to the current value in path.
The method is supposed to reach down one step into the
datastructure and return the next data subtree or leaf.

The presence of one of the required methods is the first
choice for reaching within an object. If this cannot be applied,
either because there was no required method, or because the
target object has none of them, then the second choice
is to use overloads, as described below.

=item C<use_overloads>

  use Data::Reach qw/use_overloads/; # turn the option on
  no  Data::Reach qw/use_overloads/; # turn the option off

This option is true by default; it means that if the object
has an overloaded hash or array dereferencing function,
that function will be called (see L<overload>). This feature
distinguishes C<Data::Reach> from other similar modules
listed in the L</"SEE ALSO"> section.

=item C<peek_blessed>

  use Data::Reach qw/peek_blessed/; # turn the option on
  no  Data::Reach qw/peek_blessed/; # turn the option off

This option is true by default; it means that the C<reach> functions
will go down into object implementations (i.e. reach internal attributes
within the object's hashref). Turn it off if you want objects to
stay opaque, with public methods as the only way to reach
internal information.

=back

Note that several options can be tuned in one single statement :

  no  Data::Reach qw/use_overloads peek_blessed/; # turn both options off


=head1 SEE ALSO

There are many similar modules on CPAN, each of them having some
variations in the set of features. Here are a few pointers, and the
reasons why I didn't use them :

=over 

=item L<Data::Diver>

Does quite a similar job, with a richer API (can also write into
the datastructure or use it as a lvalue). Return values may be 
complex to decode (distinctions between an empty list, an C<undef>,
or a singleton containing an C<undef>). It uses C<eval> internally,
without taking care of eval pitfalls (see L<Try::Tiny/BACKGROUND>
for explanations).


=item L<Data::DRef>

An old module (last update was in 1999), still relevant for
modern Perl, except that it does not handle overloads, which
were not available at that time. The API is a bit too rich to my
taste (many different ways to get or set data).

=item L<Data::DPath> or L<Data::Path>

Two competing modules for accessing nested data through expressions
similar to XPath. Very interesting, but a bit overkill for the needs
I wanted to cover here.

=item L<Data::Focus>

Creates a "focus" object that walks through the data using
various "lenses". An interesting approach, inspired by Haskell,
but also a bit overkill.

=item L<Data::PathSimple>

Very concise. The path is expressed as a '/'-separated string
instead of an array of values. Does not handle overloads.


=back



=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-reach at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Reach>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Reach


You can also look for information at:

=over 4

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Reach>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Reach>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Reach>

=item METACPAN

L<https://metacpan.org/pod/Data::Reach>

=back

The source code is at
L<https://github.com/damil/Data-Reach>.


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

