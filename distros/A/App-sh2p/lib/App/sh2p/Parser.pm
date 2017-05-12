package App::sh2p::Parser;

use strict;
use warnings;

use App::sh2p::Compound;
use App::sh2p::Trap;
use App::sh2p::Utils;

sub convert(\@\@);

our $VERSION = '0.06';
our $DEBUG   = 0;

###########################################################

my %icompound = 
                ( 'case'     => \&App::sh2p::Compound::Handle_case,
                  'do'       => \&App::sh2p::Compound::Handle_do,
                  'done'     => \&App::sh2p::Compound::Handle_done,
                  'elif'     => \&App::sh2p::Compound::Handle_elif,
                  'else'     => \&App::sh2p::Compound::Handle_else,
                  'esac'     => \&App::sh2p::Compound::Handle_esac,
                  'fi'       => \&App::sh2p::Compound::Handle_fi,
                  'for'      => \&App::sh2p::Compound::Handle_for,
                  'function' => \&App::sh2p::Compound::Handle_function,
                  'if'       => \&App::sh2p::Compound::Handle_if,
                  'in'       => \&App::sh2p::Compound::Ignore,
                  'select'   => \&App::sh2p::Compound::Handle_for,
                  'then'     => \&App::sh2p::Compound::Handle_then,
                  'time'     => 5,
                  'until'    => \&App::sh2p::Compound::Handle_until,
                  'while'    => \&App::sh2p::Compound::Handle_while,
                  '!'        => \&App::sh2p::Compound::Handle_not,
                  '{'        => \&App::sh2p::Compound::open_brace,
                  '}'        => \&App::sh2p::Compound::close_brace,
                );
   
my %ioperator =
               ( '&&' => \&App::sh2p::Operators::shortcut,
                 '||' => \&App::sh2p::Operators::shortcut,
                 '|&' => 3,
                 #'&'  => 4,      January 2009
                 );
                
my %idelimiter =
               ( '\''  => \&App::sh2p::Handlers::Handle_delimiter,
                 '"'   => \&App::sh2p::Handlers::Handle_delimiter,
                 '`'   => \&App::sh2p::Handlers::Handle_delimiter,
                 '$('  => \&App::sh2p::Handlers::Handle_2char_qx,
                 '${'  => \&App::sh2p::Handlers::Handle_expansion,   # Problems, do specific testing?
                 '('   => \&App::sh2p::Handlers::Handle_delimiter,
                 ')'   => \&App::sh2p::Handlers::Handle_delimiter,
                 '['   => \&App::sh2p::Compound::sh_test,
                 '#'   => \&App::sh2p::Handlers::Handle_delimiter,   # 'COMMENT',
                 ';'   => \&App::sh2p::Handlers::Handle_delimiter,
                 '|'   => \&App::sh2p::Handlers::Handle_pipe,
                 '[['  => \&App::sh2p::Compound::ksh_test,
                 '(('  => \&App::sh2p::Compound::arith,
                 '$((' => \&App::sh2p::Compound::arith,
                ); 
                
my %ibuiltins =
               ( ':'        => \&App::sh2p::Builtins::do_colon,
                 '.'        => \&App::sh2p::Builtins::do_source,
                 'alias'    => 2,
                 'autoload' => \&App::sh2p::Builtins::do_autoload,
                 'bg'       => 3,
                 'bind'     => 4,
                 'break'    => \&App::sh2p::Builtins::do_break,
                 'builtin'  => 6,
                 'cd'       => \&App::sh2p::Builtins::do_cd,
                 'command'  => 8,
                 'continue' => \&App::sh2p::Builtins::do_continue,
                 'echo'     => \&App::sh2p::Builtins::do_print,
                 'eval'     => 2,
                 'exec'     => \&App::sh2p::Builtins::do_exec,
                 'exit'     => \&App::sh2p::Builtins::do_exit,
                 'export'   => \&App::sh2p::Builtins::do_export,
                 'false'    => \&App::sh2p::Builtins::do_false,
                 'fc'       => 7,
                 'fg'       => 8,
                 'functions'=> \&App::sh2p::Builtins::do_functions,
                 'getopts'  => 9,
                 'integer'  => \&App::sh2p::Builtins::do_integer,
                 'hash'     => 10,
                 'jobs'     => 11,
                 'kill'     => \&App::sh2p::Builtins::do_kill,
                 'let'      => \&App::sh2p::Builtins::do_let,
                 'print'    => \&App::sh2p::Builtins::do_print,
                 'read'     => \&App::sh2p::Builtins::do_read,
                 'readonly' => 7,
                 'return'   => \&App::sh2p::Builtins::do_return,
                 'set'      => \&App::sh2p::Builtins::do_set,
                 'shift'    => \&App::sh2p::Builtins::do_shift,
                 'test'     => \&App::sh2p::Compound::sh_test,
                 '['        => \&App::sh2p::Compound::sh_test,
                 'time'     => 12,
                 'times'    => 13,
                 'tr'       => \&App::sh2p::Builtins::do_tr,
                 'trap'     => \&App::sh2p::Trap::do_trap,
                 'true'     => \&App::sh2p::Builtins::do_true,
                 'typeset'  => \&App::sh2p::Builtins::do_typeset,
                 'ulimit'   => 17,
                 'umask'    => \&App::sh2p::Builtins::do_chmod,
                 'unalias'  => 19,
                 'unset'    => \&App::sh2p::Builtins::do_unset,
                 'wait'     => 21,
                 'whence'   => 22,
                 # Bash specifics
                 'declare'  => \&App::sh2p::Builtins::do_typeset,
                 'local'    => \&App::sh2p::Builtins::do_typeset,
                 'shopt'    => \&App::sh2p::Builtins::do_shopt,
                 'source'   => \&App::sh2p::Builtins::do_source,
               );

my %perl_builtins =
               ( 'awk'     => [\&App::sh2p::Builtins::advise,'Perl code, often split'],
                 'basename'=> [\&App::sh2p::Builtins::advise,'File::Basename::basename'],
                 'cat'     => [\&App::sh2p::Builtins::advise,'ExtUtils::Command::cat'],
                 'chmod'   => [\&App::sh2p::Builtins::do_chmod], 
                 'chown'   => [\&App::sh2p::Builtins::do_chown],
                 'chgrp'   => [\&App::sh2p::Builtins::do_chown],
                 'cp'      => [\&App::sh2p::Builtins::advise,'File::Copy'],
                 'cut'     => [\&App::sh2p::Builtins::advise,'split'],
                 'date'    => [\&App::sh2p::Builtins::advise,'localtime or POSIX::strftime'],
                 'df'      => [\&App::sh2p::Builtins::advise,'Filesys::Df'],
                 'diff'    => [\&App::sh2p::Builtins::advise,'File::Compare'],
                 'dirname' => [\&App::sh2p::Builtins::advise,'File::Basename::dirname'],
                 'egrep'   => [\&App::sh2p::Builtins::advise,'while(<>){print if /re/} or perl grep'],
                 'eval'    => [\&App::sh2p::Builtins::one4one,'eval'],
                 'exec'    => [\&App::sh2p::Builtins::advise,'exec or pipe (co-processes) or open (file descriptors)'],		
                 'expr'    => [\&App::sh2p::Builtins::do_expr],
                 'find'    => [\&App::sh2p::Builtins::advise,'File::Find'],
                 'file'    => [\&App::sh2p::Builtins::advise,'File::Type'],
                 'ftp'     => [\&App::sh2p::Builtins::advise,'Net::Ftp'],
                 'grep'    => [\&App::sh2p::Builtins::advise,'while(<>){print if /re/} or perl grep'],
                 'ln'      => [\&App::sh2p::Builtins::one4one,'link'],
                 'ln -s'   => [\&App::sh2p::Builtins::one4one,'symlink'],
                 'ls'      => [\&App::sh2p::Builtins::advise,'glob or opendir/readdir/closedir or stat/lstat'],
                 'mkdir'   => [\&App::sh2p::Builtins::one4one,'mkdir'],
                 'mkpath'  => [\&App::sh2p::Builtins::advise,'ExtUtils::Command::mkpath'],
                 'mv'      => [\&App::sh2p::Builtins::one4one,'rename'],
                 'od'      => [\&App::sh2p::Builtins::advise,'ord or printf'],
                 'printf'  => [\&App::sh2p::Builtins::one4one,'printf'],
                 'pwd'     => [\&App::sh2p::Builtins::advise,'Cwd::getcwd'],
                 'rand'    => [\&App::sh2p::Builtins::one4one,'rand'],
                 'rm'      => [\&App::sh2p::Builtins::one4one,'unlink'],
                 'rm -f'   => [\&App::sh2p::Builtins::advise,'ExtUtils::Command::rm_rf'],
                 'sed'     => [\&App::sh2p::Builtins::advise,'s/// (usually)'],
                 'select'  => [\&App::sh2p::Builtins::advise,'Shell::POSIX::select'],
                 'sleep'   => [\&App::sh2p::Builtins::one4one,'sleep'],
                 'sort'    => [\&App::sh2p::Builtins::one4one,'sort'],
                 'tail'    => [\&App::sh2p::Builtins::advise,'File::Tail'],
                 'telnet'  => [\&App::sh2p::Builtins::advise,'Net::Telnet'],
                 'touch'   => [\&App::sh2p::Builtins::do_touch],
                );
###########################################################
# $ibuiltins added 0.04
sub get_perl_builtin {
    my $func = shift;
    
    
    if (defined $perl_builtins{$func}) {
        return @{$perl_builtins{$func}};
    }
    elsif (defined $ibuiltins{$func}) {
        return ($ibuiltins{$func}, $func);
    }
    else {
        return ();
    }
}

###########################################################

sub tokenise {
   my @tokens;
   my $index    = 0;
   my $q        = 0;
   my $qq       = 0;
   my $qx       = 0;
   my $qp       = 0;   # ()
   my $qs       = 0;   # []
   my $br       = 0;   # {}
   my $esc      = 0;   # \
   my $comment  = 0;
   my $heredoc  = 0;
   my $variable = 0;
   
   my ($line) = @_;
   
   for my $char (split '', $line) {
      
      if ($comment) {
         $tokens[$index] .= $char;
         next   
      }      
      
      if ($heredoc) {
         #$g_herelabel .= $char;
         $tokens[$index] .= $char;
         next;
      }
      
      if ($esc) {
         $tokens[$index] .= $char;
         $esc = 0;
         next;         
      }
      
      if ($variable) {
          if ($char =~ /[^A-Z0-9#@*\$\-!\{\}\[\]]/i) {
              $variable = 0;
          }
      }
      
      if ($char eq '$') {
         $variable = 1;
      }
      elsif ($char eq '\'') {
         $q = $q?0:1;
      }
      elsif ($char eq '`') {
         $qx = $qx?0:1;
      }
      elsif ($char eq '"') {
         $qq = $qq?0:1;
      }    
      elsif ($char eq '[') {  # Take into account nested []
         $qs++;
      }
      elsif ($qs && $char eq ']') {
         $qs--
      }
      elsif ($char eq '{') {  # Take into account nested {}
         $br++;
      }
#      Tried, but had unexpected side-effects
#      elsif ($br && $char eq '}' && !$q && !$qq && !$qx && !$qp && !$qs) {   
#         $tokens[$index] .= $char;
#         $index++;
#         $br--;
#         next;
#      }
      # Modification of above 
      elsif ($br && $char eq '}') {   
         $br--;
      }
      elsif ($char eq '\\') {
         $tokens[$index] .= $char;
         $esc = 1;
         next;
      }
      
      # Take into account nested ()
      if ($char eq '(') {
         $qp++
      }
      elsif ($qp && $char eq ')') {
         $qp--
      }

      # Not inside a delimiter
      if (!$q && !$qq && !$qx && !$qp && !$qs && !$br) {
         if ($char eq '#' && !$variable) {
            $comment = 1
         }
         
         if ($char =~ /\s/ && !$comment) {
            $index++ if defined $tokens[$index];
         }
         elsif ($char eq ';' && !$comment) {
           $index++ if defined $tokens[$index];
           $tokens[$index] .= $char;
           $index++;
         }
         elsif ($char eq '<' && !$comment) {
              # Here doc? 
             if (defined $tokens[$index]) {
                 if ($tokens[$index] ne '<') {         
                     $index++ if defined $tokens[$index];
                     $tokens[$index] .= $char;
                 }
                 else {
                     $heredoc = 1;
                     $tokens[$index] .= $char;
                     $index++;
                 }
             }
             else {
                 $tokens[$index] .= $char;
             }
         }
         elsif ($char eq '>' && !$comment) {
           if (defined $tokens[$index] && $tokens[$index] ne '>') {          # Append? 
              $index++ if defined $tokens[$index];
              $tokens[$index] .= $char;
           }
           else {
              $tokens[$index] .= $char;
              $index++;
           }
         }
         else {
            $tokens[$index] .= $char;
         }
      }
      else {
         $tokens[$index] .= $char;
      }
   }
   
   $tokens[$index] .= "\n" if $comment;
   
   return @tokens
}

###########################################################
# First argument is used to identify external program calls
#   nested = 0 - call is not nested, first argument may be an external program
#   nested = 1 - call is not nested, first argument is not an external program
#   nested = 2 - as 1, plus call is as a list

sub identify {
   my ($nested, @in) = @_;
   my @out;
   my $first = $in[0];
   
   if (!@in) {
       print STDERR "+++ Internal error: Empty input array to identify\n";
       my @caller = caller();
       die "@caller\n";
   }
   
   #print STDERR "identify first <$first>\n";
   # Special processing for the first token
   
   if ($first =~ /^\w+\+?=/) {
      $out[0] = [('ASSIGNMENT', 
                 \&App::sh2p::Handlers::Handle_assignment)];
      shift @in
   }
   elsif ($first =~ /^\w+\[.*\]=/) {
      $out[0] = [('ARRAY_ASSIGNMENT', 
                 \&App::sh2p::Handlers::Handle_array_assignment)];
      shift @in
   }
   elsif (is_break($first)) {
      $out[0] = [('BREAK', 
                 \&App::sh2p::Handlers::Handle_break)];
      shift @in
   }
   elsif (!$nested && $first =~ /^([\"]?)\$[A-Z0-9#@*{}\[\]]+\1/i) {   # Optional " added January 2009
       # Not a variable, but a call (variable contains call name)
       $out[0] = [('EXTERNAL',
                  \&App::sh2p::Handlers::Handle_external)];
       shift @in;
   }

   # Now process the rest
   
   for my $token (@in) {
   
      #print STDERR "Identify token: <$token> <$nested>\n";
   
      my $type = 'UNKNOWN';
      my $sub  = \&App::sh2p::Handlers::Handle_unknown;

      if (ref($token) eq 'CODE') {
         $sub  = $token;
         $type = 'INTERNAL';      
      }
      elsif ($token =~ /^\w+=/) {
         $sub  = \&App::sh2p::Handlers::Handle_assignment;
         $type = 'ASSIGNMENT';
      }
      elsif ($token =~ /^\w+\[.*\]=/) {
          $sub  = \&App::sh2p::Handlers::Handle_array_assignment;
          $type = 'ARRAY_ASSIGNMENT';
      }
      elsif (exists $icompound{$token}) {
         $sub  = $icompound{$token};
         $type = 'COMPOUND';
      }
      elsif (exists $ioperator{$token} && $nested < 2) {
         $sub  = $ioperator{$token};
         $type = 'OPERATOR';
         # Shortcut, next is another command
      }
      elsif (exists $ibuiltins{$token} && $nested < 2) {
         $sub  = $ibuiltins{$token};
         $type = 'BUILTIN'
      }
      elsif (exists $perl_builtins{$token} && $nested < 2) {
         $sub  = $perl_builtins{$token}[0];
         $type = 'PERL_BUILTIN'
      }      
      else {
         my $first_char  = '';
         my $two_chars   = '';
         my $three_chars = '';
         
         $first_char  = substr($token, 0, 1);
         $two_chars   = substr($token, 0, 2) if length($token) > 1;
         $three_chars = substr($token, 0, 3) if length($token) > 2;
                  
         if (exists $idelimiter{$three_chars}) {
            $type = 'THREE_CHAR_DELIMITER';
            $sub  = $idelimiter{$three_chars};        
         }
         elsif (exists $idelimiter{$two_chars}) {
            # Special hack for variables
            if ( $two_chars eq '${' && (!@out || ($out[-1]->[0] eq 'BREAK')) && 
	    	  !$nested && !is_break($first_char)) {   # Must be first token
	        $type = 'EXTERNAL';
	    	$sub = \&App::sh2p::Handlers::Handle_external;
	    }
	    else {
                $type = 'TWO_CHAR_DELIMITER';
                $sub  = $idelimiter{$two_chars};
            }
         }
         elsif (exists $idelimiter{$first_char}) {   # January 2009
            if ( $first_char eq '"' && (!@out || ($out[-1]->[0] eq 'BREAK')) && 
	    	  !$nested && !is_break($first_char)) {   # Must be first token
	        $type = 'EXTERNAL';
	    	$sub = \&App::sh2p::Handlers::Handle_external;
	    }
	    else {
                $type = 'SINGLE_DELIMITER';
                $sub  = $idelimiter{$first_char};
            }
         }
         elsif ($first_char eq '~') {
            $type = 'GLOB';
            $sub  = \&App::sh2p::Handlers::Handle_Glob;
         }
         elsif ( (!@out || ($out[-1]->[0] eq 'BREAK')) && 
                  !$nested && !is_break($first_char)) {   # Must be first token
            $type = 'EXTERNAL';
            $sub = \&App::sh2p::Handlers::Handle_external;
         }
         # January 2009 This test must come after the 'EXTERNAL' test, 
         # otherwise a bare variable is not seen as an external call
         elsif ($first_char eq '$' && $token =~ /^\$[A-Z0-9\#\@\*\?\{\}\[\]]+$/i) {        
            $type = 'VARIABLE';
            $sub  = \&App::sh2p::Handlers::Handle_variable
         }
         elsif (is_break($token)) {      # 0.06
            $type = 'BREAK';
            $sub = \&App::sh2p::Handlers::Handle_break;
         }
         elsif (exists $ioperator{$two_chars} && $nested) {
	    $sub  = $ioperator{$two_chars};
	    $type = 'OPERATOR'
	 }
         elsif (exists $ioperator{$first_char} && $nested) {
            $sub  = $ioperator{$first_char};
            $type = 'OPERATOR'
         }
         elsif ($token =~ /\[|\*|\?/ && !query_in_quotes()) {
            # No globbing inside quotes
	    $sub  = \&App::sh2p::Handlers::Handle_Glob;
	    $type = 'GLOB';
	 }

      }
      push @out, [($type, $sub)];
   }
   
   return @out;
   
}

###########################################################

sub convert (\@\@) {
   my ($rtok, $rtype) = @_;  
   
   if ( $DEBUG ) {
      my @caller = caller();
      print STDERR "\nconvert called from @caller\n";
      local $" = '|';
      print STDERR "convert:@$rtok\nconvert: ";
      print STDERR (map {"$_->[0] "} @$rtype),"\n";
   }

   if (@$rtok != @$rtype ) {
      print STDERR "+++ Internal Error rtok: <@$rtok>, rtype: <@$rtype>\n";
      die "Parser::convert: token and type arrays uneven\n"
   }
   
   pop @$rtok if (is_break($rtok->[-1]));
   my $tokens_processed = 0;
   
   #print_types_tokens ($rtype, $rtok);
   
   while (@$rtok) {
    
      my $type = $rtype->[0][0];
      my $sub  = $rtype->[0][1];
      
      #print STDERR "tokens: <@$rtok> type: $type, sub: $sub\n";
      if (ref($sub) eq 'CODE' ) {
      
         if ($type eq 'COMPOUND') {
             test_for_redirection($rtok, $rtype);
         }
      
         $tokens_processed = &$sub(@$rtok);
         
         if ($tokens_processed > @$rtok) {
             error_out "Internal error: Token count wrong! Was: $tokens_processed, max: ".scalar(@$rtok);
             error_out "Type: $rtype->[0][0], tokens: @$rtok";
         }
      }
      else {      
         error_out ("No conversion routine for $type $rtok->[0]");
         out "$rtok->[0]\n";
         $tokens_processed = 1;
      }
      
      if ($tokens_processed) {
          # Remove tokens already processed
          splice (@$rtok,  0, $tokens_processed);
          splice (@$rtype, 0, $tokens_processed);
      }
   }
   
}

########################################################
# Called by convert
sub test_for_redirection {
    
    my ($rtok, $rtype) = @_;
    
    my $next_type = $rtype->[1][0];
    
     
    return 0 if !defined $next_type || $next_type ne 'BUILTIN'; 
  
    #print_types_tokens($rtype, $rtok);
        
    for (my $i = 2; $i < @$rtok; $i++) {
        if ($rtok->[$i] eq '<' || $rtok->[$i] eq '>' || $rtok->[$i] eq '>>') {     
	    
	    if ( !defined $rtok->[$i+1] ) {
	         die "*** Malformed redirection (no file)\n";
	    }
	
	    my $redirection_file = $rtok->[$i+1];
	    $redirection_file =~ s/^\s+//; 
	    App::sh2p::Handlers::Handle_open_redirection ($rtok->[$i], 
	                                                  $redirection_file);
            # Remove tokens processed
            splice (@$rtok,  $i, 2);
            splice (@$rtype, $i, 2);
	    
	    return 2;
	}
    }
}

########################################################

sub join_parse_tokens {

    my ($sep, @args) = @_;
    my $ntok = 0;

    # C style for loop because I need to check the position
    for (my $i = 0; $i < @args; $i++) {
        
        my @tokens = ($args[$i]);
        my @types  = identify (2, @tokens);
   
        #print_types_tokens(\@types, \@tokens);
        
        convert (@tokens, @types); 
        $ntok++;
        
        # Look ahead to see if we are at end
        if ($i < $#args) { 
            last if substr($args[$i+1],0,1) eq '#';  
            last if is_break($args[$i+1]);
            last if $args[$i+1] eq ';';      # January 2009
            out $sep;
        }
        
    }

    return $ntok;
}

###########################################################

sub analyse_pipeline {
    my @args = @_;
    my $ntok = @args;
    my $end_value = '';
    
    error_out ();
    error_out "Pipeline '@args' detected";
    
    #my @caller = caller();
    #print STDERR "analyse_pipeline: <@args><@caller>\n";
    
    # Get commands, sometimes the | is separate, sometimes not
    @args = split /\|/, "@args";
    
    App::sh2p::Handlers::no_semi_colon();
    
    # Let's make a guess.  echo or print at the front usually means
    # that the command which follows wants a string
    if ($args[0] =~ s/^(echo |print )//) {
        $end_value = shift @args;         
    }
    
    for (my $i = 0; $i < @args; $i++) {
        $args[$i] =~ s/^\s+//;      # Strip leading whitespace
        $args[$i] =~ s/\s+$//;      # Strip trailing whitespace
        
        if (! $args[$i] ) {
            # Blank line - remove it
            splice (@args, $i, 1);
            $i--;   # to counteract the ++
            next;
        }
        
        my @tokens = tokenise ($args[$i]);
        my @types  = identify (0, @tokens);
        
        # We are delimited by |, so get the arguments as well
        # external call is not the last in the pipe, change to back-ticks
        if ( $types[0][0] eq 'EXTERNAL' && $i < $#args) {
        
            @types = (['DELIMITER',\&App::sh2p::Handlers::Handle_2char_qx]);
            @tokens = ("\$(@tokens)");
            
            if ($args[$i+1] =~ /^\s*grep/) {
                # Switch next command around with this
                $i++;
                $args[$i] =~ s/^\s+//; 
		$args[$i] =~ s/\s+$//;

                my @next_tokens = tokenise ($args[$i]);
                my @next_types  = identify (0, @next_tokens);
                convert (@next_tokens, @next_types);
            }
        }

	#print_types_tokens (\@types, \@tokens);
	
	convert (@tokens, @types);
	out '|' if $i < $#args;
    }
    out "$end_value";
    out "\n" if !App::sh2p::Compound::get_context();
    
    App::sh2p::Handlers::reset_semi_colon();
    error_out ();
    
    return $ntok;
}

###########################################################

1;
