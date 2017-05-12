package App::sh2p::Here;

# I expect only one active here doc at a time, 
# but I guess they could be in nested loops
#     while read var1
#     do
#        while read var2
#        do
#           ...
#        done << HERE
#           ...
#        HERE
#     done << HERE
#        ...
#     HERE
# This would create a problem, since the filename
# is based on the here label - TODO
#
use strict;
use Carp;
use Scalar::Util qw(refaddr);

use App::sh2p::Utils;

our $VERSION = '0.06';

#################################################################################

my %handle;
my %name;
my %access;

my $g_last_opened_here_name;
my $g_last_opened_file_name;
my $g_write_subroutines = 0;

#################################################################################

sub store_sh2p_here_subs {
    $g_write_subroutines = 1;
}

#################################################################################
# January 2009
sub abandon_sh2p_here_subs {
    $g_write_subroutines = 0;
}

#################################################################################

sub get_last_here_doc {

   my $name = $g_last_opened_here_name;
   $g_last_opened_here_name = undef;
   return $name

}

#################################################################################

sub get_last_file_name {

   my @caller = caller();
   print STDERR "get_last_file_name: <$g_last_opened_file_name> @caller\n";

   my $name = $g_last_opened_file_name;
   $g_last_opened_file_name = undef;
   return $name

}

#################################################################################

sub _get_dir {
   my $dir;
   
   if (defined $ENV{SH2P_HERE_DIR}) {
      $dir = $ENV{SH2P_HERE_DIR}
   }
   else {
      $dir = '.'
   }
   return $dir;
}

#################################################################################

sub gen_filename {
   my $name = shift;
   my $dir  = _get_dir();
   
   return "$dir/$name.here";
}

#################################################################################

sub open {
   my ($class, $name, $access) = @_;
   
   my $this = bless \do{my $some_scalar}, $class;
   my $key = refaddr $this;
   
   $name  {$key} = $name;
   $access{$key} = $access;
   
   $g_last_opened_here_name = $name;
   my $full_name = gen_filename($name);
   
   error_out ("Writing $full_name");
   open ($handle{$key}, $access{$key}, "$full_name") ||
        carp "Unable to open $full_name: $!\n";
   
   $g_write_subroutines = 1;
   
   return $this 
}

#################################################################################

sub open_rd {
   my ($class, $filename, $access) = @_;
   
   my $this = bless \do{my $some_scalar}, $class;
   my $key = refaddr $this;
   
   $name  {$key} = $filename;
   $access{$key} = $access;
   
   $g_last_opened_file_name = $filename;
   $g_write_subroutines = 1;
   
   return $this 
}

#################################################################################

sub write {
   my ($this, $buffer) = @_;
   my $key = refaddr $this;

   my $handle = $handle{$key};

   print $handle ("$buffer\n") or 
         carp "Unable to write to $name{$key}: $!";

}

#################################################################################

sub read {
   my ($this) = @_;
   my $key = refaddr $this;

   return <$handle{key}>
}

#################################################################################

sub close {
   my ($this) = @_;
   my $key = refaddr $this;

   my $retn = close $handle{$key};
   delete $handle{$key};
   delete $name  {$key};
   delete $access{$key};

   return $retn;
}

#################################################################################

sub DESTROY {
   my ($this) = @_;
   my $key = refaddr $this;

   if (exists $name{$key}) {
      close_here_doc ($this);
   }
}

#################################################################################

sub write_here_subs {

    if ($g_write_subroutines) {
    
        $g_write_subroutines = 0;
        
        out "";
        
        out << 'END';
        

######################################################
# sh2p_read_from_handle
# Arguments:
#       1. Handle
#	2. Value of $IFS
#	3. Prompt string
#	4. List of scalar references
#	Any may be undef
	
sub sh2p_read_from_handle {

   my ($handle, $sh2p_IFS, $prompt, @refs) = @_;
   
   return 0 if eof($handle);
   
   if (!defined $sh2p_IFS) {
      $sh2p_IFS = " \t\n";
   }
   
   if (defined $prompt) {
      print $prompt
   }
   
   my $line = <$handle>;
   my $sh2p_REPLY;
   
   chomp $line;
   
   my (@vars) = split /[$sh2p_IFS]+/, $line;
   my $i;
   
   # Assign values to variables
   for ($i = 0; $i < @refs; $i++) {
      if ($i > $#vars) {
         ${$refs[$i]} = '';
      }
      else {
         ${$refs[$i]} = $vars[$i];
      }
   }
   
   # If not enough variables supplied
   if ($i < @vars || !@refs) {
      my $IFS1st = substr($sh2p_IFS,0,1);
      $sh2p_REPLY = join $IFS1st, @vars[$i..$#vars];
   }

   if (@refs > 0 && defined $sh2p_REPLY) {
      # Concat extra values onto the element
      ${$refs[-1]} .= " $REPLY";
   }
   
   return 1;
}

######################################################

sub sh2p_read_from_stdin {

   my (@args) = @_;
   
   return sh2p_read_from_handle (*STDIN, @args);
}

######################################################
{
# No 'state' variables in 5.8
my $handle;

   sub sh2p_read_from_file {

      my ($filename, @args) = @_;

      if (!defined $handle) {
          open ($handle, '<', $filename) or 
              die "Unable to open $filename: $!";
      }
   
      my $retn = sh2p_read_from_handle ($handle, @args);
      if (!$retn) {
          close $handle;
          undef $handle;
      }
      
      return $retn;
   }

}

######################################################
#  End of subroutines added by sh2p
######################################################
END
# End of here document

    }
}

#################################################################################
1;

