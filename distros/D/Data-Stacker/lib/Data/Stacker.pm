##############################################################################
#
#  Data::Stacker is concise text serialization for hash/array nested structs.
#  (c) Vladi Belperchinov-Shabanski "Cade" 2016
#  <cade@bis.bg> <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>
#  http://cade.datamax.bg
#
#  GPL
#
##############################################################################
package Data::Stacker;
use strict;
use Exporter;
our $VERSION = '1.01';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

              stack_data
              unstack_data

            );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );
            

### STACK ####################################################################

# TODO: use Scalar::Util qw( reftype );

# NOTE: escaping/unescaping is intentionally left in-place

sub stack_data
{
  my $data = shift;
  
  my $ref = ref $data;
  if( $ref eq 'HASH' )
    {
    return __stack_hashref( $data );
    }
  elsif( $ref eq 'ARRAY' )
    {
    return __stack_arrayref( $data );
    }
  else
    {
    die "unsupported ref type, expected HASH or ARRAY reference, got [$data]";
    }  
}

sub __stack_hashref
{
  my $hr = shift;

  my $str = "";
  my $ec = 0;
  while( my ( $k, $v ) = each %$hr )
    {
    $k =~ s/([\\\n])/sprintf("%%%02X",ord($1))/geo;
    $ec++;
    my $ref = ref $v;
    if( $ref eq 'HASH' )
      {
      my $cnt = keys %$v;
      $str .= "$k\n" . __stack_hashref( $v );
      }
    elsif( $ref eq 'ARRAY' )
      {
      my $cnt = @$v;
      $str .= "$k\n" . __stack_arrayref( $v );
      }
    elsif( $ref eq '' )  
      {
      $v =~ s/([\\\n])/sprintf("%%%02X",ord($1))/geo;
      $str .= "$k\n=$v\n";
      }
    else
      {
      die "unsupported";
      }  
    }
  return "%$ec\n" . $str;
}

sub __stack_arrayref
{
  my $ar = shift;

  my $str = "";
  my $ec = 0;
  for my $v ( @$ar )
    {
    $ec++;
    my $ref = ref $v;
    if( $ref eq 'HASH' )
      {
      my $cnt = keys %$v;
      $str .= __stack_hashref( $v );
      }
    elsif( $ref eq 'ARRAY' )
      {    
      my $cnt = @$v;
      $str .= __stack_arrayref( $v );
      }
    elsif( $ref eq '' )  
      {
      $v =~ s/([\\\n])/sprintf("%%%02X",ord($1))/geo;
      $str .= "=$v\n";
      }
    else
      {
      die "unsupported ref type [$ref]";
      }  
    }
  return "\@$ec\n" . $str;
}

### UNSTACK ##################################################################

sub unstack_data
{
  my $str = shift;
  
  my @str = split /\n/, $str;
  chomp( @str );
  
  my ( $res_hr ) = __unstack_data_decode( \@str );
  return $res_hr;
}

sub __unstack_data_decode
{
  my $data   = shift;
  my $pos    = shift;

  while( $pos <= @$data )
    {
    my $line = $data->[ $pos ];

# print "pos $pos [$line]\n";    
    
    if( $line =~ /^\@(\d+)/ )
      {
      my $count = $1;
      return __unstack_data_decode_array( $data, $pos + 1, $count );
      }
    elsif( $line =~ /^\%(\d+)/ )  
      {
      my $count = $1;
      return __unstack_data_decode_hash( $data, $pos + 1, $count );
      }
    elsif( $line =~ /^\=/ )  
      {
      $line =~ s/\%([0-9A-F][0-9A-F])/chr(hex($1))/geo;
      return ( substr( $line, 1 ), $pos + 1 );
      }
    else
      {
      die "unsupported struct type or other error [$line]";
      }  
    }
 
}

sub __unstack_data_decode_array
{
  my $data  = shift;
  my $pos   = shift;
  my $count = shift;
# print "starting array decode pos $pos count $count line [$data->[$pos]]\n";
  
  my @res;
  while( $pos <= @$data and $count-- )
    {
    my $v;
    ( $v, $pos ) = __unstack_data_decode( $data, $pos );
    push @res, $v;
# print "adding array item [$v] at new pos $pos count $count\n";
    }
  
  return ( \@res, $pos );
}

sub __unstack_data_decode_hash
{
  my $data  = shift;
  my $pos   = shift;
  my $count = shift;
# print "starting hash decode pos $pos count $count line [$data->[$pos]]\n";
  
  my %res;
  while( $pos <= @$data and $count-- )
    {
    my $k = $data->[ $pos ];
    $k =~ s/\%([0-9A-F][0-9A-F])/chr(hex($1))/geo;
    my $v;
    $pos++;
    ( $v, $pos ) = __unstack_data_decode( $data, $pos );
    $res{ $k } = $v;
# print "adding hash item [$k]=[$v] at new pos $pos count $count\n";
    }
  
  return ( \%res, $pos );
}

##############################################################################


##############################################################################

=pod


=head1 NAME

  Data::Stacker provides concise text serialization for nested hash/array structs.

=head1 SYNOPSIS

  use Data::Stacker qw( :all );  # import all functions
  use Data::Stacker;             # the same as :all :) 
  use Data::Stacker qw( :none ); # do not import anything, use full package names

  # --------------------------------------------------------------------------

  my $str  = stack_data( $hash_ref  );
  my $str  = stack_data( $array_ref );

  my $struct_ref = unstack_data( $str );

=head1 FUNCTIONS

=head2 stack_data( $struct_ref )

Serializes hash or array reference ($struct_ref) including all nested data
into text. Result text is compact but still human readable.

=head2 unstack_data( $str_text )

Deserializes text data to perl structure (nested hash/array structs).

=head1 NOTES

Data::Stacker supports nested structures which include only ref types of
HASH, ARRAY and SCALAR.

Data::Stacker does not need to know values' types. It recognizes them only as
text string.

=head1 SERIALIZED TEXT FORMAT

The output serialized data was designed to be as short as possible but still
human readable (i.e. text). Another goal was that it have to be easily readable
by other programs with few parsing checks and in single pass.

Example source data structure:

    $hr = {
          'TESTER2' => {
                       'RANDOM' => {
                                   'FIELDS' => [ 'CTIME', 'SIZE' ],
                                   'UNIQUE' => 1,
                                   },
                       'KEY' =>    {
                                   'FIELDS' => [ 'DES', 'FUNC' ],
                                   'NAME'   => 'TEST2',
                                   '_ORDER' => 5
                                   }
                       }
          };
          
Example output text:

    %1
    TESTER2
    %2
    KEY
    %3
    NAME
    =TEST2
    _ORDER
    =5
    FIELDS
    @2
    =DES
    =FUNC
    RANDOM
    %2
    UNIQUE
    =1
    FIELDS
    @2
    =CTIME
    =SIZE


Serialized data represents stacked tree traversal data. Each line can be one
of:

=over 4

=item "BEGIN HASH"  \%[0-9]+

It starts with char '%' followed by key+value pairs count. Each key and value
are printed on separated line.

=item "BEGIN ARRAY"  \@[0-9]+

It starts with char '@' followed by array entries values count.

=item "BEGIN DATA"  \=.+

It represents single line, single string value. It can be either hash key 
value or array element value.

=item "HASH KEY"  .+

Hash keys are special case. Their position and purpose is clear, so they do
not need designated type chars (as %, @ or =).

=back

"BEGIN HASH" and "BEGIN ARRAY" can be found anywhere where "BEGIN DATA" is 
expected. 

Serialized data is expected to start with any of "BEGIN HASH", "BEGIN ARRAY" 
or "BEGIN DATA". Starting with "BEGIN DATA" is a special case where output
perl structure will hold single scalar reference.

URL-style (%XX where XX is hex ascii code) is used for escaping of special 
characters in key names and data values. Only chars that need escaping  
are the new-line/LF (%0A) char and % (%5C). Unescaping is performed for all
found escaped chars (not only for LF and %).

No comments (neither line nor trailing) are allowed. If added manually, will
be either accepted as key name or value data or will break decoding.

Example source data structure with comments:

    # ( 1) hash A (1 key)
    $hr = { 
          # ( 2) hash A, key #1
          'TESTER2' => 
                       # ( 3) hash A, value #1 == hash B (1 key)
                       {
                       # ( 4) hash B, key #1
                       'RANDOM' => 
                                   # ( 5) hash B, value #1 == hash C (2 keys)
                                   {
                                   # ( 6) hash C, key #1
                                   'FIELDS' => 
                                               # ( 7) hash C, value #1 == array D
                                               [ 'CTIME', 'SIZE' ],
                                   # ( 8) hash C, key #2 + value #2 == data "1"
                                   'UNIQUE' => 1,
                                   },
                       # ( 9) hash B, key #2
                       'KEY' =>    
                                   # (10) hash B, value #2 == hash E (3 keys)
                                   {
                                   # (11) hash E, key #1
                                   'FIELDS' => 
                                               # (12) hash E, value #1 == array F
                                               [ 'DES', 'FUNC' ],
                                   # (13) hash E, key #2 + value #2 == data "TEST2"
                                   'NAME'   => 'TEST2',
                                   # (14) hash E, key #3 + value #3 == data "5"
                                   '_ORDER' => 5
                                   }
                       }
          };

Note that order of key+value pairs in hashes is as reported by the language
(i.e. random).

Serialized output data with comments:
(as noted, comments here are invalid! only used as 

    %1       # ( 1) hash  A (1 key)
    TESTER2  # ( 2) hash  A, key     #1
    %2       # ( 3) hash  A, value   #1 == hash B (1 key)
    KEY      # ( 9) hash  B, key     #2
    %3       # (10) hash  B, value   #2 == hash E (3 keys)
    NAME     # (13) hash  E, key     #2
    =TEST2   # (13) hash  E, value   #2 == data "TEST2"
    _ORDER   # (14) hash  E, key     #3
    =5       # (14) hash  E, value   #3 == data "5"
    FIELDS   # (11) hash  E, key     #1
    @2       # (12) hash  E, value   #1 == array F (2 elements)
    =DES     # (12) array F, element #2 == data "DES"
    =FUNC    # (12) array F, element #2 == data "DES"
    RANDOM   # ( 4) hash  B, key     #1
    %2       # ( 5) hash  B, value   #1 == hash C (2 keys)
    UNIQUE   # ( 8) hash  C, key     #2
    =1       # ( 8) hash  C, value   #2 == data "1"
    FIELDS   # (11) hash  E, key     #1
    @2       # ( 7) hash  C, value   #1 == array D
    =CTIME   # ( 7) array D, element #1 == data "CTIME"
    =SIZE    # ( 7) array D, element #1 == data "SIZE"

=head1 TODO

    * Objects
    * Ordered hashes (i.e. Objects support for Tie::IxHash etc.)  

=head1 KNOWN BUGS

Escaping probably will not work with all unicode new-line chars or when 
reading from file with different record separator.

=head1 SEE ALSO

Few similar-task perl modules:

    * Storable
    * Data::MessagePack
    * JSON

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-stacker.git
  
  git clone git://github.com/cade-vs/perl-data-stacker.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

##############################################################################
1;
