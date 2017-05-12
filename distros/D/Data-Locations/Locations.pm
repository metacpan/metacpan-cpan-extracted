
###############################################################################
##                                                                           ##
##    Copyright (c) 1997 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Data::Locations;

use 5.004;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Carp;
require Symbol;
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = ();

@EXPORT_OK = ();

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = "5.5";

bootstrap Data::Locations $VERSION;

my $Class = __PACKAGE__;    ##  This class's name
my $Table = $Class . '::';  ##  This class's symbol table

my $Count = 0;  ##  Counter for generating unique names for all locations
my $Alive = 1;  ##  Flag for disabling auto-dump during global destruction

  *print  = \&PRINT;        ##  Define public aliases for internal methods
  *printf = \&PRINTF;
  *read   = \&READLINE;

sub _usage_
{
    my($text) = @_;

    Carp::croak("Usage: $text");
}

sub _error_
{
    my($name,$text) = @_;

    Carp::croak("${Table}${name}(): $text");
}

sub _alert_
{
    my($name,$text) = @_;

    Carp::carp("${Table}${name}(): $text") if $^W;
}

sub _check_filename_
{
    my($name,$file) = @_;

    if (defined $file)
    {
        if (ref($file))
        {
            &_error_($name, "reference not allowed as filename");
        }
        else
        {
            if ($file !~ /^\s*$/) { return "$file"; }
        }
    }
    return '';
}

sub new
{
  &_usage_("\$[top|sub]location = [$Class|\$location]->new( [ \$filename ] );")
    if ((@_ < 1) || (@_ > 2));

    my($outer) = shift;
    my($file,$name,$inner);

    $file = '';
    $file = shift if (@_ > 0);
    $file = &_check_filename_('new', $file);

    $name = 'LOCATION' . $Count++;   ##  Generate a unique name
no strict "refs";
    $inner = \*{$Table . $name};     ##  Create a reference of glob value
use strict "refs";
    bless($inner, $Class);           ##  Bless glob to become an object
    tie(*{$inner}, $Class, $inner);  ##  Tie glob to itself
    ${*{$inner}} = $inner;           ##  Use $ slot of glob for self-ref
    @{*{$inner}} = ();               ##  Use @ slot of glob for the data
    %{*{$inner}} = ();               ##  Use % slot of glob for obj attributes

    ${*{$inner}}{'name'} = $name;    ##  Also keep symbolic self-ref
    ${*{$inner}}{'file'} = $file;    ##  Store filename (is auto-dump flag)

    ${*{$inner}}{'outer'} = {};      ##  List of surrounding locations
    ${*{$inner}}{'inner'} = {};      ##  List of embedded locations

    ##  Enable destruction when last user ref goes out of scope:

    ${*{$inner}}{'refs'} = &_mortalize_($inner);

    if (ref($outer))  ##  Object method (or else class method)
    {
        ${${*{$inner}}{'outer'}}{${*{$outer}}{'name'}} = 1;
        ${${*{$outer}}{'inner'}}{${*{$inner}}{'name'}} = 1;
        push(@{*{$outer}}, $inner);
    }
    return $inner;
}

sub TIEHANDLE
{
    return $_[1];
}

sub CLOSE
{
    &_alert_("close", "operation ignored");
}

sub _unlink_outer_
{
    my($inner) = @_;
    my($name,$list,$item);

    $name = ${*{$inner}}{'name'};
    $list = ${*{$inner}}{'outer'};
    foreach $item (keys %{$list})
    {
        if (exists $Data::Locations::{$item})
        {
            delete ${${*{ $Data::Locations::{$item} }}{'inner'}}{$name};
        }
    }
    ${*{$inner}}{'outer'} = {};
}

sub _unlink_inner_
{
    my($outer) = @_;
    my($name,$list,$item);

    $name = ${*{$outer}}{'name'};
    $list = ${*{$outer}}{'inner'};
    foreach $item (keys %{$list})
    {
        if (exists $Data::Locations::{$item})
        {
            delete ${${*{ $Data::Locations::{$item} }}{'outer'}}{$name};
        }
    }
    ${*{$outer}}{'inner'} = {};
}

sub delete
{
    &_usage_('$location->delete();')
      if ((@_ != 1) || !ref($_[0]));

    my($location) = @_;

    &_unlink_inner_($location);
    delete ${*{$location}}{'stack'};
    @{*{$location}} = ();
}

sub DESTROY
{
    my($location) = @_;

    if ($Alive)
    {
        if (${*{$location}}{'file'} ne '')
        {
            &dump($location);
        }
        &_unlink_outer_($location);
        &_unlink_inner_($location);
        &_resurrect_($location, ${*{$location}}{'refs'});
        delete $Data::Locations::{ ${*{$location}}{'name'} };
        { local($^W) = 0; untie(*{$location}); }
        undef ${*{$location}};
        undef %{*{$location}};
        undef @{*{$location}};
    }
}

sub END
{
    my($item,$location);

    ##  Disable auto-dump during global destruction and dump all relevant
    ##  locations here while all their embedded sublocations still exist
    ##  (because global destruction destroys in random order!):

    $Alive = 0;

    foreach $item (keys %Data::Locations::)
    {
        if ($item =~ /^LOCATION\d+$/)
        {
            $location = ${*{ $Data::Locations::{$item} }};
            if (${*{$location}}{'file'} ne '')
            {
                &dump($location);
            }
            &_resurrect_($location, ${*{$location}}{'refs'});
        }
    }
}

sub filename
{
    &_usage_('$filename = $location->filename( [ $filename ] );')
      if ((@_ < 1) || (@_ > 2) || !ref($_[0]));

    my($location) = shift;
    my($file);

    $file = ${*{$location}}{'file'};
    if (@_ > 0)
    {
        ${*{$location}}{'file'} = &_check_filename_('filename', $_[0]);
    }
    return $file;
}

sub toplevel
{
    &_usage_('$flag = $location->toplevel();')
      if ((@_ != 1) || !ref($_[0]));

    return ! keys(%{${*{$_[0]}}{'outer'}});
}

sub _self_contained_
{
    my($outer,$inner) = @_;
    my($list,$item);

    return 1 if ($outer == $inner);
    $list = ${*{$outer}}{'outer'};
    foreach $item (keys %{$list})
    {
        if (exists $Data::Locations::{$item})
        {
            $outer = ${*{ $Data::Locations::{$item} }};
            return 1 if (&_self_contained_($outer,$inner));
        }
    }
    return 0;
}

sub PRINT  ##  Aliased to "print"
{
    &_usage_('$location->print(@items);')
      if ((@_ < 1) || !ref($_[0]));

    my($outer) = shift;
    my($inner);

    ITEM:
    foreach $inner (@_)
    {
        if (ref($inner))
        {
            if (ref($inner) ne $Class)
            {
                &_alert_("print", ref($inner) . " reference ignored");
                next ITEM;
            }
            if (&_self_contained_($outer,$inner))
            {
                &_error_("print", "infinite recursion loop attempted");
            }
            else
            {
                ${${*{$inner}}{'outer'}}{${*{$outer}}{'name'}} = 1;
                ${${*{$outer}}{'inner'}}{${*{$inner}}{'name'}} = 1;
            }
        }
        push(@{*{$outer}}, $inner);
    }
}

sub PRINTF  ##  Aliased to "printf"
{
    &_usage_('$location->printf($format, @items);')
      if ((@_ < 2) || !ref($_[0]));

    my($location) = shift;
    my($format) = shift;

    &print( $location, sprintf($format, @_) );
}

sub println
{
    &_usage_('$location->println(@items);')
      if ((@_ < 1) || !ref($_[0]));

    my($location) = shift;

    &print( $location, @_, "\n" );

    ##  We use a separate "\n" here (instead of concatenating it
    ##  with the last item) in case the last item is a reference!
}

sub _read_item_
{
    my($location) = @_;
    my($stack,$first,$index,$which,$item);

    if (exists ${*{$location}}{'stack'})
    {
        $stack = ${*{$location}}{'stack'};
    }
    else
    {
        $stack = [ [ 0, ${*{$location}}{'name'} ] ];
        ${*{$location}}{'stack'} = $stack;
    }

    if (@{$stack})
    {
        $first = ${$stack}[0];
        $index = ${$first}[0];
        $which = ${$first}[1];
        if ((exists $Data::Locations::{$which}) &&
            ($index < @{*{ $Data::Locations::{$which} }}))
        {
            $item = ${*{ $Data::Locations::{$which} }}[$index];
            ${$first}[0]++;
            if (defined $item)
            {
                if (ref($item))
                {
                    if (ref($item) eq $Class)
                    {
                        unshift(@{$stack}, [ 0, ${*{$item}}{'name'} ]);
                    }
                    return &_read_item_($location);
                }
                else { return $item; }
            }
            else { return ""; }
        }
        else
        {
            shift(@{$stack});
            return &_read_item_($location);
        }
    }
    else { return undef; }
}

sub _read_list_
{
    my($location) = @_;
    my(@result);
    my($item);

    while (defined ($item = &_read_item_($location)))
    {
        push(@result, $item);
    }
    return( @result );
}

sub READLINE  ##  Aliased to "read"
{
    &_usage_('[ $item | @list ] = $location->read();')
      if ((@_ != 1) || !ref($_[0]));

    my($location) = @_;

    if (defined wantarray)
    {
        if (wantarray)
        {
            return( &_read_list_($location) );
        }
        else
        {
            return &_read_item_($location);
        }
    }
}

sub reset
{
    &_usage_('$location->reset();')
      if ((@_ != 1) || !ref($_[0]));

    delete ${*{$_[0]}}{'stack'};
}

sub _traverse_recursive_
{
    my($location,$callback) = @_;
    my($item);

    foreach $item (@{*{$location}})
    {
        if (ref($item))
        {
            if (ref($item) eq $Class)
            {
                &_traverse_recursive_($item,$callback);
            }
        }
        else
        {
            &{$callback}($item);
        }
    }
}

sub traverse
{
    &_usage_('$location->traverse(\&callback_function);')
      if ((@_ != 2) || !ref($_[0]));

    my($location,$callback) = @_;

    if (ref($callback) ne 'CODE')
    {
        &_error_("traverse", "not a code reference");
    }
    &_traverse_recursive_($location,$callback);
}

sub _dump_recursive_
{
    my($location,$filehandle) = @_;
    my($item);

    foreach $item (@{*{$location}})
    {
        if (ref($item))
        {
            if (ref($item) eq $Class)
            {
                &_dump_recursive_($item,$filehandle);
            }
        }
        else
        {
            print $filehandle $item;
        }
    }
}

sub dump
{
    &_usage_('$ok = $location->dump( [ $filename ] );')
      if ((@_ < 1) || (@_ > 2) || !ref($_[0]));

    my($location) = shift;
    my($file);

    local(*FILEHANDLE);

    $file = ${*{$location}}{'file'};
    $file = shift if (@_ > 0);
    $file = &_check_filename_('dump', $file);

    if ($file =~ /^\s*$/)
    {
        &_alert_("dump", "filename missing or empty");
        return 0;
    }
    unless ($file =~ /^\s*[>\|+]/)
    {
        $file = '>' . $file;
    }
    unless (open(FILEHANDLE, $file))
    {
        &_alert_("dump", "can't open file '$file': \L$!\E");
        return 0;
    }
    &_dump_recursive_($location,*FILEHANDLE);
    unless (close(FILEHANDLE))
    {
        &_alert_("dump", "can't close file '$file': \L$!\E");
        return 0;
    }
    return 1;
}

sub tie
{
    &_usage_('$location->tie( [ "FH" | *FH | \*FH | *{FH} | \*{FH} | $fh ] );')
      if ((@_ != 2) || !ref($_[0]));

    my($location,$filehandle) = @_;

    $filehandle =~ s/^\*//;
    $filehandle = Symbol::qualify($filehandle, caller);
no strict "refs";
    tie(*{$filehandle}, $Class, $location);
use strict "refs";
}

1;

__END__

=head1 NAME

Data::Locations - magic insertion points in your data

=head1 PREFACE

Did you already encounter the problem that you had to produce some
data in a particular order, but that some piece of the data was still
unavailable at the point in the sequence where it belonged and where
it should have been produced?

Did you also have to resort to cumbersome and tedious measures such
as storing the first and the last part of your data separately, then
producing the missing middle part, and finally putting it all together?

In this simple case, involving only one deferred insertion, you might
still put up with this solution.

But if there is more than one deferred insertion, requiring the handling
of many fragments of data, you will probably get annoyed and frustrated.

You might even have to struggle with limitations of the file system of
your operating system, or handling so many files might considerably slow
down your application due to excessive file input/output.

And if you don't know exactly beforehand how many deferred insertions
there will be (if this depends dynamically on the data being processed),
and/or if the pieces of data you need to insert need additional (nested)
insertions themselves, things will get really tricky, messy and troublesome.

In such a case you might wonder if there wasn't an elegant solution to
this problem.

This is where the "C<Data::Locations>" module comes in: It handles such
insertion points automatically for you, no matter how many and how deeply
nested, purely in memory, requiring no (inherently slower) file input/output
operations.

(The underlying operating system will automatically take care if the amount
of data becomes too large to be handled fully in memory, though, by swapping
out unneeded parts.)

Moreover, it also allows you to insert the same fragment of data into
SEVERAL different places.

This increases space efficiency because the same data is stored in
memory only once, but used multiple times.

Potential infinite recursion loops are detected automatically and
refused.

In order to better understand the underlying concept, think of
"C<Data::Locations>" as virtual files with almost random access:
You can write data to them, you can say "reserve some space here
which I will fill in later", and continue writing data.

And you can of course also read from these virtual files, at any time,
in order to see the data that a given virtual file currently contains.

When you are finished filling in all the different parts of your virtual
file, you can write out its contents in flattened form to a physical, real
file this time, or process it otherwise (purely in memory, if you wish).

You can also think of "C<Data::Locations>" as bubbles and bubbles inside
of other bubbles. You can inflate these bubbles in any arbitrary order
you like through a straw (i.e., the bubble's object reference).

Note that this module handles your data completely transparently, which
means that you can use it equally well for text AND binary data.

You might also be interested in knowing that this module and its concept
have already been heavily used in the automatic code generation of large
software projects.

=head1 SYNOPSIS

  use Data::Locations;

  new
      $toplocation = Data::Locations->new();
      $toplocation = Data::Locations->new($filename);
      $sublocation = $location->new();
      $sublocation = $location->new($filename);

  filename
      $location->filename($filename);
      $filename = $location->filename();
      $oldfilename = $location->filename($newfilename);

  toplevel
      $flag = $location->toplevel();

  print
      $location->print(@items);
      print $location @items;

  printf
      $location->printf($format, @items);
      printf $location $format, @items;

  println
      $location->println(@items);

  read
      $item = $location->read();
      $item = <$location>;
      @list = $location->read();
      @list = <$location>;

  reset
      $location->reset();

  traverse
      $location->traverse(\&callback_function);

  dump
      $ok = $location->dump();
      $ok = $location->dump($filename);

  delete
      $location->delete();

  tie
      $location->tie('FILEHANDLE');
      $location->tie(*FILEHANDLE);
      $location->tie(\*FILEHANDLE);
      $location->tie(*{FILEHANDLE});
      $location->tie(\*{FILEHANDLE});
      $location->tie($filehandle);
      tie(  *FILEHANDLE,  "Data::Locations", $location);
      tie(*{$filehandle}, "Data::Locations", $location);

  tied
      $location = tied   *FILEHANDLE;
      $location = tied *{$filehandle};

  untie
      untie   *FILEHANDLE;
      untie *{$filehandle};

  select
      $filehandle = select();
      select($location);
      $oldfilehandle = select($newlocation);

=head1 IMPORTANT NOTES

=over 3

=item 1)

Although "C<Data::Locations>" behave like normal Perl file handles
in most circumstances, opening a location with "C<open()>" should
be avoided: The corresponding file or pipe will actually be created,
but subsequently data will nevertheless be sent to (and read from)
the given location instead.

There is also no need to switch from read to write mode (or vice-versa),
since locations are ALWAYS open BOTH for reading AND writing.

If you want to rewind a location to start reading at the beginning
again (usually achieved by closing and re-opening a file), use the
method "C<reset()>" instead (see farther below for a description).

Likewise, closing a location with "C<close()>" will have no other
effect than to produce a warning message (under Perl 5.005 and if
the "C<-w>" switch is set) saying "operation ignored", and should
therefore be avoided, too.

=item 2)

"C<Data::Locations>" are rather delicate objects; they are valid Perl
file handles AS WELL AS valid Perl objects AT THE SAME TIME.

As a consequence, B<YOU CANNOT INHERIT> from the "C<Data::Locations>"
class, i.e., it is NOT possible to create a derived class or subclass
of the "C<Data::Locations>" class!

Trying to do so will cause many severe malfunctions, most of which
will not be apparent immediately.

Chances are also great that by adding new attributes to a
"C<Data::Locations>" object you will clobber its (quite tricky)
data structure.

Therefore, use embedding and delegation instead, rather than
inheritance, as shown below:

  package My::Class;
  use Data::Locations;
  use Carp;

  sub new
  {
      my($self) = shift;
      my($location,$object);
      if (ref($self)) { $location = $self->{'delegate'}->new(); }
      else            { $location =     Data::Locations->new(); }
      $object =
          {
              'delegate'   => $location,
              'attribute1' => $whatever,  ##  add your own
              'attribute2' => $whatelse
          };
      bless($object, ref($self) || $self || __PACKAGE__);
  }

  sub AUTOLOAD
  {
      my($i,@args);
      $AUTOLOAD =~ s/^.*:://;
      return if ($AUTOLOAD eq 'DESTROY');
      $AUTOLOAD = 'Data::Locations::' . $AUTOLOAD;
      if (defined &$AUTOLOAD)
      {
          for ( $i = 0; $i < @_; $i++ )
          {
              if (ref($_[$i]) eq __PACKAGE__)
              {
                  $args[$i] = $_[$i]->{'delegate'};
              }
              else
              {
                  $args[$i] = $_[$i];
              }
          }
          @_ = @args;
          goto &$AUTOLOAD;
      }
      else
      {
          croak("$AUTOLOAD(): no such method");
      }
  }

  1;

Note that using this scheme, all methods available for
"C<Data::Locations>" objects are also (automatically and
directly) available for "C<My::Class>" objects, i.e.,

  use My::Class;
  $obj = My::Class->new();
  $obj->filename('test.txt');
  $obj->print("This is ");
  $sub = $obj->new();
  $obj->print("information.");
  @items = $obj->read();
  print "<", join('|', @items), ">\n";
  $sub->print("an additional piece of ");
  $obj->reset();
  @items = $obj->read();
  print "<", join('|', @items), ">\n";
  $obj->dump();

will work as expected (unless you redefine these methods in
"C<My::Class>").

Moreover, with this scheme, you are free to add new methods
and/or attributes as you please.

The class "C<My::Class>" can also be subclassed without any
restrictions.

However, "C<My::Class>" objects are NOT valid Perl file handles;
therefore, they cannot be used as such in combination with Perl's
built-in operators for file access.

=back

=head1 DESCRIPTION

=over 3

=item *

C<use Data::Locations;>

Enables the use of locations in your program.

=item *

C<$toplocation = Data::Locations-E<gt>new();>

The CLASS METHOD "C<new()>" creates a new top-level location.

A "top-level" location is a location which isn't embedded (nested)
in any other location.

Note that CLASS METHODS are invoked using the NAME of their respective
class, i.e., "C<Data::Locations>" in this case, in contrast to OBJECT
METHODS which are invoked using an OBJECT REFERENCE such as returned
by the class's object constructor method (which "C<new()>" happens to be).

Any location that you intend to dump to a file later on in your program
needs to have a filename associated with it, which you can either specify
using the "C<new()>" method (where you can optionally supply a filename,
as shown below), or by setting this filename using the method "C<filename()>"
(see further below), or by specifying an explicit filename when invoking
the "C<dump()>" method itself (see also further below).

=item *

C<$toplocation = Data::Locations-E<gt>new($filename);>

This variant of the CLASS METHOD "C<new()>" creates a new top-level
location (where "top-level" means a location which isn't embedded
in any other location) and assigns a default filename to it.

Note that this filename is simply passed through to the Perl "C<open()>"
function later on (which is called internally when you dump your locations
to a file), which means that any legal Perl filename may be used such as
">-" (for writing to STDOUT) and "| more", to give you just two of the
more exotic examples.

See the section on "C<open()>" in L<perlfunc(1)> for more details.

=item *

C<$sublocation = $location-E<gt>new();>

The OBJECT METHOD "C<new()>" creates a new location which is embedded
in the given location "C<$location>" at the current position (defined
by what has been printed to the embedding location till this moment).

Such a nested location usually does not need a filename associated with
it (because it will be dumped to the same file as the location in which
it is embedded anyway), unless you want to additionally dump this location
to a file of its own.

In the latter case use the variant of the "C<new()>" method shown
immediately below, or the method "C<filename()>" (see below) to set
this filename, or call the method "C<dump()>" (described further
below) with an appropriate filename argument.

=item *

C<$sublocation = $location-E<gt>new($filename);>

This variant of the OBJECT METHOD "C<new()>" creates a new location
which is embedded in the given location "C<$location>" at the current
position (defined by what has been printed to the embedding location
till this moment) and assigns a default filename to it.

See the section on "C<open()>" in L<perlfunc(1)> for details about the
exact syntax of Perl filenames (this includes opening pipes to other
programs as a very interesting and useful application, for instance).

=item *

C<$oldfilename = $location-E<gt>filename($newfilename);>

If the optional parameter is given, this method stores its argument as
the default filename along with the given location.

This filename also serves as an auto-dump flag. If it is set to a non-empty
string, auto-dumping (i.e., an automatic call of the "C<dump()>" method)
occurs when your last reference of the location in question goes out of
scope, or at shutdown time of your script (whichever comes first). See also
the description of the "C<dump()>" method further below for more details.

When a location is auto-dumped, its associated filename is used as the
filename of the file into which the location's contents are dumped.

This method returns the filename that was associated with the given
location before this method call (i.e., the filename given to the
"C<new()>" method or to a previous call of this method), or the
empty string if there was no filename associated with the given
location.

=item *

C<$flag = $location-E<gt>toplevel();>

Use this method to check wether the given location is a "top-level"
location, i.e., if the given location is NOT embedded in any other location.

Note that locations created by the CLASS METHOD "C<new()>" all start their
life-cycle as top-level locations, whereas locations which are embedded in
some other location by using the OBJECT METHOD "C<new()>" (or the method
"C<print()>"; see further below for details) are NOT, by definition,
top-level locations.

Whenever a top-level location is embedded in another location (using the
method "C<print()>" - see further below for more details), it automatically
loses its "top-level" status.

When you throw away the contents of a location (using the method
"C<delete()>" - see further below for details), however, the locations
that may have been embedded in the deleted location can become "orphans"
which have no "parents" anymore, i.e., they may not be embedded in any
other location anymore. These "orphan" locations will automatically
become "top-level" locations.

The method returns "true" ("C<1>") if the given location is a top-level
location, and "false" ("C<0>") otherwise.

=item *

C<$location-E<gt>print(@items);>

This method prints the given list of arguments to the indicated
location, i.e., appends the given items to the given location.

IMPORTANT FEATURE:

Note that you can EMBED any given location IN MORE THAN ONE surrounding
location using this method!

Simply use a statement similar to this one:

        $location->print($sublocation);

This embeds location "C<$sublocation>" in location "C<$location>" at
the current position (defined by what has been printed to location
"C<$location>" till this moment).

(Note that the name "C<$sublocation>" above only refers to the fact
that this location is going to be embedded in the location "C<$location>".
"C<$sublocation>" may actually be ANY location you like, even a top-level
location. Note though that a top-level location will automatically lose
its "top-level" status by doing so.)

This is especially useful if you are generating data once in your
program which you need to include at several places in your output.

This saves a lot of memory because only a reference of the embedded
location is stored in every embedding location, instead of all the
data, which is stored in memory only once.

Note that other references than "Data::Locations" object references are
illegal, trying to "print" such a reference to a location will result
in a warning message (if the "C<-w>" switch is set) and the reference
in question will simply be ignored.

Note also that potential infinite recursions (which would occur when a
given location contained itself, directly or indirectly) are detected
automatically and refused (with an appropriate error message and
program abortion).

Because of the necessity for this check, it is more efficient to embed
locations using the object method "C<new()>", where possible, rather
than with this mechanism, because embedding an empty new location
(as with "C<new()>") is always possible without checking.

Remember that in order to minimize the number of "C<print()>" method calls
in your program (remember that lazyness is a programmer's virtue! C<;-)>)
you can always use the "here-document" syntax:

  $location->print(<<"VERBATIM");
  Article: $article
    Price: $price
    Stock: $stock
  VERBATIM

Remember also that the type of quotes (single/double) around the
terminating string ("VERBATIM" in this example) determines wether
variables inside the given text will be interpolated or not!
(See L<perldata(1)> for more details.)

=item *

C<print $location @items;>

Note that you can also use Perl's built-in operator "C<print>" to
print data to a given location.

=item *

C<$location-E<gt>printf($format, @items);>

This method is an analogue of the Perl (and C library) function
"C<printf()>".

See the section on "C<printf()>" in L<perlfunc(1)> and L<printf(3)>
(or L<sprintf(3)>) on your system for a description.

=item *

C<printf $location $format, @items;>

Note that you can also use Perl's built-in operator "C<printf>" to
print data to a given location.

=item *

C<$location-E<gt>println(@items);>

This is (in principle) the same method as the "C<print()>" method described
further above, except that it always appends a "newline" character ("C<\n>")
to the list of items being printed to the given location.

Note that this newline character is NOT appended to (i.e., concatenated with)
the last item of the given list of items, but that it is rather stored as
an item of its own.

This is mainly because the last item of the given list could be a reference
(of another location), and also to make sure that the data (which could be
binary data) being stored in the given location is not altered (i.e.,
falsified) in any way.

This also allows the given list of items to be empty (in that case, there
wouldn't be a "last item" anyway to which the newline character could be
appended).

=item *

C<$item = $location-E<gt>read();>

In "scalar" context, the method "C<read()>" returns the next item of
data from the given location.

If that item happens to have the value "C<undef>", this method returns
the empty string instead.

If you have never read from this particular location before, "C<read()>"
will automatically start reading at the beginning of the given location.

Otherwise each call of "C<read()>" will return successive items from
the given location, thereby traversing the given location recursively
through all embedded locations (which it may or may not contain), thus
returning the contents of the given location (and any locations embedded
therein) in a "flattened" way.

To start reading at the beginning of the given location again, invoke
the method "C<reset()>" (see a little further below for its description)
on that location.

The method returns "C<undef>" when there is no more data to read.

Calling "C<read()>" again thereafter will simply continue to return
"C<undef>", even if you print some more data to the given location
in the meantime.

However, if you have read the last item from the given location,
but you haven't got the "C<undef>" return value yet, it is possible
to print more data to the location in question and to subsequently
continue to read this new data.

Remember to use "C<reset()>" if you want to read data from the beginning
of the given location again.

Finally, note that you can read from two (or any number of) different
locations at the same time, even if any of them is embedded (directly
or indirectly) in any other of the locations you are currently reading
from, without any interference.

This is because the state information associated with each "C<read()>"
operation is stored along with the (given) location for which the
"C<read()>" method has been called, and NOT with the locations the
"C<read()>" visits during its recursive descent.

=item *

C<$item = E<lt>$locationE<gt>;>

Note that you can also use Perl's diamond operator syntax ("C<E<lt>E<gt>>")
in order to read data from the given location.

BEWARE that unlike reading from a file, reading from a location in this
manner will return the items that have been stored in the given location
in EXACTLY the same way as they have been written previously to that
location, i.e., the data is NOT read back line by line, with "C<\n>"
as the line separator, but item by item, whatever these items are!

(Note that you can also store binary data in locations, which will likewise
be read back in exactly the same way as it has been stored previously.)

=item *

C<@list = $location-E<gt>read();>

In "array" or "list" context, the method "C<read()>" returns the
rest of the contents of the given location, starting where the last
"C<read()>" left off, or from the beginning of the given location
if you never read from this particular location before or if you
called the method "C<reset()>" (see a little further below for
its description) for this location just before calling "C<read()>".

The method returns a single (possibly very long!) list containing
all the items of data the given location and all of its embedded
locations (if any) contain - in other words, the data contained
in all these nested locations is returned in a "flattened" way
(in "infix" order, for the mathematically inclined).

If any of the items in the list happens to have the value "C<undef>",
it is replaced by an empty string.

The method returns an empty list if the given location is empty
or if a previous "C<read()>" read past the end of the data in
the given location.

Remember to use "C<reset()>" whenever you want to be sure to read
the contents of the given location from the very beginning!

For an explanation of "scalar" versus "array" or "list" context,
see the section on "Context" in L<perldata(1)>.

=item *

C<@list = E<lt>$locationE<gt>;>

Note that you can also use Perl's diamond operator syntax ("C<E<lt>E<gt>>")
in order to read data from the given location.

BEWARE that unlike reading from a file, reading from a location in
this manner will return the list of items that have been stored in
the given location in EXACTLY the same way as they have been written
previously to that location, i.e., the data is NOT read back as a
list of lines, with "C<\n>" as the line separator, but as a list
of items, whatever these items are!

(Note that you can also store binary data in locations, which will
likewise be read back in exactly the same way as it has been stored
previously.)

=item *

C<$location-E<gt>reset();>

The method "C<reset()>" deletes the state information associated with
the given location which is used by the "C<read()>" method in order
to determine the next item of data to be returned.

After using "C<reset()>" on a given location, any subsequent "C<read()>" on
the same location will start reading at the beginning of that location.

This method has no other (side) effects whatsoever.

The method does nothing if there is no state information associated
with the given location, i.e., if the location has never been accessed
before using the "C<read()>" method or if "C<reset()>" has already been
called previously.

=item *

C<$location-E<gt>traverse(\&callback_function);>

The method "C<traverse()>" performs a recursive descent on the given
location just as the methods "C<read()>" and "C<dump()>" do internally,
but instead of immediately returning the items of data contained in the
location or printing them to a file, this method calls the callback
function you specify as a parameter once for each item stored in the
location.

Expect one parameter handed over to your callback function which
consists of the next item of data contained in the given location
(or the locations embedded therein).

Note that unlike the "C<read()>" method, items returned by this method
which happen to have the value "C<undef>" are NOT replaced by the empty
string, i.e., the parameter your callback function receives might be
undefined. You should therefore take appropriate measures in your
callback function to handle this special case.

Moreover, since callback functions can do a lot of unwanted things,
use this method with precaution!

Please refer to the "examples" section at the bottom of this document
for an example of how to use this method.

Using the method "C<traverse()>" is actually an alternate way of
reading back the contents of a given location (besides using the method
"C<read()>") completely in memory (i.e., without writing the contents of
the given location to a file and reading that file back in).

Note that the method "C<traverse()>" is completely independent from the
method "C<read()>" and from the state information associated with the
"C<read()>" method (the one which can be reset to point to the beginning
of the location using the method "C<reset()>").

This means that you can "C<traverse()>" and "C<read()>" (and "C<reset()>")
the same location at the same time without any interference.

=item *

C<$ok = $location-E<gt>dump();>

The method "C<dump()>" (without parameters) dumps the contents of the
given location to its associated default file (whose filename must have
been stored along with the given location previously using the method
"C<new()>" or "C<filename()>").

Note that a warning message will be printed (if the "C<-w>" switch is set)
if the location happens to lack a default filename and that the location
will simply not be dumped to a file in that case. Moreover, the method
returns "false" ("C<0>") to indicate the failure.

Should any other problem arise while attempting to dump the given location
(for instance an invalid filename or an error while trying to open or close
the specified file), a corresponding warning message will be printed to the
screen (provided that the "C<-w>" switch is set) and the method will also
return "false" ("C<0>").

The method returns "true" ("C<1>") if and only if the given location has
been successfully written to its respective file.

Note that a ">" is prepended to the default filename just before opening
the file if the default filename does not begin with ">", "|" or "+"
(leading white space is ignored).

This does NOT change the filename which is stored along with the given
location, however.

Finally, note that this method does not affect the contents of the
location being dumped.

If you want to delete the contents of the given location once they have
been dumped, call the method "C<delete()>" (explained further below)
thereafter.

If you want to dump and immediately afterwards destroy a location, you
don't need to call the method "C<dump()>" explicitly. It suffices to
store a filename along with the location in question using the method
"C<new()>" or "C<filename()>" and then to make sure that all references
to this location are destroyed (this happens for instance whenever the
last "my" variable containing a reference to the location in question
goes out of scope - provided there are no global variables containing
references to the location in question).

This will automatically cause the location to be dumped (by calling the
"C<dump()>" method internally) and then to be destroyed. (This feature
is called "auto-dump".)

Auto-dumping also occurs at shutdown time of your Perl script or program:
All locations that have a non-empty filename associated with them will
automatically be dumped (by calling the "C<dump()>" method internally)
before the global garbage collection (i.e., the destruction of all data
variables) takes place.

In order to prevent auto-dumping, just make sure that there is no filename
associated with the location in question at the time when its last reference
goes out of scope or at shutdown time.

You can ensure this by calling the "C<filename()>" method with an empty
string (C<"">) as argument.

=item *

C<$ok = $location-E<gt>dump($filename);>

The method "C<dump()>" (with a filename argument) in principle does exactly
the same as the variant without arguments described immediately above, except
that it temporarily overrides the default filename associated with the given
location and that it uses the given filename instead.

Note that the location's associated filename is just being temporarily
overridden, BUT NOT CHANGED.

I.e., if you call the method "C<dump()>" again later without a filename
argument, the filename stored along with the given location will be used,
and not the filename specified here.

Should any problem arise while attempting to dump the given location
(for instance if the given filename is invalid or empty or if Perl is
unable to open or close the specified file), a corresponding warning
message will be printed to the screen (provided that the "C<-w>" switch
is set) and the method returns "false" ("C<0>").

The method returns "true" ("C<1>") if and only if the given location
has been successfully written to the specified file.

(Note that if the given filename is empty or contains only white space,
the method does NOT fall back to the filename previously stored along
with the given location, because doing so could overwrite valuable data.)

Note also that a ">" is prepended to the given filename if it does not
begin with ">", "|" or "+" (leading white space is ignored).

Finally, note that this method does not affect the contents of the
location being dumped.

If you want to delete the given location once it has been dumped, you
need to call the method "C<delete()>" (explained below) explicitly.

=item *

C<$location-E<gt>delete();>

The method "C<delete()>" deletes the CONTENTS of the given location -
the location CONTINUES TO EXIST and REMAINS EMBEDDED where it was!

The associated filename stored along with the given location is also
NOT AFFECTED by this method.

BEWARE that any locations which were previously embedded in the given
location might go out of scope by invoking this method!

Note that in order to actually DESTROY a location altogether it suffices
to simply let the last reference to the location in question go out of
scope, or to set the variable containing the last reference to a new
value (e.g. C<$ref = 0;>).

=item *

C<$location-E<gt>tie('FILEHANDLE');>

=item *

C<$location-E<gt>tie(*FILEHANDLE);>

=item *

C<$location-E<gt>tie(\*FILEHANDLE);>

=item *

C<$location-E<gt>tie(*{FILEHANDLE});>

=item *

C<$location-E<gt>tie(\*{FILEHANDLE});>

Although locations behave like file handles themselves, i.e., even though
they allow you to use Perl's built-in operators "C<print>", "C<printf>"
and the diamond operator "C<E<lt>E<gt>>" in order to write data to and
read data from them, it is sometimes desirable to be able to redirect
the output which is sent to other file handles (such as STDOUT and
STDERR, for example) to some location instead (rather than the
screen, for instance).

It may also be useful to be able to read data from a location via some
other file handle (such as STDIN, for example, which allows you to
"remote-control" a program which reads commands from standard input
by redirecting STDIN and then spoon-feeding the program as desired).

(Note that on the Windows NT/95 platform, tying is probably the only
way of redirecting output sent to STDERR, since the command shell
won't allow you to do so!)

The method "C<tie()>" (be careful not to confuse the METHOD "C<tie()>" and
the Perl built-in OPERATOR "C<tie>"!) provides an easy way for doing this.

Simply invoke the method "C<tie()>" for the location which should be
"tied" to a file handle, and provide either the name, a typeglob or a
typeglob reference of the file handle in question as the (only)
parameter to this method.

After that, printing data to this file handle will actually send this
data to its associated ("tied") location, and reading from this file
handle will actually read the data from the tied location instead.

Note that you don't need to explicitly "C<open()>" or "C<close()>" such
a tied file handle in order to be able to access its associated location
(regardless wether you want to read from or write to the location or both),
even if this file handle has never been explicitly (or implicitly) opened
(or even used) before.

The physical file or terminal the tied file handle may have been
connected to previously is simply put on hold, i.e., it is NOT written
to or read from anymore, until you "C<untie>" the connection between
the file handle and the location (see further below for more details
about "C<untie>").

Note also that if you do not "C<untie>" the file handle before your program
ends, Perl will try to close it for you, which under Perl 5.005 will lead
to a warning message (provided that the "C<-w>" switch is set) saying that
the attempted "C<close()>" operation was ignored. This is because under Perl
5.005, a "C<close()>" on a tied file handle is forwarded to the associated
(i.e., tied) object instead.

Under Perl 5.004, the behaviour of "C<close()>" is different: When used on
a location it is simply ignored (without any warning message), and a close
on a tied file handle will close the underlying file or pipe (if there is
one).

Finally, note that you don't need to qualify the built-in file handles
STDIN, STDOUT and STDERR, which are enforced by Perl to be in package
"main", and file handles belonging to your own package, but that it
causes no harm if you do (provided that you supply the correct
package name).

The only file handles you need to qualify are custom file handles belonging
to packages other than the one in which the method "C<tie()>" is called.

Some examples:

          $location->tie('STDOUT');
          $location->tie('MYFILE');
          $location->tie('My::Class::FILE');
          $location->tie(*STDERR);
          $location->tie(\*main::TEMP);

Please also refer to the example given at the bottom of this document
for more details about tying file handles to locations (especially
for STDERR).

See L<perlfunc(1)> and L<perltie(1)> for more details about "tying"
in general.

=item *

C<$location-E<gt>tie($filehandle);>

Note that you can also tie file handles to locations which have been created
by using the standard Perl modules "C<FileHandle>" and "C<IO::File>":

              use FileHandle;
              $fh = FileHandle->new();
              $location->tie($fh);

              use IO::File;
              $fh = IO::File->new();
              $location->tie($fh);

=item *

C<tie(*FILEHANDLE, "Data::Locations", $location);>

=item *

C<tie(*{$filehandle}, "Data::Locations", $location);>

Finally, note that you are not forced to use the METHOD "C<tie()>", and
that you can of course also use the OPERATOR "C<tie>" directly, as shown
in the two examples above.

=item *

C<$location = tied *FILEHANDLE;>

=item *

C<$location = tied *{$filehandle};>

The Perl operator "C<tied>" can be used to get back a reference to the
object the given file handle is "tied" to.

This can be used to invoke methods for this object, as follows:

          (tied   *FILEHANDLE)->method();
          (tied *{$filehandle})->method();

Note that "C<tied *{$location}>" is identical with "C<$location>" itself.

See L<perlfunc(1)> and L<perltie(1)> for more details.

=item *

C<untie *FILEHANDLE;>

=item *

C<untie *{$filehandle};>

The Perl operator "C<untie>" is used to "cut" the magic connection
between a file handle and its associated object.

Note that a warning message such as

  untie attempted while 1 inner references still exist

will be issued (provided the "C<-w>" switch is set) whenever you try
to "C<untie>" a file handle from a location.

To get rid of this warning message, use the following approach:

  {
      local($^W) = 0;     ##  Temporarily disable the "-w" switch
      untie *FILEHANDLE;
  }

(Note the surrounding braces which limit the effect of disabling the
"C<-w>" switch.)

See L<perlfunc(1)> and L<perltie(1)> for more details.

=item *

C<$filehandle = select();>

=item *

C<select($location);>

=item *

C<$oldfilehandle = select($newlocation);>

Remember that you can define the default output file handle using Perl's
built-in function "C<select()>".

"C<print>" and "C<printf>" statements without explicit file handle (note
that "C<println>" ALWAYS needs an explicit location where to send its
output to!) always send their output to the currently selected default
file handle (which is usually "STDOUT").

"C<select()>" always returns the current default file handle and allows
you to define a new default file handle at the same time.

By selecting a location as the default file handle, all subsequent "C<print>"
and "C<printf>" statements (without explicit file handle) will send their
output to that location:

  select($location);
  print "Hello, World!\n";  ##  prints to "$location"

See the section on "C<select()>" in L<perlfunc(1)> for more details.

=back

=head1 EXAMPLE #1

  #!/sw/bin/perl -w

  use Data::Locations;

  use strict;
  no strict "vars";

  $head = Data::Locations->new();  ##  E.g. for interface definitions
  $body = Data::Locations->new();  ##  E.g. for implementation

  $head->filename("example.h");
  $body->filename("example.c");

  $common = $head->new();    ##  Embed a new location in "$head"
  $body->print($common);     ##  Embed this same location in "$body"

  ##  Create some more locations...

  $copyright = Data::Locations->new();
  $includes  = Data::Locations->new();
  $prototype = Data::Locations->new();

  ##  ...and embed them in location "$common":

  $common->print($copyright,$includes,$prototype);

  ##  Note that the above is just to show you an alternate
  ##  (but less efficient) way! Normally you would use:
  ##
  ##      $copyright = $common->new();
  ##      $includes  = $common->new();
  ##      $prototype = $common->new();

  $head->println(";");  ##  The final ";" after a function prototype
  $body->println();     ##  Just a newline after a function header

  $body->println("{");
  $body->println('    printf("Hello, world!\n");');
  $body->println("}");

  $includes->print("#include <");
  $library = $includes->new();     ##  Nesting even deeper still...
  $includes->println(">");

  $prototype->print("void hello(void)");

  $copyright->println("/*");
  $copyright->println("    Copyright (c) 1997 - 2009 by Steffen Beyer.");
  $copyright->println("    All rights reserved.");
  $copyright->println("*/");

  $library->print("stdio.h");

  $copyright->filename("default.txt");

  $copyright->dump(">-");

  print "default filename = '", $copyright->filename(), "'\n";

  $copyright->filename("");

  __END__

When executed, this example will print

  /*
      Copyright (c) 1997 - 2009 by Steffen Beyer.
      All rights reserved.
  */
  default filename = 'default.txt'

to the screen and create the following two files:

  ::::::::::::::
  example.c
  ::::::::::::::
  /*
      Copyright (c) 1997 - 2009 by Steffen Beyer.
      All rights reserved.
  */
  #include <stdio.h>
  void hello(void)
  {
      printf("Hello, world!\n");
  }

  ::::::::::::::
  example.h
  ::::::::::::::
  /*
      Copyright (c) 1997 - 2009 by Steffen Beyer.
      All rights reserved.
  */
  #include <stdio.h>
  void hello(void);

=head1 EXAMPLE #2

  #!/sw/bin/perl -w

  use Data::Locations;

  use strict;
  no strict "vars";

  $html = Data::Locations->new("example.html");

  $html->println("<HTML>");
  $head = $html->new();
  $body = $html->new();
  $html->println("</HTML>");

  $head->println("<HEAD>");
  $tohead = $head->new();
  $head->println("</HEAD>");

  $body->println("<BODY>");
  $tobody = $body->new();
  $body->println("</BODY>");

  $tohead->print("<TITLE>");
  $title = $tohead->new();
  $tohead->println("</TITLE>");

  $tohead->print('<META NAME="description" CONTENT="');
  $description = $tohead->new();
  $tohead->println('">');

  $tohead->print('<META NAME="keywords" CONTENT="');
  $keywords = $tohead->new();
  $tohead->println('">');

  $tobody->println("<CENTER>");

  $tobody->print("<H1>");
  $tobody->print($title);      ##  Re-using this location!!
  $tobody->println("</H1>");

  $contents = $tobody->new();

  $tobody->println("</CENTER>");

  $title->print("'Data::Locations' Example HTML-Page");

  $description->println("Example for generating HTML pages");
  $description->print("using 'Data::Locations'");

  $keywords->print("locations, magic, insertion points,\n");
  $keywords->print("nested, recursive");

  $contents->println("This page was generated using the");
  $contents->println("<P>");
  $contents->println("&quot;<B>Data::Locations</B>&quot;");
  $contents->println("<P>");
  $contents->println("module for Perl.");

  __END__

When executed, this example will produce
the following file ("example.html"):

  <HTML>
  <HEAD>
  <TITLE>'Data::Locations' Example HTML-Page</TITLE>
  <META NAME="description" CONTENT="Example for generating HTML pages
  using 'Data::Locations'">
  <META NAME="keywords" CONTENT="locations, magic, insertion points,
  nested, recursive">
  </HEAD>
  <BODY>
  <CENTER>
  <H1>'Data::Locations' Example HTML-Page</H1>
  This page was generated using the
  <P>
  &quot;<B>Data::Locations</B>&quot;
  <P>
  module for Perl.
  </CENTER>
  </BODY>
  </HTML>

=head1 EXAMPLE #3

  #!/sw/bin/perl -w

  ##  Note that this example only works as described if the "-w" switch
  ##  is set!

  package Non::Sense;

  ##  (This is to demonstrate that this example works with ANY package)

  use Data::Locations;
  use FileHandle;

  use strict;
  use vars qw($level0 $level1 $level2 $level3 $fh $fake);

  ##  Create the topmost location:

  $level0 = Data::Locations->new("level0.txt");

  print $level0 <<'VERBATIM';
  Printing first line to location 'level0' via OPERATOR 'print'.
  VERBATIM

  ##  Create an embedded location (nested 1 level deep):

  $level1 = $level0->new();

  $level0->print(<<'VERBATIM');
  Printing last line to location 'level0' via METHOD 'print'.
  VERBATIM

  ##  Now "tie" the embedded location to file handle STDOUT:

  $level1->tie('STDOUT');

  print "Printing to location 'level1' via STDOUT.\n";

  ##  Create another location (which will be embedded later):

  $level2 = Data::Locations->new();

  ##  Create a file handle ("IO::Handle" works equally well):

  $fh = FileHandle->new();

  ##  Now "tie" the location "$level2" to this file handle "$fh":

  $level2->tie($fh);

  ##  And select "$fh" as the default output file handle:

  select($fh);

  print "Printing to location 'level2' via default file handle '\$fh'.\n";

  ##  Embed location "$level2" in location "$level1":

  print $level1 $level2;

  ##  (Automatically removes "toplevel" status from location "$level2")

  print STDOUT "Printing to location 'level1' explicitly via STDOUT.\n";

  ##  Create a third embedded location (nested 3 levels deep):

  $level3 = $level2->new();

  ##  Restore STDOUT as the default output file handle:

  select(STDOUT);

  print $fh "Printing to location 'level2' via file handle '\$fh'.\n";

  ##  Trap all warnings:

  $SIG{__WARN__} = sub
  {
      print STDERR "WARNING intercepted:\n", @_, "End Of Warning.\n";
  };

  ##  Note that WITHOUT this trap, warnings would go to the system
  ##  standard error device DIRECTLY, WITHOUT passing through the
  ##  file handle STDERR!

  ##  Now "tie" location "$level3" to file handle STDERR:

  $level3->tie(*STDERR);

  ##  Provoke a warning message (don't forget the "-w" switch!):

  $fake = \$fh;
  $level3->print($fake);

  ##  Provoke another warning message (don't forget the "-w" switch!):

  $level3->dump();

  {
      ##  Silence warning that reference count of location is still > 0:

      local($^W) = 0;

      ##  And untie file handle STDOUT from location "$level1":

      untie *STDOUT;
  }

  print "Now STDOUT goes to the screen again.\n";

  ##  Read from location "$level3":

  while (<STDERR>)  ##  Copy warning messages to the screen:
  {
      if (/^.*?\bData::Locations::[a-z]+\(\):\s+(.+?)(?=\s+at\s|\n)/)
      {
          print "Warning: $1\n";
      }
  }

  while (<STDERR>) { print; }

  ##  (Prints nothing because location was already read past its end)

  ##  Reset the internal reading mark:

  (tied *{STDERR})->reset();

  ##  (You should usually use "$level3->reset();", though!)

  while (<STDERR>) { print; }

  ##  (Copies the contents of location "$level3" to the screen)

  ##  Write output file "level0.txt":

  __END__

When running this example, the following text will be printed to the screen
(provided that you did use the "C<-w>" switch):

  Now STDOUT goes to the screen again.
  Warning: REF reference ignored
  Warning: filename missing or empty
  WARNING intercepted:
  Data::Locations::print(): REF reference ignored at test.pl line 92
  End Of Warning.
  WARNING intercepted:
  Data::Locations::dump(): filename missing or empty at test.pl line 96
  End Of Warning.

The example also produces an output file named "level0.txt" with the
following contents:

  Printing first line to location 'level0' via OPERATOR 'print'.
  Printing to location 'level1' via STDOUT.
  Printing to location 'level2' via default file handle '$fh'.
  WARNING intercepted:
  Data::Locations::print(): REF reference ignored at test.pl line 92
  End Of Warning.
  WARNING intercepted:
  Data::Locations::dump(): filename missing or empty at test.pl line 96
  End Of Warning.
  Printing to location 'level2' via file handle '$fh'.
  Printing to location 'level1' explicitly via STDOUT.
  Printing last line to location 'level0' via METHOD 'print'.

=head1 EXAMPLE #4

  #!/sw/bin/perl -w

  use Data::Locations;

  use strict;
  no strict "vars";

  $loc = Data::Locations->new();

  print $loc "Thi";
  print $loc "s is an ex";
  print $loc "treme";
  print $loc "ly long and ted";
  print $loc "ious line o";
  print $loc "f text con";
  print $loc "taining on";
  print $loc "ly meaning";
  print $loc "less gibberish.";

  $string = '';

  $loc->traverse( sub { $string .= $_[0]; } );

  print "'$string'\n";

  __END__

This example will print:

'This is an extremely long and tedious line of text containing only meaningless gibberish.'

=head1 SEE ALSO

perl(1), perldata(1), perlfunc(1), perlsub(1),
perlmod(1), perlref(1), perlobj(1), perlbot(1),
perltoot(1), perltie(1), printf(3), sprintf(3).

=head1 VERSION

This man page documents "Data::Locations" version 5.5.

=head1 AUTHOR

 Steffen Beyer
 mailto:STBEY@cpan.org
 http://www.engelschall.com/u/sb/download/

=head1 COPYRIGHT

Copyright (c) 1997 - 2009 by Steffen Beyer.
All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

