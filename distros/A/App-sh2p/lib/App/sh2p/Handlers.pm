package App::sh2p::Handlers;

use strict;

use App::sh2p::Parser;
use App::sh2p::Utils;
use App::sh2p::Here;

our $VERSION = '0.06';
sub App::sh2p::Parser::convert(\@\@);

my $g_unterminated_backtick = 0;
my $g_redirect_filename_w;
my $g_redirect_filename_r;
my %g_subs;

#  For use by App::sh2p only
############################################################################

sub Handle_assignment {
   
   my $ntok = 1;
   my ($in, @rest)  = @_;
   
   #print STDERR "Handle_assignment: <$in>\n";
   
   $in =~ /^(\w+)(\+?=?)(.*)$/;
   my $lhs  = $1;
   my $sign = $2;
   my $rhs  = $3;
   
   my $special_var = get_special_var($lhs,0);   # January 2009
   
   if (defined $special_var) {
      set_special_var ($lhs, $rhs);
      if ($special_var =~ s/^\$//) {
          $lhs = $special_var;      # Converted special variable
      }
      else {
          $special_var = undef;
      }
   }   

   # Bash 3.0, ksh93 array initialisation
   if (substr($rhs,0,1) eq '(') {
      return Handle_list_assign($lhs, $sign, $rhs, @rest);
   }

   my $name = "\$$lhs";
   
   if (!defined $special_var && Register_variable ($name) ) {
       iout "my $name";
   }
   else {
       iout "$name";
   }
   
   if ( ! defined $rhs ) {
      out ';';
      if ($ntok == @_) {
          out "\n";
      }
         
      return $ntok;
   }
   else {
      out ' = ';
   }
 
   my $isa_int = 0;
   if (get_variable_type($name) eq 'int') {
      $isa_int = 1;
   }
   
   if ( $rhs eq '' ) {
      if ($isa_int) {
         out 0
      }
      else {
         out '""'
      }
   }
   elsif ($rhs =~ /^\d+$/) {
      out $rhs
   }
   else {
      # Process the rhs
      
      if ($isa_int) {
         out "int(";
      }
      
      for my $tok (@rest) {
          last if substr($tok,0,1) eq '#' || is_break($tok);
          $rhs .= "$tok ";
          $ntok++;
      }
      
      no_semi_colon();
      my @tokens = App::sh2p::Parser::tokenise ($rhs);
      my @types  = App::sh2p::Parser::identify (1, @tokens); 
      
      #print_types_tokens (\@types, \@tokens);
      
      # Avoid recursion
      die "Nested assignment $in" if $types[0] eq 'ASSIGNMENT';
      
      App::sh2p::Parser::convert (@tokens, @types);
      reset_semi_colon();
      
      if ($isa_int) {
         out ")";
      }
   }
   
   out ';';
   #if ($ntok == @_) {  0.05  (regression OK)
       out "\n";
   #}
   
   return $ntok;
}

############################################################################
# Bash 3.0, ksh93 array initialisation (inc. += )
sub Handle_list_assign {
   my ($lhs, $sign, $rhs, @rest) = @_;
   my $ntok = 1;
   my $name = "\@$lhs";
   my $new = 0;
   my $start_index = 0;
   
   if (Register_variable ($name, '@')) {
       $new = 1;
       iout "my $name";
   }
   
   # Process the rhs
   #print STDERR "Handle_list_assign: <$lhs> <$sign> <$rhs> <@rest>\n";
   $rhs =~ s/^\((.*)\)$/$1/;   # strip out the ()
   
   my @elements = split (/\s+/, $rhs);
   my @initial;
   
   # Get first set of elements without [] (might be all, or none)
   while (@elements) {
       last if ($elements[0] =~ /^\s*\[\d+\]=/);

       push @initial,(shift @elements);
   }
   
   if (@initial) {
       
       if ($sign eq '+=') {
           if ($new) {
               out ";\n";
           }
       
           iout "push $name,(";    
       }
       else {
          if (!$new) {
             iout "$name";
          }
          out ' = (';
       }

       App::sh2p::Parser::join_parse_tokens (',', @initial);
       out ");\n";
   }
   else {
       out ";\n";
   }
   
   # indexed elements
   # Start the index at the end of the initial array
   # Is this a problem with +=  ??
   my $index = @initial;
   
   for (my $i = 0; $i < @elements; $i++) {
       
       my $rhs;
       if ($elements[$i] =~ /^\s*\[(\d+)\]=(.*)/) {
           $index = $1;
           $rhs = $2;
       }
       else {
           $index++;
           $rhs = $elements[$i];
       }
       
       iout "\$$lhs\[$index\] = ";
       my @tokens = ($rhs);
       my @types  = App::sh2p::Parser::identify (1, @tokens); 
       App::sh2p::Parser::convert (@tokens, @types);
       out ";\n"
   }
   
   # No processing of @rest 
   
   return 1;
}

############################################################################

sub define_idx_var {

    my $var = shift;
    
    $var =~ s/^\$//;    # remove leading $, if any 
    
    $var =~ s/\s*[\+\-\*\/]?\s*\d+\s*//;    # remove arithmetic
    
    if (Register_variable ($var, '$') ) {
       iout "my \$$var;\n";
    }
}

sub Handle_array_assignment {
   my $ntok = @_;
   my $in  = shift;
   
   $in =~ /^(\w+)\[(.*)\]=(.*)$/;
   
   my $arr = $1;
   my $idx = $2;
   my $rhs = $3;
   
   #print STDERR "Handle_array_assignment: <$arr> <$idx> <$rhs>\n";
   
   if ( !defined $rhs) {
      die "++++ Internal error No rhs in array assignment. <$in>"
   }
      
   if (Register_variable ("\@$arr", '@') ) {
          iout "my \@$arr;\n";
   }

   # The shell allows a variable index without a '$'
   if ($idx =~ /^[[:alpha:]_]/)  {  # No '$' [count + 1], or [i] ([1 + count] is illegal)
       
       define_idx_var ($idx);
       
       iout "\$$arr\[\$$idx\] = ";
   }
   elsif ( $idx =~ /^\D+$/) {       # \D is non-digit
       # Process the lhs
         
       my @tokens = App::sh2p::Parser::tokenise ($idx);
       my @types  = App::sh2p::Parser::identify (1, @tokens); 
 
       iout "\$$arr\[";  
       App::sh2p::Parser::convert (@tokens, @types);
       out "] = ";
   }
   else {
       if ( $idx =~ /^\s*\$/ ) {
           define_idx_var ($idx);
       }
       
       iout "\$$arr\[$idx\] = ";
   }
   
   if ( !defined $rhs ) {
      out 'undef'
   }
   else {
      # Process the rhs
      
      my @tokens = App::sh2p::Parser::tokenise ($rhs);
      my @types  = App::sh2p::Parser::identify (1, @tokens); 
      
      # Avoid recursion
      die "++++ Internal error: Nested array assignment $in" if $types[0] eq 'ARRAY_ASSIGNMENT';
      #print_types_tokens (\@types, \@tokens);
      
      App::sh2p::Parser::convert (@tokens, @types);
   }
   
   out ";\n";
   return $ntok;

}

############################################################################

sub Handle_break {

   # Maybe check to see if we are in a heredoc?
   
   # 0.05
   #if (!App::sh2p::Utils::new_line()) {
   #    out "\n";
   #}
   
   return 1;
}

############################################################################

sub Handle_open_redirection {
    my ($type, $filename) = @_;
    
    #print STDERR "Handle_open_redirection: <$type> <$filename>\n";
    my @caller = caller();
    #print STDERR "Handle_open_redirection: @caller\n";
    
    out ("\n");
    
    my $var = 'sh2p_handle';
    if (Register_variable($var, '$')) {
       rd_iout "my \$$var;\n";
    }
    
    rd_iout ("open(\$$var,'$type',\"$filename\") or\n");
    rd_iout ("     die \"Unable to open $filename: \$!\";\n");
    
    if ( $type eq '>' || $type eq '>>' ) {
        $g_redirect_filename_w = $filename;
    }
    else {
        $g_redirect_filename_r = $filename;
    }
}

############################################################################

sub Handle_close_redirection {
   
    my ($mode) = @_;
    my $filename;
    
    if ($mode eq 'w') {
        $filename = $g_redirect_filename_w;
        $g_redirect_filename_w = undef; 
    }
    else {
        $filename = $g_redirect_filename_r;
        $g_redirect_filename_r = undef; 
    }
    
    if (defined $filename) {
        iout ("close(\$sh2p_handle);\n");
        iout ("undef \$sh2p_handle;\n\n");
    }
    
    return 1;   # In case it gets used as a token
}

############################################################################

sub Query_redirection { 
    my ($mode) = @_;
    
    if ($mode eq 'w') {
        return $g_redirect_filename_w;
    }
    else {
        return $g_redirect_filename_r;
    }
}

############################################################################

sub Handle_variable {
   my ($token, $join) = @_;
   my $new_token;
   
   #print STDERR "Handle_variable: <$token> ".query_in_quotes()." context: <".
   #             App::sh2p::Compound::get_context().">\n";
   
   # Check for specials
   if ($new_token = get_special_var($token)) {
      $token = $new_token;
   }
   elsif ( $token =~ s/^\$#(\w+)(.*)/\$$1/ ) {   # length
        my $suffix = $2;
        if ( $suffix =~ /\[\s*[\*\@]\s*\]/ ) {   # [*] or [@]
            $token =~ s/^\$/\@/;
            out "scalar($token)";
        }
        else {
            out "length($token)";
        }
        return 1;
   }
   elsif ( $token =~ s/^\$!(\w+)\[.*\]/\@$1/ ) {    # ksh92 & bash !
        # Find indexes of set variables
        iout "sh2p_array_count($token)";
        store_sh2p_array_count ($token);
        
        return 1;
   }
   elsif ( substr($token, 0, 3) eq '$((' ) {
      # Calculation
      $token =~ s/\$\(\((.*)\)\)/$1/g;
      
   }
   elsif ( substr($token, 0, 2) eq '$(' ) {
      # Back-ticks
            
      $token =~ s/\$\((.*)\)/`$1`/g;
   }
   elsif ( $token =~ /\[(.+)\]/) {
       #print STDERR "Handle_variable array <$1>\n";
       my $idx = $1;
       
       # The shell allows a variable index without a '$'
       if ($idx =~ /^[[:alpha:]_]/)  {  # No '$' [count + 1] or even [i]
          $idx = "\$$idx"; 
          
          $token =~ s/\[(.+)\]/[$idx]/;
       }
       elsif ( $idx eq '*' || $idx eq '@' ) {
           # How do we find if we are quoted?
           $token =~ s/\$(.+)\[.*\]/$1/; 

           if (query_in_quotes()) {
               if ($idx eq '@') {
                   $token = "\"\@$token\"";
               }
               else {
                   my $glue = get_special_var('IFS');
                   $glue =~ s/^([\"\'])(.*)\1$/$2/;   # Not certain there are quotes
                   $glue = substr($glue,0,1);
                   $token = "join(\"$glue\",\@$token)";
               }
           }
           else {
               $token = "\@$token";
           }
       }

   }
      
   out $token;
   
   return 1;
}

############################################################################
sub Handle_expansion {
    my ($token) = @_;
    my $ntok;
    
    #print STDERR "Handle_expansion: <$token>\n";
    #  my @caller = caller();
    #  print STDERR "Called from @caller\n";

    # Strip out the braces
    # $2: (.*?) replaced with (.*) 0.04
    $token =~ s/\$\{(.*?)\}(.*)/\$$1/;
    my $suffix = $2;
            
    # Arrays
    if ($token =~ /\w+\[.*\]/) {
        $ntok = Handle_variable($token);
    }
    elsif ( $token =~ /(\w+)([:?\-=+]{1,2})([^:?\-=+]+)/ ) {
        my $var    = '$'.$1;
        my $qual   = $2;
        my $extras = $3;
        #print STDERR "Handle_expansion <$var><$2><$3>\n";
        
        if (my $new_var = get_special_var($var)) {
    	    $var = $new_var;
        }

        # Remove the : 
        # Done this way in case further modification is required
        $qual =~ s/^://;
   
        if ($qual eq '?') {
            if (! $extras) {
                $extras = "'$var undef or not set'";
            }
            
            # $extras should already be quoted
            out ("print STDERR $extras,\"\\n\" if (! defined $var or ! $var);");
        }
        elsif ($qual eq '=') {
 	    out ("(defined $var or $var) || $var = ");
 	    my @tmp = ($extras);
 	    my @types  = App::sh2p::Parser::identify (1, @tmp);     
 	    App::sh2p::Parser::convert (@tmp, @types);
        }
        elsif ($qual eq '-') {
	    out ("(defined $var or $var) || ");
	    my @tmp = ($extras);
	    my @types  = App::sh2p::Parser::identify (1, @tmp);     
	    App::sh2p::Parser::convert (@tmp, @types);
        }
        elsif ($qual eq '+') {
	    out ("(! defined $var or ! $var) || ");
	    my @tmp = ($extras);
	    my @types  = App::sh2p::Parser::identify (1, @tmp);     
	    App::sh2p::Parser::convert (@tmp, @types);
  	}
        else {
            error_out ("Pattern $qual not currently supported");
            out ($token);
        }
        $ntok = 1;
    }    
    elsif ( $token =~ s/^\$#(.+)/\$$1/ ) {
        out "length($token)";
        $ntok = 1;
    }
    elsif ($token =~ /^(\$\w+)([%#]{1,2})(.*)/) {
        my $var     = $1;
        my $mod     = $2;
        my $pattern = $3;
        #print STDERR "Handle_expansion <$var><$2><$3>\n";
        
        if (my $new_var = get_special_var($var)) {
	    $var = $new_var;
        }
   
        if ($mod eq '#')  {  # delete the shortest on the left
            $pattern = App::sh2p::Compound::glob2pat($pattern,1,1);
            out "($var =~ /^(?:$pattern)+?(.*)/)[0]";
        }
        elsif ($mod eq '##') {  # delete the longest on the left
            $pattern = App::sh2p::Compound::glob2pat($pattern,1,0);
            out "($var =~ /^(?:$pattern)+(.*)/)[0]";    
        }
        if ($mod eq '%')  {  # delete the shortest on the right
            $pattern = App::sh2p::Compound::glob2pat($pattern,1,1);
            out "($var =~ /^(.*)(?:$pattern)+?\$/)[0]";
        }
        elsif ($mod eq '%%') {  # delete the longest on the right
            $pattern = App::sh2p::Compound::glob2pat($pattern,1,0);
            out "($var =~ /^(.*?)$pattern\$/)[0]";    
        }
        
        $ntok = 1;
    }
    else {  
        $ntok = Handle_variable($token);
    }
    
    if ($suffix) {
        out '.';
        my @tokens = App::sh2p::Parser::tokenise ($suffix);
        my @types  = App::sh2p::Parser::identify (1, @tokens);
   
        App::sh2p::Handlers::no_semi_colon();
        App::sh2p::Parser::convert (@tokens, @types);
        App::sh2p::Handlers::reset_semi_colon();
    }
    
    # Suffix was in the same token
    return $ntok;
}

############################################################################

sub Handle_delimiter {

   my $ntok = 1;
   my ($tok) = @_;
   
   #print STDERR "Handle_delimiter: <$tok>\n";
   
   if ($tok =~ /^\(\((.+)=(.+)\)\)$/) {
      my $lhs = $1;
      my $rhs = $2;
      # Could be compound assignment (like +=)
      out "\$$lhs= $rhs;\n";  
   }
   elsif (substr($tok,0,1) eq '"') {
         # Special case for an empty string  January 2009
         if ($tok eq '""') {      
             out $tok;
         }
         else {
             interpolation($tok);
         }
   }
   elsif (substr($tok,0,1) eq "'") {
         out $tok;
   }
   elsif ($tok =~ s/^\((.+)\)/$1/) {      # subshell
      Handle_subshell ($tok);
   }
   elsif ($tok eq ')' && $g_unterminated_backtick) {
      out '`';
      $g_unterminated_backtick = 0;
      dec_indent();
   }
   elsif ($tok eq ';') {
      out "\n";
   }
   elsif ( $tok =~ /\|[^\|]/) {    # RE change 0.05       
       shift @_;
       out $tok;
       if ( @_ ) {
           $ntok += App::sh2p::Parser::analyse_pipeline (@_);
       }
   }
   elsif ($tok =~ /^#/ && App::sh2p::Utils::new_line()) {
      out $tok;
   }
   elsif ($tok =~ /^(.*)\`\s*(.*)\s*\`(.*)/ && substr($tok,0,1) ne '"') {
      my $preamble = $1;      # Added January 2009
      my $cmd      = $2;
      my $rest     = $3;
      my @cmd = split (/\s+/, $cmd);
      my @perlbi;

      if (@perlbi = App::sh2p::Parser::get_perl_builtin($cmd[0])) {
          # print STDERR "Handle_delimiter2: <@cmd> <$rest>\n";
          # Do my best to trap unnecessary child processes
          out "\n" if query_semi_colon();    # For tidy messages
          #&{$perlbi[0]}(@cmd,$rest);
          &{$perlbi[0]}(@cmd);
          
          if ($rest) {
              unless ($preamble eq $rest && 
                     ($rest eq '"' or $rest eq "'"))
              {
                  out '.';
                  interpolation ($rest);
              }
          }
      }
      else {
          out " $tok ";
      }
   }
   else {
      out " $tok";
      out ' ' unless substr($tok,-1) eq "\n";     # 0.04
   }
   
   return $ntok;
}

############################################################################

sub Handle_subshell {

   my ($subshell) = @_;
   
   error_out "Subshell: ($subshell)";
   iout "{\n";
   inc_indent();
   inc_block_level();    # 0.05
   mark_subshell();
   iout "local \%ENV;\n";      # one of the features of a subshell
      
   # Search for different statements
   
   for my $tok (split (';', $subshell)) {
      # should probably be done in sh2p
      my @tokens = App::sh2p::Parser::tokenise ($tok);
      my @types  = App::sh2p::Parser::identify (0, @tokens);
      #print_types_tokens (\@types,\@tokens);
      App::sh2p::Parser::convert (@tokens, @types);
   }
   
   dec_indent();
   dec_block_level();    # 0.05
   unmark_subshell();
   out "}\n";

}

############################################################################

sub interpolation {
   my ($string) = @_;
   my $delimiter = '';
   
   #print STDERR "interpolation: <$string>\n";
   #my @caller = caller();
   #print STDERR "@caller\n";
   
   # single quoted string
   if ($string =~ /^(\'.*\')(.*)/) {
       my $single = $1;
       $string = $2;
       
       if ($string) {
           out "$single.";
       }
       else {
           out "$single";
           return;
       }
   }
   
   if ( substr($string,0,1) eq '"') {
       # strip out leading & trailing double quotes
       $string =~ s/^\"(.*)\"$/$1/;
       set_in_quotes();
   }
   
   # Insert leading quote to balance end
   # Why?  Because the string might not be quoted 
   out ('"');           
   
   my @chars = split '', $string;
   
   for (my $i = 0; $i < @chars; $i++) {
   
       if ($chars[$i] eq '\\') {   # esc
           out $chars[$i];
           $i++;
           out $chars[$i];
       }
       elsif ($chars[$i] eq '"' and !query_in_quotes()) {   
           # embedded quote 0.04
           out '\\"';
       }
       elsif ($chars[$i] eq '`') {
           out '".';
           $delimiter = '`';
         
           my $cmd = $chars[$i];
           $i++;
           
           while ($i < @chars) {
               $cmd .= $chars[$i];
               last if ($chars[$i] eq $delimiter);
               $i++;    # Position change January 2009
           }

           Handle_delimiter ($cmd);
           out '."' if $i < (@chars-1);
       }
       elsif ($chars[$i] eq '$') {
           my $token = $chars[$i];
           $i++;

           if ($chars[$i] eq '(') {
               out '".';
               $delimiter = ')';
               while ($i < @chars) {
                   $token .= $chars[$i];
                   $i++;
                   if ($chars[$i] eq $delimiter) {
                       $token .= $chars[$i];
                       last
                   }
               }
               Handle_2char_qx ($token);
               out '."' if $i < (@chars-1);
               
           }
           elsif ($chars[$i] eq '{') {
 
               out '".';  
               $delimiter = '}';
               while ($i < @chars) {
                   $token .= $chars[$i];
                   $i++;
                   if ($chars[$i] eq '}') {
                       $token .= $chars[$i];
                       last
                   }
               }
               Handle_expansion ($token);
               out '."' if $i < (@chars-1);
           }
           else {
               $delimiter = '';
               
               while ($i < @chars) {
                   $token .= $chars[$i];                 
                   last if ($chars[$i+1] !~ /[a-z0-9\#\[\]\@\*]/i); # 0.04
                   $i++;
               }
               
               # Remove trailing whitespace, then put it back
               my $whitespace = '';
               
               if ($token =~ s/(\s+)$//) {
                   $whitespace = $1;
               }
               
               out '".' if ! can_var_interpolate($token);
               
               Handle_variable ($token);
               
               out '."' if ! can_var_interpolate($token);
               
               out $whitespace if ($whitespace);
               
           }
       }
       else {
           $delimiter = '';
           out $chars[$i];
       }
       
   }
   
   if ($chars[-1] ne $delimiter) {
       out '"';
   }
   
   unset_in_quotes();
   
   # Not my favorite hack (in Utils)
   rem_empty_string();
}

############################################################################

sub Handle_2char_qx {
   
   my $ntok;
   my ($tok) = @_;
   
   #print STDERR "Handle_2char_qx token: <$tok>\n";
   
   # Simple case first
   if ($tok =~ /^\$\((.*)\)(.*)$/) {
      my $cmd  = $1;
      my $rest = $2;
      my @cmd = split (/\s+/, $cmd);
      my @perlbi;
      my $shell = 0;
      
      # Any shell meta-characters?
      $shell = 1 if ($tok =~ /[|><&]/);
   
      if (!$shell and @perlbi = App::sh2p::Parser::get_perl_builtin($cmd[0])) {
          # Do my best to trap unnecessary child processes
          out "\n" if query_semi_colon();    # For tidy messages
          &{$perlbi[0]}(@cmd,$rest);
      }
      elsif (is_user_function($cmd[0])) {
          error_out "User function '$cmd[0]' called in back-ticks";
          iout "`$cmd`$rest";
      }
      else {
          my $pipe = 0;
          
          # Is this really a pipe, or is | embeded in a string? January 2009
          if ( $cmd =~ /\|[^\|]/) {    # RE change 0.05
              my $quote = 0;
              for my $char (split '',$cmd) {
                  
	          if ($char eq "'" || $char eq '"') {
	              $quote = $quote?0:1;
	          }
	          
	          next if $quote;
	          if ($char eq '|') {
	              $pipe = 1;
	              last;
	          }
              }
          }
          
          if ($pipe) {
              if ( substr($tok, 0, 2) eq '$(' ) {
                  $tok =~ s/^\$\((.*)\)$/$1/;
              }
              else {
                  $tok =~ s/^`(.*)`$/$1/;
              }
              
              App::sh2p::Parser::analyse_pipeline ($tok);
              out " $rest";
          }
          else {
              iout "`$cmd`$rest";
          }
      }
      
      $ntok = 1;
   }
   elsif ( substr($tok, 0, 2) eq '$(' ) {
      $tok =~ s/\$\(/`/;
      
      # This is the ONLY place this is set, and might now be obsolete
      $g_unterminated_backtick = 1;   

      my @tokens = App::sh2p::Parser::tokenise ($tok);
      my @types  = App::sh2p::Parser::identify (1, @tokens); 
      
      #print_types_tokens (\@types,\@tokens);      
      App::sh2p::Parser::convert (@tokens, @types);
      
      inc_indent();
      $ntok = @_;
   }
   else {
      iout "@_";
      $ntok = @_;
   }
   
   return $ntok;
}

############################################################################
# Simplistic call to external program, should this be converted?

sub Handle_external {
      
   my $ntok = 0;
   my (@args) = @_;
   my $func = 'system';
   
   #{local $" = '*'; print STDERR "Handle_external <@args>\n";}
   
   # Is final token a comment?
   my $last = '';

   if (substr($args[-1],0,1) eq '#') {
       pop @args;
   }
   
   if ($g_unterminated_backtick) { 
      if ($args[-1] eq ')') {
         $args[-1] = '`';
         $g_unterminated_backtick = 0; 
         iout "@args $last";
         dec_indent();
      }
      else {
         iout "@args $last";
      }
      
      $ntok += @args;      # January 2009
   }
   else {
      my @perlbi;
      my $user_function = 0;
      
      # pipes?
      # This loop replaces the grep below (it was detecting | inside quotes)
      for my $tok (@args) {
          next if $tok =~ /^([\'\"]).*\1$/;
          if ($tok =~ /\|[^\|]/) {    # RE change 0.05
              $ntok = App::sh2p::Parser::analyse_pipeline (@args);
              return $ntok;
          }
      }

      #if ( grep /\|[^\|]/, @args) {    # RE change 0.05
      #    $ntok = App::sh2p::Parser::analyse_pipeline (@args);
      #    return $ntok;
      #}
      
      # shortcuts or break? 0.05
      my @types  = App::sh2p::Parser::identify (1, @args);
      my $i;
      for ($i = 0;$i < @types; $i++) {
          if ($types[$i][0] eq 'OPERATOR') {
              no_semi_colon();
              splice (@args, $i);
              last
          }
          elsif ($types[$i][0] eq 'BREAK') {
              splice (@args, $i);
              last
          }
      }
            
      # Strip quotes January 2009
      my $name = $args[0];
      $name =~ s/^([\"\'])(.*)\1$/$2/;
      #print STDERR "Handle_external: <$name>\n";
      
      # If a user function, then call it as a subroutine
      if (is_user_function($name)) {
         $func = $name;
         shift @args;
         $user_function = 1;
         $ntok++;
      }
      elsif (@perlbi = App::sh2p::Parser::get_perl_builtin($name)) {
         # Do my best to trap unnecessary child processes
         $ntok = &{$perlbi[0]}(@_);
         return $ntok;
      }
      
      if (is_break($args[0])) {
          my @caller = caller();
          print STDERR "@caller\n";
          error_out ("++++ Internal error: Invalid break in Handle_external");
      }
     
      my $append = '';
      $append = ';' if query_semi_colon();
      
      iout "$func (";
                
      # Parse arguments
      if ( $user_function ) {
          
          if (@args) {
          
              for (my $i = 0; $i < @args; $i++) {         
                  $ntok++;
                  # Escape embedded quotes
                  $args[$i] =~ s/\"/\\\"/g;
                  #"help syntax highlighter
                  $args[$i] = "\"$args[$i]\"";
                  $args[$i] .= ',' if $i < $#args;
              } 
              
	      interpolation ("@args");
	  }
      }
      else {
          for my $arg (@args) {           
              $ntok++;
              # Escape embedded quotes
              $arg =~ s/\"/\\\"/g;
              #"help syntax highlighter
          }
                        
	  interpolation ("@args");
      }
      
      # Added 0.03
      if ($func eq 'system') {
          my $context = App::sh2p::Compound::get_context();
          if ($context eq 'if' || $context eq 'while') {
              $append .= '== 0';
          }
          elsif ($context eq 'until') {
              $append .= '!= 0';
          }
      }
      
      out ")$append $last";   # Moved 0.04

      out "\n" if query_semi_colon();
   }
   
   return $ntok;
}

##############################################################

sub Handle_Glob {

   my (@tokens) = @_;
   my $ntok = @tokens;
   
   local $" = '';
   iout "(glob(\"@tokens\"))";
   
   return $ntok;
}

############################################################################

sub Handle_unknown {   

   my ($token) = @_;

   # Don't quote if numeric or already has quotes
   if ($token =~ /^[-+]?\d+$/ || $token =~ /^\".*\"$/) {
       out "$token";
   }
   else {
       #my @caller = caller();
       #print STDERR "Handle_unknown token: <$token> @caller\n";
       out "\"$token\"";
   }
   
   return 1;
}

############################################################################
sub store_subs {

    my ($name, $subroutine) = @_;
    
    $g_subs{$name} = $subroutine;
    
}

sub write_subs {

    if (%g_subs) {
        out "\n#\n#  Subroutines added by sh2p\n#\n";
    }

    for my $sub (sort keys %g_subs) {
        out $g_subs{$sub};   
    }
}

############################################################################

sub store_sh2p_array_count {
    return if exists $g_subs{sh2p_array_count};
    
    $g_subs{sh2p_array_count} = << 'AC_HERE';

############################################################################
# Generated when ${!array[@]} is used
sub sh2p_array_count {
    my @array = @_;
    my $result = '';
    
    for (my $i=0; $i < @array; $i++) {
        $result .= "$i " if defined $array[$i];
    }
    
    # Should return a space separated scalar
    chop $result;   # remove final space
    return $result;
}

AC_HERE
}

############################################################################

1;

__END__
=head1 Summary

package App::sh2p::Handlers;
sub Handle_assignment
sub Handle_list_assign
# Bash 3.0, ksh93 array initialisation (inc. += )
sub Handle_array_assignment
sub Handle_break
sub Handle_open_redirection
sub Handle_close_redirection
sub Query_redirection
sub Handle_variable
sub Handle_expansion
sub Handle_delimiter
sub Handle_subshell 
sub interpolation
sub Handle_2char_qx
sub Handle_external
sub Handle_Glob 
sub Handle_unknown 
sub write_subs 
sub store_sh2p_array_count 
sub sh2p_array_count 
# Generated when ${!array[@]} is used
=cut
