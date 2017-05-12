package CGI::Mungo::Log;
use strict;
use warnings;
use base qw(CGI::Mungo::Utils);
###########################################################
sub log{	#a simple way to log a message to the apache error log
	my($self, $message) = @_;
	my $date = localtime();	#add the time
	my $script = $self->_getScriptName();	#add the name of the script
	print STDERR $script . " " . $message . "\n";
	return 1;
}
#################################################
return 1;
