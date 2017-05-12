#=========================================================================
#=----------------->  R E T A I N _ F I L E  <---------------------------=
#=========================================================================
#  File: Retain.pm
#
#  Usage: Subroutine
#
#  Purpose: Copy and Compress files saving to backup directories
#
#   EXAMPLE - 
#  use Batch::Batchrun::Retain;
#
#  retain(FILE=>test, LIMIT=>5, DIR=>/apps/irmprod/archive,COMPRESS=>yes, 
#         DELETE=>NO};
#
#   FILE          - name of file to retain
#   LIMIT         - number of copies to keep (default 1)
#   DIR           - main directory to keep the copies
#   PREFIX        - the prefix of the numbered directories (default bk)
#   CHMOD         - numeric mode of the file to be copied (default 0775)
#   COMPRESS      - value 1 or yes if file to be compressed
#   DELETE        - value 1 or yes if original file to be deleted
#   VERBOSE       - show each file as it is moved (default off)
#
#--------------------------------------------------------------------------
#-  Revision History                                          
#-                                                               
#-  Daryl Anderson  03/27/1998  1.00  Rewrite as perl5 module.                     
#--------------------------------------------------------------------------
package Batch::Batchrun::Retain;



use strict;
no strict 'vars';
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT     = qw(retain);

$VERSION = '1.03';

# Preloaded methods go here.
use File::Copy; 
use File::Basename;
use File::Path;
use strict;
$Retain::Compress = '/bin/compress -f ';

sub retain 
  {
  #------------------------------------------------------------------------
  #-  Get passed parameters and make upper case    
  #------------------------------------------------------------------------
  my(@tmpparms) = @_;
  my($i,$tmpdir);
  my($newfile,$oldfile) = ("","");
  
  for ($i=0;$i<@tmpparms;$i+=2)
   {
   $tmpparms[$i]=~tr/a-z/A-Z/; # Parameters are upper case
   }
  my(%Retain) = @tmpparms;

  #------------------------------------------------------------------------
  #-  Check mandatory parameters. 
  #------------------------------------------------------------------------
  #------------------------------------------------------------------------
  #-  INSTANCE      - allows starting at lower level directory            -
  #-                  (used primarily to control recursion)               -
  #------------------------------------------------------------------------

  #------------------------------------------------------------------------
  # If INSTANCE not defined this is the first time - define it.
  #    and do other parameter checks;
  #------------------------------------------------------------------------

  if ( not $Retain{INSTANCE} ) 
    {
    $Retain{INSTANCE} = 1;

    if (not $Retain{FILE} and not $Retain{DIR} )
      {
      warn("*** ERROR: Mandatory Retain parameters FILE and DIR not specified! - Retain not executed!!\n");
      return(0);
      }

    if ( not -e $Retain{FILE} )
      {
      warn("*** FILE :$Retain{FILE}: DOES NOT EXIST - Retain not executed!!\n");
      return(0);
      }

    if ( not $Retain{PREFIX} )
      {
      $Retain{PREFIX} = 'bk';
      }
      
    if ( not $Retain{LIMIT} )
      {
      $Retain{LIMIT} = 1;
      }

    if ( $^O =~ /win/i or $Retain{COMPRESS} != 1 and $Retain{COMPRESS} !~ /yes/i )
      {
      $Retain{COMPRESS} = undef;
      }

    if ($Retain{DELETE} != 1 and $Retain{DELETE} !~ /yes/i )
      {
      $Retain{DELETE} = undef;
      }

    }

  #------------------------------------------------------------------------
  # If first time save the original filename in case of compress 
  #------------------------------------------------------------------------

  if (not $Retain{ORIGINAL})
    {
    $Retain{ORIGINAL} = $Retain{FILE};
    $Retain{FILE} = basename($Retain{FILE});
    #----------------------------------------------------------------------
    # If compress specified then change the filename.            
    #----------------------------------------------------------------------
    
    if ($Retain{COMPRESS})
      {
      $Retain{FILE} .= ".Z";
      }
    }

  #------------------------------------------------------------------------
  # Check if limit reached if so delete last occurrence          
  #------------------------------------------------------------------------
  my $currentfile = $Retain{DIR}.'/'.$Retain{PREFIX}.
                    $Retain{INSTANCE}.'/'.$Retain{FILE};
  $currentfile =~ s%/%\\%g if ($^O =~ /mswin/i);               
  if ($Retain{INSTANCE} == $Retain{LIMIT}) 
    {
    if (-e $currentfile )
      {
      unlink($currentfile);
      }
    }

  #------------------------------------------------------------------------
  # Check if file exists if so call retain again to move it      
  #------------------------------------------------------------------------

  elsif (-e $currentfile)  
    {
    print " " x $Retain{INSTANCE},
          $currentfile, "\n" if ($Retain{VERBOSE});
    print " " x $Retain{INSTANCE},
          "^- File exists: RETAIN will be called again!\n\n"    if ($Retain{VERBOSE});
    my(%tmpRetain) = %Retain;
    $tmpRetain{INSTANCE}++;
    &retain(%tmpRetain) or return(0);
    }

  #========================================================================
  # Recursion falls through here 
  #========================================================================
  
  #------------------------------------------------------------------------
  # If at first retain level copy and optionally compress and delete file 
  #------------------------------------------------------------------------
  $tmpdir = "$Retain{DIR}/$Retain{PREFIX}$Retain{INSTANCE}";
  if ($Retain{INSTANCE} == 1) 
    {
    if (not -d $tmpdir ) 
      {
      if (not mkpath($tmpdir,1,0775) )
        {
        warn("*** No Directory exists and can't make it: $!\n");
        return(0);
        }
      }
      
    if ($Retain{COMPRESS})
      {
      if (not compress("< $Retain{ORIGINAL} > $currentfile") )
        {
        warn("*** Compress from $Retain{ORIGINAL}\n***    to $currentfile \n *** FAILED: $!\n");
        return(0);
        };
      }
    else
      {
      if (not copy($Retain{ORIGINAL},$currentfile) )
        {
        warn("*** Copy from $Retain{ORIGINAL}\n***    to $currentfile \n *** FAILED: $!\n");
        return(0);
        }
      }
      
    if ( $Retain{CHMOD} and not chmod $Retain{CHMOD},$currentfile )
        {
        warn("*** CHMOD $Retain{CHMOD} of $currentfile\n FAILED: $!\n");
        }  
        
    if ( $Retain{DELETE} and not unlink($Retain{ORIGINAL}) )
      {
      warn("*** CHMOD $Retain{CHMOD} of $currentfile\n FAILED: $!\n");
      }         
      
    return(1);
    }

  #------------------------------------------------------------------------
  # Otherwise move from one retain dir to the next                        
  #------------------------------------------------------------------------

  else
    {
    $oldfile = "$Retain{DIR}/$Retain{PREFIX}". eval($Retain{INSTANCE}-1) ."/$Retain{FILE}"; 
    $newfile = "$Retain{DIR}/$Retain{PREFIX}$Retain{INSTANCE}/$Retain{FILE}";
    $tmpdir  = "$Retain{DIR}/$Retain{PREFIX}$Retain{INSTANCE}";   
    $oldfile =~ s%/%\\%g if ($^O =~ /mswin/i); 
    $newfile =~ s%/%\\%g if ($^O =~ /mswin/i); 
    $tmpdir  =~ s%/%\\%g if ($^O =~ /mswin/i);  
    
    print "MOVING:$oldfile\n" if ($Retain{VERBOSE});
    print "TO--->:$newfile\n" if ($Retain{VERBOSE});
    
    if (not -d $tmpdir ) 
      {
      if (not mkpath($tmpdir,1,0775) )
        {
        warn("*** No Directory exists and can't make it: $!\n");
        return(0);
        }
      }
   
    if (not move($oldfile,$newfile) )
      {
      warn("*** Move from $oldfile\n***    to $newfile \n *** FAILED: $!\n");
      return(0);
      }
    return(1);
    }
}

sub compress
  {
  my($filename) = @_;
  my($sys_result,$exit_val) = (0,0);
 
  $sys_result = system("$Retain::Compress $filename");
  if ($sys_result)
    {
    $exit_val = int($sys_result / 256);
    if ($exit_val == 2)
      {
      warn("Compress actually made $filename bigger!\n");
      $exit_val = 0;
      }
    else
      {
      warn("Compress FAILED! Exit value = $exit_val");
      return(0);
      }
    }
  return(1);
  }
 
1;

__END__

=head1 NAME
 
 
Retain - keep backup copies of a file


=head1 SYNOPSIS


use Batch::Batchrun::Retain;

retain(FILE=>test,LIMIT=>5,DIR=>/apps/irmprod/archive,COMPRESS=>yes,DELETE=>NO);

=head1 DESCRIPTION

The C<retain> function provides a convenient way to keep backups of files. It keeps
a determined number of files in numbered directories. Arguments are passed using named
parameters.  Each name is case insensitive.  Of the several parameters only FILE and DIR 
are required. 

=head2 REQUIRED PARAMETERS

=over 4

=item B<FILE>

the name of the file to retain

=item B<DIR>

the name of the main directory.  This is the directory where the numbered subdirectories
will be created. 

  EXAMPLE:  archive/
                   bk1/
                   bk2/

=back

=head2 OPTIONAL PARAMETERS

=over 4

=item B<COMPRESS>

compress the backup copies of the file. True values are indicated by 
passing 1 or yes. (unix only - defaults to no)

=item B<CHMOD>

the numeric mode to use when creating the backup file
(defaults to 0775)

=item B<DELETE>

deletes the original file if specified. True values are indicated by 
passing 1 or yes. (defaults to no)


=item B<LIMIT>

number of backup copies to keep.

=item B<PREFIX>

the prefix to use for each numbered directory.  The numbered directory will 
automatically be created if it does not exist. (defaults to bk)

=item B<VERBOSE>

show each file as it is moved or copied.
(defaults to off)

=back

B<NOTE:> C<retain> returns 1 or 0 to determine completion status.

=head1 TESTED PLATFORMS

=over 4

=item Solaris 2.5.1, 2.6

=item WinNT 4.0 

=back

=head1 AUTHOR

=over 4

=item Daryl Anderson <F<batchrun@pnl.gov>> 

=back

=head1 REVISION

Current $VERSION is 1.03.

=cut