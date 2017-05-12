package DBIx::Perform::AttributeGrammar;

use strict;
use Parse::RecDescent;
use base 'Exporter';
use Data::Dumper;

our $VERSION = '0.695';

# exported methods
our @EXPORT_OK = qw( &get_grammar );

# Enable warnings within the Parse::RecDescent module.

$::RD_ERRORS = 1;    # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1;    # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1;    # Give out hints to help fix problems.

$::Lindex             = 0;
$::Jindex             = 0;
$::Index              = 0;
#$::Verify_Join        = undef;
$::Verify_Lookup_Join = undef;

our $grammar = <<'_EOGRAMMAR_';

   OP              : m([-+*/%])         # Mathematical operators
   QUOTE           : /"/ | /'/          # Quoted string
   INTEGER         : /[-+]?\d+/        # Signed integers
   DOUBLE          : /[-+]?\d+\.\d+/    # Signed doubles
   ALPHANUM        : /\w-?\w*/ # Unquoted alphanumberic characters
   NAME_STRING     : /\w+/i    # Limited complexity strings for names
   GENERIC_STRING  : /[\.a-zA-Z0-9\*\-\_\(\)\$\/\[\]\#\@\&\!\+\=\%\>\<\,\;\:\ \'\\]*/i
   QSTRING         : /"((^|[^\\])(\\\\)*\\"|[^"])*"/
   BSTRING         : /[^"),\s][^),\s]*/
   FORMAT_STRING   : /[\#\.\/\-\$\&mdyMDY]*/i

   empty_tag : ''
             {
                $::Lindex = 0;
                $::Jindex = 0;
                $::res = undef;
                $::res->{field_tag} = "EMPTY_FIELD_TAG";
             }

   field_tag   : NAME_STRING 
               { 
                  $::Lindex = 0;
                  $::Jindex = 0;
                  $::res = undef;
                  $::res->{field_tag} = lc $item{NAME_STRING};
               }

   table_name  : NAME_STRING 
               {
                  $::res->{table_name} = lc $item{NAME_STRING};
               }
               | 
               {
                  $::res->{table_name} = "EMPTY_TABLE_NAME";
               }

   column_name : NAME_STRING 
               {
                  $::res->{column_name} = lc $item{NAME_STRING};
               }

   lookup_tag   : NAME_STRING

   lookup_table  : NAME_STRING

   lookup_column : NAME_STRING

   join_table  : NAME_STRING

   join_column : NAME_STRING

   field_join_table  : NAME_STRING

   field_join_column : NAME_STRING

   verify_lookup_join : "*"
                      {
                         $::Verify_Lookup_Join  = 1;
                      }
                      |

   verify_field : "*" 
                {
                   $::res->{VERIFY} = 1;
                }
                | 

   numeric_value: DOUBLE
                | INTEGER

   data_type : /CHARACTER/i
             | /CHAR/i
             | /SMALLINT/i
             | /INTEGER/i
             | /INT/i
             | /SERIAL/i
             | /DECIMAL/i
             | /DEC/i
             | /NUMERIC/i
             | /MONEY/i
             | /SMALLFLOAT/i
             | /REAL/i
             | /FLOAT/i
             | /DATETIME/i
             | /DATE/i
             | /INTERVAL/i

   include_string : QSTRING
               {
		  $item{QSTRING} =~ /^"(.*)"$/;
                  $::res->{INCLUDE_VALUES}->{$1} = 1;
               }

   range_floor   : QSTRING
                 | BSTRING

   range_ceiling  : QSTRING
                  | BSTRING

   subscript_floor : numeric_value

   subscript_ceiling : numeric_value

   null_rule : /(,\s*)?NULL(\s*,)?/i   { $::res->{INCLUDE_NULL_OK} = 1; }
             |

   range_statement : null_rule range_floor /TO/i range_ceiling null_rule
                   {
                       $::res->{RANGE}->{$item{range_floor}}
                         = $item{range_ceiling};
                   }

   comment_spec : "," /COMMENTS/i "=" QSTRING
                {
                   ($::res->{COMMENTS}) = $item{QSTRING} =~ /^"(.*)"$/;
                }
   
   default_spec : "," /DEFAULT/i "=" QSTRING
                {
                  ($::res->{DEFAULT}) = $item{QSTRING} =~ /^"(.*)"$/;
                }
                | "," /DEFAULT/i "=" numeric_value
                {
                  $::res->{DEFAULT} = $item{numeric_value};
                 }
                | "," /DEFAULT/i "=" ALPHANUM
                {
                  $::res->{DEFAULT} = uc $item{ALPHANUM};
                }

   format_spec : "," /FORMAT/i "=" QUOTE FORMAT_STRING QUOTE
               {
                  $::res->{FORMAT} = uc $item{FORMAT_STRING};
               }

   include_item  : range_statement
                 | include_string

   include_list  : include_item "," include_list
                 | include_item

   include_spec : "," /INCLUDE/i "=" "(" include_list ")" 

   joining_spec : /JOINING/i join_table "." join_column
                {
                  $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{join_table}  = lc $item{join_table};
                  $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{join_column} = lc $item{join_column};
                }
                | /JOINING/i verify_lookup_join join_table "." join_column
                {
                  $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{join_table}  = lc $item{join_table};
                  $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{join_column} = lc $item{join_column};
                  $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{verify}      = $::Verify_Lookup_Join;
                }

   lookup_assignment : lookup_tag "=" lookup_table "." lookup_column
                     {
                       $::Tag = lc $item{lookup_tag};
                       $::Jindex++ if ! defined $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag};
                       $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{table_name}  = lc $item{lookup_table};
                       $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{column_name} = lc $item{lookup_column};
                       $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{join_index} = $::Jindex;
                     }
                     | lookup_tag "=" lookup_column
                     {
                       $::Tag = lc $item{lookup_tag};
                       $::Jindex++ if ! defined $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag};
                       $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{table_name}  = "EMPTY_TABLE_NAME";
                       $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{column_name} = lc $item{lookup_column};
                       $::res->{LOOKUP_HASH}->{$::Lindex}->{$::Tag}->{join_index} = $::Jindex;
                     }

   repeat_lookup_assignment  : lookup_assignment "," repeat_lookup_assignment
                             | lookup_assignment

   lookup_spec : "," /LOOKUP/i repeat_lookup_assignment joining_spec
               { 
                 $::Lindex++;
               }

   picture_spec : "," /PICTURE/i "=" QUOTE GENERIC_STRING QUOTE
                {
                   $::res->{PICTURE} = $item{GENERIC_STRING};
                }

   wordwrap_spec : "," /WORDWRAP/i
                 {
                    $::res->{WORDWRAP} = 1;
                 }
                 | "," /WORDWRAP/i /COMPRESS/i
                 {
                   $::res->{WORDWRAP} = 1;
                   $::res->{COMPRESS} = 1;
                 }

   attr_spec : "," /AUTONEXT/i   { $::res->{uc $item[2]} = 1; }
             | "," /DOWNSHIFT/i  { $::res->{uc $item[2]} = 1; }
             | "," /INVISIBLE/i  { $::res->{uc $item[2]} = 1; }
             | "," /NOENTRY/i    { $::res->{uc $item[2]} = 1; }
             | "," /NOUPDATE/i   { $::res->{uc $item[2]} = 1; }
             | "," /QUERYCLEAR/i { $::res->{uc $item[2]} = 1; }
             | "," /REVERSE/i    { $::res->{uc $item[2]} = 1; }
             | "," /RIGHT/i      { $::res->{uc $item[2]} = 1; }
             | "," /REQUIRED/i   { $::res->{uc $item[2]} = 1; }
             | "," /UPSHIFT/i    { $::res->{uc $item[2]} = 1; }
             | "," /ZEROFILL/i   { $::res->{uc $item[2]} = 1; }
             | comment_spec
             | default_spec
             | format_spec
             | include_spec
             | picture_spec
             | wordwrap_spec
             | lookup_spec
             
   repeat_attr_spec : attr_spec repeat_attr_spec

   subscript_field_description : "[" subscript_floor "," subscript_ceiling "]"
                               {
                                 $::res->{SUBSCRIPT_FLOOR}   = $item{subscript_floor};
                                 $::res->{SUBSCRIPT_CEILING} = $item{subscript_ceiling};
                               }

   displayonly_type : /TYPE/i data_type
                    {
                      $::res->{data_type} = uc $item{data_type};
                    } 

   displayonly_options : /ALLOWING/i /INPUT/i displayonly_type /NOT/i /NULL/i
                       {
                         $::res->{ALLOWING_INPUT} = 1;
                         $::res->{NOTNULL} = 1;
                       }
                       | displayonly_type /NOT/i /NULL/i
                       {
                          $::res->{NOTNULL} = 1;
                       }
                       | /ALLOWING/i /INPUT/i displayonly_type
                       {
                         $::res->{ALLOWING_INPUT} = 1;
                       }
                       | displayonly_type

   displayonly_field : /DISPLAYONLY/i displayonly_options repeat_attr_spec
                     {
                       $::res->{DISPLAYONLY} = 1;
                     }
                     | /DISPLAYONLY/i displayonly_options 
                     {
                       $::res->{DISPLAYONLY} = 1;
                     }
                     | /DISPLAYONLY/i 
                     {
                       $::res->{DISPLAYONLY} = 1;
                     }

   field_desc : "=" verify_field field_join_table "." field_join_column 
              {
                $::res->{FIELD_TAG_JOIN_HASH}->{$::Index}->{join_table}  = lc $item{field_join_table};
                $::res->{FIELD_TAG_JOIN_HASH}->{$::Index}->{join_column} = lc $item{field_join_column};

                $::Index++;
              }

   repeat_field_desc : field_desc repeat_field_desc
                     | field_desc
                     |

   field_description_list : repeat_field_desc repeat_attr_spec
                          {
                            $::Index = 0;
                          }
                          |
                          {
                            $::Index = 0;
                          }

   attrs : field_tag "=" verify_field displayonly_field
         {
           return $::res;
         } 
         | field_tag "=" verify_field table_name "." column_name subscript_field_description field_description_list
         {
           return $::res;
         } 
         | field_tag "=" verify_field table_name "." column_name field_description_list
         {
           return $::res;
         } 
         | empty_tag  "=" verify_field table_name "." column_name  field_description_list
         {
           return $::res;
         } 
         | field_tag "=" verify_field column_name subscript_field_description field_description_list
         {
            return $::res;
         }
         | field_tag "=" verify_field column_name field_description_list
         {
           return $::res;
         }

   startrule : attrs(s /;/)

_EOGRAMMAR_

# methods

sub get_grammar {
    return $grammar;
}

1;
