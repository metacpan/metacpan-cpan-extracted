#!/usr/bin/perl -Tw
use 5.004;
use strict;
use CfgTie::TieGeneric;
my %Gen;
tie %Gen, 'CfgTie::TieGeneric';
my $pathinfo;
my $Base0="http://xiotech.com/~randym";
my $CSS="$Base0/CfgTie.css";
my $Base="$Base0/sys.cgi/";

sub redirect($) {exec ("cat ".shift);}
sub Untaint_path($) {$_[0]=~ s/^(.*)$/$1/;}

sub Prefixes_To_Avoid($)
{
   my $self=shift;
   #Avoid anything that starts with act-
   if ($self->{'name'} =~ /^act-/i) {return 0;}
   return 1;
}

sub Gen_print($$)
{
   my ($Space,$Name)= @_;

   #If the user does not exists, gripe
   if ( (defined $Space && $Space && length $Space &&  !exists $Gen{$Space}) ||
	(defined $Name && $Name && !exists $Gen{$Space}->{$Name}))
     {
	#Carlington miniscule
	my $Thingy=$Space;
        if ($Space=~/^(\w)(\w+)/) {my $a=$1;$a=~tr/a-z/A-Z/;$Thingy=$a.$2;}
        print "<html><h1>$Thingy does not exist</h1>$pathinfo</html>\n";
        exit 0;
     }

   #Print neat information about the user out.
   my $U = \%Gen;
   if (defined $Space && $Space) {$U = $Gen{$Space};}
   if (defined $Name && $Name) {$U=$U->{$Name};}
   print "<html><head>";
   if (defined $CSS)
     {print "<!-- Call style sheet -->\n".
	    "<link rel=\"stylesheet\" href=\"$CSS\" type=\"text/css\" ".
	    "name=\"CfgTie Style\">\n";
     }

   if (!defined $Name && defined $Space) {$Name=$Space;}
   if (!defined $Name) {$Name="Directory";}
   print "<title>$Name</title>\n";
   if (defined $Base) {print "<base href=\"$Base\">\n";}
   print "</head><body>\n";
   if (defined $U)
    {my $A =(tied %{$U})->HTML();
       print $A;
    }
    else {print "Nothing\n";}
   print "</body></html>\n";
}

if (exists $ENV{'PATH_INFO'})
  {
     $pathinfo=$ENV{'PATH_INFO'};
     Untaint_path($pathinfo);
  }

my $oldbar=$|;
my $cfh=select(STDOUT);
$|=1;
open STDERR, ">&STDOUT";

print "Content-type: text/html\n\n";

# Set up for security.
$ENV{'PATH'} = '/bin:/usr/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
my ($Space,$Name);
if ($pathinfo)
  {
if ($pathinfo=~ /^\/(\w+)(?:s)?\/(\w+)/)
  {$Space=lc($1);$Name=$2;}
elsif ($pathinfo=~/^\/(\w+)(?:s)?\/?$/)
  {$Space=lc($1);}
  }

&Gen_print($Space,$Name);

=head1 NAME

sys.cgi -- An example CGI script to browse configuration space via CfgTie

=head1 SYNPOSIS

	http://www.mydomain.com/sys.cgi/user/joeuser
	http://www.mydomain.com/sys.cgi/users
	http://www.mydomain.com/sys.cgi/groups

=cut

