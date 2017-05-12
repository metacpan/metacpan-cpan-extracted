package App::sh2p::Utils;

use warnings;
use strict;

our $VERSION = '0.06';

require Exporter;
our (@ISA, @EXPORT);
@ISA = ('Exporter');
@EXPORT = qw (Register_variable  Register_env_variable
              Delete_variable    get_variable_type
              print_types_tokens reset_globals
              iout    out        pre_out   error_out    flush_out
              rd_iout rd_remove 
              get_special_var    set_special_var    can_var_interpolate
              mark_function      unmark_function    ina_function
              mark_subshell      unmark_subshell    ina_subshell
              inc_block_level    dec_block_level    get_block_level
              is_user_function   set_user_function  unset_user_function
              dec_indent         inc_indent         
              rem_empty_string   fix_print_arg
              no_semi_colon      reset_semi_colon   query_semi_colon
              set_in_quotes      unset_in_quotes    query_in_quotes
              out_to_buffer      off_out_to_buffer
              set_shell          which_shell
              open_out_file      close_out_file
              set_break          is_break);

############################################################################

my $g_indent_spacing = 4;

my %g_special_vars = (
      'IFS'      => '" \t\n"',
      'ERRNO'    => '$!',
      'HOME'     => '$ENV{HOME}',
      'PATH'     => '$ENV{PATH}',
      'FUNCNAME' => '(caller(0))[3]',    # Corrected 0.04
      '?'        => '($? >> 8)',
      '#'        => 'scalar(@ARGV)',
      '@'        => '"@ARGV"',
      '*'        => '"@ARGV"',    
      '-'        => 'not supported',
      '$'        => '$$',
      '!'        => 'not supported'
      );
      
# This hash keeps a key for each variable declared
# so we know if to put a 'my' prefix
my %g_variables;

# This hash keeps track of environment variables
my %g_env_variables;

my %g_user_functions;
my $g_new_line       = 1;
my $g_use_semi_colon = 1;
my $g_ina_function   = 0;
my $g_ina_subshell   = 0;
my $g_block_level    = 0;
my $g_indent         = 0;
my $g_errors         = 0;
my $g_is_in_quotes   = 0;
my $g_shell_in_use   = "ksh";

my $g_outh;
my $g_filename;
my $g_out_buffer;    # Main output buffer
my $g_err_buffer;    # INSPECT messages, for output before the statement
my $g_pre_buffer;    # For preamble, like declaring 'my' variables
my $g_ref_redirect;  # Redirect output to buffer instead of script file
my $g_break = \do{my $some_scalar};   # We have to define a 'break' somehow

# Remember position and length for later deletion
my $g_rd_pos = 0;
my $g_rd_len = 0;

#  For use by App::sh2p only
############################################################################
# Called by Handlers::interpolate
sub can_var_interpolate {

   my ($name) = @_;
   my $retn;
   
   $retn = get_special_var ($name, 1);
   
   if (defined $retn && $retn !~ /^[\$\@]/) {
       return 0
   }
   else {
       return 1
   }
}
########################################################
# This is primarily for [@] and [*].  Also to prevent globbing inside ""
sub query_in_quotes {
    return $g_is_in_quotes;
}

sub set_in_quotes {
    $g_is_in_quotes = 1;
}

sub unset_in_quotes {
    $g_is_in_quotes = 0;
}

############################################################################

sub set_break {

    return $g_break
}

sub is_break {
    my $ref = shift;
    
    if (defined $ref && ref($ref) && $ref eq $g_break) {
        return 1
    }
    else {
        return 0
    }
}

############################################################################

sub get_special_var {
   my ($name, $no_errors) = @_;
   my $retn;
   
   return undef if ! defined $name;

   $no_errors = 0 if ! defined $no_errors;

   # Remove dollar prefix and quotes
   $name =~ s/^([\'\"]?)\$(.*?)\1/$2/;

   if ($name eq '0') {
       $retn = '$0';
   }
   elsif ($name =~ /^(\d+)$/) {
       my $offset = $1 - 1;
       $retn = "\$ARGV[$offset]";
   }
   elsif ($name eq 'PWD') {
       
       if (!$no_errors) {
           error_out ("Using \$PWD is unsafe: use Cwd::getcwd");
       }
       $retn = '$ENV{PWD}';
   }
   elsif ($name eq '*' && query_in_quotes()) {
               
       my $glue = $g_special_vars{'IFS'};
       $glue =~ s/^([\"\'])(.*)\1$/$2/;
       $glue = substr($glue,0,1);
       $retn = "join(\"$glue\",\@ARGV)";   
   }
   else {
       $retn = $g_special_vars{$name};
   }

   # In a subroutine we use @_
   if (defined $retn && $g_ina_function) {
       $retn =~ s/ARGV/_/;
   }
   
   return $retn;
}

############################################################################

sub set_special_var {
   my ($name, $value) = @_;
   #print STDERR "set_special_var: <$name> <$value>\n";
   
   # Do not set environment variables through here - January 2009
   if (substr($g_special_vars{$name},0,4) ne '$ENV') {
       $g_special_vars{$name} = $value;
   }
   
   return $value;
}

############################################################################

sub no_semi_colon() {
    $g_use_semi_colon = 0;
}

sub reset_semi_colon() {
    $g_use_semi_colon = 1;
}

sub query_semi_colon() {
    return $g_use_semi_colon;
}

############################################################################

sub set_shell {
    my $shell = shift;
    $g_shell_in_use = $shell;
    #print STDERR "Shell set to <$shell>\n";
}

sub which_shell {
    return $g_shell_in_use;
}

#################################################################################

sub mark_function {
    $g_ina_function++;
}

sub unmark_function {
    $g_ina_function--;
    
    if ($g_ina_function < 0) {
        print STDERR "++++ Internal Error, function count = $g_ina_function\n";
    }
}

sub ina_function {
    return $g_ina_function;
}

#################################################################################

sub mark_subshell {
    $g_ina_subshell++;
}

sub unmark_subshell {

    # Delete all the variables for this subshell
    
    while (my($key, $value) = each %g_variables) {
          if ($value->[2] == $g_ina_subshell) {
              delete $g_variables{$key};
          }
    }

    $g_ina_subshell--;
    
    if ($g_ina_subshell < 0) {
        print STDERR "++++ Internal Error, subshell count = $g_ina_subshell\n";
    }
}

sub ina_subshell {
    return $g_ina_subshell;
}

############################################################################
# Return TRUE if NOT already registered
sub Register_variable {
    
    my ($name, $type) = @_;
    my $level  = get_block_level();
    
    if (! defined $type) {
        $type = '$'
    }
    
    # Remove '$' if it exists
    $name =~ s/^\$//;
      
    # January 2009
    if (exists $g_special_vars{$name} && $name ne 'IFS') {
        return 0;
    }
    
    if (exists $g_variables{$name}) {
    
       if ($g_variables{$name}->[0] <= $level && 
           $g_variables{$name}->[2] == $g_ina_subshell) { 
           #print STDERR "Register_variable: <$name> <$g_variables{$name}->[1]> returning 0\n";
           return 0
       }
       else {
           # Create the variable with the block level and type	          
           $g_variables{$name} = [$level, $type, $g_ina_subshell];
           return 1
       }
    }
    elsif (exists $g_env_variables{$name}) {
    
       $g_env_variables{$name} = undef; 
       return 0;
    }
    else {
       # Create the variable with a block level and type
       
       $g_variables{$name} = [$level, $type, $g_ina_subshell];
       return 1
    } 
}

############################################################################

sub Register_env_variable {
    my ($name) = @_;
    
    # Does not matter if it already exists, or its type
    $g_env_variables{$name} = undef; 
}

############################################################################

sub get_variable_type {

    my ($name) = @_;
    my $level  = get_block_level();

    # Remove '$' if it exists - 0.06
    $name =~ s/^\$//;

    if (exists $g_variables{$name}) {
  
       if ($g_variables{$name}->[0] <= $level) {
           return $g_variables{$name}->[1]
       }
    }
    
    return '$';      # default
}

############################################################################
# Called by unset and export
sub Delete_variable {
    my ($name) = @_;
    my $level  = get_block_level();
        
    if (exists $g_variables{$name}) {
       if ($g_variables{$name}->[0] <= $level) {    # ->[0] 0.05
           delete $g_variables{$name}
       }
    }
   
}

#################################################################################

sub inc_block_level {
    $g_block_level++;
}

sub dec_block_level {
    
    # Remove registered variables of current block level ->[0] added 0.05
    while (my($key, $value) = each (%g_variables)) {
        delete $g_variables{$key} if $value->[0] == $g_block_level;
    }
    
    $g_block_level--;
    
    if ($g_block_level < 0) {
        print STDERR "++++ Internal Error, block level = $g_block_level\n";
        my @caller = caller;
        die "@caller\n";
    }
}

sub get_block_level {
    return $g_block_level;
}

#################################################################################

sub is_user_function {
   my ($name) = @_;

   return (exists $g_user_functions{$name})
}

sub set_user_function {
   my ($name) = @_;

   $g_user_functions{$name} = undef;
   
   return 1;   # true
}

sub unset_user_function {
   my ($name) = @_;
   
   delete $g_user_functions{$name} if exists $g_user_functions{$name};
   
   return 1;   # true
}

#################################################################################

sub mark_new_line {
    $g_new_line = 1;
}

sub new_line {
    return $g_new_line;
}

#################################################################################

sub inc_indent { $g_indent++ if $g_indent < 80 }
sub dec_indent { $g_indent-- if $g_indent > 0  }

#################################################################################

sub open_out_file {
    my ($g_filename, $perms) = @_;
    
    if ($g_filename eq '-') {
        $g_outh = *STDOUT;
    }
    else {
        open ($g_outh, '>', $g_filename) || die "$g_filename: $!\n";
        
        # fchmod is not implemented on all platforms
        chmod ($perms, $g_filename) if defined $perms;
        print STDERR "Processing $g_filename:\n";
    }
    
    $g_out_buffer = '';
    $g_err_buffer = '';
    $g_pre_buffer = '';
}

sub close_out_file {
    
    flush_out ();
    
    close ($g_outh);
    print STDERR "\n";
    $g_filename = undef;
}

#################################################################################
# Out to remember redirection position
sub rd_iout {

    $g_rd_pos = length ($g_out_buffer);
    iout (@_);
    $g_rd_len = length ($g_out_buffer) - $g_rd_pos;
}

sub rd_remove {

    if ($g_rd_len) {
        $g_out_buffer = substr ($g_out_buffer, 0, $g_rd_pos) .
                        substr ($g_out_buffer, $g_rd_pos + $g_rd_len);
    }
}

#################################################################################

sub out_to_buffer {
    flush_out();
    ($g_ref_redirect) = @_;
}

sub off_out_to_buffer {
    flush_out();
    $g_ref_redirect = undef;
}

#################################################################################
# Indented out
sub iout {

   #print $g_outh ' ' x ($g_indent * $g_indent_spacing);
   
   my (@args) = @_;
  
   if (query_semi_colon()) {
       unshift @args, (' ' x ($g_indent * $g_indent_spacing));
   }
   
   out (@args);
}

#################################################################################

sub out {
   
   local $" = '';   
   #my @caller = caller();
   #print STDERR "out: <@_> @caller\n";
  
   $g_out_buffer .= "@_";
      
   $g_new_line = 0;
   
}

################################################################################
# I don't like these hacks, but any other way is convoluted
sub fix_print_arg {
    # This avoids 'print (...) interpreted as function'
    #print STDERR "fix_print_arg: <$g_out_buffer>\n";
    
    if ($g_out_buffer =~ /print/) {
        $g_out_buffer =~ s/(^|[^\'\"]+)(print\s+)\(/$2\"\",(/;    
    }
}

sub rem_empty_string {
    
    return if $g_out_buffer =~ /print/;   # Often required

    # Remove "". at start of calls
    $g_out_buffer =~ s/\(\"\"\./(/;
    
    # Remove "". in assignments
    $g_out_buffer =~ s/= \"\"\./= /;
    
}

################################################################################

sub error_out {
    my $msg = shift;
    
    # 0.06
    if (defined $msg) {
        $g_err_buffer .= "# **** INSPECT: $msg\n";
    }
    else {
        $g_err_buffer .= "\n";
    }
    
    $g_errors++;
}

################################################################################

sub pre_out {
    my $msg = shift;
    
    if (!defined $msg) {
        $msg = "\n";
    }
    
    if (query_semi_colon()) {
        $g_pre_buffer .= (' ' x ($g_indent * $g_indent_spacing)).$msg;
    }
    else {
        $g_pre_buffer .= $msg;
    }
    
}

#################################################################################

sub flush_out {

   if (defined $g_ref_redirect) {
       $$g_ref_redirect .= $g_err_buffer if $g_err_buffer;
       $$g_ref_redirect .= $g_pre_buffer if $g_pre_buffer;
       $$g_ref_redirect .= $g_out_buffer;
       
       $g_ref_redirect = undef;
   }
   else {
       print $g_outh $g_err_buffer if $g_err_buffer;
       print $g_outh $g_pre_buffer if $g_pre_buffer;
       print $g_outh $g_out_buffer;
   }
   
   # Leading space for readability with multiple files
   $g_err_buffer =~ s/\#/ \#/g;
   print STDERR $g_err_buffer; 
   
   $g_out_buffer = '';
   $g_err_buffer = '';
   $g_pre_buffer = '';
   $g_rd_len     = 0;
   
}

#################################################################################

sub reset_globals {

    %g_variables      = ();
    %g_env_variables  = ();
    %g_user_functions = ();
    
    $g_out_buffer     = '';
    $g_err_buffer     = '';
    $g_pre_buffer     = '';
      
    $g_new_line       = 1;
    $g_use_semi_colon = 1;
    $g_ina_function   = 0;
    $g_ina_subshell   = 0;
    $g_block_level    = 0;
    $g_indent         = 0;
    $g_errors         = 0;
    $g_is_in_quotes   = 0;
    $g_shell_in_use   = "ksh";
    
    $g_rd_pos = 0;
    $g_rd_len = 0;
    
}

#################################################################################
# Debug purposes only
sub print_types_tokens {
    
    my ($types, $tokens) = @_;
    my $caller = (caller(1))[3];
    
    for (my $i = 0; $i < @$types; $i++) {
    
        if (defined $types->[$i][0]) {
            print STDERR "$caller Type: ".$types->[$i][0].", ";
            print STDERR "Token: ".$tokens->[$i]."\n";
        }
        else {
            print STDERR "**** Type undefined for Token: <".$tokens->[$i].">\n";
        }
    }
    
    if (@$types != @$tokens) {
        print STDERR "Types array: ".@$types.", Token array: ".@$tokens."\n";
    }
    print STDERR "\n";
}

#################################################################################

# Module end
1;
