package Data::Presenter::Sample::Census;
#$Id: Census.pm 1218 2008-02-10 00:11:59Z jimk $
$VERSION = 1.03; # 02-10-2008
@ISA = qw(Data::Presenter);
use strict;

our %data = ();
our %reserved = ();

sub _init {
	my ($self, $sourcefile, $fieldsref, $paramsref, $index, $reservedref) = @_;
	my @fields = @$fieldsref;       # for convenience
	my %parameters = %$paramsref;   # for convenience
	my @paramvalues = ();
	my %seen = ();	# NEW!
	%reserved = %$reservedref;
	
	$data{'fields'} = [@fields];
	for (my $i = 0; $i < scalar(@fields); $i++) {
			push @paramvalues, \@{$parameters{$fields[$i]}};
	}
	$data{'parameters'} = [@paramvalues];
	$data{'index'} = $index;

	open(CENSUS, $sourcefile) || die "cannot open $sourcefile for reading: $!";     
	while (<CENSUS>) {
		my @corrected = ();
		# DATA MUNGING STARTS HERE
		next if (/^CLIENTS/);
		next if (/\bSHRED\b|\bDELETE\b/);
		next if (/^\s?NAME\s+C\.\sNO/);
		next if (/^\s*$/);
		# DATA MUNGING ENDS HERE
		
		die "The character '!' is reserved for internal use and cannot appear\nin data being processed by Data::Presenter:  $!"
			if (/!/);
			
		# DATA MUNGING STARTS HERE
		my ($lastname, $firstname, $cno, 
			$unit, $ward, $dateadmission, $datebirth) = 
				unpack("x A14 x A10 x A6 x 
						A6 x A4 xxxxxx A10 x A10", $_);
		# The data coming from the $sourcefile may need "munging" in order to process 
		# smoothly.  For example, dates may need to be transformed from, say, 7/2/2001 or 
		# 07/02/2001 to 2001-07-02.  Whitespace may need to be stripped off from the end of 
		# data.  If so, write subroutines to achieve these objectives and call them for 
		# individual fields as needed.  Then assign the results to @corrected.
        $lastname =~ s/\s+$//;
        $firstname =~ s/\s+$//;
        $cno =~ s/^\s+//;
        $unit =~ s/^\s+//;
		@corrected = ($lastname, $firstname, $cno, $unit, $ward, $dateadmission, $datebirth);
		# DATA MUNGING ENDS HERE
		$seen{$corrected[$index]}++;	# NEW!
		die "You have attempted to use $corrected[$index] as the index key\n    for more than 1 entry in the data source.\n    Each entry in the data must have a unique value\n    in the index column:  $!"
			if $seen{$corrected[$index]} > 1;	# NEW!
		if (! $reserved{$corrected[$index]}) {
			$data{$corrected[$index]} = \@corrected;
		} else {
			die "The words 'fields', 'parameters', 'index' and 'options'\n    cannot be used as the unique index to a data record\n    in this program.  $!";
		}
	}
	close(CENSUS) || die "cannot close $sourcefile: $!";
	return \%data;	#  is now a hash of references to arrays, each of which stores the info for 1 record
}

sub _extract_rows {
    my ($self, $column, $relation, $choicesref, $fpref, $flref, 
    	$_analyze_relation_subref, $_strip_non_matches_subref) = @_;
    my %objdata = %$self;
    my %fp = %$fpref;
    my %fieldlabels = %$flref;
    my ($inequality_ref, $dataref);

    # Analysis of $column
    # DATA MUNGING STARTS HERE
    $column = lc($column);  # In 'fields_census.data', all elements of @fields are l.c.
	# DATA MUNGING ENDS HERE
    die "Column (field) name requested does not exist in \@fields:  $!"  
    	unless (exists $fieldlabels{$column});
    my $sortorder = $fp{$column}[1];
    my $sorttype = $fp{$column}[2];
    
    # Analysis of $relation:  &_analyze_relation passed by reference from Data::Presenter
    ($relation, $inequality_ref) = &$_analyze_relation_subref($relation, $sorttype);

    # Analysis of @choices (partial)
    my $choice = '';
    my @corrected = ();
    my %seen = ();
    die "Too many choices for less than\/greater than comparison:  $!"
	    if (scalar(@$choicesref) > 1 && ${$inequality_ref}{$relation});
    foreach $choice (@$choicesref) {
    	# DATA MUNGING STARTS HERE
		# What the user has entered as $choice may need "munging" in order to process 
		# correctly.  For example, dates may need to be transformed from, say, 7/2/2001 or 
		# 07/02/2001 to 2001-07-02.  Whitespace may need to be stripped off from the end of 
		# data.  If so, write subroutines to achieve these objectives and call them for 
		# individual fields as needed.  Then assign the results to @corrected.  (Note below an # instance where the munging consisted of making all data upper case.)
	    $choice = uc($choice);  # because all data in 'census.txt' is u.c.
		# DATA MUNGING ENDS HERE
		push(@corrected, $choice);
		$seen{$choice} = 1;
    }

    # Strip out non-matching rows:  &_strip_non_matches passed by reference from Data::Presenter
    $dataref = &$_strip_non_matches_subref(
    	\%objdata, \%fieldlabels, $column, $relation, \@corrected, \%seen);
    return $dataref;
}

1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Sample::Census

=head1 VERSION

This document refers to version 1.03 of Data::Presenter::Sample::Census, released February 10, 2008. 

=head1 DESCRIPTION

This package is a sample subclass of, and inherits from, Data::Presenter.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Sample::Census.

As a sample package, Data::Presenter::Sample::Census is intended to be used with the following files contained in this distribution:

=over 4

=item *

F<census.txt>

=item *

F<fields.census.data>

=back

=head1 HISTORY AND DEVELOPMENT

=head2 History

=over 4

=item *

v0.60 (4/6/03):  Version number was advanced to 0.60 to be consistent with steps taken to prepare Data::Presenter for public distribution.

=item *

v0.61 (4/12/03):  First version uploaded to CPAN.

=back

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 25, 2001.  Last modification date:  February 10, 2008.  Copyright (c) 2001-08 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 


