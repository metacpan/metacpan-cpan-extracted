package Data::Presenter::Sample::Hair;
#$Id: Hair.pm 1218 2008-02-10 00:11:59Z jimk $
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
    my %seen = ();
    %reserved = %$reservedref;
    
    $data{'fields'} = [@fields];
    for (my $i = 0; $i < scalar(@fields); $i++) {
            push @paramvalues, \@{$parameters{$fields[$i]}};
    }
    $data{'parameters'} = [@paramvalues];
    $data{'index'} = $index;

    open(HAIR, $sourcefile) || die "cannot open $sourcefile for reading: $!";     
    while (<HAIR>) {
        # DATA MUNGING STARTS HERE
        my @corrected = ();
        next if (/^INPATIENTS/);
        next if (/\bSHRED\b|\bDELETE\b/);
        next if (/^\s+C\.\sNO/);
        next if (/^\s+$/);
        next if (/^\s*\d+\s*$/);

        die "The character '!' is reserved for internal use and cannot appear\nin data being processed by Data::Presenter:  $!"
            if (/!/);    # REQUIRED!

        my ($cno, $lastname, $firstname, $haircolor, $number) = 
            unpack("A6 xx A14 x A10 x A9 x A2", $_);
        # Data munging here as needed
        $lastname =~ s/\s+$//;
        $firstname =~ s/\s+$//;
        $cno =~ s/^\s+//;
        $haircolor =~ s/\s+$//;
        $number =~ s/^\s+//;
        @corrected = ($cno, $lastname, $firstname, $haircolor, $number);
        # DATA MUNGING ENDS HERE
        $seen{$corrected[$index]}++;    # NEW!
        die "You have attempted to use $corrected[$index] as the index key\n    for more than 1 entry in the data source.\n    Each entry in the data must have a unique value\n    in the index column:  $!"
            if $seen{$corrected[$index]} > 1;    # NEW!
        if (! $reserved{$corrected[$index]}) {
            $data{$corrected[$index]} = \@corrected;
        } else {
            die "The words 'fields', 'parameters', 'index' and 'options'\n    cannot be used as the unique index to a data record\n    in this program.  $!";
        }
    }
    close(HAIR) || die "cannot close $sourcefile: $!";
    return \%data;    #  is now a hash of references to arrays, each of which stores the info for 1 record
}

sub _extract_rows{
    my ($self, $column, $relation, $choicesref, $fpref, $flref, 
        $_analyze_relation_subref, $_strip_non_matches_subref) = @_;
    my %objdata = %$self;
    my %fp = %$fpref;
    my %fieldlabels = %$flref;
    my ($inequality_ref, $dataref);

    # Analysis of $column
    $column = lc($column);
    die "Column (field) name requested does not exist in \@fields:  $!"  unless (exists $fieldlabels{$column});
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
        # Data munging here as needed
        $choice = uc($choice);  # because all data in 'in.txt' is u.c.
        if ($column eq 'cno') {
            $choice = cnocorrector($choice);
        } elsif ($column eq 'lastname') {
            $choice = strip_trail($choice);
        } elsif ($column eq 'firstname') {
            $choice = strip_trail($choice);
        } elsif ($column eq 'haircolor') {
            $choice = strip_trail($choice);
        } elsif ($column eq 'number') {
            $choice = strip_lead($choice);
        } else {
            die "Error in specifying column (field): $!";
        }
        push(@corrected, $choice);
        $seen{$choice} = 1;
    }

    # Strip out non-matching rows:  &_strip_non_matches passed by reference from Data::Presenter
    $dataref = &$_strip_non_matches_subref(\%objdata, \%fieldlabels, $column, $relation, \@corrected, \%seen);
    return $dataref;
}

1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Sample::Hair

=head1 VERSION

This document refers to version 1.03 of Data::Presenter::Sample::Hair, released February 10, 2008. 

=head1 DESCRIPTION

This package is a sample subclass of, and inherits from, Data::Presenter.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Sample::Hair.

As a sample package, Data::Presenter::Sample::Hair is intended to be used with the following files contained in this distribution:

=over 4

=item *

F<hair.txt>

=item *

F<fields.hair.data>

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


