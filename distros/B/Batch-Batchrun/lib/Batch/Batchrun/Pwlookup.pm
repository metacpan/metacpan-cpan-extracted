#!/apps/perl5/bin/perl
#
###############################################################################
#  Batch::Batchrun::Pwlookup.pm
#
#  Usage: 
#         use Batch::Batchrun::Pwlookup.pm
#         $variable = dbpwdlookup($servername,$user);
#
#  Database password lookup routine. 
#
#  Change history
#
#  DATE            AUTHOR        DESCRIPTION
#
# 04/16/98      Daryl Anderson   Modifications to work with Batchrun. 
#
# 08/03/99      Daryl Anderson   Modifications to allow distribution and generic
#                                usage.
#                               
###############################################################################
#
package Batch::Batchrun::Pwlookup;

use strict;
no strict 'vars';
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT     = qw(dbpwdlookup);
@EXPORT_OK  = qw();

$VERSION = '1.03';

# Preloaded methods go here.

use Batch::Batchrun::Initialize qw(get_config get_the_options);
use Batch::Batchrun::Library qw(expand_variables);

get_config;
get_the_options;

sub dbpwdlookup 
  {

  #
  #---------------------------------------------------------------------------
  #  Get parameters database server, database_user
  #---------------------------------------------------------------------------
  #

  my($server,$user)=@_;

  #
  #---------------------------------------------------------------------------
  #  Open a pipe to irmpwd to do the work          
  #---------------------------------------------------------------------------
  #

  my($dbpasswd) = pwdlookup($server,$user,"lookup");

  #
  #---------------------------------------------------------------------------
  #  Return the password                           
  #---------------------------------------------------------------------------
  #

  return($dbpasswd);

  }


#
#  Password lookup routines.  
#
#  Change history
#
#  DATE                 AUTHOR        DESCRIPTION
#
# 11/15/96         Daryl Anderson     Initial release.
# 07/21/99         Daryl Anderson     Added set_pwd subroutine.
#
##############################################################################
#


#  Usage: 
#
#  require "pwdlib.pl";
#
#  $variable = pwdlookup($servername,$username,$action,$ftp,$convert,$newpasswd);
#
sub pwdlookup
  {
  #---------------------------------------------------------------------------
  #  Variable summary:
  #
  #   servername    database name or host name
  #   username      user name of database or host
  #   action        what to do                              
  #     lookup      lookup password (requires -u and -s)
  #     view        view password file contents
  #     convert     load text file into password file (overwrites)
  #     modify      modify password (requires -u and -s)
  #   ftp           legacy....  left in for compatability
  #   convert       file to convert                                  
  #---------------------------------------------------------------------------

  my($servername,$username,$action,$ftp,$convert,$newpasswd) = @_;
  my($passwd) = "";


  #
  #---------------------------------------------------------------------------
  # Decide on an action                    
  #---------------------------------------------------------------------------
  #

  if ($action =~ /lookup/io)
    {
    $passwd = &lookup_pwd;
    return($passwd);
    }
  elsif ($action =~ /convert/io)
    {
    &convert_pwd;
    }
  elsif ($action =~ /view/io)
    {
    &view_pwd;
    }
  elsif ($action =~ /modify/io)
    {
    &modify_pwd;
    }
  elsif ($action =~ /set/io)
    {
    &set_pwd;
    }  
  return();

  #----------------------------------------------------------------
  #===========  Subroutines  ======================================
  #----------------------------------------------------------------
  #
  #----------------------------------------------------------------
  # lookup_pwd - lookup password from file
  #----------------------------------------------------------------
  #
  sub lookup_pwd
    {
    &open_read_pwd;
    my($server) = $servername;
    my($user) = $username;
    my($node,$login,$passwd,$nodename,$rest) = ('','','','','');

    while(<READPWD>) 
      {
      next if (/^#/);
      /^([^:]+):([^:]+)/;
      #print $1, " ", $2, "\n";
      if ( ($1 eq $server) && ($2 eq $user) ) 
    { 
    ($node, $login, $passwd, $nodename, $rest) = split(/:/);
    #print "login:     ", $login,   "\n";
    #print "password:  ", $passwd,  "\n";
    #print "nodename:  ", $nodename,"\n";
    #print $passwd;
    last;
    }
      }
      return($passwd);

    &close_read_pwd;

    die("$user not defined in lookup file.\n") 
           unless (length($passwd) > 0);
    }

  #
  #----------------------------------------------------------------
  # convert_pwd - load text file into password file (overwrite)
  #----------------------------------------------------------------
  #

  sub convert_pwd
    {
    open(FROM,"<$convert") 
    || die("Can't open $convert!\n");
    &open_write_pwd;
    while (<FROM>)
      {
      print WRITEPWD $_;
      }
    close(FROM);
    &close_write_pwd;

    print "\nFile created and encrypted from $convert.\n";
    print "\nIf you did not use update_passwords to edit or create\n";
    print "your password file then please remove the file that \n";
    print "you just converted!\n";
    print "Do not leave passwords in unencrypted files!\n";
    
    }

  #
  #----------------------------------------------------------------
  # view_pwd - view the entire password file                  
  #----------------------------------------------------------------
  #

  sub view_pwd
    {
    &open_read_pwd;
    foreach $line (<READPWD>)
      {
      print STDOUT $line;
      }
    &close_read_pwd;
    }

  #
  #----------------------------------------------------------------
  # modify_pwd - modify a password in the password file         
  #----------------------------------------------------------------
  #

  sub modify_pwd
    {
    #
    #  Read the password file into an array
    #
    @newlines = "";
    &open_read_pwd;
    @lines = <READPWD>;
    &close_read_pwd;
    foreach $line (@lines)
      {
      $line =~ /^([^:]+):([^:]+)/;
      if ( ($1 eq $servername) && ($2 eq $username) )
        {
        my($server, $login, $passwd, $nodename, $rest) = split(/:/,$line);
        print "server:", $server,   "\n";
        print "login:", $login,   "\n";
    $loop_count = 0;

        #
        # Prompt for password, give three tries
        #
    while (1)
      {
      $loop_count++;
      if ($loop_count > 3) 
            { 
            warn "Exceeded 3 passwd attempts!\n";
            last;
            }
      print "Enter Passwd:"; 
      `stty -echo`;
      $input = <STDIN>; print "\n";
      `stty echo`;
      $newpasswd = $input;
      print "Enter Passwd again:"; 
      `stty -echo`;
      $input = <STDIN>; print "\n";
      `stty echo`;
      if ($newpasswd eq $input) 
        {
        #
        #  Newline that was entered must be removed
        #

        chop($newpasswd);
            
        #
        #  Check for null password                  
        #

            if ($newpasswd eq "")
              {
              print "\nNull passwords not acceptable! No update performed!\n";
              }
            else
              {
              $passwd = $newpasswd;
              }
        last; # Exit the while loop
        }

      else  # Password doesn't match
        {
        print "Bad passwd! Try #$loop_count\n";
        }
          if (defined($ftp))
            {
            #
            # If ftp and nodename exists then prompt
            #

            if ($nodename ne "")
          {
          print "Enter nodename:";
          $nodename = <STDIN>;
          print "\n";
          }

            }
          } # End of while
        $line = $server.':'.$login.':'.$passwd.':'.$nodename.':'."\n";
        } # Endif 
      push(@newlines,$line);
      } # End of foreach
   
    #
    # Write new array to password file
    #

    &open_write_pwd;
    foreach $line (@newlines)
      {
      print WRITEPWD $line;
      }
    &close_write_pwd;

    return;
    } # End of subroutine

  #
  #----------------------------------------------------------------
  # open_read_pwd - Opent the passwd file pipe for reading         
  #----------------------------------------------------------------
  #

  sub open_read_pwd
    {
    $Batch::Batchrun::BRDecrypt = &Batch::Batchrun::Library::expand_variables($Batch::Batchrun::BRDecrypt);
    open (READPWD, "$Batch::Batchrun::BRDecrypt|") || 
     die("Can't open $Batch::Batchrun::BRDecrypt for input!\n");
    }

  #
  #----------------------------------------------------------------
  # close_read_pwd - Close the passwd file pipe                     
  #----------------------------------------------------------------
  #

  sub close_read_pwd
    {
    close(READPWD);
    }

  #
  #----------------------------------------------------------------
  # close_write_pwd - Close the passwd file pipe                     
  #----------------------------------------------------------------
  #

  sub close_write_pwd
    {
    close(WRITEPWD);
    }

  #
  #----------------------------------------------------------------
  # open_write_pwd - Open the passwd file pipe for write access     
  #----------------------------------------------------------------
  #

  sub open_write_pwd
    {
    $Batch::Batchrun::BREncrypt = expand_variables($Batch::Batchrun::BREncrypt);
    open(WRITEPWD,"|$Batch::Batchrun::BREncrypt") 
    || die("Can't open $Batch::Batchrun::BREncrypt for output!\n");
    }

  #
  #----------------------------------------------------------------
  # set_pwd - set a password in the password file         
  #----------------------------------------------------------------
  #

  sub set_pwd
    {
    #
    #  Read the password file into an array
    #
    @newlines = "";
    &open_read_pwd;
    @lines = <READPWD>;
    &close_read_pwd;
    my($server, $login, $passwd, $nodename, $rest);    
    foreach $line (@lines)
      {
      $line =~ /^([^:]+):([^:]+)/;
      if ( ($1 eq $servername) && ($2 eq $username) )
        {
        ($server, $login, $passwd, $nodename, $rest)= split(/:/,$line);
        $line = $server.':'.$login.':'.$newpasswd.':'.$nodename.':'."\n";
        $foundone = 1;
        } # Endif 
      push(@newlines,$line);
      } # End of foreach
      
    if (! $foundone)
      {
      $line = $servername.':'.$username.':'.$newpasswd.':'.$nodename.':'."\n";
      push(@newlines,$line);
      }
    #
    # Write new array to password file
    #

    &open_write_pwd;
    foreach $line (@newlines)
      {
      print WRITEPWD $line;
      }
    &close_write_pwd;

    return;
    } # End of subroutine

  } # End of pwdlookup
  1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Pwlookup - Batchrun extension to lookup passwords

=head1 SYNOPSIS

  use Batch::Batchrun::Pwlookup qw(dbpwdlookup);
  
  $dbpassword = dbpwdlookup($database_server,$database_user);

=head1 DESCRIPTION

Pwlookup is an important part of the Batchrun application.  This module
allows passwords to be looked up from an encrypted file and passed to 
database functions requiring authentication.  To successfully run in a 
batch environment it is often necessary to store a password somewhere.  By
storing it in an encrypted file that can only be unencrypted by the user, 
security can be much better than if hardcoded in the program.  It also 
allows a program to move from development to testing to production without
having to edit the code.

Pwlookup does not do encryption itself.  Pwlookup is designed to read a 
pipe that contains database names, user names, and passwords.  It is up
to the user to provide whatever type of encryption they wish (if any).  

Pwlookup runs the program specified by the environment variable BR_ENCRYPT
or the br.config configuration variable BREncrypt and reads its output.
The output must be one or more lines in the following format.

databasename:username:password:some comment:
databasename2:username2:password2::

(The comment field is not currently being used but all the colons are 
important!)

The command being run does allow $ENV{} variables to be replaced in the
string before the command is executed thus allowing a user or application
specific file.  Simple examples are contained in the br.config file.


=head1 AUTHOR

Daryl Anderson <F<batchrun@pnl.gov>> 

=head1 SEE ALSO

batchrun(1).

=cut


