package App::sh2p::Builtins;

use strict;
use Getopt::Std;
use App::sh2p::Utils;
use App::sh2p::Parser;
use App::sh2p::Here;

our $VERSION = '0.06';
sub App::sh2p::Parser::convert(\@\@);

my %g_shell_options;
my %g_file_handles;

########################################################
#
# Note for developers: 
#      There are a lot of functions in here, 
#      try to keep them in alphabetic order
#
########################################################
# For builtins/functionality that cannot be implemented
sub not_implemented {
   error_out "The following line cannot be translated:";
   error_out "@_";

   return scalar(@_);
}

########################################################

sub one4one {

    my ($func, @args) = @_;
    my $new_func = (App::sh2p::Parser::get_perl_builtin($func))[1];
    
    error_out ("$func replaced by Perl built-in $new_func\n".
               "#               Check arguments and return value");
    
    return general_arg_list($new_func, @args);
}

########################################################

sub general_arg_list {
    my ($cmd, @args) = @_;
    my $ntok = 1;
    my $last = '';
    
    #{local $" = '|';print STDERR "general_arg_list: <@args>\n";}
    
    # Is final token a comment?
    if (substr($args[-1],0,1) eq '#') {
        $last = pop @args;
        $ntok++;
    }
    
    my $semi = '';
    $semi = ';' if query_semi_colon();
          
    # Parse arguments
    for my $arg (@args) { 
    
        last if is_break($arg);  # 0.05
        last if $arg eq ';';     # January 2009
        $ntok++;
        
        # Here doc January 2009
        if ( $arg eq '<<' ) {
           my $heredoc = App::sh2p::Here::get_last_here_doc();
	   
	   if (defined $heredoc) {
	      my $filename = App::sh2p::Here::gen_filename($heredoc);
	      App::sh2p::Here::abandon_sh2p_here_subs ();
	      error_out("Heredoc replaced by simple redirection");
	      $arg = "< $filename";
           } 
           next;      # Yuk!
        }

        # Wrap quotes around it:
        #    if it is not a digit && it doesn't already have quotes &&
        #    it isn't a glob constuct
        if ($arg !~ /^\d+$/ && $arg !~ /^([\'\"]).*\1$/ && $arg !~ /\[|\*|\?/) {
            # Escape embedded quotes 
            $arg =~ s/\"/\\\"/g;
            #"help syntax highlighter
            $arg = "\"$arg\"";
        }
    }    

    #{local $" = '|';print STDERR "general_arg_list: <@args>\n";}
    iout "$cmd (";
    App::sh2p::Parser::join_parse_tokens (',', @args);
    out ")$semi $last";
        
    iout "\n" if query_semi_colon();
    
    return $ntok;

}

########################################################

sub advise {

    my $func = shift;
        
    my $advise = (App::sh2p::Parser::get_perl_builtin($func))[1];
    
    error_out ("$func should be replaced by something like $advise");
    
    my @args;
    
    # Pipeline?
    for my $arg (@_) {
        last if ($arg eq '|');
        push @args, $arg if $arg;
        # print STDERR "advise: <$arg>\n";
    }
    
    return general_arg_list($func, @args);
}

########################################################

sub do_autoload {

    my ($cmd, @functions) = @_;
    my $ntok = 1;
    
    for my $func (@functions) {
        my $first_char = substr($func,0,1);
        last if is_break($func) || $func eq ';' || $first_char eq '#';

        if ($first_char eq '$') {
            # $cmd used - this might be called from typedef
            error_out "$cmd '$func' ignored";
        }
        else {
            set_user_function ($func);
        }
        
        $ntok++;
    }
    
    return $ntok;   
}

########################################################

sub do_break {

   my (undef, $level) = @_;
   my $ntok = 1;
   
   iout 'last';
   
   if (query_semi_colon()) {
       out ";\n";
   }

   if (defined $level && $level =~ /^\d+$/) {
      error_out "Multiple levels in 'break $level' not supported";
      $ntok++;
   }

   return $ntok;
}

########################################################

sub do_colon {

    my ($colon) = @_;
    
    if (!query_semi_colon()) {
        # Probably in a conditional
        out '(1)';
    }
    else {
        iout '';
    }
    
    return 1;
}

########################################################

sub do_continue {

   my (undef, $level) = @_;
   my $ntok = 1;
   
   iout 'next';
   
   if (query_semi_colon()) {
       out ";\n";
   }

   if (defined $level && $level =~ /^\d+$/) {
      error_out "Multiple levels in 'continue $level' not supported";
      $ntok++;
   }

   return $ntok;
}

########################################################
# 0.04 - removed quote handling
sub do_cd {

   my (undef, @args) = @_;
   my $ntok = 1;
   my $comment = "\n";
   
   pop @args if !$args[-1];
   
   iout 'chdir (';
           
   for (my $i=0; $i < @args; $i++) {
                   
       $ntok++;
   	        
       if (substr ($args[$i],0,1) eq '#') {
           my @comment = splice (@args,$i);
           $comment = "@comment";
   	            
           # remove trailing comment from previous item
           $args[$i-1] =~ s/\.$// if $i > 0;
           last
       }
   
       # Wrap quotes around it:
       if ($args[$i] !~ /^\d+$/    &&     # if it is not a digit 
           $args[$i] !~ /^\".*\"$/ &&     # it doesn't already have quotes 
           $args[$i] !~ /\[|\*|\?/) {     # it isn't a glob constuct
           # Escape embedded quotes
           $args[$i] =~ s/\"/\\\"/g;
           #"help syntax highlighter
           $args[$i] = "\"$args[$i]\"";
       }
       
       $args[$i] .= '.' if $i < $#args;
   } 
   
#   $ntok += App::sh2p::Parser::join_parse_tokens ('.', @args);
   App::sh2p::Parser::join_parse_tokens ('.', @args);
   
   out ')';

   if (query_semi_colon()) {
       out "; $comment";
   }

   return $ntok;
}

########################################################
# TODO: comma separated groups
sub chmod_text_permissions {

   my ($in, $file) = @_;
   
   iout "# chmod $in $file\n";
   
   # Remove any surrounding quotes 0.06
   $file =~ s/^\"(.*)\"$/$1/; 
   
   my $stat = "{ my \$perm = (stat \"$file\")[2] & 07777;\n";
   
   # numbers are base 10: I'm constructing a string, not an octal int
   my %classes = ( u => 100, g => 10, o => 1);
   my %access  = ( x => 1, w => 2, r => 4);
   
   # Linux man page                      [ugoa]*([-+=]([rwxXst]*|[ugo]))+
   my ($class, $op, $access) = $in =~ /^([ugoa]*)([-=+])([rwx]+)?$/;
   
   my $mask  = 0;
   my $perms = 0;
   
   $class = 'ugo' if $class eq 'a' or !$class;
   $access = 0 if !$access;

   for (split('', $access)) {$mask  += $access{$_}}
   for (split('', $class))  {$perms += $mask * $classes{$_}}
    
   $perms = sprintf ("0%03d", $perms);
 
   iout "$stat  ";

   if ($op eq '=') {
       my $mask = 0; 
       for (split('', $class))  {$mask += 7 * $classes{$_}}
       $mask = sprintf ("0%03d", $mask);

       out "\$perm &= ~0$mask;";
       out "chmod(\$perm,\"$file\");chmod(\$perm|$perms"
   }
   elsif ($op eq '+') {
       out "chmod (\$perm | $perms";
   }
   else {
       out "chmod (\$perm & ~$perms";
   }

   out ", \"$file\")}\n";     
}

########################################################
# also used by umask
sub do_chmod {
    
    my ($cmd) = shift;
    my ($opt) = shift;
    my $perms;
    my $ntok = 2; 

    if (substr($opt,0,1) eq '-') {
       error_out ("$cmd options not yet supported");
       $perms = shift;
       $ntok++;
    }
    else {
       $perms = $opt;
       $opt = '';
    }
    
    my @args = @_;

    my $comment = '';
    my $text = '';
    
    if ( $perms !~ /^\d+$/ ) {
       for my $file (@args) {
           chmod_text_permissions ($perms, $file);
           $ntok++;
       }
       return $ntok;
    }

    iout "$cmd ";
    
    if (defined $perms) {
        #$ntok++;      0.06
        
        if ($cmd eq 'chmod') {
            out "0$perms,";
        }
        elsif ($cmd eq 'umask') {
            out "0$perms";
        }
        else {
            out "$perms,";
        }
        
        if (@args && $cmd ne 'umask') {
        
            for (my $i=0; $i < @args; $i++) {
                
	        $ntok++;
	        if (substr ($args[$i],0,1) eq '#') {
	            my @comment = splice (@args,$i);
	            $comment = "@comment";
	            
	            # remove trailing comment from previous item
	            $args[$i-1] =~ s/,$// if $i > 0;
	            last
	        }
	        
	        # Remove any surrounding quotes 0.06
	        $args[$i] =~ s/^\"(.*)\"$/$1/;      
	        
	        # Escape embedded quotes 
	        #$args[$i] =~ s/\"/\\\"/g;   # commented out 0.06
	        #"help syntax highlighter
	        
	        $args[$i] = "\"$args[$i]\"";
	        $args[$i] .= ',' if $i < $#args;
	    } 
	          
            App::sh2p::Handlers::interpolation ("@args");
        }
    }
    out "; $comment\n";
    
    return $ntok;
}

########################################################

sub do_chown {
    
    my ($cmd) = shift;
    my ($opt) = shift;
    my $ugrp;
    my $ntok = 1;

    if (substr($opt,0,1) eq '-') {
       error_out ("$cmd options not yet supported");
       $ugrp = shift;
       $ntok++;
    }
    else {
       $ugrp = $opt;
       $opt = '';
    }
    
    my @args = @_;

    my $comment = '';
    my $text = '';
    
    if (defined $ugrp) {
        $ntok++;   
        if ($cmd eq 'chown') {
            iout "{my(\$uid,\$gid)=(getpwnam(\"$ugrp\"))[2,3];";
        }
        else { # chgrp
            iout "{my (\$name,undef,\$gid)=getgrname(\"$ugrp\");\n";
            out  " my \$uid=(getpwnam(\$name))[2];\n ";
        }
        out "chown \$uid, \$gid,";   # There is no chgrp
    }
    else {
        error_out ("No user/group supplied for $cmd");
        iout $cmd;
    }
        
    if (@args) {
        
       for (my $i=0; $i < @args; $i++) {
                
           $ntok++;
	        
           if (substr ($args[$i],0,1) eq '#') {
               my @comment = splice (@args,$i);
               $comment = "@comment";
	            
               # remove trailing comment from previous item
               $args[$i-1] =~ s/,$// if $i > 0;
               last
           }
	        
           # Escape embedded quotes
           $args[$i] =~ s/\"/\\\"/g;
           #"help syntax highlighter
           $args[$i] = "\"$args[$i]\"";
           $args[$i] .= ',' if $i < $#args;
       } 
	          
       App::sh2p::Handlers::interpolation ("@args");

    }
    out "}; $comment\n";
    
    return $ntok;
}

########################################################
 
sub do_exec {

   my (undef, @rest) = @_;
   my $ntok = 1;
   
   if ($rest[0] =~ /^\d$/) {
       error_out ("Warning: file descriptors are not supported");
       my ($fd, $access, $filename) = @rest;
       iout "open(my \$sh2p_handle$fd, '$access', \"$filename\") or ".
            "die \"Unable to open $filename: \$!\";\n";
       $ntok += 3;
       $g_file_handles{$fd} = $filename;
   }
   else {
       $ntok = general_arg_list('exec', @rest);
   }
   
   return $ntok;
}

########################################################

sub do_exit {

   my ($cmd, $arg) = @_;
   my $ntok = 1;
   
   if (defined $arg) {
       iout ("exit ($arg);\n");
       $ntok++;
   }
   else {
       iout ("exit;\n");
   }
   
   return $ntok;
}

########################################################

sub do_export {

   my $ntok = @_;
   # First argument should be 'export'
   shift @_;
   
   # TODO - other export arguments
   
   for my $env (@_) {
      if  ($env =~ /^(\w+)=(.*)$/) {
         $env = $1;
         my $value = $2;
         
         # 0.06
         if ($value =~ /^\$/) {
             my $special = get_special_var($value);
             $value = $special if defined $special;
             iout "\$ENV{$env} = $value;\n";
         }
         elsif ($value =~ /^\$/ || $value =~ /^([\"\']).*\1/) {
             iout "\$ENV{$env} = $value;\n";
         }
         else {
             iout "\$ENV{$env} = \"$value\";\n";
         }
      }
      else {
         iout "\$ENV{$env} = \$$env;\n";
         iout "undef \$$env;\n";
         Delete_variable ($env);
      }
      Register_env_variable ($env);
   }
   
   return $ntok;
}

########################################################

sub do_expr {
     
     # $cmd should be expr
     my ($cmd, @rest) = @_;
     my $ntok = 1;
     
     # temporary fix
     error_out ('Suspious conversion from expr');
     
     if (query_semi_colon()) {
         iout ("@rest");
     }
     else {
         out ("@rest");
     }
     
     return $ntok; 
}

########################################################

sub do_functions {

    my ($func) = @_;
    
    iout 'print map {"sub $_\n" if defined &{$_}} keys %main::;';
    
    return 1;

}

########################################################

sub do_integer {
    
    # $cmd should be 'integer'
    my ($cmd, $action, @rest) = @_;
    
    my $var = $action;
    
    # Remove any assignment from the name
    $var =~ s/=.*//;
           
    if (Register_variable ("\$$var", 'int') ) {
       iout 'my ';
    }
    
    my $retn = App::sh2p::Handlers::Handle_assignment ($action, @rest);
    
    $retn++;   # $cmd
    return $retn;
}

########################################################

sub do_kill {
    my ($cmd, @rest) = @_;
    my $signal;
    my $ntok = 0;
    
    # Remove the hyphen - it has a different meaning in Perl!
    if ($rest[0] =~ s/^-//) {
        $signal = shift @rest;
    }
    else {
        $signal = 'TERM';  # default signal
        
        # 0.06 Hack because this is an inserted token and 
        # general_arg_list will include this in its count
        $ntok--;           
    }

    #print STDERR "do_kill: <@rest>\n";

    $ntok += general_arg_list ($cmd, $signal, @rest);
    
    return $ntok;
}

########################################################

sub do_let {

    my ($cmd, @rest) = @_;
    my $ntok = 1;
    
    # Find any comment - this should go first
    if (substr($rest[-1],0,1) eq '#') {
        $ntok++;
        iout $rest[-1];      # Write the comment out
        pop @rest
    }
    
    for my $token (@rest) {
        # strip quotes
	$token =~ s/[\'\"]//g;

        # Get variable name
        $token =~ /^(.*?)=/;
        my $var = "\$$1";
        if (Register_variable($var, int)) {
            iout "my $var;\n";      # 0.05 added leading $
        }
        
        App::sh2p::Compound::arith ($token);
        $ntok++;
    }
    
    return $ntok;
}

########################################################
# Also does for echo
sub do_print {

   my $ntok = 1;
   my ($name, @args) = @_;
   my $newline = 1;
   my $handle = '';

   my $opt_u;
   my %options;
   local @ARGV;

   my $redirection = '';
   my $file        = '';
   my $from_fd     = '';       # TODO - not currently supported
   
   # Move the comment to before the statement
   if ( substr($args[-1],0,1) eq '#' ) {
       my $comment = pop @args;
       out "\n";
       iout $comment;
       $ntok++;
   }
   
   for my $arg (@args) {
       last if is_break($arg) || $arg eq ';';
       my $in_redirection_token = 0;
       
       # This is so a > inside a string is not seen as redirection
       if ($arg =~ /^([\"\']).*?\1/) {
           set_in_quotes();
       }
       
       # This should also strip out the redirection
       if (!query_in_quotes() && $arg =~ s/(\>{1,2})//) {
           
           $ntok++;
           $redirection = $1;
           $in_redirection_token = 1;
           
           if ($ARGV[-1] =~ /\d/) {
	       $from_fd = pop @ARGV;
               error_out ("dup file descriptors ($from_fd>&n) not currently supported");
               $ntok++;
           }
       }
       
       if ($arg && $redirection && (! $file)) {
           $arg =~ s/(\S+)//;
           $file = $1;
           $ntok++ unless $in_redirection_token;
       }
       
       unset_in_quotes();
       push @ARGV, $arg if $arg;
       #$ntok++;    0.05 commented out
   }
   
   if ($redirection) {
       
       #print STDERR "do_print redirection file <$file>\n";
       # January 2009
       if ( $file =~ /^\&(\d+)$/ ) {
           my $fd = $1;
           if ($fd == 1) {
               $handle = 'STDOUT ';
           }
           elsif ($fd == 2) {
               $handle = 'STDERR ';
           }
           else {
               error_out ('file descriptors not currently supported');
               $handle = "$fd ";  # Just to show something 
           }
           $redirection = 0;    # Avoid the close
       }
       else {
           App::sh2p::Handlers::Handle_open_redirection ($redirection, $file);    
           $handle = '$sh2p_handle ';
       }
   }
   elsif (App::sh2p::Handlers::Query_redirection('w')) {
       # Redirection may have been done in sh2p
       $redirection = 1;
       $handle = '$sh2p_handle ';
   }
   
   my $ARGV_length = @ARGV;   # 0.05
   getopts ('nEepu:', \%options);
   
   # How many tokens have I processed?
   $ntok += $ARGV_length - @ARGV;   # 0.05
   
   # Ignore -e and -E options (from echo)
   if (exists $options{n}) {
       $newline = 0;
   }
   
   if ($name eq 'print') {
       if (exists $options{p}) {
           error_out ('Pipes/co-processes are not supported, use open');
       }
       
       if (exists $options{u} && defined $options{u}) {
           my @handles = ('', 'STDOUT ', 'STDERR ');
           if ($options{u} > $#handles) {
               error_out ('file descriptors not currently supported');
               $handle = "$options{u} ";  # Just to show something 
           }
           else {
               $handle = $handles[$options{u}];
           }
       }
   }
   
   iout ("print $handle");
   
    @args = @ARGV;    # Removed the 'my'   0.05
    
    # Is final token a comment?    
    pop @args if substr($args[-1],0,1) eq '#';

    my $string = '';
    my @trailing_tokens;
    
    # C style for loop because I need to check the position
    for (my $i = 0; $i < @args; $i++) {
        
        # Strip out existing quotes
        if ($args[$i] =~ s/^([\"])(.*)\1(.*)$/$2$3/) {
            set_in_quotes();
        }
        
        my @tokens = ($args[$i]);
        my @types  = App::sh2p::Parser::identify (2, @tokens);

        #print_types_tokens(\@types, \@tokens);
        
        if ($types[0][0] eq 'UNKNOWN' || 
            $types[0][0] eq 'SINGLE_DELIMITER' ||
            $types[0][0] eq 'TWO_CHAR_DELIMITER') {      # 0.05
        
            $string .= "$tokens[0]";
            
            # append with a space for print/echo
            $string .= ' ' if $i < $#args; 
        }
        elsif ($types[0][0] eq 'OPERATOR') {   # 0.05
            @trailing_tokens = splice (@args, $i);
            last;
        }
        else {
        
            if ($string) {
                App::sh2p::Handlers::interpolation ($string);   
                $string = ' ';  # Add a space between args
                out ',';
            }
        
            App::sh2p::Parser::convert (@tokens, @types); 
            out ',' if $i < $#args; 
        }
        
        $ntok++;    # 0.05 (moved)
    }
       
    if ($string && $string ne ' ') {
       if ($newline) {
          $string .= "\\n"
       }

       App::sh2p::Handlers::interpolation ($string);
    }
    elsif ($newline) {
       out ",\"\\n\""
    }
    
    if (@trailing_tokens) {    # 0.05
        out " ";    # cosmetic
        $ntok += @trailing_tokens;
        my @trailing_types  = App::sh2p::Parser::identify (1, @trailing_tokens);
        App::sh2p::Parser::convert (@trailing_tokens, @trailing_types); 
    }
    else {
        out ";\n";
    }
    
    # An ugly hack, but necessary where the first arg is parenthesised
    fix_print_arg();
    
    App::sh2p::Handlers::Handle_close_redirection('w') if $redirection;

    return $ntok;
    
}   # do_print

########################################################

sub do_read {
   my %args;
   my $prompt = 'undef';
   my $ntok;
   local @ARGV;

   # First argument is 'read'
   shift @_;
   $ntok++;
   
   # Find end of statement
   for my $arg (@_) {   
      last if is_break($arg) || $arg eq ';';   # Inserted in sh2p loop
      push @ARGV, $arg;
      $ntok++;
   }
   
   getopts ('p:rsu:nAa', \%args);
   
   if (exists $args{p} && which_shell() eq 'bash') { 
       # Bash syntax for prompt
       $prompt = $args{p}
   }
   elsif ($ARGV[0] =~ /^(\w*)\?(.*)$/) {   # ksh syntax for prompt
       
      $ARGV[0] = $1 || 'REPLY';    
      $prompt  = $2;
   }   

   # Default variable
   @ARGV = ('REPLY') if ! @ARGV;     

   # Add $ prefix to variable names   
   # Do I need to pre-define them?
   for (my $i = 0; $i < @ARGV; $i++) {

       if (exists $args{a} || exists $args{A}) {
           $ARGV[$i] = "\@$ARGV[$i]";
           if (Register_variable($ARGV[$i], '@')) {
               pre_out "my $ARGV[$i];\n";
           }
       }
       elsif ($ARGV[$i] =~ s/^<//) {
           my $filename;
           if (defined $ARGV[$i] && $ARGV[$i]) {
               $filename = $ARGV[$i];
           }
           else {
               $filename = $ARGV[$i+1];
           }
           pop @ARGV;
           pop @ARGV if $i == $#ARGV;
           
           App::sh2p::Handlers::Handle_open_redirection('<', $filename);
           
       }
       else {
           $ARGV[$i] = "\$$ARGV[$i]";
           if (Register_variable($ARGV[$i], '$')) {
               pre_out "my $ARGV[$i];\n";
           }
       }
   }
   
   if (exists $args{p} && which_shell() eq 'ksh') { 
       # ksh syntax for pipes
       error_out "read through ksh pipes is not supported";
       iout "read @_;\n";
       return $ntok;
   }
   
   my $heredoc = App::sh2p::Here::get_last_here_doc();
   
   if (defined $heredoc) {
      my $filename = App::sh2p::Here::gen_filename($heredoc);
      if (Register_variable('$IFS', '$')) {
          pre_out "my \$IFS=".get_special_var('IFS').";\n";
      }
      iout "sh2p_read_from_file ('$filename', \"\$IFS\", $prompt, ". 
             '\\'.(join ',\\', @ARGV).")";
      App::sh2p::Here::store_sh2p_here_subs();
   } 
   else {
      if (exists $args{u} && $args{u} ne 0) {
          my $fd = $args{u};
         
          iout "$ARGV[0] = <\$sh_handle$fd>";
     
          if (@ARGV > 1) {
             iout "(".(join ',', @ARGV).") = split /\$IFS/, $ARGV[0];"
          }
      }
      else {
          if (Register_variable('$IFS', '$')) {
              pre_out "my \$IFS=".get_special_var('IFS').";\n";
          }
          
          my $filename = App::sh2p::Handlers::Query_redirection('r');
          
          if (defined $filename) {
              iout 'sh2p_read_from_handle ($sh2p_handle,"$IFS",'."$prompt,".
                     '\\'.(join ',\\', @ARGV).")";
          }
          else {
              iout "sh2p_read_from_stdin (\"\$IFS\", $prompt, ".
                     '\\'.(join ',\\', @ARGV).")";
          }
          
          if (!App::sh2p::Compound::get_context()) {
              out ";\n";
              App::sh2p::Handlers::Handle_close_redirection('r');
          }

          App::sh2p::Here::store_sh2p_here_subs();
      }
   }
   
   return $ntok;
   
}  # do_read

########################################################

sub do_return {

   my ($name, $arg) = @_;
   my $ntok = 1;

   iout $name;
   
   if (defined $arg            && 
       substr($arg,0,1) ne '#' && 
       substr($arg,0,1) ne ';'    ) {
       
      out ' ';
      my @tokens = ($arg);
      my @types  = App::sh2p::Parser::identify (1, @tokens); 
                                                
      App::sh2p::Parser::convert (@tokens, @types);
      $ntok++;
   }

   out ";\n";
   return $ntok;
}

########################################################

sub do_shift {

   my (undef, $level) = @_;
   my $ntok = 1;
   
   if (defined $level && $level =~ /^\d+$/ && !is_break($level)) {
      $ntok++;
   }
   else {
      $level = 1;
   }

   iout (('shift;' x $level)."\n");     # 0.04
   
   return $ntok;

}

########################################################

sub do_shopt {

   my (undef, $switch, @rest) = @_;
   my $ntok = 2;
   my @options;
   
   for my $option (@rest) {
       last if is_break($option) || $option eq ';' || substr($option,0,1) eq '#';
       push @options, $option;
       $ntok++;
   }  
   
   error_out ("Shell option @options being set");
   if ($switch eq '-s') {
       @g_shell_options{@options} = undef;
   }
   elsif ($switch eq '+s') {
       delete @g_shell_options{@options};
   }
   else {
       error_out ("Unrecognised shopt argument: <$switch>");
   }
   
   return $ntok;
   
}

########################################################

sub do_source {

   my (undef, @tokens) = @_;
   my $ntok = 1;
   
   error_out ();
   error_out "sourced file should also be converted";
   
   # Removed enclosing " in 0.06
   iout 'do ';
   
   no_semi_colon(); 
   
   $ntok += App::sh2p::Parser::join_parse_tokens ('.', @tokens);
   
   reset_semi_colon();
   out ';';
   
   return $ntok;
}

########################################################

sub do_touch {
    my    $ntok = @_;
    my    $cmd  = shift;
    local @ARGV = @_;

    my %args;
    getopts ('acdfmr:t', \%args);
    if (keys %args) {
        error_out "$cmd options not currently supported";
    }

    my $text = "# $cmd @_\n";
    
    for my $file (@ARGV) {
        if (substr ($file,0,1) eq '#') {
            iout "$file\n";     # Output comment first         
        }
        
        # Remove surrounding quotes
        $file =~ s/^([\'\"])(.*)\1/$2/;
        
$text .= << "END"
    if (-e \"$file\") {
        # update access and modification times, requires perl 5.8
        utime undef, undef, \"$file\";
    }
    else {
        open(my \$fh,'>',\"$file\") or warn \"$file:\$!\";
    }

END
    }

    iout $text;

    return $ntok;
}

########################################################

sub do_tr {

    my ($cmd, @args) = @_;
    my $ntok = 1;
    my %args;
    
    local @ARGV = @args;
    getopts ('cCsd', \%args);
    if (keys %args) {
        error_out "$cmd options not currently supported";
    }
    
    $ntok = @_ - @ARGV;
    
    return $ntok if !@ARGV;
    
    my $from = shift @ARGV;
    $ntok++;
    
    my $to;
    if (@ARGV) {
        $to = shift @ARGV;
        $ntok++;
    }
    
    # Strip quotes if there are any
    $from =~ s/^\'(.*)\'/$1/g;
    $to   =~ s/^\'(.*)\'/$1/g;
    
    # common case
    if (($from eq '[a-z]' || $from eq '[:lower:]') && 
        ($to   eq '[A-Z]' || $to   eq '[:upper:]')) {
        iout 'uc ';    
    }
    elsif (($from eq '[A-Z]' || $from eq '[:upper:]') && 
           ($to   eq '[a-z]' || $to   eq '[:lower:]')) {
        iout 'lc ';
    }
    else {
        # Convert patterns TODO
        iout "tr/$from/$to/";
    }
    
    return $ntok;
}

########################################################
# typeset [[+-Ulprtux] [-L[n]]  [-R[n]]  [-Z[n]]  [-i[n]]  |  -f  [-tux]]
#         [name[=value] ...]
# Needs more work!
sub do_typeset {
   
   my $ntok = @_;
   my %args;
   
   #print STDERR "do_typeset: $_[0]\n";
   # First argument should be 'typeset' or 'declare'
   shift @_;
   
   local @ARGV = @_;
   
   getopts ('UPRTUXLRZ:iftux', \%args);
   
   my %type = (i => 'int',
               l => 'lc',
               u => 'uc',
               Z => '%0nd',
               L => '%-s',
               R => '%s',
               X => '%X',
               x => '%x');
   
   my $type = '$';
   my @opt = grep {$args{$_}} keys %args;
   
   if (exists $type{$opt[0]}) {
      $type = $type{$opt[0]};
   }

   # These types are not yet supported by other functions
   if (@opt > 1) {
       if ( $args{Z} && defined $args{Z}) {
           $type =~ s/n/$args{Z}/;
       }
       elsif ( $args{f} ) {
           if ($args{u}) {
               $ntok += do_autoload ('typeset -fu',@ARGV);
               $ntok--;   # artificial 1st argument
           }
           return $ntok;
       }
       else {
           error_out "Only one option supported for typedef or declare";
       }
   }

   my $var = $ARGV[0];

   # Remove any assignment for the name
   $var =~ s/=.*//;
   
   if (Register_variable ("\$$var", $type) ) {
          iout 'my ';
   }
   
   #$ntok +=    January 2009 
   App::sh2p::Handlers::Handle_assignment (@ARGV);
   
   return $ntok;
}

########################################################
# Need getopt here, but it can't deal with +
#  set [+-abCefhkmnpsuvxX] [+-o [option]] [+-A name] [--] [arg ...]

sub do_set {
   
   my $ntok = 1;
   
   # First argument is 'set'
   shift @_;
   my @values;
   
   for my $option (@_) {
      my $act = substr($option, 0, 1);

      if ($act eq '+' || $act eq '-') {
          my $set = substr($option, 1);
      
          if ( $set eq 'A') {
              if ($act eq '-') {
                 initialise_array (@_);
              }
              else {
                 overwrite_array (@_);
              }
              
              $ntok += @_;   # Added 0.05
              last;
          }
      }
      elsif (is_break($option)) {
          last
      }
      else {
          push @values, $option;
      }
      $ntok++;
   }  
   
   if (@values) {
        my $IFS = get_special_var('IFS');
        
        iout "\@ARGV = (";
        for (my $i=0; $i < @values;$i++) {
            my @tokens = ($values[$i]);
            #print STDERR "do_set: <$values[$i]>\n";
            
            my @types  = App::sh2p::Parser::identify (2,@tokens);
            if ($values[$i] =~ /^[\"\']*\$/ && !get_special_var($values[$i])) {
                out "(split /[$IFS]/,";
                App::sh2p::Parser::convert (@tokens, @types); 
                out ")";
            }
            else {
                App::sh2p::Parser::convert (@tokens, @types);                 
            }
            out ',' if $i < $#values;
        }
        #App::sh2p::Parser::join_parse_tokens (',', @values);
                
        out ");\n";
   }
   
   return $ntok;
   
}  # do_set

# set -A
sub initialise_array {
   my ($nu, $array, @values) = @_;
   
   iout "my \@$array = qw(@values);\n";
}

# set +A
sub overwrite_array {
    my ($nu, $array, @values) = @_;
      
    # Fix for 5.6 01/09/2008
    iout "my \@${array}\[0..". $#values ."\] = qw(@values);\n";
}

########################################################

sub do_true {

    my ($name, $rest) = @_;
    my $ntok = 1;
    
    if (App::sh2p::Compound::get_context()) {
        # Inside a conditional
        out ' 1 ';
    }
    else {
        iout '$? = 0;';

        if (!defined $rest) {
            out "\n";
        }
    }
    
    return 1;
}

sub do_false {

    my ($name, $rest) = @_;
    my $ntok = 1;
    
    if (App::sh2p::Compound::get_context()) {
        # Inside a conditional
        out ' 0 ';
    }
    else {
        iout '$? = 1;';
    
        if (!defined $rest) {
            out "\n";
        }
    }

    return 1;
}

########################################################

sub do_unset {
   
   my (undef, $var, @rest) = @_;
   my $ntok = 1;
   
   if (substr($var,0,1) eq '-') {
       my $option = $var;
    
       $var = $rest[0];
       $ntok++;
      
       # unset only supports two options (POSIX)
       # -v has the same effect as not being there
       
       if ($option eq '-f') {
           unset_user_function ($var);
           $ntok++;
           return $ntok;
       }
       
   }
   
   iout 'undef ';

   if (defined $var && substr($var,0,1) ne '#') {
   
      my $type = '$';
      
      if (get_special_var($var,0)) {
          set_special_var(undef);
      }
      else {
          $type = get_variable_type($var);
          Delete_variable ($var);
      }
      
      $var = $type.$var;
      
      my @tokens = ($var);
      my @types  = App::sh2p::Parser::identify (1, @tokens); 
                        
      App::sh2p::Parser::convert (@tokens, @types);
      $ntok++;
      
   }
   out ";\n";
   
   return $ntok;
}

########################################################

1;

__END__
=head1 Summary
package App::sh2p::Builtins;
sub not_implemented 
# For builtins/functionality that cannot be implemented 
sub one4one
sub general_arg_list 
sub advise
sub do_autoload
sub do_break 
sub do_colon 
sub do_continue
sub do_cd
sub chmod_text_permissions
sub do_chmod 
# also used by umask
sub do_chown 
sub do_exec 
sub do_exit 
sub do_export 
sub do_expr 
sub do_functions 
sub do_integer
sub do_kill 
sub do_let 
sub do_print
sub do_read
sub do_return
sub do_shift
sub do_shopt
sub do_source
sub do_touch
sub do_tr
sub do_typeset
sub do_set
sub initialise_array
# set -A
sub overwrite_array
# set +A
sub do_true
sub do_false
sub do_unset

=cut
