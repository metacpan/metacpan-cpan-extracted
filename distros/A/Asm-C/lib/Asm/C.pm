#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Extract macro values and structure details from C programs.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Asm::C;
our $VERSION = "20210330";
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

#D1 Asm::C                                                                      # Extract macro values and structure details from C programs.

#D2 Structures                                                                  # Extract structure details from C programs.

my %extractCStructure;                                                          # Structured extracted from C files

sub extractCStructure($)                                                        # Extract the details of a structure
 {my ($input) = @_;                                                             # Input C file - a temporary one is ok

  return $extractCStructure{$input} if exists $extractCStructure{$input};       # Return cached value if it exists
  return undef unless confirmHasCommandLineCommand(q(gcc));                     # Check that we have gcc

  my $inputFile = -f $input ? $input : writeTempFile($input);                   # Make sure input is in a file

  my $e = qq(gcc -c -x c -fno-eliminate-unused-debug-symbols -fno-eliminate-unused-debug-types -gdwarf $inputFile -o a.out; readelf -w a.out; rm a.out);
  my @e = qx($e);                                                               # Structure details via dwarf debugging info
  my @s;                                                                        # Structure

  for my $e(@e)                                                                 # Each line of dwarf
   {if ($e =~ m(<(\w+)><(\w+)>: Abbrev Number:\s+(\w+)\s+(.*)))
     {push @s, [[$1, $2, $3, $4]];
     }
    if ($e =~ m(<(\w+)>\s+(\w+)\s*:\s(.*)))
     {push $s[-1]->@*, [$1, $2, $3];
     }
   }

  my %s; my %b;                                                                 # Structure details, base details
  for my $i(keys @s)                                                            # Each dwarf
   {if             ($s[$i][0][3] =~ m(DW_TAG_structure_type))                   # Structure followed by fields
     {my $name    = $s[$i][1][2] =~ s/\(.*\):\s*//gsr;;
      my $size    = $s[$i][2][2];
      $s{$name}   = genHash('structure', size=>$size, fields=>{});
      for(my $j   = $i + 1; $j < @s; ++$j)                                      # Following tag fields
       {last unless  $s[$j][0][3] =~ m(DW_TAG_member);
        my $field =  $s[$j][1][2] =~ s/\(.*\):\s*//gsr;
        my $type  =  $s[$j][5][2];
        my $loc   =  $s[$j][6][2];
        $type =~ s(<0x|>) ()gs;
        $s{$name}->fields->{$field} = genHash('field',
          field=>$field, type=>$type, loc=>$loc, size=>undef);
       }
     }
    if (            $s[$i][0][3] =~ m(DW_TAG_base_type))                        # Base types
     {my $offset  = $s[$i][0][1];
      my $size    = $s[$i][1][2];
      my $type    = $s[$i][3][2];
      $b{$offset} = genHash('base', size=>$size, type=>$type);
     }
   }

  for my $s(keys %s)                                                            # Fix references to base types
   {my $fields = $s{$s}->fields;
    for my $f(sort keys %$fields)
     {my $type  = $$fields{$f}->type;
      if (my $b = $b{$type})
       {$$fields{$f}->size = $b->size;
        $$fields{$f}->type = $b->type;
       }
      else
       {say STDERR "No base for offset: $type";
       }
     }
   }

  $extractCStructure{$input} = \%s                                              # Structure details
 } # extractCStructure

sub extractCField($$$)                                                          # Extract the details of a field in a structure in a C file
 {my ($input, $structure, $field) = @_;                                         # Input file, structure name,  field within structure
  if     (my $s = extractCStructure $input)                                     # Structures in file
   {if   (my $S = $$s{$structure})                                              # Found structure
     {if (my $F = $S->fields)                                                   # Structure has fields
       {return $$F{$field};                                                     # Field detail
       }
     }
   }
  undef                                                                         # Parse failed or no such structure
 } # extractCField

sub extractCFieldLoc($$$)                                                       # Extract the offset to the location of a field in a structure in a C file
 {my ($input, $structure, $field) = @_;                                         # Input file, structure name,  field within structure
  if (my $f = extractCField($input, $structure, $field))                        # Structures in file
   {return $f->loc;                                                             # Offset to field location
   }
  undef                                                                         # Parse failed or no such structure or no such field
 } # extractCFieldLoc

sub extractCFieldSize($$$)                                                      # Extract the size of a field in a structure in a C file
 {my ($input, $structure, $field) = @_;                                         # Input file, structure name,  field within structure
  if (my $f = extractCField($input, $structure, $field))                        # Structures in file
   {return $f->size;                                                            # Size of field
   }
  undef                                                                         # Parse failed or no such structure or no such field
 } # extractCFieldSize

sub extractCFieldType($$$)                                                      # Extract the type of a field in a structure in a C file
 {my ($input, $structure, $field) = @_;                                         # Input file, structure name,  field within structure
  if (my $f = extractCField($input, $structure, $field))                        # Structures in file
   {return $f->type;                                                            # Type of field
   }
  undef                                                                         # Parse failed or no such structure or no such field
 } # extractCFieldType

sub extractCStructureFields($$)                                                 # Extract the names of the fields in a C structure
 {my ($input, $structure) = @_;                                                 # Input file, structure name
  if (my $s = extractCStructure $input)                                         # Structures in file
   {if (my $S = $$s{$structure})                                                # Found structure
     {if (my $F = $S->fields)                                                   # Structure has fields
       {return sort keys %$F;                                                   # Return names of fields in structure in ascending order
       }
     }
   }
  ()                                                                            # Parse failed or no such structure
 } # extractCStructureSize

sub extractCStructureSize($$)                                                   # Extract the size of a C structure
 {my ($input, $structure) = @_;                                                 # Input file, structure name
  if (my $s = extractCStructure $input)                                         # Structures in file
   {if (my $S = $$s{$structure})                                                # Found structure
     {return $S->size;                                                          # Return structure size
     }
   }
  undef                                                                         # Parse failed or no such structure
 } # extractCStructureSize

#D2 Macros                                                                      # Extract macro values from C header files

my %extractMacroDefinitionsFromCHeaderFile;                                     # Cache macro definitions

sub extractMacroDefinitionsFromCHeaderFile($)                                   # Extract the macro definitions found in a C header file using gcc
 {my ($includeFile) = @_;                                                       # C Header file name as it would be entered in a C program
  my $d = $extractMacroDefinitionsFromCHeaderFile{$includeFile};                # Cached macro definitions
  return $d if $d;                                                              # Return cached value

  confirmHasCommandLineCommand("gcc");                                          # Check gcc
  my @l = qx(gcc -E -dM -include "$includeFile" - < /dev/null);                 # Use gcc to extract macro definitions

  my %d;
  for my $l(@l)                                                                 # Extract macro definitions
   {if ($l =~ m(\A#define\s+(\S+)\s+(\S+)(.*)))
     {$d{$1} = $2;
     }
   }

  $extractMacroDefinitionsFromCHeaderFile{$includeFile} = \%d;                  # Return definitions
 }

sub extractMacroDefinitionFromCHeaderFile($$)                                   # Extract a macro definitions found in a C header file using gcc
 {my ($includeFile, $macro) = @_;                                               # C Header file name as it would be entered in a C program, macro name
  if (my $d = extractMacroDefinitionsFromCHeaderFile($includeFile))             # Get macro definitions
   {return $$d{$macro};
   }
  undef
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
extractCField
extractCFieldLoc
extractCFieldSize
extractCFieldType
extractCStructure
extractCStructureFields
extractCStructureSize
extractMacroDefinitionFromCHeaderFile
extractMacroDefinitionsFromCHeaderFile
);
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Asm::C - Extract macro values and structure details from C programs.

=head1 Synopsis

=head2 Extract structure details from C programs.

Given:

  struct S
   {int a;
    int b;
    int c;
   } s;
  void main() {}

Get:

  is_deeply extractCStructure($input),
 { S => bless({
     fields => {
       a => bless({field => "a", loc => 0, size => 4, type => "int"}, "field"),
       b => bless({field => "b", loc => 4, size => 4, type => "int"}, "field"),
       c => bless({field => "c", loc => 8, size => 4, type => "int"}, "field"),
     },
     size   => 12,
  }, "structure")};

=head2 Extract macro values from a C header file.

Find the value of a macro definition in a C header file:

  my $m = extractMacroDefinitionsFromCHeaderFile("linux/mman.h");

  is_deeply $$m{MAP_ANONYMOUS}, "0x20";

=head1 Description

Extract macro values and structure details from C programs.


Version "20210328".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Asm::C

Extract macro values and structure details from C programs.

=head2 Structures

Extract structure details from C programs.

=head3 extractCStructure($input)

Extract the details of a structure

     Parameter  Description
  1  $input     Input C file - a temporary one is ok

B<Example:>



    is_deeply extractCStructure($input),                                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head3 extractCField($input, $structure, $field)

Extract the details of a field in a structure in a C file

     Parameter   Description
  1  $input      Input file
  2  $structure  Structure name
  3  $field      Field within structure

B<Example:>


  if (1)
   {my $input = writeTempFile <<END;
  struct S
   {int a;
    int b;
    int c;
   } s;


=head3 extractCFieldLoc($input, $structure, $field)

Extract the offset to the location of a field in a structure in a C file

     Parameter   Description
  1  $input      Input file
  2  $structure  Structure name
  3  $field      Field within structure

B<Example:>


  if (1)
   {my $input = writeTempFile <<END;
  struct S
   {int a;
    int b;
    int c;
   } s;


=head3 extractCFieldSize($input, $structure, $field)

Extract the size of a field in a structure in a C file

     Parameter   Description
  1  $input      Input file
  2  $structure  Structure name
  3  $field      Field within structure

B<Example:>


  if (1)
   {my $input = writeTempFile <<END;
  struct S
   {int a;
    int b;
    int c;
   } s;


=head3 extractCFieldType($input, $structure, $field)

Extract the type of a field in a structure in a C file

     Parameter   Description
  1  $input      Input file
  2  $structure  Structure name
  3  $field      Field within structure

B<Example:>


  if (1)
   {my $input = writeTempFile <<END;
  struct S
   {int a;
    int b;
    int c;
   } s;


=head3 extractCStructureFields($input, $structure)

Extract the names of the fields in a C structure

     Parameter   Description
  1  $input      Input file
  2  $structure  Structure name

B<Example:>


  if (1)
   {my $input = writeTempFile <<END;
  struct S
   {int a;
    int b;
    int c;
   } s;


=head3 extractCStructureSize($input, $structure)

Extract the size of a C structure

     Parameter   Description
  1  $input      Input file
  2  $structure  Structure name

B<Example:>


  if (1)
   {my $input = writeTempFile <<END;
  struct S
   {int a;
    int b;
    int c;
   } s;


=head2 Macros

Extract macro values from C header files

=head3 extractMacroDefinitionsFromCHeaderFile($includeFile)

Extract the macro definitions found in a C header file using gcc

     Parameter     Description
  1  $includeFile  C Header file name as it would be entered in a C program

B<Example:>


  if (1)
   {my $h = "linux/mman.h";

    my $m = extractMacroDefinitionsFromCHeaderFile("linux/mman.h");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $$m{MAP_ANONYMOUS}, "0x20";
    ok extractMacroDefinitionFromCHeaderFile("linux/mman.h", q(PROT_WRITE)) eq "0x2";
   }


=head3 extractMacroDefinitionFromCHeaderFile($includeFile, $macro)

Extract a macro definitions found in a C header file using gcc

     Parameter     Description
  1  $includeFile  C Header file name as it would be entered in a C program
  2  $macro        Macro name

B<Example:>


  if (1)
   {my $h = "linux/mman.h";
    my $m = extractMacroDefinitionsFromCHeaderFile("linux/mman.h");
    is_deeply $$m{MAP_ANONYMOUS}, "0x20";

    ok extractMacroDefinitionFromCHeaderFile("linux/mman.h", q(PROT_WRITE)) eq "0x2";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }



=head1 Index


1 L<extractCField|/extractCField> - Extract the details of a field in a structure in a C file

2 L<extractCFieldLoc|/extractCFieldLoc> - Extract the offset to the location of a field in a structure in a C file

3 L<extractCFieldSize|/extractCFieldSize> - Extract the size of a field in a structure in a C file

4 L<extractCFieldType|/extractCFieldType> - Extract the type of a field in a structure in a C file

5 L<extractCStructure|/extractCStructure> - Extract the details of a structure

6 L<extractCStructureFields|/extractCStructureFields> - Extract the names of the fields in a C structure

7 L<extractCStructureSize|/extractCStructureSize> - Extract the size of a C structure

8 L<extractMacroDefinitionFromCHeaderFile|/extractMacroDefinitionFromCHeaderFile> - Extract a macro definitions found in a C header file using gcc

9 L<extractMacroDefinitionsFromCHeaderFile|/extractMacroDefinitionsFromCHeaderFile> - Extract the macro definitions found in a C header file using gcc

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Asm::C

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Time::HiRes qw(time);
use Test::More;

my $localTest = ((caller(1))[0]//'Asm::C') eq "Asm::C";                         # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)
  {if (confirmHasCommandLineCommand(q(gcc))
   &&  confirmHasCommandLineCommand(q(readelf)))
    {plan tests => 17
    }
  else
   {plan skip_all =>qq(gcc or readelf missing on: $^O);
   }
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

my $start = time;                                                               # Tests

if (1)                                                                          #TextractCField #TextractCStructureFields #TextractCStructureSize  #TextractCFieldLoc #TextractCFieldSize #TextractCFieldType
 {my $input = writeTempFile <<END;
struct S
 {int a;
  int b;
  int c;
 } s;
void main() {}
END

  is_deeply extractCStructure($input),                                          #TextractCStructure
{ S => bless({
      fields => {
        a => bless({ field => "a", loc => 0, size => 4, type => "int" }, "field"),
        b => bless({ field => "b", loc => 4, size => 4, type => "int" }, "field"),
        c => bless({ field => "c", loc => 8, size => 4, type => "int" }, "field"),
      },
      size => 12,
    }, "structure")};

  is_deeply extractCField($input, q(S), q(a)),
    bless({ field => "a", loc => 0, size => 4, type => "int" }, "field");

  is_deeply extractCField($input, q(S), q(b)),
    bless({ field => "b", loc => 4, size => 4, type => "int" }, "field");

  is_deeply extractCField($input, q(S), q(c)),
    bless({ field => "c", loc => 8, size => 4, type => "int" }, "field");

  is_deeply [extractCStructureFields($input, q(S))], [qw(a b c)];

  is_deeply extractCStructureSize($input, q(S)), 12;

  is_deeply extractCFieldLoc ($input, q(S), q(a)), 0;
  is_deeply extractCFieldLoc ($input, q(S), q(b)), 4;
  is_deeply extractCFieldLoc ($input, q(S), q(c)), 8;

  is_deeply extractCFieldSize($input, q(S), q(a)), 4;
  is_deeply extractCFieldSize($input, q(S), q(b)), 4;
  is_deeply extractCFieldSize($input, q(S), q(c)), 4;

  is_deeply extractCFieldType($input, q(S), q(a)), q(int);
  is_deeply extractCFieldType($input, q(S), q(b)), q(int);
  is_deeply extractCFieldType($input, q(S), q(c)), q(int);
 }

if (0)
 {my $s = extractCStructure q(#include <time.h>);
 }

if (1)                                                                          #TextractMacroDefinitionsFromCHeaderFile #TextractMacroDefinitionFromCHeaderFile
 {my $h = "linux/mman.h";
  my $m = extractMacroDefinitionsFromCHeaderFile("linux/mman.h");
  is_deeply $$m{MAP_ANONYMOUS}, "0x20";
  ok extractMacroDefinitionFromCHeaderFile("linux/mman.h", q(PROT_WRITE)) eq "0x2";
 }

lll "Finished:", time - $start;
