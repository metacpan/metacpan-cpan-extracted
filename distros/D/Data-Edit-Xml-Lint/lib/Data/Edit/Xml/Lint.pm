#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Lint an xml file using xmllint
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml::Lint;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
our $VERSION = 2017.714;

#1 Methods                                                                      # Methods in this package
sub new                                                                         # Create a new xml linter - call this method statically as in Data::Edit::Xml::Lint::new()

 {bless {}                                                                      # Create xml linter
 }

genLValueScalarMethods(qw(file));                                               # File that the xml will be written to and read from
genLValueScalarMethods(qw(catalog));                                            # Optional catalog file containing the locations of the DTDs used to validate the xml
genLValueScalarMethods(qw(dtds));                                               # Optional directory containing the DTDs used to validate the xml
genLValueScalarMethods(qw(errors));                                             # Number of lint errors detected by xmllint
genLValueScalarMethods(qw(linted));                                             # Date the lint was performed
genLValueScalarMethods(qw(source));                                             # String containing the xml to be written or the xml read

sub lint($@)                                                                    # Store some xml in a file and apply xmllint
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments
  my $x = $lint->source;                                                        # Xml text
  $x or confess "Use the ->source method to provide the source xml";            # Check that we have some source
  $lint->source = $x =~ s/\s+\Z//gsr;                                           # Xml text to be written minus trailing blanks

  my $f = $lint->file;                                                          # File to be written to
  $f or confess "Use the ->file method to provide the target file";             # Check that we have an output file

  my $C = $lint->catalog;                                                       # Catalog to be used to validate xml
  my $d = $lint->dtds;                                                          # Folder containing dtds used to validate xml

  $attributes{file}    = $f;                                                    # Record attributes
  $attributes{catalog} = $C if $C;
  $attributes{dtds}    = $d if $d;

  my $a = sub                                                                   # Attributes to be recorded with the xml
   {my @s;
    for(sort keys %attributes)
     {push @s, "<!--${_}: ".$attributes{$_}." -->";                             # Place attribute inside a comment
     }
    join "\n", @s
   }->();

  my $T = "<!--linted: ".dateStamp." -->\n";                                    # Time stamp marks the start of the added comments

  writeFile($f, my $source = "$x\n$T\n$a");                                     # Write xml to file

  if (my $v = qx(xmllint --version 2>&1))                                       # Check xmllint is present
   {unless ($v =~ m(\Axmllint)is)
     {confess "xmllint missing, install with:\nsudo apt-get xmllint";
     }
   }

  my $c = sub                                                                   # Lint command
   {return "xmllint --path \"$d\" --noout --valid \"$f\" 2>&1" if $d;           # Lint against DTDs
    return qq(xmllint --noout - < '$f' 2>&1) unless $C;                         # Normal lint
    qq(export XML_CATALOG_FILES='$C' && xmllint --noout --valid - < '$f' 2>&1)  # Catalog lint
   }->();

  if (my @errors = qx($c))                                                      # Perform lint and add errors as comments
   {my $s = readFile($f);
    my $e = join '', map {chomp; "<!-- $_ -->\n"} @errors;
    my $n = int @errors / 3;                                                    # Three lines per error message
    my $t = "<!--errors: $n -->";

    writeFile($f, "$source\n$T$e\n$t");                                         # Update xml file with errors
   }
 }

sub read($)                                                                     # Reload a linted xml file and extract attributes
 {my ($file) = @_;                                                              # File containing xml
  my $s = readFile($file);                                                      # Read xml from file

  my %a = $s =~ m/<!--(\w+):\s+(.+?)\s+-->/igs;                                 # Get attributes
          $s =~ s/\s+<!--linted:.+\Z//s;                                        # Remove generated comments at end

  bless{%a, source=>$s}                                                         # Return a matching linter
 }

# Tests and documentation

sub test{eval join('', <Data::Edit::Xml::Lint::DATA>) or die $@}                ## Test

test unless caller;

#extractDocumentation() unless caller();                                         ## podDocumentation

1;

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Lint - Lint an xml file using xmllint

=head1 Synopsis

Create a sample file with an error, lint it and retrieve the number of errors:

  my $x = Data::Edit::Xml::Lint::new();                                         # New xml file linter
     $x->file = 'zzz.xml';                                                      # Target file

  my $c = filePathExt(qw(/home phil hp dtd Dtd_2016_07_12 catalog-hpe xml));    # Possible catalog

  $x->catalog = $c if -e $c;                                                    # Use catalog if possible

  $x->source = <<END;                                                           # Sample source
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
<concept>
 <title>Title</title>
 <conbody>
   <p>Body</p>
 </conbody>
</concept>
END
  $x->lint(aaa=>1, bbb=>2);                                                     # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file

  my $X = Data::Edit::Xml::Lint::read($x->file);                                # Reload the written file
  ok $X->{aaa}  == 1;                                                           # Check the reloaded attributes
  ok $X->{bbb}  == 2;
  ok $X->errors == 1;
  is $X->$_, $x->$_ for qw(catalog file source);                                # Check linter fields

Produces:

 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
 <concept>
  <title>Title</title>
  <conbody>
    <p>Body</p>
  </conbody>
 </concept>

 <!--linted: 2017-Jul-13 -->

 <!--aaa: 1 -->
 <!--bbb: 2 -->
 <!--catalog: /home/phil/hp/dtd/Dtd_2016_07_12/catalog-hpe.xml -->
 <!--file: zzz.xml -->
 <!--linted: 2017-Jul-13 -->
 <!-- -:8: element concept: validity error : Element concept does not carry attribute id -->
 <!-- </concept> -->
 <!--           ^ -->

 <!--errors: 1 -->

=head1 Description

=head2 Methods

Methods in this package

=head3 new

Create a new xml linter - call this method statically as in Data::Edit::Xml::Lint::new()


=head3 file

File that the xml will be written to and read from


=head3 catalog

Optional catalog file containing the locations of the DTDs used to validate the xml


=head3 dtds

Optional directory containing the DTDs used to validate the xml


=head3 errors

Number of lint errors detected by xmllint


=head3 linted

Date the lint was performed


=head3 source

String containing the xml to be written or the xml read


=head3 lint

Store some xml in a file and apply xmllint

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head3 read

Reload a linted xml file and extract attributes

     Parameter  Description
  1  $file      File containing xml


=head1 Index


L<catalog|/catalog>

L<dtds|/dtds>

L<errors|/errors>

L<file|/file>

L<lint|/lint>

L<linted|/linted>

L<new|/new>

L<read|/read>

L<source|/source>

=head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, use, modify
and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
# podDocumentation

__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>7;

if (1)
 {my $x = Data::Edit::Xml::Lint::new();                                         # New xml file linter
     $x->file = 'zzz.xml';                                                      # Target file

  my $c = filePathExt(qw(/home phil hp dtd Dtd_2016_07_12 catalog-hpe xml));    # Possible catalog

  $x->catalog = $c if -e $c;                                                    # Use catalog if possible

  $x->source = <<END;                                                           # Sample source
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
<concept>
 <title>Title</title>
 <conbody>
   <p>Body</p>
 </conbody>
</concept>
END
  $x->lint(aaa=>1, bbb=>2);                                                     # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file

  my $X = Data::Edit::Xml::Lint::read($x->file);                                # Reload the written file
  ok $X->{aaa}  == 1;                                                           # Check the reloaded attributes
  ok $X->{bbb}  == 2;
  ok $X->errors == 1;
  is $X->$_, $x->$_ for qw(catalog file source);                                # Check linter fields

  unlink $X->file;                                                              # Clean up
  ok !-e $x->file;
 }
