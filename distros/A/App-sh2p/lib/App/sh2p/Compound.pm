package App::sh2p::Compound;

use strict;
use App::sh2p::Parser;
use App::sh2p::Utils;
use App::sh2p::Handlers;
use App::sh2p::Trap;

sub App::sh2p::Parser::convert(\@\@);
our $VERSION = '0.06';

my $g_not = 0;
my $g_context = '';
my @g_case_statements;

#####################################################
              #  shell   perl
my %convert = ( '=='  => 'eq',
                '='   => 'eq',
                '!='  => 'ne',
                '<'   => 'lt',
                '>'   => 'gt',
                '<='  => 'le',
                '>='  => 'ge',
                '-eq' => '==',
                '-ne' => '!=',
                '-lt' => '<',
                '-gt' => '>',
                '-ge' => '>=',
                '-le' => '<=',
                '-nt'=> undef,
                '-ot'=> undef,
                '-ef'=> undef,
                '-n' => '',       # No value required
                '-z' => '!',
                '-a' => '-e',     # see %sh_convert
                '-h' => '-l',
                '-o' => undef,    # shell option, but see %sh_convert
                '-O' => '-o',     # confused?
                '-G' => undef,    # owned by egid
                '-L' => '-l',
                '-N' => undef);   # modified since last read);

# Many options are the same as the Perl functions, but not all
# Bourne shell syntax overlaps
my %sh_convert = ('-o' => 'or',
                  '-a' => 'and');
                     
#####################################################
# ((
sub arith {

   my ($statement, @rest) = @_;  
   
   # First 2 chars passed should be (( or $((, unless from let
   $statement =~ s/^\$?\(\(//;
   # Last 2 chars passed should be )), unless from let
   $statement =~ s/\)\)$//;
   
   my $out = '( ';
   my @tokens = App::sh2p::Parser::tokenise ($statement);

   my $pattern = '<<|>>|==|>=|<=|\/=|%=|\+=|-=|\*=|=|>|<|!=|\+\+|\+|--|-|\*|\/|%';

   for my $token (@tokens) {  
      # Further tokenise
      
      $token =~ s/($pattern)/$1 /;
      
      for my $subtok (split (/ /, $token)) {
      
          if ($subtok =~ /^[_A-Za-z]/) {
              # Must be a variable!
              $subtok = "\$$subtok";
          }
          elsif ($subtok =~ /\$[A-Z0-9\?#\{\}\[\]]+/i) {
              my $special = get_special_var($subtok,0); 
              $subtok = $special if (defined $special);
          }
          
          $out .= "$subtok "
      }
      
   }
  
   if (query_semi_colon()) {
       out "$out);\n";
   }
   else {
       out "$out)";
   }
   return 1;
}

#####################################################
# identify_ksh_boolean ($tokens[$i], $types[$i])

sub identify_ksh_boolean (\$\$){

    my ($rtok, $rtype) = @_;
    my $retn = 1;
    
    if (exists $convert{$$rtok}) {   # ksh options
       $$rtok  = $convert{$$rtok};
       $$rtype = [('OPERATOR', \&App::sh2p::Operators::boolean)];
    } 
    elsif (substr($$rtok,0,1) eq '-') {
        $$rtype = [('OPERATOR', \&App::sh2p::Operators::boolean)];
    }
    else {
        $retn = 0;
    }

    return $retn;
    
}  # identify_ksh_boolean

#####################################################
# [[
sub ksh_test {

   my ($statement) = @_;   
   #print STDERR "ksh_test: <$statement>\n";
   
   # First 2 chars passed should be [[
   $statement =~ s/^\[\[//;
   # Last 2 chars passed should be ]]
   $statement =~ s/\]\](.*)$//;
   
   my $rest = $1;
   
   # extglob
   my $specials = '\@|\+|\?|\*|\!';
   
   my @tokens = App::sh2p::Parser::tokenise ($statement);
   my @types  = App::sh2p::Parser::identify (1, @tokens);
   
   for (my $i = 0; $i < @tokens; $i++) {
   
      my $token = $tokens[$i];
      
      #print STDERR "ksh_test token: <$token>\n";
      if (identify_ksh_boolean ($tokens[$i], $types[$i])) {
      
          if ( $i < $#tokens && $tokens[$i+1] !~ /^($specials)\(/ ) {
              
              $i++;
              while(!identify_ksh_boolean ($tokens[$i], $types[$i]) &&
                    $i < $#tokens) {
                  
                  $i++;
              }
              
          }
      }
      else {
      
         # look for shell pattern matching constructs (extglob)
         if ($token =~ /^($specials)\(/) {
             my $char = $1;
             
             if ($char eq '+' || $char eq '?' || $char eq '*') {
                 $types[$i] = [('OPERATOR', \&App::sh2p::Operators::swap1stchar)];  
             }
             elsif ($char eq '@') {
                 $types[$i] = [('OPERATOR', \&App::sh2p::Operators::chop1stchar)];
             }
             elsif ($char eq '!') {
	         if ($tokens[$i-1] eq 'eq') {
	             $tokens[$i-1] = '!~';
	         }
             }
             else {
	         error_out ("Unable to convert shell pattern matching <$token>");
	         $types[$i] = [('OPERATOR', \&App::sh2p::Operators::no_change)];
	     }
	     
	     # Fix previous operator
	     if ( $i > 0 ) {
	         if ($tokens[$i-1] eq 'eq') {
	             $tokens[$i-1] = '=~';
	         }
	         elsif ($tokens[$i-1] eq 'ne') {
	             $tokens[$i-1] = '!~';
	         }
	     }
	 }
	 elsif ($token eq '!') {
	     $g_not = 1;
	 }
	 elsif ($types[$i][0] eq 'VARIABLE') {      # January 2009
	     if (Register_variable($token, '$')) {
	         pre_out "my $token;\n";
	     } 
	 }

      }

   }

   if ($g_not) {
      out '( ! ';
      $g_not = 0;
   }
   else {
      out '( ';   
   }
   
   # Operators & stuff
   #print_types_tokens (\@types, \@tokens);
   App::sh2p::Parser::convert (@tokens, @types);
         
   out ' ) ';
   
   # We haven't finished yet!
   if ($rest) {
       my @tokens = App::sh2p::Parser::tokenise ($rest);
       my @types  = App::sh2p::Parser::identify (2, @tokens);          
       App::sh2p::Parser::convert (@tokens, @types);          
   }
   
   return  1;
}

#####################################################
# identify_sh_boolean ($tokens[$i], $types[$i])

sub identify_sh_boolean (\$\$){

    my ($rtok, $rtype) = @_;
    my $retn = 1;
    
    if (exists $sh_convert{$$rtok}) {
       $$rtok  = $sh_convert{$$rtok};        
       $$rtype = [('OPERATOR', \&App::sh2p::Operators::boolean)];         
    }       
    elsif (exists $convert{$$rtok}) {   # ksh options
       $$rtok  = $convert{$$rtok};
       $$rtype = [('OPERATOR', \&App::sh2p::Operators::boolean)];
    } 
    elsif (substr($$rtok,0,1) eq '-') {
        $$rtype = [('OPERATOR', \&App::sh2p::Operators::boolean)];
    }
    else {
        $retn = 0;
    }

    return $retn;
    
}  # identify_sh_boolean

#####################################################
# Not strictly a compound statement, but near enough
# This is called for test and [
sub sh_test {
 
   my $ntok = 1;
   my ($statement, @rest) = @_;  
   
   # First char/s passed should be [ or test
   $statement =~ s/^\[|^test//;
      
   if (@rest) {
      
      my $i;
      for ($i = 0; $i < @rest; $i++) {
          
          last if is_break($rest[$i]) || $rest[$i] eq ';';
      }
      
      if ( $i ) {      
          $statement = join (' ', splice(@rest,0,$i));
          $ntok += $i;
      }
   }

   # Last char passed may be ] (might not, because of 'test')
   $statement =~ s/\](.*)$//;;  
   my $rest = $1;
   
   # glob
   my $specials = '\[|\*|\?';
      
   my @tokens = App::sh2p::Parser::tokenise ($statement);
   my @types  = App::sh2p::Parser::identify (1, @tokens);
      
   my $index = 0;
   for (my $i = 0; $i < @tokens; $i++) {
      
      if (identify_sh_boolean ($tokens[$i], $types[$i])) {
      
          if ( $i < $#tokens && $tokens[$i+1] !~ /^($specials)\(/ ) {
              
              $i++;
              while(!identify_sh_boolean ($tokens[$i], $types[$i]) &&
                    $i < $#tokens) {
                  
                  $i++;
              }
              
          }
      }
      else {   # [^\$] is to avoid matching $?
         if ($tokens[$i] =~ /[^\$]($specials)/) {
	     $types[$i] = [('OPERATOR', \&App::sh2p::Compound::convert_pattern)];
	 }
	 elsif ($tokens[$i] eq '!') {
	     $g_not = 1;
	 }
	 elsif ($types[$i][0] eq 'VARIABLE') {      # January 2009
	     if (Register_variable($tokens[$i], '$')) {
	         pre_out "my $tokens[$i];\n";
	     }
	 }
      }
   }
  
   if ($g_not) {
       out '( ! ';
       $g_not = 0;
   }
   else {
       out '( ';   
   }
   
   #print_types_tokens (\@types, \@tokens);
   App::sh2p::Parser::convert (@tokens, @types);

   out ' )';
   
   $g_not = 0;   # This can be reset by the conversions above

   # We haven't finished yet!
   if (defined $rest && $rest) {
       my @tokens = App::sh2p::Parser::tokenise ($rest);
       my @types  = App::sh2p::Parser::identify (2, @tokens); 
       
       #print_types_tokens (\@types, \@tokens);
       
       App::sh2p::Parser::convert (@tokens, @types);          
   }

   return  $ntok;
}

#####################################################

sub convert_pattern {
    
    my ($in) = @_;
    out ('/'.glob2pat ($in).'/');
    return 1;
}

#####################################################

sub Handle_if {

   my ($cmd, @statements) = @_;
   my $ntok = 1;

   $g_context = 'if';

   for (my $i=0; $i < @statements; $i++) {
       if (substr($statements[$i],0,1) eq '#') {
           splice (@statements, $i);
           last;
       }
   }
   
   # First token is 'if'
   iout "$cmd ";
   
   # 2nd command?
   if (@statements) {
       $ntok += process_second_statement(1, @statements);
   }
   
   $g_context = '';

   return $ntok;
}

#####################################################

sub Handle_fi {

   dec_indent();
   dec_block_level();
   #out "\n";
   
   iout "}\n";
   
   return 1;
}

#####################################################

sub Handle_not {
    $g_not = 1;
    return 1;
}

#####################################################

sub Handle_then {
   my ($cmd, @statements) = @_;
   my $ntok = 1;

   for (my $i=0; $i < @statements; $i++) {
       if (substr($statements[$i],0,1) eq '#') {
           splice (@statements, $i);
           last;
       }
   }
  
   iout "{\n";
   inc_indent();
   inc_block_level();
      
   # 2nd command?
   if (@statements) {
       $ntok += process_second_statement(0, @statements);
   } 
      
   return $ntok;
}

#####################################################

sub Handle_else {
   my ($cmd, @statements) = @_;
   my $ntok = 1;

   for (my $i=0; $i < @statements; $i++) {
       if (substr($statements[$i],0,1) eq '#') {
           splice (@statements, $i);
           last;
       }
   }

   dec_indent();
   dec_block_level();
   out "\n";
   iout "}\n";
   iout "else {\n";
   inc_indent();
   inc_block_level();

   $g_context = 'else';

   # 2nd command?
   if (@statements) {
       $ntok += process_second_statement(0, @statements);
   }
   
   $g_context = '';
   return $ntok;
}

#####################################################

sub Handle_elif {
   my ($cmd, @statements) = @_;
   my $ntok = 1;

   for (my $i=0; $i < @statements; $i++) {
       if (substr($statements[$i],0,1) eq '#') {
           splice (@statements, $i);
           last;
       }
   }

   dec_indent(); 
   dec_block_level();
   out "\n";
   iout "}\n";
   iout 'elsif ';

   $g_context = 'if';

   # 2nd command?
   if (@statements) {
       $ntok += process_second_statement(1, @statements);
   }

   $g_context = '';

   return $ntok;
}

#####################################################
# see http://www.perlmonks.com/?node_id=708493
#    $globstr =~ s{(?:^|(?<=[^\\]))(.)} { $patmap{$1} || "\Q$1" }ge;
# nested : 1 do not add ^ and $
# minimal: 1 do a minimal match
sub glob2pat {
    my ($globstr, $nested, $minimal) = @_;
    my $inside_br = 0;
    my @chars = (split '', $globstr);
    
    # C style used because I need to skip-ahead and look-behind
    for (my $i; $i < @chars; $i++) {
        if ($chars[$i] eq '\\') {
            $i++;          # ignore next char
        }
        elsif ($chars[$i] eq '[') {
            $inside_br++;  # Allow for nested []
        }
        elsif ($chars[$i] eq ']' && $inside_br) {
            $inside_br--;
        }
        elsif ($chars[$i] eq '!' && $inside_br && $chars[$i-1] eq '[') { 
            # ! only means 'not' at the front of the [] list
            $chars[$i] = '^'
        }
        elsif (! $inside_br) {
            if ($chars[$i] eq '*') {
                if (defined $minimal && $minimal) {
                    $chars[$i] = '.*?'
                }
                else {
                    $chars[$i] = '.*'
                }
            }
            elsif ($chars[$i] eq '?') {
                $chars[$i] = '.'
            }
        }
    }
    
    local $" = '';
    if (defined $nested && $nested) {
        return "@chars";
    }
    else {
        return "^@chars\$";
    }
}

#####################################################

sub push_case {
    
    push @g_case_statements, @_, set_break();  # 0.05 added break
    
}

#####################################################

sub Handle_case {

    my ($cmd, $var, $in, @rest) = @_;
    my $ntok = 3;

    #print STDERR "Handle_case <$cmd> <$var> <$in> <@rest>\n";
    
    $g_context = 'case';
    
    if ($in ne 'in') {
        error_out ("Expected 'in', got <$in> ");
    }

    iout '$_ = ';
    App::sh2p::Handlers::interpolation ($var);
    out ";\n";
        
    iout "SWITCH: {\n";

    # These are decremented in Handle_esac
    inc_indent();
    inc_block_level();
    
    my $i;
    
    for ($i = 0; $i < @rest; $i++) {

        my $condition = $rest[$i];
        next if is_break($condition);      # 0.05
        
        # January 2009 for case nested in other conditionals
        if ($condition eq 'esac') {
            dec_indent();
            dec_block_level();
            iout "}\n";
            $i++;
            last;
        }
        
        $condition =~ s/^\(?(.*)\)$/$1/;
        $condition = glob2pat ($condition);
        iout ("/$condition/ && do {\n");
        inc_indent();
        inc_block_level();
        
        my @tokens;
        
        for ( $i++; $i < @rest; $i++) {
            push @tokens,$rest[$i]; 
            
            if ($rest[$i] eq ';' && $rest[$i+1] eq ';') {
                $i++;
                last;
            }
        }
        
        my @types  = App::sh2p::Parser::identify (0, @tokens);	
        
        #print_types_tokens(\@types, \@tokens);
        
	App::sh2p::Parser::convert (@tokens, @types);
        
        iout ("last SWITCH;\n");
        dec_indent();
        dec_block_level();
        iout ("};\n");      # Added ';' 0.05
    }
    
    $ntok = $ntok + $i;     # January 2009
 
    $g_context = '';
    
    return $ntok;
}

#####################################################

sub Handle_esac {

    my ($cmd) = @_;

    #print STDERR "Handle_esac\n";
    
    Handle_case (@g_case_statements);

    dec_indent();
    dec_block_level();
    @g_case_statements = ();
    
    # Fix January 2009 (was: iout "\n}\n")
    out "\n";
    iout "}\n";
    
    return 1;
}

#####################################################

sub Handle_for {

   # Format: for var in list
   my ($cmd, $var, $in, @list) = @_;
   
   $g_context = 'for';

   my $ntok = 1;
      
   # Using first argument because this is also used for select (temp)
   error_out ("No conversion for $cmd, consider Shell::POSIX::select") if $cmd eq 'select';
   
   $ntok++ if defined $var;
   iout "$cmd my \$$var (";
   
   $ntok++ if defined $in;
   
   my @for_tokens;

   for (my $i=0; $i < @list; $i++) {
       last if $list[$i] eq 'do';
       last if $list[$i] eq ';';
       last if substr($list[$i],0,1) eq '#';
       
       push @for_tokens, $list[$i]; 
   }
   
   #print STDERR "Handle_for: for_tokens <@for_tokens>\n";
   
   if (@for_tokens) {
       $ntok += @for_tokens;
   }
   else {
       if (ina_function()) {
           out '@_';
       }
       else {
           out '@ARGV';
       }
   }
   
   # Often a variable to be converted to a list
   # Note: excludes @ and * which indicate an array
   if ($for_tokens[0] =~ /\$[A-Z0-9#\{\}\[\]]+/i) {
      my $IFS = App::sh2p::Utils::get_special_var('IFS',0);
      $IFS =~ s/^"(.*)"/$1/;
      out "split /$IFS/,$for_tokens[0]";
      shift @for_tokens;
   }
   
   if (@for_tokens) {
       my @types  = App::sh2p::Parser::identify (2, @for_tokens);
       App::sh2p::Parser::convert (@for_tokens, @types);
   }
   
   out ')';
   
   $g_context = '';

   return $ntok;
}

#####################################################

sub Handle_while {

   my ($cmd, @statements) = @_;
   my $ntok = 1;
   
   for (my $i=0; $i < @statements; $i++) {
       if (substr($statements[$i],0,1) eq '#') {
           splice (@statements, $i);
           last;
       }
   }
   
   #print STDERR "Handle_while: <@statements>\n";
   
   # First token is 'while'
   iout "$cmd ";
   
   $g_context = 'while';
   
   # 2nd command?
   if (@statements) {
       $ntok += process_second_statement(1, @statements);
   }
   
   $g_context = '';
   return $ntok;
}

#####################################################

sub Handle_until {

   my ($cmd, @statements) = @_;
   my $ntok = 1;
   
   # First token is 'until'
   iout "$cmd ";
   
   $g_context = 'until';
   
   # 2nd command?
   if (@statements) {
       $ntok += process_second_statement(1, @statements);
   }
   
   $g_context = '';
   return $ntok;
}


#####################################################

sub Ignore {
   return 1;
}

#####################################################

sub Handle_done {

   dec_indent();
   dec_block_level();
   out "\n";
   iout "}\n";
   
   return 1;
}


#####################################################

sub Handle_do {

   iout "{\n";
   inc_indent();
   inc_block_level();
   
   return 1;
}

#####################################################

sub Handle_function {

   # Format: function name {
   
   my (undef, $name) = @_;
   
   out "sub $name ";
   
   set_user_function($name);
   
   return 2;
}

#####################################################

sub open_brace {

   iout "{\n";
   inc_indent();

   mark_function();
   inc_block_level();
   
   return 1;
}

#####################################################

sub close_brace {

   # Support for trap January 2009
   
   App::sh2p::Trap::uninstall_function_traps();
   
   dec_indent();
   iout "\n}\n";

   unmark_function();
   dec_block_level();

   return 1;
}

#####################################################

sub get_context {
    return $g_context;
}

#####################################################
# Called by if, then, else, elif, while, until
# First parameter set to true by if, elif, while, until

sub process_second_statement {
   my ($cmd, @statements) = @_;
   my $statement;
   my $i;
   my $paren = 0;   
   
   for ($i = 0; $i < @statements; $i++) {
       
       if (is_break($statements[$i]) || $statements[$i] eq ';') {
           last;
       }
   }

   return 0 unless $i > 0;
   
   $statement = join (' ', splice(@statements,0,$i));
   #print STDERR "process_second_statement: <$statement>\n";
   
   my @tokens = App::sh2p::Parser::tokenise ($statement);
   my @types  = App::sh2p::Parser::identify (0, @tokens);

   #print_types_tokens (\@types, \@tokens);

   if ($cmd && $tokens[0] ne 'test' &&
      ($types[0][0] eq 'EXTERNAL' || 
       $types[0][0] eq 'BUILTIN'  ||
       $types[0][0] eq 'PERL_BUILTIN')
      ) {
       $paren = 1;
       out '('
   }
   
   App::sh2p::Handlers::no_semi_colon() if $cmd;
   App::sh2p::Parser::convert (@tokens, @types);
   App::sh2p::Handlers::reset_semi_colon() if $cmd;

   if ($paren) {
       out ')'
   }

   return $i;
}

#####################################################

1;
