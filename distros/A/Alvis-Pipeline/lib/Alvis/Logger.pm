# $Id: Logger.pm,v 1.1 2005/06/17 15:45:56 mike Exp $

# This is a simple logging object that I have accidentally implemented
# several different 90% subsets of in half a dozen different projects.
# It's time to get it done once, properly.

package Alvis::Logger;
use strict;
use warnings;


# Create a new logger object.  Options that may be specified include:
#	level [default 0]: only emit messages with priority less than
#		or equal to this (so that the default behaviour is to
#		be silent except for priority-zero messages, which are
#		really error messages).
#	stream [stderr]: where to write messages
#	
sub new {
    my $class = shift();
    #warn("new($class): \@_ = ", join(", ", map { "'$_'" } @_), "\n");
    my %options = ( level => 0, stream => \*STDERR, @_ );
    $options{level} = 0 if !defined $options{level};

    return bless {
	options => \%options,
    }, $class;
}


# Log a message.  The first argument is the priority of the message,
# the remainder are strings that will be concatenated to form the
# message.
#
sub log {
    my $this = shift();
    my($msglevel, @msg) = @_;

    my $level = $this->{options}->{level};
    return if $msglevel > $level;

    my $stream = $this->{options}->{stream};
    my $text = "log($msglevel): ";
    if ($this->{options}->{timestamp}) {
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	# ISO date format, which is big-endian and so sorts nicely
	$text .= sprintf("%04d-%02d-%02d %02d:%02d:%02d: ",
			 $year+1900, $mon+1, $mday, $hour, $min, $sec);
    }

    print $stream $text, @msg, "\n";
}


1;
