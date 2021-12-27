package Data::Reach;
use strict;
use warnings;
use Carp         qw/carp croak/;
use Scalar::Util qw/blessed reftype/;
use overload;

our $VERSION    = '2.00';


#======================================================================
# reach() and utility functions
#======================================================================
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
  my $use_overloads = $hint_hash->{'Data::Reach/use_overloads'} // 1; # default
  my $peek_blessed  = $hint_hash->{'Data::Reach/peek_blessed'}  // 1; # default

  # choice 1 : call named method in object
  my $meth_name = $hint_hash->{'Data::Reach/reach_method'} || '';
  return $obj->$meth_name($key) if $obj->can($meth_name);

  # choice 2 : use overloaded methods -- active by default
  if ($use_overloads) {
    # overloaded array dereferencing is tried first but only if the key is numeric.
    # Otherwise, the hash dereferencing is tried.
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


#======================================================================
# map_paths()
#======================================================================

sub map_paths (&+;$$$); # the prototype must be declared beforehand, because the sub is recursive
sub map_paths (&+;$$$) {
  my ($coderef, $tree, $max_depth, $path, $recurse)= @_;
  $max_depth  //= -1;
  $path       //= [];                                        # only used for recursive calls
  $recurse    //= reftype $tree // '';                       # only used for recursive calls

  my $hint_hash             = (caller(1))[10];
  my $ignore_empty_subtrees = ! $hint_hash->{'Data::Reach/keep_empty_subtrees'};

  if ($max_depth) {
    if ($recurse eq 'ARRAY' and (@$tree or $ignore_empty_subtrees)) {
      return map {map_paths(\&$coderef, $tree->[$_], $max_depth-1, [@$path, $_])} 0 .. $#$tree;
    }
    elsif ($recurse eq 'HASH' and (my @k = sort keys %$tree or $ignore_empty_subtrees)) {
      return map {map_paths(\&$coderef, $tree->{$_}, $max_depth-1, [@$path, $_])} @k;
    }
    elsif (blessed $tree) {
      # try to call named method in object
      if (my $meth_name = $hint_hash->{'Data::Reach/paths_method'}) {
        if ($tree->can($meth_name)) {
          my @paths = $tree->$meth_name();
          return map {map_paths(\&$coderef, reach($tree, $_), $max_depth-1, [@$path, $_])} @paths;
        }
      }

      # otherwise, try to use overloaded methods, or else use the object's internal representation (if allowed)
      my $use_overloads = $hint_hash->{'Data::Reach/use_overloads'} // 1; # default
      my $peek_blessed  = $hint_hash->{'Data::Reach/peek_blessed'}  // 1; # default
      $recurse = $use_overloads && overload::Method($tree, '@{}') ? 'ARRAY'
               : $use_overloads && overload::Method($tree, '%{}') ? 'HASH'
               : $peek_blessed                                    ? reftype $tree
               :                                                    undef;

      # recursive call if appropriate
      return map_paths(\&$coderef, $tree, $max_depth, $path, $recurse) if $recurse;

      # if all else failed, treat this object as an opaque leaf (see base case below)
    }
  }

  # base case
  for ($tree) {return $coderef->(@$path)};                   # @_ contains the path, $_ contains the leaf
}



#======================================================================
# each_path()
#======================================================================

sub each_path (+;$) {
  my ($tree, $max_depth) = @_;
  $max_depth //= -1;
  my $hint_hash = (caller(1))[10];
  my $use_overloads       = $hint_hash->{'Data::Reach/use_overloads'} // 1; # default
  my $peek_blessed        = $hint_hash->{'Data::Reach/peek_blessed'}  // 1; # default
  my $keep_empty_subtrees = $hint_hash->{'Data::Reach/keep_empty_subtrees'};

  # local boolean variable to avoid returning the same result multiple times
  my $is_consumed = 0;

  # closure to be used at tree leaves
  my $leaf = sub {return $is_consumed++ ? () : ([], $tree)};

  my $paths_method = $hint_hash->{'Data::Reach/paths_method'};
  my $recurse = !blessed $tree                                   ? reftype $tree
              : $paths_method  && $tree->can($paths_method)      ? 'OBJECT'
              : $use_overloads && overload::Method($tree, '@{}') ? 'ARRAY'
              : $use_overloads && overload::Method($tree, '%{}') ? 'HASH'
              : $peek_blessed                                    ? reftype $tree
              :                                                    undef;

  # either this tree is a leaf, or we must recurse into subtrees
  if (!$recurse || $recurse !~ /^(OBJECT|HASH|ARRAY)$/ || !$max_depth) {
    return $leaf;
  }
  else {
    my @paths = $recurse eq 'OBJECT' ? $tree->$paths_method()
              : $recurse eq 'HASH'   ? sort keys %$tree
              : $recurse eq 'ARRAY'  ? (0 .. $#$tree)
              :                        ();
    if (!@paths && $keep_empty_subtrees) {
      return $leaf;
    }
    else {
      my $next_subpath;                                          # iterator into next subtree

      return sub {
        while (1) {
          if (!$next_subpath) {                                  # if there is no current iterator
            if (!$is_consumed && @paths) {                       # if there is a chance to get a new iterator
              my $subtree   = reach $tree, $paths[0];
              $next_subpath = each_path($subtree, $max_depth-1); # build an iterator on next subtree
            }
            else {                                               # end of data
              $is_consumed++;
              return ();
            }
          }
          if (my ($subpath, $subval) = $next_subpath->()) {      # try to get content from the current iterator
            return ([$paths[0], @$subpath], $subval);            # found a path, return it
          }
          else {                                                 # mark that the iterator on this subtree ..
            $next_subpath = undef;                               # .. is finished and move to the next data item
            shift @paths;
          }
        }
      }
    }
  }
}




#======================================================================
# class methods: import and unimport
#======================================================================

# the 'import' method does 2 things : a) export the required functions,
# like the regular Exporter, but possibly with a change of name;
# b) implement optional changes to the algorithm, lexically scoped
# through the %^H hint hash (see L<perlpragma>).

my $exported_functions = qr/^(?: reach | each_path | map_paths )$/x;
my $hint_options       = qr/^(?: peek_blessed | use_overloads | keep_empty_subtrees )$/x;

sub import {
  my $class = shift;
  my $pkg   = caller;

  # defaults
  my %export_as = map {($_ => $_)} qw/reach each_path map_paths/ if !@_;
  my $last_func = 'reach';

  # loop over args passed to import()
  while (my $option = shift) {
    if ($option =~ $exported_functions) {
      $export_as{$option} = $option;
      $last_func          = $option;
    }
    elsif ($option eq 'as') {
      my $alias = shift
        or croak "use Data::Reach : no export name after 'as'";
      $export_as{$last_func} = $alias;
    }
    elsif ($option =~ /^(reach|call)_method$/) {
      warn q{"use Data::Reach call_method => .." is obsolete; use "reach_method => .."} if $1 eq 'call';
      my $method = shift
        or croak "use Data::Reach : no method name after 'reach_method'";
      $^H{"Data::Reach/reach_method"} = $method;
    }
    elsif ($option eq 'paths_method') {
      my $method = shift
        or croak "use Data::Reach : no method name after 'paths_method'";
      $^H{"Data::Reach/paths_method"} = $method;
    }
    elsif ($option =~ $hint_options) {
      $^H{"Data::Reach/$option"} = 1;
    }
    else {
      croak "use Data::Reach : unknown option : $option";
    }
  }

  # export into caller's package, under the required alias names
  while (my ($func, $alias) = each %export_as) {
    no strict 'refs';
    *{$pkg . "::" . $alias} = \&$func if $alias;
  }
}


sub unimport {
  my $class = shift;
  while (my $option = shift) {
    $^H{"Data::Reach/$option"} = '' if $option =~ $hint_options;
    # NOTE : mark with a false value, instead of deleting from the
    # hint hash, in order to distinguish options explicitly turned off
    # from default options
  }
}


1;


__END__

=head1 NAME

Data::Reach - Walk down or iterate through a nested Perl datastructure

=head1 SYNOPSIS

    # reach a subtree or a leaf under a nested datastructure
    use Data::Reach;
    my $node = reach $data_tree, @path; # @path may contain a mix of hash keys and array indices

    # do something with all paths through the datastructure ..
    my @result = map_paths {do_something_with(\@_, $_)} $data_tree;

    # .. or loop through all paths
    my $next_path = each_path $data_tree;
    while (my ($path, $val) = $next_path->()) {
      do_something_with($path, $val);
    }

    # import under a different name
    use Data::Reach reach => as => 'walk_down';
    my $node = walk_down $data_tree, @path;

    # optional changes of algorithm, lexically scoped
    { no Data::Reach  qw/peek_blessed use_overloads/;
      use Data::Reach reach_method => [qw/foo bar/];
      my $node = reach $object_tree, @path;
    }
    # after end of scope, back to the regular algorithm

=head1 DESCRIPTION

Perl supports nested datastructures : a hash may contain references to
other hashes or to arrays, which in turn may contain further references
to deeper structures -- see L<perldsc>. Walking down through such
structures usually involves nested loops, and possibly some tests on
C<ref $subtree> for finding out if the next level is an arrayref or a hashref.

The present module offers some utilities for easier handling of nested
datastructures :

=over

=item *

the C<reach> function finds a subtree or a leaf according to a given
C<@path> -- a list of hash keys or array indices. If there is no data
corresponding to that path, C<undef> is returned, without any autovivification
within the tree.

=item *

the C<map_paths> function applies a given code reference to all paths within the nested
datastructure.


=item *

the C<each_path> function returns an iterator over the nested datastructure; it can be
used in the same spirit as a regular C<each> statement over a simple hash, except that it will
walk down multiple levels until finding leaf nodes

=back


The L</"SEE ALSO"> section
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

No autovivification nor any writing into the datastructure is ever
performed. Missing data merely returns C<undef>, while wrong use of
data (for example looking into an arrayref with a non-numerical index)
generates an exception.

By default, blessed objects are treated just like raw, unblessed
datastructures; however that behaviour can be changed through
pragma options, as described below.


=head2 map_paths

  my @result = map_paths { ... } $data_tree [, $max_depth];

Applies the given block to each path within C<$data_tree>, returning the list
of collected results. Within the block, C<@_> contains the
sequence of hash keys or array indices that were traversed, and C<$_> is aliased to
the leaf node. Hence, for a C<$data_tree> of shape :

  { foo => [ undef,
             'abc',
             {bar => {buz => 987}},
             1234,
            ],
    empty_slot  => undef,
    qux         => 'qux',  }

the block will be called six times, with the following values

  # value of @_              value of $_
  # ===========              ===========
   ('empty_slot,')             undef
   ('foo', 0)                  undef
   ('foo', 1)                  'abc'
   ('foo', 2, 'bar', 'buz')     987
   ('foo', 3)                  1234
   ('qux')                     'qux'

The optional C<$max_depth> argument limits the depth of tree traversal : subtrees
below that depth will be treated as leaves.

The C<$data_tree> argument is usually a reference to a hash or to an array;
but it can also be supplied directly as a hash or array -- this will be automatically
converted into a reference.

By default, blessed objects are treated just like raw, unblessed
datastructures; however that behaviour can be changed through
pragma options, as described below.


=head2 each_path

  my $next_path_iterator = each_path $data_tree [, $max_depth];
  while (my ($path, $val) = $next_path_iterator->()) {
    do_something_with($path, $val);
  }

Returns an iterator function that will walk through the datastructure.
Each call to the iterator will return a pair C<($path, $val)>, where
C<$path> is an arrayref that contains the sequence of hash keys or
array indices that were traversed, and C<$val> is the leaf node.

By default, blessed objects are treated just like raw, unblessed
datastructures; however that behaviour can be changed through
pragma options, as described below.


=head1 IMPORT INTERFACE

=head2 Exporting the 'reach', 'map_paths' and 'each_path' functions

The 'reach', 'map_paths' and 'each_path' functions are exported by default
when C<use>ing this module :

  use Data::Reach;
  use Data::Reach qw/reach map_paths each_path/; # equivalent to the line above

However the exported names can be changed through the C<as> option :

  use Data::Reach reach => as => 'walk_down', map_paths => as => 'find_subtrees';
  my $node = walk_down $data, @path;


=head2 Pragma options for reaching within objects

Arguments to the import method may also change the algorithm used to
deal with objects met while traversing the datastructure. These
options can be turned on or off as lexical pragmata; this means that
the effect of change of algorithm is valid until the end of the
current scope (see L<perlfunc/use>, L<perlfunc/no> and L<perlpragma>).

=over

=item C<reach_method>

  use Data::Reach reach_method => $method_name;

If the target object possesses a method corresponding to the
name specified, that method will be called, with a single
argument corresponding to the current value in path.
The method is supposed to reach down one step into the
datastructure and return the next data subtree or leaf.

The presence this method is the first
choice for reaching within an object. If this cannot be applied,
either because there was no required method, or because the
target object has no such method, then the second choice
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


=item C<paths_method>

  use Data::Reach paths_method => $method_name;

If the target object possesses a method corresponding to the
name specified, that method will be called for for finding the
list of path items under the current tree (like the list of
keys for a hash, or the list of indices for an array).


=back

Note that several options can be tuned in one single statement :

  no  Data::Reach qw/use_overloads peek_blessed/; # turn both options off


=head1 SEE ALSO

For reaching data subtrees, there are many similar modules on CPAN,
each of them having some variations in the set of features. Here are a
few pointers, and the reasons why I didn't use them :

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

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Reach

You can also look for information at L<https://metacpan.org/pod/Data::Reach>


The source code is at L<https://github.com/damil/Data-Reach>.
Bug reports or feature requests can be addressed at L<https://github.com/damil/Data-Reach/issues>.



=head1 LICENSE AND COPYRIGHT

Copyright 2015, 2022 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

