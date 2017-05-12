# --8<--8<--8<--8<--
#
# Copyright (C) 2006 Smithsonian Astrophysical Observatory
#
# This file is part of CIAO-Lib-Param
#
# CIAO-Lib-Param is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# CIAO-Lib-Param is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the 
#       Free Software Foundation, Inc. 
#       51 Franklin Street, Fifth Floor
#       Boston, MA  02110-1301, USA
#
# -->8-->8-->8-->8--

package CIAO::Lib::Param;


use 5.008002;
use Carp;

use strict;
use warnings;

require Exporter;

our @ISA = qw/Exporter/;
our @CARP_NOT = qw/ CIAO::Lib::Param::Croak /;

our %EXPORT_TAGS = ( 'all' => [ qw(
        pget
	pquery
	pset
	pfind
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('CIAO::Lib::Param', $VERSION);

# very simple exception class.  don't use Exception::Class to avoid
# too many dependencies for users.
{
  package CIAO::Lib::Param::Error;

  use overload '""' => \&error;

  sub new { my $class = shift; bless { @_ }, $class; }

  sub error   { $_[0]->{error} }
  sub errno   { $_[0]->{errno} }
  sub errstr  { $_[0]->{errstr} }
  sub errmsg  { $_[0]->{errmsg} }
}



# simple wrapper around open to get croakability. note
# that the object is blessed into CIAO::Lib::ParamPtr
# by open.
sub new
{
  my $class = shift;

  my $self;
  my $file = shift;
  my $mode  = shift || "r";

  my @arglist = @_;

  my $filename;

  if ( 'ARRAY' eq ref $file )
  {
    $filename = $file->[0];
    unshift @arglist, $file->[1];
  }

  else
  {
    unshift @arglist, $file;
    $filename = undef;
  }

  $self = CIAO::Lib::Param::open( $filename, $mode, @arglist );


  $self;
}

sub _pread
{
  my $pfile = shift;
  my $mode  = shift;


  my $argv = 'ARRAY' eq ref $_[0] ? shift : undef;
  my $wantarray = wantarray();

  my $pf = CIAO::Lib::Param->new( $pfile, $mode, defined $argv ? @$argv : () );

  if ( @_ )
  {
    my @bogus = grep { ! $pf->access( $_ ) } @_;
    croak( "unknown parameters: ", join( ', ', @bogus ), "\n") 
      if @bogus;
    return $wantarray ? map { $pf->get( $_ ) } @_ : $pf->get($_[0]);
  }

  else
  {
    my $pm = $pf->match( '*' );

    my @params;
    push @params, $_ while $_ = $pm->next;

    return map { ( $_ => $pf->get( $_ ) ) } @params;
  }

  die( "impossible!\n" );
}

# class get method to perform a one shot read of parameters
# never query
sub pget
{
  my $pfile = shift;

  unshift @_, $pfile, "rH";
  # act like we were never here
  goto &_pread;
}

# class get method to perform a one shot read of parameters
sub pquery
{
  my $pfile = shift;

  unshift @_, $pfile, "r";
  # act like we were never here
  goto &_pread;
}

sub pset
{
  my ( $pfile, %params ) = @_;

  return unless keys %params;

  my $pf = CIAO::Lib::Param->new( $pfile, "w" );

  while( my ( $param, $value ) = each %params )
  {
    $pf->set( $param, $value );
  }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CIAO::Lib::Param - an interface to the CIAO parameter library.

=head1 SYNOPSIS

  use CIAO::Lib::Param;

  my $pf = CIAO::Lib::Param->new( $filename, $mode );

  my $value = $pf->get( 'var1' );
  $pf->set( 'var1', $newvalue);


=head1 DESCRIPTION

CIAO::Lib::Param is a Perl interface to the parameter library
(cxcparam) shipped with the Chandra Interactive Analysis of
Observations (CIAO) software package.  It implements an interace to
IRAF (Image Reduction and Analysis Facility) style parameter files.

This document does not fully discuss the format and usage of parameter
files; see L<http://asc.harvard.edu/ciao/ahelp/parameter.html> for
more information.

CIAO::Lib::Param provides both object oriented and quick and dirty
procedural interfaces.  See the L</OBJECT INTERFACE> and L</PROCEDURAL
INTERFACE> sections for the two interfaces.

The Perl interface presents unified error reports from the underlying
cxcparam library.  If an error is encountered, the module will throw
an exception via B<croak()>.  For simple applications, simply not
catching the exception with C<eval{}> will cause the application to
terminate.

For more complicated handling, one can use the exception (which is a
CIAO::Lib::Param::Error object) to determine more information about
what happenend.

=over

=back



=head1 PROCEDURAL INTERFACE

This interface is for quick and dirty parameter retrieval.  The
parameter file is opened for each call, so these should not be used
for repeated access to parameters.

=over

=item pget

  use CIAO::Lib::Param qw/ pget /;

  $pvalue  = pget( $filename, $pname );
  @pvalues = pget( $filename, @pnames );
  %params  = pget( $filename );

  $pvalue  = pget( $filename, $argv, $pname );
  @pvalues = pget( $filename, $argv, @pnames );
  %params  = pget( $filename, $argv );

Read one or more parameter values.  The user is never queried for a
parameter value.  Illegal values result in an exception being thrown.

In the first form (called in scalar context), retrieve the value of a
single parameter.

In the second form (list context, parameter names), the values for the
specified parameters are returned as a list.

In the third form, retrieve all of the parameters from the file as a
hash, keyed off of the parameter name.

The C<$filename> argument may optionally be followed by an arrayref, which
should contain elements of the form C<param=value>.  Typically this is
used to allow command line argument assignment:

  %params = pget( $0, \@ARGV );

=item pquery

  use CIAO::Lib::Param qw/ pquery /;

  [...]

This is identical to =pget= except that the user is queried when
necessary.

=item pset

  use CIAO::Lib::Param qw/ pset /;

  pset( $filename, $pname1 => $pvalue1, $pname2 => $pvalue2, ... );

Set the named parameters to the given values.

=item pfind

   use CIAO::Lib::Param qw/ pfind /;
   $pfile = pfind( $name, $mode, $extn, $path )


Find a parameter file. The C<extn> and C<path> arguments are lists of
allowable extension and directories to attempt to search for parameter
files.  For example, the default search used in the class constructor
is

        extn = ".par .rdb $PFEXTN"
        path = "$PDIRS $PFILES $UPARM"

Identifiers prefixed with C<$> are recursivly expanded in the run time
environment.  For comaptiblity with IRAF $UPARM should be set to a
single directory name with a trailing C</>.  C<$PFILES> may be set to
a space or C<,> separated list of directories.


=back

=head1 OBJECT INTERFACE

=head2 Constructor

=over

=item new

   $pf = CIAO::Lib::Param->new( $filename );
   $pf = CIAO::Lib::Param->new( $filename, $mode );
   $pf = CIAO::Lib::Param->new( $filename, $mode, @arglist );
   $pf = CIAO::Lib::Param->new( [ $filename, $argv0], $mode, @arglist );

Create a new object and associate it with the specified parameter
file.  See L<Finding Parameter Files> for more information on how the
path to the file is determined.

B<$mode> indicates the IRAF mode with which the file should be opened
(it defaults to C<rw> if not specified).  It should be one of the
"IRAF-compatible" paramater-interface access modes (eg C<r>, C<rw>,
C<rH>, etc).  C<@arglist> is a list of parameter settings that will
override those given in the parameter file.  They are strings of the
form of C<par=value>.

C<$filename> is typically C<$0>.  However, the underlying library uses
I<two> arguments to determine the name of the parameter file.  In the
(extremely) rare situation where you wish to use that functionality,
pass the two names as elements of an anonymous array.  The underlying
call has the following definition:

  paramopen( filename, argv, argc, filemode )

The C<$filename> parameter will be passed as C<filename>.  The
C<$argv0> parameter, which is typically just C<$0>, will be inserted
into the C<argv> array as the first element.

B<new> throws an exception via B<croak> if there is an error.

The parameter file is closed (and optionally updated) upon object
destruction.



=back

=head2 Miscellaneous Parameter methods

=over

=item access

  $pf->access( $pname );

This returns true if the named parameter exists.

=item info

   ( $mode, $type, $value, $min, $max, $prompt ) =
 			$pf->info( $pname );

Return various bits of information about the named parameter.  It
throws an exception via B<die> if the parameter is not found.

=back


=head2 Retrieving Parameter Values

The parameter library supports a large variety of data types.  Perl
really only has two: strings and double precision floating point
values, and it automatically converts between the two as needed.

To retrieve a parameter value, in most cases one simply calls B<get>.

To ease recoding older code into Perl, the other type specific
routines (C<getX>) have been incorporated into the Perl interface,
even though they should rarely be used.  One effect of these routines is
that the value is first converted into the specified type (e.g. short)
before being passed to Perl.  This may be of some benefit in some
instances.

=over

=item get

  $pf->get( $pname );

Retrieve the value of the named parameter.  In all cases but Boolean
parameters this performs no conversion, returning the value as a
string (remember that Perl will automatically convert this to a number
as required).

In the case of Boolean parameters (which are stored in the parameter
file as the strings C<yes> and C<no>), they are converted to Perl's true
and false values.

=item getb

  $pf->getb( $pname );

Retrieve the named parameter's value as a Boolean value.

=item gets

  $pf->gets( $pname );

Retrieve the named parameter's value as a short.

=item geti

  $pf->geti( $pname );

Retrieve the named parameter's value as an integer.

=item getf

  $pf->getf( $pname );

Retrieve the named parameter's value as a float.

=item getd

  $pf->getd( $pname );

Retrieve the named parameter's value as a double.

=item getstr

  $pf->getstr( $pname );

Retrieve the named parameter's value as a string.  This is identical
to B<get> except for the case of Boolean parameters.

=back

=head2 Setting Parameter Values

These routines update the parameter values in the B<Param> object. The
parameter file is updated when the Param object is destroyed (if the
file was opened with the correct mode to permit writing).

In keeping with standard naming schemes for accessors, the function
prefixes have been renamed from C<putX> to C<setX>, although the others
are still available to ease porting code.

In general one should use B<set>, which uses Perl's intrinsic
stringification mechanisms to convert the Perl value to a string which
is passed on to the parameter interface routines.  In all but the most
esoteric cases this should suffice.

=over

=item set [put]

  $pf->set( $pname, $value );

Set the named parameter to the given value.  In the case that the
parameter is boolean, and the value is not a string, it will
automatically convert Perl booleans to those required by B<cxcparam>.

=item setb [putb]

  $pf->setb( $pname, $value );

Set the named parameter to the given value.
Convert the value to a Boolean.

=item setd [putd]

  $pf->setd( $pname, $value );

Set the named parameter to the given value.
Convert the value to a double.

=item seti [puti]

  $pf->seti( $pname, $value );

Set the named parameter to the given value.
Convert the value to an integer.

=item sets [puts]

  $pf->sets( $pname, $value );

Set the named parameter to the given value.
Convert the value to a short.

=item setstr [putstr]

  $pf->setd( $pname, $value );

Set the named parameter to the given value.  Convert the value to a
string.

=back

=head2 Miscellaneous methods

=over

=item getpath

   $path = $pf->getpath;

This returns the path to the parameter file associated with the
object.

=item match

  $pmatch = $pf->match( $template );

Return a list of the parameters which match the given template.  The
list is returned as a CIAO::Lib::Param::Match object.  The template
may be either the single character C<*>, which returns all parameters,
or a string where the following characters have special meanings:

=over

=item  ?

match any one character

=item  *

match anything, or nothing

=item [<c>...]

match an inclusive set


=back

=back


=head1 SEE ALSO

CIAO::Lib::Param::Match, CIAO::Lib::Param::Error.

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpanE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by the Smithsonian Astrophysical Observatory

This code is released under the GNU General Public License.  You may
find a copy at <http://www.fsf.org/copyleft/gpl.html>.

=cut
