#=============================== Version.pm ==================================
# Filename:             Version.pm
# Description:          Version number handling class.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:14:03 $ 
# Version:              $Revision: 1.8 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;

package DMA::Version;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#			Class Methods
#=============================================================================

sub new {
  my ($class,$format,$gre,$numfields,@rest) = @_;
  my $self = bless {}, $class;

  $format    || (return undef);
  $gre       || (return undef);
  $numfields || (return undef);

  @$self{'format','gre','numfields'} = ($format,$gre,$numfields);

  # If we have more args, assume we're to immediately init the version string
  ($#rest lt 0) || (return ($self->setlist (@rest)));
  return $self;
}

#------------------------------------------------------------------------------

sub parse {
  my ($class,$lexeme, $gre) = @_;
  my $version;
  $lexeme || return ("","");
  $gre    || ($gre = '\d*\.\d\d');

  ($version,$lexeme) = ($lexeme =~ /(^$gre)?(.*)/);
  return ($version,$lexeme);
}

#=============================================================================
#				Object Methods
#=============================================================================

sub setVersion {
  my ($self,$string) = @_;

  my @list = ($string =~ $self->{'gre'});
  ($#list+1 eq $self->{'numfields'}) || (return undef);

  @$self{'list','version'} = ([@list], $string);
  return $self;
}

#------------------------------------------------------------------------------

sub setlist {
  my ($self,@args) = @_;
  ($#args+1 eq $self->{'numfields'}) || (return undef);

  @$self{'list','version'} = ([@args], sprintf $self->{'format'}, @args);
  return $self;
}

#------------------------------------------------------------------------------

sub version   {return shift->{'version'};}
sub format    {return shift->{'format'};}
sub gre       {return shift->{'gre'};}
sub numfields {return shift->{'numfields'};}
sub list      {return shift->{'list'};}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 DMA::Version.pm - Version number handling class.

=head1 SYNOPSIS

 use DMA::Version;

 $obj             = DMA::Version->new ($format, $gre, $numfields, @list);
 ($version,$rest) = DMA::Version->parse ($lexeme,$gre);

 $obj             = $obj->setVersion ($string);
 $obj             = $obj->setlist(@list);
 $string          = $obj->version;
 @list            = $obj->list;
 $format          = $obj->format;
 $gre             = $obj->gre;
 $n               = $obj->numfields;

=head1 Inheritance

 UNIVERSAL

=head1 Description

This Class handles parsing, storage  and creation of version strings in any 
format you choose. To handle your desired layout of fields, you must create 
an DMA::Version object with a printf style format code to build one; a 
regular expression to break one into a number of fields; and the number of 
fields the GRE  is expected to create.

At some point we will want more direct use of Linux kernel version 
nomenclature: Version.Patchlevel.Sublevel-Extraversion. Perl and other 
applications also use variants of this. We should subclass to get special 
handling, such as  methods and ivars matching the field nomenclature.

A subclass addition might be methods to increment version elements.

It would really be nice if we could generate a gre and numfields from a 
format string. Probably doable but probably more than an evenings work.

Also would be nice to have some algorithm for comparing version numbers in 
various ways, to be able to pose questions like, Are the Major numbers 
equal? Is the minor number of one gt, eq, lt than another?

=head1 Examples

 use DMA::Version;

 my $foo  = DMA::Version->new ("%d.%02d",'(\d*).(\d\d)',2,2,4);
 my $flg1 = $foo->parse ("3.01");
 my $flg2 = $foo->setlist (2, 3);

 my $ver  = $foo->version;
 my $fmt  = $foo->format;
 my $gre  = $foo->gre;
 my $nf   = $foo->numfields;
 my @ver  = $foo->list;

 my $foo2 = DMA::Version->new ("%d.%02d.%02d",'(\d+).(\d+).(\d+)',3,2,4,20);
 my @ver2 = foo2->list;

=head1 Class Variables

 None.

=head1 Instance Variables

 version          Version string
 list             List of version all components.
 format           Format to build a version string, eg"%d.%02d" 
                  for versions like "2.04".
 gre              General regular expression to break up a string, eg 
                  "(\d+).(\d\d)" for "2.04"
 numfields        Number of fields in the format and gre.

=head1 Class Methods

=over 4

=item B<$obj = DMA::Version-E<gt>new ($format, $gre, $numfields, @list)>

Build a version number object based on $format, $gre and $numfields. If there
are no other arguments, succeed with other ivars undef.

The format is used when generating an output version string from it's parts;
the gre string and numfields are used when breaking down an input string into
a list of items. Note that ' ' delimiters should be used on gre's so that 
backslashes do not get removed during arg passing. In short:

    $format    printf style format string eg, "%d.%02d"
    $gre       gre to split strings into fields (should be single quoted to
               prevent \d's from becoming just d's: '(\d*).(\d\d)'
    $numfields number of fields produced by gre, eg:  2

If @list args are supplied, use the supplied format to build a version string
from them. If successful, return the object. Otherwise return undef to 
indicate failure. 
  
It may be of value to have a wide range of standard version strings for the 
default version parse. It also may be of value for new to handle either a list
of version elements as above, or a single string which is passed to setVersion
as an alternative initializer.

It would be nice to have a way to confirm the gre arg, if present, really is a
valid GRE.

This is the base initializer and should be overridden and chained to by 
subclasses.

=item <($version,$rest) = DMA::Version-E<gt>parse ($lexeme,$gre)>

Parse $lexeme according to the optional version format described by gre. The 
default GRE, if none is specified, is '\d*.\d\d'. Note that the handling of 
the split into match and reset is handled internally so the gre argument need 
only deal with the definition of what is a version number string. Note 
that ' ' delimiters should be used on GRE's so that backslashes do not get
removed during argument passing.

If $lexeme contains a right justified version string, that is returned as 
$version and any remaining chars are placed in $rest. If no version is found,
$version is  and all of $lexeme is return in $rest; if $lexeme is empty or 
undef to start with, both values are .
  
It may be of value to have a wide range of standard version strings for the 
default version parse.

=back 4

=head1 Instance Methods

=over 4

=item B<$format = $obj-E<gt>format>

Return the version format string.

=item B<$gre = $obj-E<gt>gre>

Return the version general regular expression  string.

=item B<@list = $obj-E<gt>list>

Return the list of version elements.

=item B<$n = $obj-E<gt>numfields>

Return the number of fields in the format and gre.

=item B<$obj = $obj-E<gt>setlist(@list)>

Generate the version string from @list according to our format string. Fail 
if the number of elements does not match the number of fields we require.

This is a general class and has no way to check the types of the args
against the format string requirements. So subclass it if that isn't good 
enough for you.

Return self on success,  undef otherwise.

=item B<$obj = $obj-E<gt>setVersion ($string)>

Break up the string into an ordered set of elements as defined by the objects
format string. It will parse $string according to the gre and if successful, 
set the version and list parseable and return self. Return undef if $string 
is not parseable. 

A parse is deemed successful if it the gre places numfields items into list.

=item B<$string = $obj-E<gt>version>

Return the version string.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#============================================================================
#                                CVS HISTORY
#============================================================================
# $Log: Version.pm,v $
# Revision 1.8  2008-08-28 23:14:03  amon
# perldoc section regularization.
#
# Revision 1.7  2008-08-15 21:47:52  amon
# Misc documentation and format changes.
#
# Revision 1.6  2008-04-18 14:07:54  amon
# Minor documentation format changes
#
# Revision 1.5  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.4  2008-04-11 18:56:35  amon
# Fixed quoting problem with formfeeds.
#
# Revision 1.3  2008-04-11 18:39:15  amon
# Implimented new standard for headers and trailers.
#
# Revision 1.2  2008-04-10 15:01:08  amon
# Added license to headers, removed claim that the documentation section still
# relates to the old doc file.
#
# Revision 1.1.1.1  2004-08-31 00:16:50  amon
# Dale's library of primitives in Perl
#
# 20040828	Dale Amon <amon@vnl.com>
#		Changed parse object method to setVersion;
#		created a new parse Class method structured
#		like that in PageId.
#
# 20040813	Dale Amon <amon@vnl.com>
#		Moved to DMA:: from Archivist::
#		to make it easier to enforce layers.
#
# 20021217	Dale Amon <amon@vnl.com>
#		Created.
1;
