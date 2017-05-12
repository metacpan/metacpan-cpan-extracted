package Date::Namedays::Simple;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.01;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

####################################################################################
# Create object - we do nothing with the parameters now (maybe in a later version)
####################################################################################
sub new {
	my ($class, %parameters) = @_;
	my $self = bless ({}, ref ($class) || $class);
	return ($self);
}


###########################################################
# Input: month, day, [year]
# A list of names is returned.
# Year is optional, but if you do not provide it, leap
# years are not taken into consideration!
###########################################################
sub getNames {
        my ($self, $month, $day, $year) = @_;

	# some calendars handle leap-years in a special way... like
	# the Hungarian, which is totally insane
	my $leapyearmonth = 0;
	my $leapyearmonth = 1 if ($year && (not ($year % 4) ) && ($month == 2));	
	# note: this is a VERY lame leap-year calculation here...
	
	if ($leapyearmonth) {
		($month, $day) = $self->leapYear($month, $day)
	}
	
        my $namedays = $self->_getNameDays;
        return @{$namedays->[$month-1]->[$day-1]};
}

############################################################################
# Leap year, default implementation: does nothing.
############################################################################
sub leapYear {
	my ($self, $year, $month, $day) = @_;

	return ($month, $day);	# default: don't change; some override this...
}

############################################################################
# Returns all namedays in an arrayref
############################################################################
sub _getNameDays {
        my $self = shift;
	
	# We simply "cache" namedays data
	return $self->{NAMEDAYS} if ($self->{NAMEDAYS});
                                                                                                  
        my $namedays = [];
        my $in = $self->processNames;
        my (@lines) = split (/\n/, $in);
        foreach my $line (@lines) {
                my ($month, $day, $names) = ($line =~ /^(\d+)\.(\d+)\.(\S+)$/);
                chomp ($names);
                my (@names) = split (/,/, $names);
                $month--;
                $day--;
                $namedays->[$month] = [] if (not $namedays->[$month]);
                $namedays->[$month]->[$day] = \@names;
        }
	
	$self->{NAMEDAYS} = $namedays;	# "cache" for later use
                                                                                                                             
        return $namedays;
}

sub processNames {
	die ("Hi, I am Date::Namedays::Simpler. Sorry, you must provide a 'processNames' sub in subclasses!");
}

########################################### main pod documentation begin ##


=head1 NAME

Date::Namedays::Simple - simple base class for getting namedays for a given date.

=head1 SYNOPSIS

  use Date::Namedays::Simple::Your_Language_Module_Here;

  # create an instance
  # Date::Namedays::Simple is abstract, so must use a subclass
  my $nd = new Date::Namedays::Simple::Hungarian;	

  # get (all!) names for the year 2001, 24th of July
  my (@names) = $nd->getNames(7,24,2001);	
    
  # Now simply print them
  my $namestoday = join (',',@names);
  print $namestoday;


=head1 DESCRIPTION

In many countries, people not only celebrate their birthdays annually, but there is also the concept of "nameday". 
Calendars in these countries (e.g. Hungary) contain one ore more names for each day - the day on which a person with 
the given first name celebrate his/her nameday.

This module is here simply to aid you to get the namedays for a date. You simply supply the year, month and day, and 
the corresponding names are returned. It is as simple as that. 

This module uses no external modules. It does not export anything - I wanted to keep it as simple as possible.

Please note: THIS MODULE IS ALPHA PHASE! It works, but I need some feedback. (Send feedback!) The methods and their 
parameters can change any time!

Note: names are stored in a human readable format. Because of this, they are parsed at runtime. This takes some 
time obviously - just don't worry about it, we "cache" that in $self, and actually that's why this module must be 
instanteniated, that's why we have instance methods instead of class methods.


Date::Namedays::Simple is an abstract class, it is always subclassed, for example to 
Date::Namedays::Simple::Hungarian. Subclasses must implement the "processNames()" method. This method shall return 
a string(!) in the following format:

1.1.name1,name2,...,nameN
1.2.name1,name2,...,nameN
...
12.31.name1,name2,...,nameN

Which is more precisely a "\n" separated list of the following lines:

$month.$day.$name1[,$name2,...,$nameN]\n

See Date::Namedays::Simple::Hungarian for example!


=head1 USAGE

 See SYNOPSIS.

=head1 BUGS

None so far... send bugreports!


=head1 SUPPORT

Ask the author. Only bugs concerning this module, please!


=head1 AUTHOR

	Csongor Fagyal
	csongorNOSPAMREMOVEME@fagyal.com
	http://www.conceptonline.com/about

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##
#
#=head2 sample_function
#
# Usage     : How to use this function/method
# Purpose   : What it does
# Returns   : What it returns
# Argument  : What it wants to know
# Throws    : Exceptions and other anomolies
# Comments  : This is a sample subroutine header.
#           : It is polite to include more pod and fewer comments.
#
#See Also   : 
#
#=cut
#
################################################## subroutine header end ##



1;	# boinggg
__END__

