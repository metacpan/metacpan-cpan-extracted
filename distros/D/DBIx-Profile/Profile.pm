#
# Version: 1.0
# Jeff Lathan
# Kerry Clendinning
#
# Aaron Lee
#    Deja.com, 10-1999
# Michael G Schwern, 11-1999
#

#  Copyright (c) 1999,2000 Jeff Lathan, Kerry Clendinning.  All rights reserved. 
#  This program is free software; you can redistribute it and/or modify it 
#  under the same terms as Perl itself.

# .15 First public release.  Bad naming.
# .20 Fixed naming problems
# .30 Module is now more transparent, thanks to Michael G Schwern
#     One less "To Do" left!
#     11-4-1999
# 1.0 Added ability to trace executes, chosen by an environment variable
#     Added capability of saving everything to a log file
#

#
# This package provides an easy way to profile your DBI-based application.
# By just "use"ing this module, you will enable counting and measuring
# realtime and cpu time for each and every query used in the application.
# The times are accumulated by phase: execute vs. fetch, and broken down by
# first fetch, subsequent fetch and failed fetch within each of the 
# fetchrow_array, fetchrow_arrayref, and fetchrow_hashref methods.  
# More DBI functions will be added in the future.
# 
# USAGE:
# Add "use DBIx::Profile;" or use "perl -MDBIx::Profile <program>"
# Add a call to $dbh->printProfile() before calling disconnect,
#    or disconnect will dump the information.
#
# To Do:
#    Make the printProfile code better
#    

##########################################################################
##########################################################################

=head1 NAME

  DBIx::Profile - DBI query profiler
  Version 1.0

  Copyright (c) 1999,2000 Jeff Lathan, Kerry Clendinning.  
  All rights reserved. 

  This program is free software; you can redistribute it and/or modify it 
  under the same terms as Perl itself.

=head1 SYNOPSIS

  use DBIx::Profile; or "perl -MDBIx::Profile <program>" 
  use DBI;
  $dbh->printProfile();

=head1 DESCRIPTION

  DBIx::Profile is a quick and easy, and mostly transparent, profiler
  for scripts using DBI.  It collects information on the query 
  level, and keeps track of first, failed, normal, and total amounts
  (count, wall clock, cput time) for each function on the query.

  NOTE: DBIx::Profile use Time::HiRes to clock the wall time and
  the old standby times() to clock the cpu time.  The cpu time is
  pretty coarse.

  DBIx::Profile can also trace the execution of queries.  It will print 
  a timestamp and the query that was called.  This is optional, and 
  occurs only when the environment variable DBIXPROFILETRACE is set 
  to 1. (ex: (bash) export DBIXPROFILETRACE=1).

  Not all DBI methods are profiled at this time.
  Except for replacing the existing "use" and "connect" statements,
  DBIx::Profile allows DBI functions to be called as usual on handles.

  Prints information to STDERR, prefaced with the pid.

=head1 RECIPE

  1) Add "use DBIx::Profile" or execute "perl -MDBIx::Profile <program>"
  2) Optional: add $dbh->printProfile (will execute during 
     disconnect otherwise)
  3) Run code
  4) Data output will happen at printProfile or $dbh->disconnect;

=head1 METHODS

  printProfile
     $dbh->printProfile();

     Will print out the data collected.
     If this is not called before disconnect, disconnect will call
     printProfile.

  setLogFile
     $dbh->setLogFile("ProfileOutput.txt");

     Will save all output to the file.

=head1 AUTHORS

  Jeff Lathan, lathan@pobox.com
  Kerry Clendinning, kerry@deja.com

  Aaron Lee, aaron@pointx.org
  Michael G Schwern, schwern@pobox.com

=head1 SEE ALSO

  L<perl(1)>, L<DBI>

=cut

#
# For CPAN and Makefile.PL
#
$VERSION = '1.0';

use DBI;

package DBIx::Profile;

# Store DBI's original connect & disconnect then replace it with ours.
{
    local $^W = 0;  # Redefining a subrouting makes noise.
    *_DBI_connect = DBI->can('connect');
    *DBI::connect = \&connect;
}
 
use strict;
use vars qw(@ISA);

@ISA = qw(DBI);

#
# Make DBI aware of us.
#
__PACKAGE__->init_rootclass;

$DBIx::Profile::DBIXFILE = "";
$DBIx::Profile::DBIXFILEHANDLE = "";
$DBIx::Profile::DBIXTRACE = 0;

if ($ENV{DBIXPROFILETRACE}) {
    $DBIx::Profile::DBIXTRACE = 1;
}

sub connect {
    my $self = shift;
    my $result = __PACKAGE__->_DBI_connect(@_);

    if ($result ) {
	# set flag so we know if we have not printed profile data
	$result->{'private_profile'}->{'printProfileFlag'} = 0;
    }

    return $result;
}

##########################################################################
##########################################################################

package DBIx::Profile::db;
use strict;
use vars qw(@ISA );

@ISA = qw( DBI::db );

# 
# insert our "hooks" to grab subsequent calls
#
sub prepare {

    my $self = shift;
    
    my $result = $self->SUPER::prepare(@_);

    if ($result) {
	$result->initRef();
    } 

    return ($result);
}

# 
# disconnect from the database; if printProfile has not been called, call it.
#
sub disconnect {
    my $self = shift;

    if ( !$self->{'private_profile'}->{'printProfileFlag'}) {
	$self->printProfile;
    }

    return $self->SUPER::disconnect(@_);
}

sub setLogFile { 
    my $self = shift;
    my $logName = shift;

    $DBIx::Profile::DBIXFILE = $logName;

    open(OUT,">$logName") || die "Could not open file!";

    $DBIx::Profile::DBIXFILEHANDLE = \*OUT;

    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect(@_);
}

#
# Print the data collected.
#
# JEFF - The printing and the print code is kinda (er... very) ugly!
#

sub printProfile {

    my $self = shift;
    my %result;
    my $total = 0;
    no integer;

    # Set that we have printed the results
    $self->{'private_profile'}->{'printProfileFlag'} = 1;

    # Loop through the queries
    foreach my $qry (keys %{$self->{'private_profile'}}) {

	my $text = "";

	if ( $qry eq "printProfileFlag" ) {
	    next;
	}

	$total = 0;

	# Now loop through the actions (execute, fetchrow, etc)
	foreach my $name ( sort keys %{$self->{'private_profile'}->{$qry}}) {
	    # Right now, this assumes that we only have wall clock, cpu
	    # and count.  Not generic, but what we want NOW
   
	    if ( $name eq "first" ) {
		next;
	    }

	    $text .= "   $name ---------------------------------------\n";

	    foreach my $type (sort keys %{$self->{'private_profile'}->{$qry}->{$name}}) {
		$text .= "      $type\n";
		
		my ($count, $time, $ctime);
		$count = $self->{'private_profile'}->{$qry}->{$name}->{$type}->{'count'};
		$time = $self->{'private_profile'}->{$qry}->{$name}->{$type}->{'realtime'};
		$ctime = $self->{'private_profile'}->{$qry}->{$name}->{$type}->{'cputime'};
		
		$text .= sprintf "         Count        : %10d\n",$count;
		$text .= sprintf "         Wall Clock   : %10.7f s   %10.7f s\n",$time,$time/$count;
		$text .= sprintf "         Cpu Time     : %10.7f s   %10.7f s\n",$ctime,$ctime/$count;

		if ($type eq "Total") {
		    $total += $time;
		}
		
	    } # $type
	} # $name

	$text = "$$ \"" . $qry . "\"   Total wall clock time: ". $total ."s \n" . $text;
	$text = "=================================================================\n" . $text;

	# In order to sort based on the total time taken for a query "easily"
	# we are placing the information in a hash with the total time as the key.
	# Since we could have many queries with the same total, if this exists,
	# we cat the query string to the total string and use that as the key.
	# The sort function will do the right thing.

	if (exists $result{$total} ) {
	    $total .= $qry;
	}

	$result{$total} = $text;
    } # each query

    foreach my $qry (sort stripsort keys %result) {
	if ($DBIx::Profile::DBIXFILE eq "" ) {
	    warn $result{$qry} . "\n";
	} else {
	    print $DBIx::Profile::DBIXFILEHANDLE $result{$qry} . "\n";
	}
    }
}
    
sub stripsort {

    # Strip off the actual number amount, since the variables may
    # contain text as well

    $a =~ m/^(\d+\.\d+)/;
    my $na = $1;
    $b =~ m/^(\d+\.\d+)/;
    my $nb = $1;
    
    # Yes, this processes backwards since we want to go decreasing
    $nb <=> $na;

}

##########################################################################
##########################################################################

package DBIx::Profile::st;
use strict;
use vars qw(@ISA);

@ISA = qw(DBI::st);

# Get some accurancy for wall clock time
# Cpu time is still very coarse, but...

use Time::HiRes qw ( gettimeofday tv_interval);

# Aaron Lee (aaron@pointx.org) provided the majority of
# BEGIN block below.  It allowed the removal of a lot of duplicate code
# and makes the code much much cleaner, and easier to add DBI functionality.

BEGIN {

    # Basic idea for each timing function:
    # Grab timing info
    # Call real DBI call
    # Grab timing info
    # Calculate time diff
    # 
    # Just add more functions in @func_list

    my @func_list = ('fetchrow_array','fetchrow_arrayref','execute', 
		     'fetchrow_hashref');
    
    my $func;

    foreach $func (@func_list){
	
	# define subroutine code, incl dynamic name and SUPER:: call 
	my $sub_code = 
	    "sub $func {" . '
		my $self = shift;
		my @result; 
                my $result;
		my ($time, $ctime, $temp, $x, $y, $z, $type);

                if (wantarray) {

                   $time = [gettimeofday];
		   ($ctime, $x ) = times();

                   @result =  $self->SUPER::' . "$func" . '(@_); 
	
		   ($y, $z ) = times();
		   $time = tv_interval ($time, [gettimeofday]);

                   #
                   # Checking scalar because we are also interested
                   # in catching empty list
                   #
                   if (scalar @result) {
                      $type = "normal";
                   } else {
                      if (!$self->err) {
                         $type = "no more rows";
                      } else {
                         $type = "error";
                      }
                   }

		   $ctime = ($y + $z) - ($x + $ctime);
                   $self->increment($func,$type,$time, $ctime);
                   return @result;

                } else {

		   $time = [gettimeofday];
		   ($ctime, $x ) = times();

                   $result =  $self->SUPER::' . "$func" . '(@_); 
	
		   ($y, $z ) = times();
		   $time = tv_interval ($time, [gettimeofday]);

                   if (defined $result) {
                      if ($result ne "0E0") {
                         $type = "normal";
                      } else {
                         $type = "returned 0E0";
                      }

                   } else {
                      if (!$self->err) {
                         $type = "no more rows";
                      } else {
                         $type = "error";
                      }
                   }

		   $ctime = ($y + $z) - ($x + $ctime);
                   $self->increment($func,$type,$time, $ctime);
                   return $result;

                } # end of if (wantarray);

	    } # end of function definition
        ';
	
	# define $func in current package
	eval $sub_code;
    }
}

sub fetchrow {
    my $self = shift;
    #
    # fetchrow is just an alias for fetchrow_array, so
    # send it that way
    #
    # Is the return below safe, given the main function above? - JEFF
    #

    return $self->fetchrow_array(@_);
}

sub increment {
    my ($self, $name, $type, $time, $ctime) = @_;

    my $ref;
    my $qry = $self->{'Statement'};
    $ref = $self->{'private_profile'};

    # text matching?!?  *sigh* - JEFF
    if ( $name =~ /^execute/ ) {
	$ref->{"first"} = 1;
	if ( $DBIx::Profile::DBIXTRACE ) {
	    my ($sec, $min, $hour, $mday, $mon);
	    ($sec, $min, $hour, $mday, $mon) = localtime(time);
	    my $text = sprintf("%d-%2d %2d:%2d:%2d", $mon, $mday,$hour,$min,$sec);
	    if ($DBIx::Profile::DBIXFILE eq "" ) {
		warn "$$ text $name SQL: $qry\n";
	    } else {
		print $DBIx::Profile::DBIXFILEHANDLE "$$ $text $name SQL: $qry\n";
	    }
	}
    }

    if ( ($name =~ /^fetch/) && ($ref->{'first'} == 1) ) {
	$type = "first";
	$ref->{'first'} = 0;
    }

    $ref->{$name}->{$type}->{'count'}++;
    $ref->{$name}->{$type}->{'realtime'}+= $time;
    $ref->{$name}->{$type}->{'cputime'}+= $ctime;

    $ref->{$name}->{"Total"}->{'count'}++;
    $ref->{$name}->{"Total"}->{'realtime'}+= $time;
    $ref->{$name}->{"Total"}->{'cputime'}+= $ctime;
    
}

# initRef is called from Prepare in DBIProfile
#
# Its purpose is to create the DBI's private_profile info
# so that we do not lose DBI::errstr in increment() later

sub initRef {
    my $self = shift;
    my $qry = $self->{'Statement'};

    if (!exists($self->{'private_profile'})) {
	if (!exists($self->{'Database'}->{'private_profile'}->{$qry})) {
	    $self->{'Database'}->{'private_profile'}->{$qry} = {};
        }
        $self->{'private_profile'} = 
	    $self->{'Database'}->{'private_profile'}->{$qry};    
    }
}

1;






