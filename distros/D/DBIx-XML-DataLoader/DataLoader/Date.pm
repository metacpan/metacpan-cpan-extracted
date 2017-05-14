
package DBIx::XML::DataLoader::Date;

use strict;
use warnings;

### this is a simple module that has four available sub routine
###
###  the sub "now" takes no arguments and returns the date as 
###  translated from localtime
###
###   the sub "nowTime" takes no argument and returns the current time
###
###   the sub "nowDate" takes no argument and returns the current date
###
###   the sub "nowDay" takes no argument and returns the current day of week
###


###########
sub new{
########

my $self = shift;
bless \$self;

#######
} # end sub new
################

###############
sub now{
########

my @time=localtime;
$time[1]=~ s/^\d$/0$&/;
$time[2]=~ s/^\d$/0$&/;
$time[0]=~ s/^\d$/0$&/;
my $now= "Time ".$time[2].":".$time[1].":".$time[0]." Date ".($time[4]+1)."/".$time[3]."/".($time[5]+1900);
return $now;

########
}# end sub now
#################

################
sub nowTime{
############
my @time=localtime;
$time[1]=~ s/^\d$/0$&/;
$time[2]=~ s/^\d$/0$&/;
$time[0]=~ s/^\d$/0$&/;
my $now=$time[2].":".$time[1].":".$time[0];
return $now;

###########
} #end sub nowTime
###################

##################
sub nowDate{
############

my @time=localtime;
$time[1]=~ s/^\d$/0$&/;
$time[2]=~ s/^\d$/0$&/;
$time[0]=~ s/^\d$/0$&/;

my $now=($time[4]+1)."/".$time[3]."/".($time[5]+1900);

return $now;

###########
} # end sub nowDate
##################

###################
sub nowDay{
###########

my $now=('Sun', 'Mon', 'Tue', 'Wed', 'Thr', 'Fri', 'Sat')[(localtime)[6]];

return $now;

###########
} #end sub nowDay
##################


1;


__END__




=head1 NAME

        DBIx::XML::DataLoader::Date


=head1 SYNOPSIS

	use DBIx::XML::DataLoader::Date;

	print "the Time is \t", Date->nowTime(), "\n";	
	print "the Date is \t", Date->nowDate(), "\n";
	print "The Day is \t", Date->nowDay(), "\n";
	print "The Full date and time is:  ", Date->now(), "\n";	

=for text or

=for man  or

=for html <b>or</b>
	
	my $d=Date->new();
	print "the Time is \t", $d->nowTime(), "\n";
	print "the Date is \t", $d->nowDate(), "\n";
	print "The Day is \t", $d->nowDay(), "\n";
	print "The Full date and time is:  ", $d->now(), "\n";
	

=head2 Results

	the Time is 	13:55:24
	the Date is 	1/29/2002
	The Day is	Fri
	The Full date and time is:  Time 13:55:24 Date 1/29/2002
 	

=head1 DESCRIPTION

	This module is for convenience use by DBIx::XML::DataLoader::XMLWriter and DBIx::XML::DataLoader.
	It's purpose is most likly replicated by other more standard modules
	




=for html
<p><hr><p>

