#!/usr/bin/perl
# Clive Darke 2006
# Additional modifications 2008, 2009. See Changes file

use warnings;
use strict;
use Getopt::Std;
use File::Basename;
use Config;

use App::sh2p::Statement;

use App::sh2p::Parser;
use App::sh2p::Handlers;
use App::sh2p::Builtins;
use App::sh2p::Operators;
use App::sh2p::Compound;
use App::sh2p::Here;
use App::sh2p::Utils;

sub process_script (\@);          

my %g_block_commands = ('while'  => 'done',
                        'until'  => 'done',
                        'for'    => 'done',
                        'select' => 'done',
                        'if'     => 'fi',
                        'case'   => 'esac'
                        );

# Runtime options
my $g_integer = 1;
my $g_clobber = 0;
my $g_display = 0;

our $VERSION = 0.06;
our $DEBUG   = 0;

###########################################################

sub outer
{
   my $num_of_files = 0;
   my @files;
   
   if (-d $_[-1]) {
       my $dir = pop;
       
       for my $file (@_) {
       
           my $outfile = basename $file;
	   
	   # There might not be an extension
	   $outfile =~ s/\..*$//;
           $outfile = "$dir/$outfile.pl";    
           
           if (-f $outfile && !$g_clobber) {
               print STDERR "$outfile already exists. Overwrite(Y/N)?: "; 
               my $reply = <STDIN>;
               if ( uc(substr($reply,0,1)) eq 'N' ) {
                   print STDERR "$file ignored\n";
                   next;
               }
           }
           push @files,[ ($file, $outfile) ];   
       }
   }
   elsif (@_ == 2) {
       @files = [ @_[0,1] ];    
   }
   else {
       usage();
   }

   for my $ref (@files)
   {
      my $script_h;
       
      if ($ref->[0] eq '-') {
          $script_h = *STDIN;
      }
      else {
          open ($script_h, '<', $ref->[0]) || die "$ref->[0]: $!\n";
      }
      
      # Pass the file name and the permissions
      open_out_file ($ref->[1], (stat $script_h)[2] & 07777);
      
      $num_of_files++;

      if ( $DEBUG ) {
         print STDERR "Processing $ref->[0] -> $ref->[1]\n";
      }
      
      my @the_script = <$script_h>;
      close $script_h;
      
      reset_globals();
      @the_script = pre_process (@the_script);
      
      # Test in case the file is empty
      if (@the_script) {
          process_script (@the_script);
      }
      else {
          error_out "Nothing found to process";
      }
      
      close_out_file();
   }
   
   return $num_of_files;

}  # outer

###########################################################
# Join together wrapped lines
# Currently only deals with one delimiter
sub pre_process
{
    my @in_lines = @_;
    my @out_lines;
    
    # Braces are not here because of functions
    my %delimiters = ('[' => ']',
                      '`' => '`',
                      '(' => ')',
                      "'" => "'",
                      '"' => '"');
    
    my $open_delimiters = '['.join('',keys(%delimiters)).']';

    # Inspect the first line for the shell
    if ($in_lines[0] =~ /^#!\s*.*\/(\w+)/) {
        set_shell ($1);
    }

    for (my $i = 0; $i < @in_lines; $i++) {
        my $line = $in_lines[$i];

        # Do not test inside a comment
        my $temp = $line;
        $temp =~ s/#.*$//;
        
        if ($temp =~ /($open_delimiters)/) {
            
            my $delim = $1;
            my $pattern = "\\$delim\[^\\$delimiters{$delim}\]*\\$delimiters{$delim}";
                        
            if ($line !~ /$pattern/) {
                
                my $comments = '';
                my $line_pos = @out_lines;  # Remember the start of this block
                
                while ($i < $#in_lines) {
                    chomp $line;
                    
                    # Remove trailing comments
                    if ($line =~ s/\s+(#.*)$//) {
                        $comments .= " $1";
                    }
                  
                    # February 2009 substitute line continuation with "\n"
                    $line =~ s/\\$/\n/;           
                    
                    $i++;
                    
                    # Remove leading whitespace if not quoted
                    $in_lines[$i] =~ s/^\s+// if ($delim ne "'" && $delim ne '"');
                    
                    $line .= " $in_lines[$i]";
                    
                    last if index($in_lines[$i],$delimiters{$delim}) > -1;
                }
                
                # February 2009 (if)
                if ( $comments ) {
                    splice (@out_lines, $line_pos, 0, $comments);
                }
            }
        }

        push @out_lines, $line;
        #{local $" = '|'; print STDERR "out_lines: <@out_lines>\n\n";}

    }

    return @out_lines;
}

###########################################################

sub process_script (\@)
{
   my ($ref) = @_;
   my $index = 0;
   my $limit = @$ref;
   my $line  = '';
   my $delimiter = ';';
   my $here_label;
   my $here;
   my $redirection_file;
   my $statement = undef;
  
   # Maybe make this optional?
   if ( $ref->[0] =~ /^#!/ ) {
      if ($ref->[0] =~ /^#!.*(t?csh|perl|awk|sed)/) {
         warn "This file appears to be a $1 script - abandoned\n";
         return;
      }
      $index = 1;
   }
   
   # use . (not "") in case path contains weird chars
   out '#!'.$Config{'perlpath'}."\n\n";
   out "# Generated by $0 on ".localtime()."\n\n";
   out "use warnings;\n";
   out "use strict;\n";
   
   out "use integer;\n" if $g_integer;
   out "\n";
   flush_out ();
   
   # A foreach loop would be too simplistic
   OUTER:
   while ($index < $limit) {
      
      my @tokens;         

      $line .= $ref->[$index];
      $index++;

      # shortcut for blank lines
      if ($line =~ /^\s*$/) { 
          out $line;
          next 
      }
      
      # Remove leading & trailing whitespace
      # Also allows for Windows line endings (Cygwin)
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      
      if ( substr($line,-1) eq '\\' ) {
         # Continuation character
         substr($line,-1) = "\n";      
         next;
      }    
      
      if ($line) {
         
         App::sh2p::Utils::mark_new_line();
         
         if ( $DEBUG ) {
             print STDERR "\nProcessing <$line>\n";
         }
         
         # Option -t (testing) - ignore comment lines
         if ($g_display  && $line !~ /^\s*#/) {
             # convert newlines - for line continuation (January 2009)
             my $out_line = $line;
             $out_line =~ s/\n/\n#< /g;
             out ("#< $out_line\n");
         }
         
         if (! defined $statement) {
             $statement = new App::sh2p::Statement();
         }
         
         # Hack for here-docs
         if ( defined $here_label ) {

            if ($here_label eq $line) {
               $here_label = undef;
               $here->close();
            }
            else {
               # push line into here doc
               $here->write($line);            
            }
            $line = '';
            next
         }
         
         # Hack for Bourne shell function syntax
         # Change it to ksh syntax (cheat)
         if ($line =~ /^(\w+)\s*\(\)(.*)/) {
             my $name = $1;
             my $rest = $2;
             $line = "function $name $rest"
         }
         
         @tokens = App::sh2p::Parser::tokenise ($line);
         
         # Look for statement delimiters
         for (my $i = 0; $i < @tokens; $i++) {
         
            my $tok = $tokens[$i];
            #print STDERR "Processing token: <$tok>\n";
            
            # This check is to 'read-ahead' looking for redirection
            # $delimiter test added January 2009 for nested conditionals
            if (exists $g_block_commands{$tok} && $delimiter eq ';') {
               # print STDERR "Delimiter switched from <$delimiter> to <$g_block_commands{$tok}>\n";
               $delimiter = $g_block_commands{$tok};
            }
            
            # Look ahead to check for redirection
            # Currently only 'here' documents
            
            # We need the code here twice, since redirections
            # also occur AFTER a while loop, if statement, or function
            # This one handles redirection on the statement
            if ($tok eq '<<') {
                $i += 1;
                if ( !defined $tokens[$i] ) {
                    die "*** Malformed here document (no label) line ",$index + 1,"\n";
                }
                $here_label = $tokens[$i];
                $here_label =~ s/^\s+//;
                $here = App::sh2p::Here->open($here_label, '>');
            }
            # This is no good for built-ins and externals
            #elsif ($tok eq '<' || $tok eq '>' || $tok eq '>>') {     
            #    $i += 1;
            #    if ( !defined $tokens[$i] ) {
            #        die "*** Malformed redirection (no file) line ",$index + 1,"\n";
            #    }
            #    $redirection_file = $tokens[$i];
            #    $redirection_file =~ s/^\s+//; 
            #    App::sh2p::Handlers::Handle_open_redirection ($tok, $redirection_file);
            #    next;
            #}

            if ($tok eq $delimiter) {
               # We need the code here twice, since redirections
	       # also occur AFTER a while loop, if statement, or function
               # This one handles redirection AFTER the statement
               if ( defined $tokens[$i+1] && $tokens[$i+1] eq '<<' ) { 
               
                  $statement->add_token ($tok);
               
                  $i += 2;
                  if ( !defined $tokens[$i] ) {
                     die "*** Malformed here document (no label) line ",$index + 1,"\n";
                  }
                  $here_label = $tokens[$i];
                  $here_label =~ s/^\s+//;
                  $here = App::sh2p::Here->open($here_label, '>');
               }
               elsif (defined $tokens[$i+1] &&        # ADDED 11/11/2008
                     ($tokens[$i+1] eq '<' || 
                      $tokens[$i+1] eq '>' ||
                      $tokens[$i+1] eq '>>')) { 
                  
                  $statement->add_token ($tok);
                  
                  my $access = $tokens[$i+1];
                  $i += 2;
                  if ( !defined $tokens[$i] ) {
                      die "*** Malformed redirection (no file) line ",$index + 1,"\n";
                  }
                  $redirection_file = $tokens[$i];
                  $redirection_file =~ s/^\s+//; 
                  App::sh2p::Handlers::Handle_open_redirection ($access, $redirection_file);
                  $statement->add_token (\&App::sh2p::Handlers::Handle_close_redirection);
               }
               #elsif ($tok ne ';' && $tok ne BREAK) {
               elsif ($tok ne ';') {
                  $statement->add_token ($tok);
               }
               
               # Process statements 
               if (defined $statement) {
                  $statement->identify_tokens(0);
                  $statement->convert_tokens();
                 
                  undef $statement;
               }
               
               $delimiter = ';';
            } 
            elsif (defined $statement) {
               # Inside a while, until, for, if, or case
               # print STDERR "statement <$tok> added\n";
               $statement->add_token ($tok);
            }
            else {
               # statements after ;
               $statement = new App::sh2p::Statement();
               $statement->add_token ($tok);
            }
         }
         
         # 0.05
         if (defined $statement && $delimiter eq ';' ) {
            $statement->identify_tokens(0);
            $statement->convert_tokens();
            $statement = undef;
         }
         elsif ($delimiter eq 'esac') {
               $statement->push_case();
               $statement = undef;
         }
         elsif (defined $statement) {
            $statement->add_break ();
         }
         
      }
      
      # At end

      flush_out ();
      
      $line = '';
   }
   
   App::sh2p::Handlers::write_subs();
   App::sh2p::Here::write_here_subs();
   flush_out ();
 
}  # process_script
   
###########################################################

sub usage {
   print STDERR "Usage: sh2p.pl [-i] [-t] [-f] input-file output-file | input-files... out-directory\n";
   exit 1;
}

###########################################################
# main
# done this way to aid testing 
# see "Perl Testing, A Developer's Notebook" by Ian Langworth & chromatic (O'Reilly)

main(@ARGV) unless caller();

sub main
{
    my %args;

    getopts ('ift', \%args);
    $g_integer = 0 if exists $args{'i'};
    $g_clobber = 1 if exists $args{'f'};
    $g_display = 1 if exists $args{'t'};

    if ( @ARGV < 2 ) {
        usage();
    }
    
    outer(@ARGV);
}

__END__

####################################################
# POD is in sh2p.pod