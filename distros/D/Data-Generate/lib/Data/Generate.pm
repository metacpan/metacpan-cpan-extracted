#!/usr/bin/perl -w 
################################################################################
# package Data::Generate
# Description: returns an SQL-Data generator object 
# Design: during parsing we create following data structure internally: 
# 'value_term': ascii string 
# 'value_column': array of possible alternative choices for the value term 
# 'value_chain': a chain of value columns 
# 'chain_list':  the generator itself   
# output data : output data is retrieved by subsequent concatenation 
# of value terms in a value chain. If more than one value chains are defined,
# then, based on weigthing, each chain at turn will be "asked" to return an 
# output value, until an array of the requested cardinality is filled.  
# 
################################################################################
package Data::Generate;
 

use 5.006;
use strict;
use warnings;
use Carp;
use Parse::RecDescent;
use Date::Parse;
use Date::DayOfWeek;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;


our @ISA = qw(Exporter);




# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use  Data::Generate  ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
				                   parse
                                  ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.02';


$Data::Generate::Parser=undef;
$Data::Generate::current=undef;
$Data::Generate::ACTUAL_VALUE_COLUMN=undef;
$Data::Generate::VC_RANGE_REVERSE_FLAG=undef;



#-------------------------------------------------------------------------------
# Various constant definitions 
#-------------------------------------------------------------------------------
$Data::Generate::vcol_type ={};
$Data::Generate::vcol_type->{year}->{lowlimit}=1970;  # Unix 32 bit date
$Data::Generate::vcol_type->{year}->{highlimit}=2037; # Unix 32 bit date
$Data::Generate::vcol_type->{year}->{type}='year'; 
$Data::Generate::vcol_type->{month}->{lowlimit}=1;
$Data::Generate::vcol_type->{month}->{highlimit}=12;
$Data::Generate::vcol_type->{month}->{type}='month'; 
$Data::Generate::vcol_type->{day}->{lowlimit}=1;
$Data::Generate::vcol_type->{day}->{highlimit}=31;
$Data::Generate::vcol_type->{day}->{type}='day'; 
$Data::Generate::vcol_type->{hour}->{lowlimit}=0;
$Data::Generate::vcol_type->{hour}->{highlimit}=24;
$Data::Generate::vcol_type->{hour}->{type}='hour'; 
$Data::Generate::vcol_type->{minute}->{lowlimit}=0;
$Data::Generate::vcol_type->{minute}->{highlimit}=59;
$Data::Generate::vcol_type->{minute}->{type}='minute'; 
$Data::Generate::vcol_type->{second}->{lowlimit}=0;
$Data::Generate::vcol_type->{second}->{highlimit}=59;
$Data::Generate::vcol_type->{second}->{type}='second'; 
$Data::Generate::vcol_type->{fraction}->{type}='fraction'; 

$Data::Generate::vchain_type ={};
$Data::Generate::vchain_type->{DATE}->{type}='DATE'; 
$Data::Generate::vchain_type->{DATE}->{vcol_output_format}=
   ['%s',' %02d:','%02d:','%02d','.%s']; 
#   ['%04d','%02d','%02d',' %02d:','%02d:','%02d','.%s']; 
$Data::Generate::vchain_type->{DATE}->{check_type}=sub {
    no warnings "all"; 
    my $input=shift;
    (my $ss,my $mm, my $hh,my $day,my $month,my $year)= strptime($input);
    return undef unless defined $year;
    $year+=1900;
    $month++;
    my $precision=0;
    $precision = $Data::Generate::current->{ct_precision} 
       if defined $Data::Generate::current->{ct_precision};
    my $result=sprintf('%04d%02d%02d %02d:%02d:%02.'.$precision.'f',
          $year, $month, $day,$hh,$mm,$ss); 
    return undef unless defined str2time($result);
    return $result; 
    };
$Data::Generate::vchain_type->{DATE}->{output_format_fct}=sub {
    my $input=shift;
    return $input unless defined $Data::Generate::current->{ct_precision}; 
    my $precision=$Data::Generate::current->{ct_precision};
    my ( $date_string,  $date_fraction) = ($input =~ /^(.+?)(\d{2}\.\d*)$/);
    $date_fraction=sprintf('%02.'.$precision.'f',$date_fraction); 
    return $date_string.$date_fraction; 
    };

$Data::Generate::vchain_type->{DATE}->{subtype}->{'DATEWITHFRACTION'}
    ->{fraction_start_ix}=4; 


$Data::Generate::vchain_type->{INTEGER}->{type}='INTEGER'; 
$Data::Generate::vchain_type->{INTEGER}->{check_type}=sub {
    no warnings "all"; 
    my $input=shift;
    my $result=int($input);
    return undef unless $result == $input;
    return $result;
};

$Data::Generate::vchain_type->{FLOAT}->{output_format_fct}=sub {
    my $input=shift;
    $input =~ s/^\-0+\.0+$/0.0/;
    $input =~ s/^\+//;
    return eval($input); 
    };

$Data::Generate::vchain_type->{FLOAT}->{check_type}=sub {
#    no warnings "all"; 
    my $input=shift;
    my $result=$input*1.0;
    $input=eval($input);
    $result=eval($result);
    return undef unless $result == $input;
    return $result;
};


$Data::Generate::vcol_type->{weekday}->{type}='weekday'; 
$Data::Generate::vcol_type->{weekday}->{term_list}=[qw{SUN MON TUE WED THU FRI SAT}];    

################################################################################
# sub new
# Description:
# inital constructor for a list of value chains.
# 
################################################################################
sub new 
{
    my ($class,$text)   = @_;
    my $self = {};
    $self->{vchain_text} = $text;
    $self->{vchain_length} = 0;
    $self->{data_array} = ['']; 
    $self->{vchain_array} = []; 
    $self->{vchain_hash} = {}; 
    $self->{actual_vcol} = {};
    bless  $self, $class;    
    $self->reset_actual_vchain();
    return $self;
}
 


################################################################################
# sub load_parser
# Description:
# create a Parse::RecDescent parser 
# and load Data::Generate grammatics into.
# 
################################################################################
sub load_parser
{

#------------------------------------------------------------------------------#
#                          START OF GRAMMATICS                                 #
#------------------------------------------------------------------------------#

   my $grammar = q {     
     start:  varchar_type 
                   | string_type 
                   | date_type 
                   | integer_type 
                   | float_type 
              
#------------------------------------------------------------------------------#
#                         STRING TYPE GRAMMATICS                               #
#------------------------------------------------------------------------------#
# different intialization, but for the rest see varchar type

     string_type:  ct_string vch_list  

     ct_string: /STRING/  
     {
         $Data::Generate::current->{chain_type}='STRING';
     }
#------------------------------------------------------------------------------#
#                         VARCHAR TYPE GRAMMATICS                              #
#------------------------------------------------------------------------------#

     varchar_type:  ct_varchar vch_list  

     ct_varchar: /(VC2|VC|VARCHAR2|VARCHAR)/ '('   /\d+/ ')' 
     {
         $Data::Generate::current->{chain_type}='VARCHAR';
         $Data::Generate::current->{ct_length}=$item[3];
      }

     vch_list: <leftop: value_chain /\|/ value_chain > 

     value_chain:  value_col(s)   vchain_weigth(?)
     {       
               $Data::Generate::current->bind_actual_vchain();
               1; } 
           
     vchain_weigth: /\(/  /\d+\.?\d*/ /\%\)/ 
     { $Data::Generate::current->{actual_vchain}->{weigth}=$item[2]; 1; }

     value_col:  vcr_integer vcol_card(?)
     {
       $Data::Generate::current->bind_actual_vcol();  
         1;
      }
                   | vcol_range 
                   | vcol_literal 
                   | vcol_filelist



     vcol_literal:  vcol_lit_term  vcol_card(?)   
     {
       $Data::Generate::current->bind_actual_vcol();  
       1;
      }


     vcol_card: '{' /\d+/ '}' 
     {
         $Data::Generate::current->{actual_vcol}->{quantifier}=$item[2];
         1;
      }

     vcol_lit_term:  /\'.+?\'/  
     {
         $item[1] =~ /\'(.+?)\'/;
         push(@{$Data::Generate::current->
                                      {actual_vcol}->{value_term_list}},$1); 1;
     }

     vcol_range: vcr_start vcr_reverse(?)  vcr_term(s) vcr_end  vcol_card(?)
     {    
       $Data::Generate::current->check_reverse_flag();  
       $Data::Generate::current->bind_actual_vcol();  
      1;}


     vcr_start:  /\[/   

     vcr_reverse: /\^/ { $Data::Generate::current->{actual_vcol}
                                                     ->{reverse_flag}=1; }


    vcr_term:  /[^\s\]\[]/ '-' /[^\s\]\[]/   
                  {
                       my @cmp = map(chr, 
                           (
                                 ord($item[1])..ord($item[3])
                            )
                         );    
                         push(@{$Data::Generate::current->
                                      {actual_vcol}->{value_term_list}},@cmp);
                      }
                  | '\\\\ '    
                  {
                         push(@{$Data::Generate::current->
                                      {actual_vcol}->{value_term_list}},' ');
                  }
                  | '\\\\'  /./  
                  {
                         push(@{$Data::Generate::current->
                                   {actual_vcol}->{value_term_list}},$item[2]);
                  }
                  | /[^\]\[]/   
                  {
                         push(@{$Data::Generate::current->
                                   {actual_vcol}->{value_term_list}},$item[1]);
                  }

     vcr_end:   /\]/  


     vcr_integer: /\[/  /\d+/ '..' /\d+/ /\]/   
     {
         warn "false integer order " if $item[4] < $item[2];
         my @cmp = ($item[2]..$item[4]);
         push(@{$Data::Generate::current->
                        {actual_vcol}->{value_term_list}},@cmp);
      }


     vcol_filelist:  vcol_filelist_term  vcol_card(?)   
     {
       $Data::Generate::current->bind_actual_vcol();  
       1;
      }


     vcol_filelist_term: /\<\S+\>/   
     {
         (my $file)= ($item[1] =~ /\<(\S+)\>/);   
         $Data::Generate::current->vcol_file_process($file);
         1;
      }



      
#------------------------------------------------------------------------------#
#                         INTEGER TYPE GRAMMATICS                              #
#------------------------------------------------------------------------------#

     integer_type: ct_integer vch_int_list

     ct_integer: /(INTEGER|INT)/ ct_int_length(?)
     {
         $Data::Generate::current->{chain_type}='INTEGER';
          $Data::Generate::current->{ct_length}=9 # max integer value
               unless (exists $Data::Generate::current->{ct_length});
         
         if ($Data::Generate::current->{ct_length}>9)
         {
          warn " maximal integer length is 9 \n".
           "Current Value: $Data::Generate::current->{ct_length} is too high"
           .",will use length 9.";
          $Data::Generate::current->{ct_length}=9;
         }
      }

     ct_int_length:  '('   /\d+/ ')'
     {
         $Data::Generate::current->{ct_length}=$item[2]; 
      }

     vch_int_list: <leftop: vch_int /\|/ vch_int > 


     vch_int: vchi_sign(?) vcol_int(s)   vchain_weigth(?)
     {       
         $Data::Generate::current->bind_actual_vchain();
       1; } 

     vchi_sign: 
       /\+\/\-/   
        {       
          $Data::Generate::current->{actual_vchain}->{sign}->{'+'}++;
          $Data::Generate::current->{actual_vchain}->{sign}->{'-'}++;
          1; }
     | /[+-]/ 
        {       
          $Data::Generate::current->{actual_vchain}->{sign}->{$item[1]}++;
         1; }
 


     vcol_int:  vcint_range 
                   | vcint_literal 
                   | vcol_filelist

     vcint_range:  /\[/ <leftop: vcint_term /\,/ vcint_term > /\]/ vcint_card(?)
     {    
       $Data::Generate::current->bind_actual_vcol();  
      1;}


     vcint_term:  /\d+/ '-' /\d+/   
                  {
                       my @cmp = (($item[1]+0)..($item[3]+0));    
                     push(@{$Data::Generate::current->
                                      {actual_vcol}->{value_term_list}},@cmp);
                      }
                  | vcint_lit_term 

     vcint_literal:  vcint_lit_term  vcint_card(?)   
     {
       $Data::Generate::current->bind_actual_vcol();  
       1;
      }

     vcint_lit_term:    /\d+/    
     {
          push(@{$Data::Generate::current->
                         {actual_vcol}->{value_term_list}},($item[1]+0));  
     }

     vcint_card: '{' /\d+/ '}' 
     {
         $Data::Generate::current->{actual_vcol}->{quantifier}=$item[2];
         1;
      }

#------------------------------------------------------------------------------#
#                           FLOAT TYPE GRAMMATICS                              #
#------------------------------------------------------------------------------#

     float_type: ct_float vch_float_list

     ct_float: /FLOAT/  '('   /\d+/  ')'
     {
         $Data::Generate::current->{chain_type}='FLOAT';
         $Data::Generate::current->{ct_length}=$item[3];
      }
      
      vch_float_list: <leftop: vch_float /\|/ vch_float > 
       


     vch_float:   vchfloat_filelist    
     | vcol_float_int_part vcol_float_fraction vcol_float_exponent(?) vchain_weigth(?)    
       {       
         $Data::Generate::current->{actual_vchain}
                       ->{chain_subtype}='FLOATTOTAL';
         $Data::Generate::current->bind_actual_vchain();
         1; } 
 

     vchfloat_filelist: /\<\S+\>/   
     {
       $Data::Generate::current->{actual_vchain}
                     ->{chain_subtype}='FLOATLIST';
         (my $file)= ($item[1] =~ /\<(\S+)\>/);   
         $Data::Generate::current->vcol_file_process($file);
          $Data::Generate::current->bind_actual_vcol();
          $Data::Generate::current->bind_actual_vchain();
         1;
      }



     vcol_float_int_part: vchi_sign(?) vcol_int(s)    
     {       
       $Data::Generate::current->{actual_vchain}
                     ->{chain_subtype}='FLOATINTPART';
         $Data::Generate::current->bind_actual_vchain();
       1; } 


     vcol_float_exponent: 'E'  vcfloat_exp_sign(?) vcfloat_exp_term     
     {       
       $Data::Generate::current->{actual_vchain}
                     ->{chain_subtype}='FLOATEXP';
         $Data::Generate::current->bind_actual_vchain();
       1; } 


     vcfloat_exp_sign:  /[+-]/ 
        {       
          $Data::Generate::current->{actual_vchain}->{sign}->{$item[1]}++;
         1; }


     vcfloat_exp_term:   vcfloatexp_lit_term    
     {
       $Data::Generate::current->bind_actual_vcol();  
       1;
     }

     vcfloatexp_lit_term:    /\d+/    
     {
          push(@{$Data::Generate::current->
                         {actual_vcol}->{value_term_list}},($item[1]+0));  
          1;
     }

     vcol_float_fraction: '.' vcol_fraction     
     {
       $Data::Generate::current->{actual_vchain}
                     ->{chain_subtype}='FLOATFRACTION';
         $Data::Generate::current->bind_actual_vchain();
       1;
     }


#------------------------------------------------------------------------------#
#                            DATE TYPE GRAMMATICS                              #
#------------------------------------------------------------------------------#

     date_type: ct_date  ct_date_precision(?) vch_date_list  

     ct_date: /(DT|DATE)/  
     {
         $Data::Generate::current->{chain_type}='DATE';
         $Data::Generate::current->{ct_length}=17;
      }

     ct_date_precision: '(' /\d+/ ')' 
     {
         $Data::Generate::current->{ct_precision}=$item[2];
         if ($Data::Generate::current->{ct_precision}>14)
         {
          warn " maximal precision for fraction of seconds is 14 \n".
           "Current Value: $Data::Generate::current->{ct_precision} is too high"
           .",will use precision 14.";
          $Data::Generate::current->{ct_precision}=14;
         }

         $Data::Generate::current->{ct_length}+=
           $Data::Generate::current->{ct_precision}+1; # +1 because of dot sign
      }



     vch_date_list: <leftop: vch_date /\|/ vch_date > 

     vch_date:  vcol_year vcol_month vcol_day vcol_time(?) vchain_weigth(?)
     {       
          $Data::Generate::current->bind_actual_vchain();
       1; } 
     | vchdate_filelist


     vchdate_filelist: /\<\S+\>/   
     {
         (my $file)= ($item[1] =~ /\<(\S+)\>/);   
         $Data::Generate::current->vcol_file_process($file);
          $Data::Generate::current->bind_actual_vcol();
          $Data::Generate::current->bind_actual_vchain();
         1;
      }


     vcol_time:   vcol_hour ':' vcol_min ':' vcol_sec  vcol_date_fraction(?)

     vcol_year:  vcdate_range    
                 { $Data::Generate::current->bind_vcol_range('year'); 1;}
               | vcdate_literal 
                 { $Data::Generate::current->bind_vcol_literal('year'); 1;}

     vcol_month:  vcmonth_range    
                 { $Data::Generate::current->bind_vcol_range('month'); 1;}
               |   vcmonth_literal   
           {
              my $litval=shift(@{$Data::Generate::current->{actual_vcol}->{month_literal_values}});
              $Data::Generate::current->{actual_vcol}->{literal_value}=$litval;
                     $Data::Generate::current->bind_vcol_literal('month'); 1;}

     vcol_day:  vcday_range    
                 { $Data::Generate::current->bind_vcol_range('day'); 1;}
               | vcdate_literal 
                 { $Data::Generate::current->bind_vcol_literal('day'); 1;}

     vcol_hour:  vcdate_range    
                 { $Data::Generate::current->bind_vcol_range('hour'); 1;}
               | vcdate_literal 
                 { $Data::Generate::current->bind_vcol_literal('hour'); 1;}

     vcol_min:  vcdate_range    
                 { $Data::Generate::current->bind_vcol_range('minute'); 1;}
               | vcdate_literal 
                 { $Data::Generate::current->bind_vcol_literal('minute'); 1;}

     vcol_sec:  vcdate_range    
                 { $Data::Generate::current->bind_vcol_range('sec'); 1;}
               | vcdate_literal 
                 { $Data::Generate::current->bind_vcol_literal('sec'); 1;}

     vcol_date_fraction:  '.' vcol_fraction    
     {
       $Data::Generate::current->{actual_vchain}
                     ->{chain_subtype}='DATEWITHFRACTION';
     1;
     }

     vcdate_literal:    /\d+/    
     {
       $Data::Generate::current->{actual_vcol}->{literal_value}=$item[1];
     1;
     }

     
     vcdate_range:  /\[/   <leftop: vcdate_term /\,/ vcdate_term >   /\]/

     vcdate_term:  /\d+/ '-' /\d+/ 
     { $Data::Generate::current->add_term_range($item[1],$item[3]);1; }
     | /\d+/ 
     { 
         push(@{$Data::Generate::current->{actual_vcol}->{value_term_list}},
            $item[1]); 1; 
     } 


     vcday_range:   /\[/   <leftop: vcday_term /\,/ vcday_term >     /\]/
     
     vcday_term:  vcdate_term
     | <leftop: vcday_literal /\-/ vcday_literal > 
     { 
       my $low =shift(@{$Data::Generate::current->{actual_vcol}->{weekday_index_values}});
       my $high =shift(@{$Data::Generate::current->{actual_vcol}->{weekday_index_values}});
         push(@{$Data::Generate::current->{actual_vcol}->{weekday_term_list}},
            $low) unless defined $high; 
         $Data::Generate::current-> add_weekday_term_range($low,$high)
            if defined $high;
         1; 
     }


     vcday_literal:  /[a-zA-Z]+/    
     {
       my  @week=@{$Data::Generate::vcol_type->{weekday}->{term_list}};
       my $ix=-1;
       foreach my $wday_ix (0..$#week)
       {
         $ix=$wday_ix if $item[1] =~ /^$week[$wday_ix]/i;   
       }    
       die "cant process day term $item[1] "  if $ix==-1;
       push(@{$Data::Generate::current->{actual_vcol}->{weekday_index_values}}
                 ,$ix);
       1;
     }

     vcmonth_range: /\[/   <leftop: vcmonth_term /\,/ vcmonth_term > /\]/

     vcmonth_term:   <leftop: vcmonth_literal /\-/ vcmonth_literal > 
     { 
       my $low =shift(@{$Data::Generate::current->{actual_vcol}->{month_literal_values}});
       my $high =shift(@{$Data::Generate::current->{actual_vcol}->{month_literal_values}});
         push(@{$Data::Generate::current->{actual_vcol}->{value_term_list}},
            $low) unless defined $high; 
         $Data::Generate::current->add_term_range($low,$high)
            if defined $high;
         1; 
     }

     vcmonth_literal:   /(\d+|[a-zA-Z]+)/      
     {
       my $month=undef;
       if ($item[1] =~ /\d+/)
       {  
         $month =$item[1]; 
       }
       else
       { 
         (undef,undef,undef,undef,$month,undef,undef) = Date::Parse::strptime($item[1].' 01');
         die "Month $item[2] invalid " unless defined $month;
         ++$month;
       }
       push(@{$Data::Generate::current->{actual_vcol}->{month_literal_values}}
                 ,$month);
       1;
     }

#------------------------------------------------------------------------------#
#                     FRACTION SUBTYPE GRAMMATICS                              #
#                     (RELEVANT FOR DATE AND FLOAT)                            #
#------------------------------------------------------------------------------#

     vcol_fraction:  vcol_fract(s)    

     vcol_fract:  vcfract_range 
                   | vcfract_literal 

     vcfract_range:  /\[/ <leftop: vcfract_term /\,/ vcfract_term > /\]/ vcfract_card(?)
     {    
       $Data::Generate::current->bind_actual_vcol();  
      1;}


     vcfract_term:  /\d+/ '-' /\d+/   
                  {
                       my @cmp = (($item[1]+0)..($item[3]+0));    
                     push(@{$Data::Generate::current->
                                      {actual_vcol}->{value_term_list}},@cmp);
                      }
                  | vcfract_lit_term 

     vcfract_literal:  vcfract_lit_term  vcfract_card(?)   
     {
       $Data::Generate::current->bind_actual_vcol();  
       1;
      }

     vcfract_lit_term:    /\d+/    
     {
          push(@{$Data::Generate::current->
                         {actual_vcol}->{value_term_list}},($item[1]+0));  
     }

     vcfract_card: '{' /\d+/ '}' 
     {
         $Data::Generate::current->{actual_vcol}->{quantifier}=$item[2];
         1;
      }
};
#------------------------------------------------------------------------------#
#                            END OF GRAMMATICS                                 #
#------------------------------------------------------------------------------#

   my $parser = Parse::RecDescent->new($grammar);
   defined $parser or carp "couldn't load parser";
   return $parser;

}


################################################################################
# Description: helper function
################################################################################
sub check_reverse_flag 
{
    my $self =shift;
    return unless exists $self->{actual_vcol}->{reverse_flag};
    $self->{actual_vcol}->{value_term_list}= 
       $self->get_value_column_reverse($self->{actual_vcol}->{value_term_list});
    delete $self->{actual_vcol}->{reverse_flag};
}

################################################################################
# Description: helper function
################################################################################
sub check_range_order ($$)
{
    my $min =shift;
    my $max =shift;
    if ($min >$max )  
    {
     carp "false range order, $min > $max". 
          " will invert limits";
     return [$max, $min];
    }
    return [$min, $max];
}

################################################################################
# sub vcol_file_process
# Description: read vcol_terms from file   
# 
################################################################################
sub vcol_file_process
{
    my $self =shift;
    my $file =shift;
    open(VCOLFILE,$file) or carp "Couldnt open term file $file ";
    my @cmp = (<VCOLFILE>);         
    close(VCOLFILE);
    @cmp=('') if $#cmp==-1;
    map(chomp($_),@cmp);
    if (exists $Data::Generate::vchain_type->{$self->{chain_type}} 
    && exists $Data::Generate::vchain_type->{$self->{chain_type}}->{check_type}
    )
    {
      my @cmp2=();      
      foreach my $element (@cmp)
      {          
        my $result=
          &{$Data::Generate::vchain_type->{$self->{chain_type}}->{check_type}}
                  ($element);
        push(@cmp2,$result) if defined $result;
      }
      @cmp=@cmp2;
    };
    my $uniq={};
    map($uniq->{$_}++,@cmp);
    @cmp=(keys %$uniq);
    push(@{$self->{actual_vcol}->{value_term_list}},@cmp); 
}




################################################################################
# sub vcol_date_process
# Description: processing action for dates.
# At the end of each date production the three vcol date types year month day
# will be merged to a single one, so that date validity can be assessed,
# therefore instead of normally adding the date columns year and month, 
# we keep them aside until the day column is processed.
# 
################################################################################
sub vcol_date_process 
{
    my $self =shift;
    if ($self->{actual_vcol}->{type} =~ /^(month|year)$/ )
    {
      my $type=$self->{actual_vcol}->{type};
      $type.='_vcol';
      $self->{$type} = $self->{actual_vcol};
      return;
    }
    die "internal eror" if ($self->{actual_vcol}->{type} ne 'day' );
    $self->{day_vcol} = $self->{actual_vcol};
    $self->{actual_vcol}={};
    my @value_term_list=();
    my $weekdays={};
    if (exists $self->{day_vcol}->{weekday_term_list})
    {
      foreach my $day_term (@{$self->{day_vcol}->{weekday_term_list}})
      {
        $weekdays->{$day_term}++  
      }
    }
    foreach my $year_term (@{$self->{year_vcol}->{value_term_list}})
    {
      foreach my $month_term (@{$self->{month_vcol}->{value_term_list}})
      {      
         my $monthdays={};
         foreach my $day_term (@{$self->{day_vcol}->{value_term_list}})
         {
          # convert 'char dates in numeric ones like '07'-> 7 
          # otherwise we cannot make unique value set   
          $day_term+=0;
          $monthdays->{$day_term}++      
         }
         my $first_month_weekday=dayofweek( 01,$month_term, $year_term );
         foreach my $wkday_term (keys %{$weekdays})
         {
            my $day_term=$wkday_term-$first_month_weekday+1;
            $day_term+=7 if $day_term<1;
            while ($day_term<31)
            {
              $monthdays->{$day_term}++;
              $day_term+=7;     
            } 
         }
         foreach my $day_term (keys %{$monthdays})
         {
           my $date_term =
                  sprintf('%04d%02d%02d',$year_term, $month_term, $day_term);  
           push(@value_term_list,$date_term) 
                         if defined str2time($date_term);
         }        
      }
    }
    @value_term_list=sort(@value_term_list);
    $self->{actual_vcol}->{value_term_list}=\@value_term_list;

    $self->add_value_column($self->{actual_vcol}->{value_term_list});
    delete $self->{year_vcol};
    delete $self->{month_vcol};
    delete $self->{day_vcol};

}


################################################################################
# sub vchain_date_fraction_process
# Description: reorganizes the internal vchain structure of date types with 
# fraction  values due to the possible presence of trailing zeros.
################################################################################
sub vchain_date_fraction_process 
{
    
    my $self =shift;    
    my $vchain_full=$self->{actual_vchain};
    $self->reset_actual_vchain();

    my $vchain_fraction={};
    $vchain_fraction->{vcol_count}=$vchain_full->{vcol_count};
    map($vchain_fraction->{vcol_hash}->{$_}->{value_column}=
             $vchain_full->{vcol_hash}->{$_}->{value_column},
            (0..$vchain_fraction->{vcol_count}));


    my $fraction_start=
         $Data::Generate::vchain_type->{DATE}->{subtype}->{'DATEWITHFRACTION'}
           ->{fraction_start_ix}; 
    map_vchain_indexes($vchain_fraction,
    sub {  return undef if $_[0] <$fraction_start; 
           return $vchain_fraction->{vcol_count}-$_[0];
        }
    );     
    $vchain_fraction->{vcol_count}=$vchain_full->{vcol_count}-
       $fraction_start;

    my $vchain_data={};
    $vchain_data->{weigth}=$vchain_full->{weigth};
    my $vchain_weigth_list=$self->vchain_number_reprocess($vchain_fraction);

    foreach my $vchain (@$vchain_weigth_list)
    {
      $vchain->{vcol_count}+=$fraction_start;
      map_vchain_indexes($vchain,
      sub {  return $vchain->{vcol_count}-$_[0];
         }
      );     
      map($vchain->{vcol_hash}->{$_}->{value_column}=
             $vchain_full->{vcol_hash}->{$_}->{value_column},
            (0..$fraction_start-1));
    }

    # weigth has to be recalculated now.
    calculate_vchain_list_weigth($vchain_weigth_list,$vchain_data->{weigth});


1;
}


################################################################################
# sub vchain_fraction_process
# Description: reorganizes the internal vchain structure of a fractional 
# vchain part due to the possible presence of trailing zeros.
################################################################################
sub vchain_fraction_process 
{
    
    my $self =shift;    
    my $vchain_fraction =$self->{actual_vchain};
    $self->reset_actual_vchain();
    map_vchain_indexes($vchain_fraction,
    sub {  
           return $vchain_fraction->{vcol_count}-$_[0];
        }
    );     
    my $vchain_data={};
    $vchain_data->{weigth}=$vchain_fraction->{weigth};
    my $vchain_weigth_list=$self->vchain_number_reprocess($vchain_fraction);

    foreach my $vchain (@$vchain_weigth_list)
    {
      map_vchain_indexes($vchain,
      sub {  return $vchain->{vcol_count}-$_[0];
         }
      );     
    }
    return $vchain_weigth_list;


1;
}


################################################################################
# sub merge_vchain_float_lists
# Description: merge int and float vchain lists together.(and add a '.' inbet.)
################################################################################
sub merge_vchain_float_lists 
{
    my $self =shift;
    my $vchain_sign_list =shift;    
    my $vchain_integer_list =shift;    
    my $vchain_float_list =shift;    
    my $vchain_exp_list =shift;    
    my $vchain_merge_list =[];
    my $vchain_zero =undef;
    foreach my $vchain_integer (@$vchain_integer_list)
    {
        map_vchain_indexes($vchain_integer, sub {  return 1+$_[0] ;});     
        $vchain_integer->{vcol_hash}->{0}->{value_column}=$vchain_sign_list;
        $vchain_integer->{vcol_count}++;
    }
    if (@$vchain_exp_list ==0)
    {
        my $vchain_exp={}; 
        $vchain_exp->{vcol_hash}->{0}->{value_column}=['0'];
        $vchain_exp->{vcol_count}++;
        push(@$vchain_exp_list,$vchain_exp);  
    }
    foreach my $vchain_exp (@$vchain_exp_list)
    {
        map_vchain_indexes($vchain_exp, sub {  return 1+$_[0] ;});     
        $vchain_exp->{vcol_hash}->{0}->{value_column}=['E'];
        $vchain_exp->{vcol_count}++;
    }
    my $vchain_exp = $vchain_exp_list->[0];
    foreach my $vchain_integer (@$vchain_integer_list)
    {
      foreach my $vchain_float (@$vchain_float_list)
      {
      foreach my $vchain_exp (@$vchain_exp_list)
      {
        my $vchain_merged={};
        $vchain_merged->{vcol_count}=$vchain_integer->{vcol_count};
        map($vchain_merged->{vcol_hash}->{$_}->{value_column}=
             $vchain_integer->{vcol_hash}->{$_}->{value_column},
            (0..$vchain_integer->{vcol_count}));
        $vchain_merged->{vcol_count}++;
        $vchain_merged->{vcol_hash}->{$vchain_merged->{vcol_count}}->{value_column}=['.'];

        map($vchain_merged->{vcol_hash}->{$vchain_merged->{vcol_count}+1+$_}
             ->{value_column}=$vchain_float->{vcol_hash}->{$_}->{value_column},
            (0..$vchain_float->{vcol_count}));
        $vchain_merged->{vcol_count}+=$vchain_float->{vcol_count}+1;


        # avoid double +/-0.0 , skip exp processing
            if (($#{$vchain_merged->{vcol_hash}->{1}->{value_column}}==0)
             && ($vchain_merged->{vcol_hash}->{1}->{value_column}->[0]==0)
             && ($#{$vchain_merged->{vcol_hash}->{2}->{value_column}}==0)
             && ($vchain_merged->{vcol_hash}->{2}->{value_column}->[0] eq '.')
             && ($#{$vchain_merged->{vcol_hash}->{3}->{value_column}}==0)
             && ($vchain_merged->{vcol_hash}->{3}->{value_column}->[0]==0)
             && ($vchain_merged->{vcol_count}==3)
            )
        {
          next if defined $vchain_zero;
          $vchain_merged->{vcol_hash}->{0}->{value_column}=['+'];
          $self->bind_vchain($vchain_merged);
          push(@$vchain_merge_list,$vchain_merged);
          $vchain_zero=$vchain_merged;
          next;
        }



        map($vchain_merged->{vcol_hash}->{$vchain_merged->{vcol_count}+1+$_}
             ->{value_column}=$vchain_exp->{vcol_hash}->{$_}->{value_column},
            (0..$vchain_exp->{vcol_count}));
        $vchain_merged->{vcol_count}+=$vchain_exp->{vcol_count}+1;
        
        $self->bind_vchain($vchain_merged);
        push(@$vchain_merge_list,$vchain_merged);
        
      }
      }
    }
    return $vchain_merge_list;

1;
}




################################################################################
# sub vchain_date_fraction_process
# Description: reorganizes the internal vchain structure of date types with 
# fraction  values due to the possible presence of trailing zeros.
################################################################################
sub vchain_float_process 
{    
    my $self =shift;
    if ($self->{actual_vchain}->{chain_subtype} eq 'FLOATLIST'  )
    {
      $self->bind_vchain($self->{actual_vchain});
      $self->reset_actual_vchain();
      return;  
    }

    if ($self->{actual_vchain}->{chain_subtype} eq 'FLOATINTPART'  )
    {
      $self->{FLOAT_CHAIN_START}=1+$#{$self->{vchain_array}};      
      $self->{FLOAT_CHAIN_SIGN}=[];      
      push (@{$self->{FLOAT_CHAIN_SIGN}},'+')  
        if (! exists $self->{actual_vchain}->{sign} 
             || exists $self->{actual_vchain}->{sign}->{'+'} ); 
      push (@{$self->{FLOAT_CHAIN_SIGN}},'-')  
        if ( exists $self->{actual_vchain}->{sign} 
             && exists $self->{actual_vchain}->{sign}->{'-'} ); 

      my $actual_vchain= $self->{actual_vchain};
      $self->reset_actual_vchain();
      $self->{FLOAT_INTEGER_PART}=$self->vchain_number_reprocess($actual_vchain);      
      return;  

    }



    if ($self->{actual_vchain}->{chain_subtype} eq 'FLOATFRACTION'  )
    {
      $self->{FLOAT_FRACTION_PART}=$self->vchain_fraction_process(); 
      my $actual_vchain= $self->{actual_vchain};
      $self->reset_actual_vchain();
      return;  
    }
    if ($self->{actual_vchain}->{chain_subtype} eq 'FLOATEXP'  )
    {
      $self->{FLOAT_EXP_PART}=$self->vchain_integer_process();      
      return;  
    }





    croak "Error in float parsing $self->{actual_vchain}->{chain_subtype} "
            unless $self->{actual_vchain}->{chain_subtype} eq 'FLOATTOTAL';
#      print "*********************".$self->{actual_vchain}->{weigth}."\n";   
      $self->{FLOAT_CHAIN_WEIGTH}=$self->{actual_vchain}->{weigth};   

    unless (exists $self->{FLOAT_EXP_PART})
    {
      $self->{actual_vchain}->{chain_subtype}= 'FLOATEXP';
      push(@{$self->{actual_vcol}->{value_term_list}},0);  
      $self->bind_actual_vcol();  
      $self->{FLOAT_EXP_PART}=$self->vchain_integer_process();      
      $self->{zzzzFLOAT_EXP_PART}=$self->{FLOAT_EXP_PART};      
    }

    foreach my $vchain_id ($self->{FLOAT_CHAIN_START}..$#{$self->{vchain_array}})
    {
      delete  $self->{vchain_hash}->{$vchain_id};
      pop(@{$self->{vchain_array}});  
    }
      my $merge_list=$self->merge_vchain_float_lists($self->{FLOAT_CHAIN_SIGN},
               $self->{FLOAT_INTEGER_PART},
               $self->{FLOAT_FRACTION_PART},
               $self->{FLOAT_EXP_PART});     
      calculate_vchain_list_weigth($merge_list,$self->{FLOAT_CHAIN_WEIGTH});
      delete  $self->{FLOAT_CHAIN_START};
      delete  $self->{FLOAT_CHAIN_SIGN};
      delete  $self->{FLOAT_CHAIN_WEIGTH};
      delete  $self->{FLOAT_INTEGER_PART};
      delete  $self->{FLOAT_FRACTION_PART};
      delete  $self->{FLOAT_EXP_PART};

1;
}



################################################################################
# sub vchain_integer_process
# Description: reorganizes the internal vchain structure of integer types.
# due to the possible presence of leading zeros.
################################################################################
#   INT (9) +/- [3,0] [21,3,0] [4,0]
#   
#  + 0 0  4 -> converted to  + 0  | + 3 0  4 | + 21 4| + 4        
#  - 3 21 0                       | -   21 0 | -  3 0| -      
#      3                          |     3    |       |        
#                                 |          |       |        
# 
# degr of freedom = 1 + 12 + 8 + 2 = 23
# -210','-214','-30','-300','-304','-3210','-3214','-330','-334','-34','-4','0','210','214','30','300',
# '304','3210','3214
sub vchain_integer_process 
{
    
    my $self =shift;    
    my $last_vchain=$self->{actual_vchain};
    $self->reset_actual_vchain();
    my $vchain_data={};
    $vchain_data->{weigth}=$last_vchain->{weigth};

    push (@{$vchain_data->{sign}},'+')  
      if (! exists $last_vchain->{sign} || exists $last_vchain->{sign}->{'+'} ); 
    push (@{$vchain_data->{sign}},'-')  
      if ( exists $last_vchain->{sign} && exists $last_vchain->{sign}->{'-'} ); 
    delete $last_vchain->{sign};
    my $vchain_weigth_list=$self->vchain_number_reprocess($last_vchain);

    foreach my $vchain (@$vchain_weigth_list)
    {
       next if $vchain->{vcol_count}==0 
         && @{$vchain->{vcol_hash}->{0}->{value_column}}==1
         && $vchain->{vcol_hash}->{0}->{value_column}->[0]==0;
       map_vchain_indexes($vchain,sub {  return 1+$_[0];});     
       $vchain->{vcol_count}++;         
       @{$vchain->{vcol_hash}->{0}->{value_column}}=@{$vchain_data->{sign}};   
    }
    # weigth has to be recalculated now.
    calculate_vchain_list_weigth($vchain_weigth_list,$vchain_data->{weigth});
    return $vchain_weigth_list;
}



################################################################################
# sub vchain_number_reprocess
# Description: reorganizes the internal vchain structure of numeric types.
# Due to the possible presence of leading or trailing zeros, we have to 
# restructure the vcols in vchains to avoid duplicates (001, 01 problem).   
# Other solutions are either too memory intensive (build the output values at  
# vchain binding) or lead to incorrect cardinality calculation (eliminate 
# duplicates at output data production);
################################################################################
#   INT (9) +/- [3,0] [21,3,0] [4,0]
#   
#  + 0 0  4 -> converted to  + 0  | + 3 0  4 | + 21 4| + 4        
#  - 3 21 0                       | -   21 0 | -  3 0| -      
#      3                          |     3    |       |        
#                                 |          |       |        
# 
# degr of freedom = 1 + 12 + 8 + 2 = 23
# -210','-214','-30','-300','-304','-3210','-3214','-330','-334','-34','-4','0','210','214','30','300',
# '304','3210','3214','330','334','34','4
sub vchain_number_reprocess 
{
    my $self =shift;    
    my $last_vchain =shift;    
    
    my $vcol_nonzero_list=[];
    my $vcol_zero_list=[];
    my $vchain_weigth_list=[];
    
    while($last_vchain->{vcol_count}>=0)
    {
      my $vcol_list=
           $last_vchain->{vcol_hash}->{0}->{value_column};
    
      $vcol_nonzero_list=[];
      $vcol_zero_list=[];
      foreach my $vcol_value (@$vcol_list)
      {
        push (@$vcol_nonzero_list,$vcol_value) unless $vcol_value =~ /^0+$/;     
        push (@$vcol_zero_list,$vcol_value) if $vcol_value =~ /^0+$/;     
      }
      if(@$vcol_nonzero_list >0)
      {
        $last_vchain->{vcol_hash}->{0}->{value_column}
              =$vcol_nonzero_list;
        $self->bind_vchain($last_vchain);
        push(@$vchain_weigth_list,$self->{vchain_hash}
             ->{$#{$self->{vchain_array}}});               
      }
      last unless(@$vcol_zero_list>0);
      my $next_vchain={};
      $next_vchain->{vcol_count}=$last_vchain->{vcol_count};
      map($next_vchain->{vcol_hash}->{$_}->{value_column}=
             $last_vchain->{vcol_hash}->{$_}->{value_column},
            (0..$last_vchain->{vcol_count}));
      map_vchain_indexes($next_vchain,sub {  
          return undef if $_[0]==0; 
          return $_[0]-1;
          });     
      $next_vchain->{vcol_count}--;
      $last_vchain=$next_vchain;
    }  
      if (@$vcol_zero_list>0)
      {
        # add now 0 chain in place  of +/-
        $last_vchain->{vcol_hash}->{0}->{value_column}=[0];
       $last_vchain->{vcol_count}++;         
        $self->bind_vchain($last_vchain);
        push(@$vchain_weigth_list,$self->{vchain_hash}
             ->{$#{$self->{vchain_array}}});               
      }
      return $vchain_weigth_list;
}

################################################################################
# Description: helper function. Calculate weigth for a group of vchains
################################################################################
sub calculate_vchain_list_weigth 
{
    my $vchain_list =shift; 
    my $weigth      =shift;
    my $card=
       calculate_vchain_list_degrees_of_freedom($vchain_list);    
    map($_->{weigth}=$weigth,@$vchain_list);
    map($_->{weigth}*=$_->{vchain_card},@$vchain_list);
    map($_->{weigth}/=$card,@$vchain_list);
}

################################################################################
# Description: helper function.Change internal vcol indexes of a vchain 
################################################################################
sub map_vchain_indexes 
{
    my $vchain =shift; 
    my $change_function =shift;
    foreach my $index (0..$vchain->{vcol_count})
    { 
      my $new_index=&$change_function($index);  
      next unless defined $new_index;
      $vchain->{vcol_hash_tmp}->{$new_index}->{value_column}=
             $vchain->{vcol_hash}->{$index}->{value_column};
    }
    $vchain->{vcol_hash}=$vchain->{vcol_hash_tmp};
    delete $vchain->{vcol_hash_tmp};
}


################################################################################
# Description: helper function
################################################################################
sub check_input_limits 
{
    my $type =shift;
    my $value =shift; 
    
    # no type defined, no ranges to check
    return unless defined $type;
    return unless exists $Data::Generate::vcol_type->{$type};

    my $limit_check_hash=$Data::Generate::vcol_type->{$type};
    if ((exists $limit_check_hash->{lowlimit}) &&
        (defined $limit_check_hash->{lowlimit}))  
    {
      croak " $limit_check_hash->{type} went out of range,". 
             " $value < $limit_check_hash->{lowlimit} "
        if $value < $limit_check_hash->{lowlimit};
    }
    if ((exists $limit_check_hash->{highlimit}) &&
        (defined $limit_check_hash->{highlimit}))  
    {
      croak " $limit_check_hash->{type} went out of range,". 
             " $value > $limit_check_hash->{highlimit} "
        if $value > $limit_check_hash->{highlimit};
    }
}


################################################################################
# sub # vcol_add_term_range 
# Description:
# add an expression (a..b) after parsing 
################################################################################
sub add_weekday_term_range 
{
    my $self =shift;
    my $min =shift;
    my $max =shift;
    my $act_vcol=$self->{actual_vcol};
    if ($min>$max)
    {
      # index 6 is sunday  
      push(@{$self->{actual_vcol}->{weekday_term_list}},($min..6));
      # index 0 is monday      
      push(@{$self->{actual_vcol}->{weekday_term_list}},(0..$max));
      return;    
    }
    push(@{$self->{actual_vcol}->{weekday_term_list}},($min..$max));
}


################################################################################
# sub # vcol_add_term_range 
# Description:
# add an expression (a..b) after parsing 
################################################################################
sub add_term_range 
{
    my $self =shift;
    my $min =shift;
    my $max =shift;
    my $minmax=check_range_order($min,$max);
    my $act_vcol=$self->{actual_vcol};
    push(@{$self->{actual_vcol}->{value_term_list}},
      ($minmax->[0]..$minmax->[1]));
}


################################################################################
# sub # add_value_column_range 
# Description:
# add an expression (a..b) after parsing 
################################################################################
sub bind_vcol_range 
{
    my $self =shift;
    my $type =shift;
    my $act_vcol=$self->{actual_vcol};
    foreach my $value (@{$self->{actual_vcol}->{value_term_list}})
    {
      check_input_limits($type,$value);
    }
    $act_vcol->{type}=$type;
    $self->bind_actual_vcol();  
}



################################################################################
# sub # add_value_column_range 
# Description:
# add an expression (a..b) after parsing 
################################################################################
sub bind_vcol_literal 
{
    my $self =shift;
    my $type =shift;
    my $act_vcol=$self->{actual_vcol};
    check_input_limits($type,$self->{actual_vcol}->{literal_value});
    $self->{actual_vcol}->{value_term_list}=
      [$act_vcol->{literal_value}];
    $act_vcol->{type}=$type;
    $self->bind_actual_vcol();  
}


################################################################################
# sub # sub set_actual_vchain_weigth
# Description:
# add weigth to actual value chain 
################################################################################
sub reset_actual_vchain 
{
    my $self =shift;
    $self->{actual_vchain} = {};
    $self->{actual_vchain}->{vchain_length} = 0; 
    $self->{actual_vchain}->{weigth}=100;
}

################################################################################
# sub bind_actual_vcol
# Description: Postprocessing action.
# At the end of each value column  production, add actual value column to the 
# actual vchain. Afterwards reset actual_vcol to an empty hash
# 
################################################################################
sub bind_actual_vcol 
{
    my $self =shift;
    my $quantifier=1;
    $quantifier=$self->{actual_vcol}->{quantifier}
       if exists $self->{actual_vcol}->{quantifier};
    

    if ((defined $self->{actual_vcol}->{type} ) && 
        ($self->{actual_vcol}->{type} =~ /^(day|month|year)$/ ))
    {
      $self->vcol_date_process();
    }
    elsif ((defined $self->{actual_vcol}->{type} ) && 
        ($self->{actual_vcol}->{type} eq 'sign' ))
    {
      $self->{sign_value_list}=$self->{actual_vcol}->{value_term_list};
      $self->reset_actual_vcol();
    }
    else
    { 
      $self->add_value_column($self->{actual_vcol}->{value_term_list})
           foreach(1..$quantifier);
    }
    $self->{actual_vcol} = {}; 
    $self->{actual_vcol}->{type} = undef; 
}

sub reset_actual_vcol 
{
    my $self =shift;
    $self->{actual_vcol} = {}; 
    $self->{actual_vcol}->{type} = undef; 
}


################################################################################
# Description: helper function. add vchain to generator object
################################################################################
sub bind_vchain 
{
    my $self =shift;
    my $vchain =shift;
    push(@{$self->{vchain_array}},$vchain);
    $self->{vchain_hash}
         ->{$#{$self->{vchain_array}}}=$vchain;
}


################################################################################
# sub bind_actual_vchain
# Description: Postprocessing action.
# At the end of each chain production, add actual value chain to the chain list 
# root structure, and afterwards reset actual_vchain to an empty hash
# 
################################################################################
sub bind_actual_vchain 
{
    my $self =shift;
    if ($self->{chain_type} eq 'INTEGER')
    {
      $self->vchain_integer_process();
      return;    
    }
    if ((exists $self->{actual_vchain}->{chain_subtype})
       && ($self->{actual_vchain}->{chain_subtype} eq 'DATEWITHFRACTION'))
    {
      $self->vchain_date_fraction_process();
      return;    
    }
    if ($self->{chain_type} eq 'FLOAT')  
    {
      $self->vchain_float_process();
      return;    
    }
    $self->bind_vchain($self->{actual_vchain});
    $self->reset_actual_vchain();
}

################################################################################
# sub add_value_column
# Description:
# add array of terms.
# 
################################################################################
sub add_value_column 
{
    my $self = shift;
    my $tmp_value_column = shift;
    my $value_column = [];
    my $vcol_maxlength=0;
    my $ix=0;
    my $unique={};
    foreach my $value_term (@{$tmp_value_column})
    { 
       my $vterm_length=length($value_term);
       if (exists $self->{ct_length} && defined $self->{ct_length} &&
           $self->{actual_vchain}->{vchain_length}+ $vterm_length>$self->{ct_length})
       {
           carp "Maximal length for type $self->{chain_type}($self->{ct_length}) "
             ."exceeded for \n$self->{vchain_text}\n"
             ."Element \'$value_term\' will be removed from output structures.\n"  
             ."Please check your data creation rules\n"; 
           next;
       }
       elsif ($unique->{$value_term}++>0)
       {
           carp "Duplicate entry \'$value_term\' found while building up internal structures.\n"
             ."Element \'$value_term\' will be removed from output structures.\n"  
             ."Please check your data creation rules\n"; 
           next;
       }
       else
       {       
         push(@{$value_column},$value_term);
         $vcol_maxlength =($vterm_length>$vcol_maxlength?$vterm_length:$vcol_maxlength);
         $ix++;
       }
    };
    $self->{actual_vchain}->{vchain_length}+=$vcol_maxlength;
    if ($#{$value_column}==-1)
    {
           return 1;   
    }

    if (exists $self->{actual_vchain}->{vcol_count})
    {  
        
        $self->{actual_vchain}->{vcol_count}++
    }
    else
    {$self->{actual_vchain}->{vcol_count}=0}
    
    $self->{actual_vchain}->{vcol_hash}->{$self->{actual_vchain}->{vcol_count}}->{value_column} = $value_column; 
}



################################################################################
# sub get_value_column_reverse
# Description: fill array in place with complementary  ascii chars  
# 
################################################################################
sub get_value_column_reverse {
    my $self = shift;
    my $value_column = shift;
    my @complement = map(chr,(0..255));
    my $hash={};
    $hash->{$_}++ foreach (@{$value_column});
    $value_column=[];
    foreach (@complement)
    {
     push(@$value_column,$_) unless  $hash->{$_};
    }
    return $value_column;
}


################################################################################
# sub get_occupation_ratio
# Description:
# Based on input cardinality and degrees of freedom calculate
# the ratio of array elements to give / total number of elements
# 
################################################################################
sub set_occupation_ratio 
{
    my $self = shift;
    foreach my $actual_vchain (@{$self->{vchain_array}})
    {  
      my $occupation_ratio = 0;
        $occupation_ratio =
          log($actual_vchain->{data_card}/$actual_vchain->{vchain_card})
          /  ($actual_vchain->{vcol_count}+1);
          $occupation_ratio =exp($occupation_ratio);
        $actual_vchain->{vchain_occupation_ratio}= $occupation_ratio;
    }
}



################################################################################
# sub calculate_occupation_levels
# Description:
# based on input cardinality calculate occupation levels.
# 
################################################################################
sub calculate_occupation_levels 
{
    my $self = shift;
    my $data_card = shift;
    $self->check_input_card($data_card);
    $self->set_occupation_ratio();
    foreach my $actual_vchain (@{$self->{vchain_array}})
    {  
      my $vchain_occupation_ratio =$actual_vchain->{vchain_occupation_ratio};
      foreach (values %{$actual_vchain->{vcol_hash}})
      {  
        my $vcol_degrees_of_freedom =$#{$_->{value_column}}+1;
        if ($vchain_occupation_ratio ==1)      
        { $_->{occupation_level} = $vcol_degrees_of_freedom  }
        else
        {
         $_->{occupation_level} = 
            int($vchain_occupation_ratio*$vcol_degrees_of_freedom)+1;
        }
      }  
    }  
    return ;
}


################################################################################
# sub get_degrees_of_freedom
# Description:
# get maximal cardinality 
#
################################################################################
sub get_degrees_of_freedom 
{
    my $self = shift;
    my $weigthed_card=undef;
    foreach my $vchain_ref (@{$self->{vchain_array}})
    {
      confess " weigth undefined " unless defined  $vchain_ref->{weigth} &&
                  defined $vchain_ref->{vchain_card};
      if ($vchain_ref->{weigth} >0.0001)
      {
          $vchain_ref->{weigthed_card}=$vchain_ref->{vchain_card}/
                 $vchain_ref->{weigth};      
      }
      else
      {
         $vchain_ref->{weigthed_card}=10000 
      }
      $vchain_ref->{weigthed_card}=1 if $vchain_ref->{weigthed_card}<1;  
      $weigthed_card = $vchain_ref->{weigthed_card}
         unless defined $weigthed_card;                        
      $weigthed_card = $vchain_ref->{weigthed_card}
         if  $weigthed_card   >  $vchain_ref->{weigthed_card} ;                        
    }	
    
    # workaround to handle integers numbers converted to float and back
    if ( int($weigthed_card)+1-$weigthed_card <1e-9)
    {
      return int($weigthed_card)+1;
    }
    return int($weigthed_card);
}




################################################################################
# sub calculate_vchain_list_degrees_of_freedom
# Description:
# calculate maximal cardinality for a vchain 
#
################################################################################
sub calculate_vchain_list_degrees_of_freedom 
{
    my $vchain_list = shift;
    my $card=0;
    foreach my $vchain_ref (@$vchain_list)
    {
      $vchain_ref->{vchain_card}=1;
      foreach my $vcol_ref (values %{$vchain_ref->{vcol_hash}})
      { $vchain_ref->{vchain_card}*=$#{$vcol_ref->{value_column}}+1 }
      $card+=$vchain_ref->{vchain_card};
    }
    return $card;
}


################################################################################
# sub calculate_degrees_of_freedom
# Description:
# calculate maximal cardinality of the generation rules
#
################################################################################
sub calculate_degrees_of_freedom 
{
    my $self = shift;
    $self->{card}=
       calculate_vchain_list_degrees_of_freedom($self->{vchain_array});
    return $self->{card};
}


################################################################################
# sub calculate_weigth
# Description:
# normalize weigth so that total is 100% 
#
################################################################################
sub calculate_weigth 
{
    my $self = shift;
    my $weigth=0.0;
    foreach  my $vchain_ref (@{$self->{vchain_array}})
    {
      $weigth+= $vchain_ref->{weigth}; 
    }
    foreach  my $vchain_ref (@{$self->{vchain_array}})
    {
      $vchain_ref->{weigth}/=$weigth 
    }
}


################################################################################
# sub check_input_card
# Description:
# ensures that degrees of freedom >= input_card
# generates a warning when input_card is bigger
# 
################################################################################
sub check_input_card 
{
    my $self = shift;
    my $data_card = shift;
    if ($data_card > $self->{card})
       {
         carp "Input card ".$data_card." too big, maximal nr of ".
          "values is $self->{card}.\nReturn only ".    
           $self->{card} ." values. \n";
           $data_card=$self->{card};
        }   

    foreach my $vchain_ref (@{$self->{vchain_array}})
    {
       $vchain_ref->{data_card}=$data_card; 
       $vchain_ref->{data_card}*=$vchain_ref->{weigth};
#       $vchain_ref->{data_card}=int($vchain_ref->{data_card}); 
#       $vchain_ref->{data_card}=1 if $vchain_ref->{data_card}==0; 
       if (int($vchain_ref->{data_card}) >$vchain_ref->{vchain_card})
       {
         carp "Either input card ".$data_card." too big or vchain weigth ".
          "$vchain_ref->{weigth} too high.\nShould produce  ".
          $vchain_ref->{data_card}." values, can't produce more than ".
           $vchain_ref->{vchain_card}." different values.\nReturn only ".    
           $vchain_ref->{vchain_card} ." values. \n";
           $vchain_ref->{data_card}=$vchain_ref->{vchain_card};
        }   
    }
}

################################################################################
# sub fisher_yates_shuffle
# Description: create a randomized array order. From Perl Cookbook
# 
################################################################################
# fisher_yates_shuffle( \@array ) : generate a random permutation
# of @array in place
sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}



################################################################################
# sub is_valid
# Description: check if generator structure was built up successfully 
# 
################################################################################
sub is_valid {
    my $self = shift;
    return undef if  @{$self->{vchain_array}} ==0; 
    1;
}



################################################################################
# sub get_data
# Description:
# get data 
# 
################################################################################
sub get_unique_data 
{
    my $self = shift;
    my $data_card =shift;
    $self->calculate_occupation_levels($data_card);
    my $data =[];  
    my $chain_type=$self->{chain_type};
    foreach my $actual_vchain (@{$self->{vchain_array}})
    {  
     my $tmpdata =[''];  
     foreach my $value_column_index (0..$actual_vchain->{vcol_count})
     { 
       my $value_column=$actual_vchain->{vcol_hash}->{$value_column_index};
       my @tmp_value_column_copy=@{$value_column->{value_column}};
       my @value_column_array =();
       while(@value_column_array<$value_column->{occupation_level})
       {
         my $rnd_index=int(rand(@tmp_value_column_copy));  
         push(@value_column_array,splice(@tmp_value_column_copy,$rnd_index,1));
       }
       my $format=undef;
       $format=
         $Data::Generate::vchain_type->{$chain_type}->{vcol_output_format}
         ->[$value_column_index] 
         if ((exists $Data::Generate::vchain_type->{$chain_type})
              && (exists $Data::Generate::vchain_type
                ->{$chain_type}->{vcol_output_format}));   
       $tmpdata=vcol_chain($tmpdata, \@value_column_array,
                    $actual_vchain->{data_card},$format);

      }
      push(@$data,@$tmpdata);
    }
    # makes a random order
    fisher_yates_shuffle($data); 
    # take away too much produced data
    shift(@$data) while(@$data>$data_card);
    map($_=&{$Data::Generate::vchain_type
                ->{$chain_type}->{output_format_fct}}($_),@$data)
         if ((exists $Data::Generate::vchain_type->{$chain_type})
              && (exists $Data::Generate::vchain_type
                ->{$chain_type}->{output_format_fct}));   
    @$data = map(int($_),@$data) if $chain_type eq 'INTEGER';
    @$data = sort(@$data);
    my $uniq=[];
    my $last='';
    my $duplicates=0;
    foreach my $item (@$data) {
        if ($last eq $item)
        {
          $duplicates++;
          next;     
        }
        push(@$uniq, $item);
        $last=$item;
    }
    carp "$duplicates duplicates found while generating ouput values.\n"
         ."Check syntax of statements" if $duplicates>0;
    return $uniq;
}


################################################################################
# sub vcol_chain
# Description:
# make a cross product of two value columns and concatenate the values.
# if type is with formatted output prepare values with a pipe inbetween.
# 
################################################################################
sub vcol_chain
{
  my @original=@{shift()};
  my @added =@{shift()};
  my $card=shift;
  my $format=shift;
  $format= "%s" unless defined $format;
  my @composed =();  
  foreach my $ele (@added)
  {
     
     foreach my $e2 (@original)
     {
         push(@composed,$e2.sprintf($format,$ele)); 
         next unless defined $card;
         return \@composed if(@composed>=$card);
     }
  }
  return \@composed;

};






################################################################################
# sub parse
# Description:
# parse given text.
# return either an error or a Data::Generate object
# 
################################################################################
sub parse($)
{
    my ($text)   = @_;
    
    # check that parser is up and running
    $Data::Generate::Parser=load_parser()  
              unless (defined $Data::Generate::Parser);


    # create a new generator and set it as global for parse routines 
    $Data::Generate::ACTUAL_VALUE_COLUMN=undef;
    $Data::Generate::VC_RANGE_REVERSE_FLAG=undef;


    $Data::Generate::current= Data::Generate->new($text);
    $Data::Generate::Parser->start($text);
    $Data::Generate::current->is_valid() or 
      croak "Error in parsing, invalid generator for $text";    
    $Data::Generate::current->calculate_weigth();
    $Data::Generate::current->calculate_degrees_of_freedom();
    return $Data::Generate::current;
}




1;


__END__