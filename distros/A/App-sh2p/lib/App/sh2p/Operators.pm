package App::sh2p::Operators;

use warnings;
use strict;
use App::sh2p::Utils;

sub App::sh2p::Parser::convert(\@\@);

our $VERSION = '0.06';
my $g_specials = '\[|\*|\?';
my %g_perl_ops;

@g_perl_ops{qw( eq ne lt gt le ge )} = undef;
   
######################################################

sub no_change {
   my ($op, @rest) = @_;
   
   out $op;
   
   return 1;
}

######################################################
# Altered for changed tokenising 0.04
sub shortcut {
   my ($input, @rest) = @_;
   my $ntok = @_;
   my $op;  
   
   # operators are followed by whitespace
   if ($input =~ s/(.+?)\s+//)  { 
       $op = $1;
   }
   else {
       $op = $input;
       $input = '';     # Avoid recursion
   }

   out "$op ";
   
   return $ntok if !@rest;
   
   my @types;
   
   if (@rest >= 3) {
       # string op string
       @types  = App::sh2p::Parser::identify (1, @rest);
       
       #print_types_tokens (\@types,\@rest);
       
       # Token may already have been converted
       if ($types[1][0] eq 'UNKNOWN' && exists $g_perl_ops{$rest[1]}) {
           $types[1] = [('OPERATOR', \&App::sh2p::Operators::boolean)];
       }
       elsif ($types[1][0] ne 'OPERATOR') {
           @types  = App::sh2p::Parser::identify (0, @rest); 
       }
   }
   else {
       @types  = App::sh2p::Parser::identify (0, @rest); 
   }
   
   App::sh2p::Parser::convert (@rest, @types);

   return $ntok;
}

######################################################

sub boolean {

   my ($op, @rest) = @_;
   my $ntok = 1;
   
   #print STDERR "boolean: <$op> <@rest>\n";
   
   if (substr($op,0,1) eq '-' && length($op) eq 2) {
       out "$op (";
       
       if (@rest) {
          $ntok = @_;
          App::sh2p::Handlers::interpolation ("@rest");
       }
       out ")";
   }
   elsif ($op) {  # $op might be an empty string (ignore)
       out " $op ";
   }   

   return $ntok;
}

######################################################
# Used for patterns like +([0-9]) -> [0-9]+
sub swap1stchar {
    my ($op) = @_;
    my $ntok = 1;
    
    # Remove parentheses & swap quanifier
    $op =~ s/(.)(\(.+\))/$2$1/;
    
    $op = App::sh2p::Compound::glob2pat($op);

    out " /$op/ ";
    
    return $ntok;
}

######################################################
# Used for patterns like @(one|two) -> (one|two)
sub chop1stchar {
    my ($op) = @_;
    my $ntok = 1;
    
    # Remove first char
    $op =~ s/^.//;
    
    $op = App::sh2p::Compound::glob2pat($op);

    out " /$op/ ";
    
    return $ntok;
}

######################################################

# Module end
1;
