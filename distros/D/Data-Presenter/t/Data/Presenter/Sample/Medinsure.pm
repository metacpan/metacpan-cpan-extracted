package Data::Presenter::Sample::Medinsure;
#$Id: Medinsure.pm 1218 2008-02-10 00:11:59Z jimk $
$VERSION = 1.03; # 02-10-2008
@ISA = qw(Data::Presenter);
use strict;
use warnings;
use Carp;

sub _init {
    my ($self, $sourcefile, $fieldsref, $paramsref, $index, $reservedref) = @_;
    my @fields = @$fieldsref;
    my %parameters = %$paramsref;
    my (@paramvalues, %seen, %data);
    my %reserved = %$reservedref;
    
    $data{'fields'} = [@fields];
    for (my $i = 0; $i < scalar(@fields); $i++) {
            push @paramvalues, \@{$parameters{$fields[$i]}};
    }
    $data{'parameters'} = [@paramvalues];
    $data{'index'} = $index;
    local $_;

    open(my $MEDIDATA, $sourcefile) || croak "cannot open $sourcefile for reading: $!";     
    while (<$MEDIDATA>) {
        # DATA MUNGING STARTS HERE
        next unless (/^\s{4}\b[\w\s\d-]{35}\d{6}/);
        my ($lastname, $firstname, $cno, $stateid, $medicare, $medicaid);
        my ($balance, @entries);
        croak "The character '!' is reserved for internal use and cannot appear\nin data being processed by Data::Presenter:  $!"
            if (/!/);    # REQUIRED!
        ($lastname, $firstname, $cno, $balance) =
            unpack("xxxx A16 x A16 xx A6 x A*", $_);
        $lastname =~ s/\s+$//;
        $firstname =~ s/\s+$//;
        $cno =~ s/^\s+//;
        if ($balance =~ /^\s*(\d+)\s{5}(\S+?)\s+([A-Z\d]{8})/) {
            $stateid = $1;
            $medicare = $2;
            $medicaid = $3;
        } else {
            croak "Couldn't complete parsing of line $_: $!";
        }
        @entries = ($lastname, $firstname, $cno, $stateid, $medicare, $medicaid);
        
        # DATA MUNGING ENDS HERE
        $seen{$entries[$index]}++;    # NEW!
        croak "You have attempted to use $entries[$index] as the index key\n    for more than 1 entry in the data source.\n    Each entry in the data must have a unique value\n    in the index column:  $!"
            if $seen{$entries[$index]} > 1;    # NEW!
        if (! $reserved{$entries[$index]}) {
            $data{$entries[$index]} = \@entries;
        } else {
            croak "The words 'fields', 'parameters', 'index' and 'options'\n    cannot be used as the unique index to a data record\n    in this program.  $!";
        }
    }
    close ($MEDIDATA) || croak "can't close $sourcefile:$!";
    # %data is now a hash of references to arrays, each of which stores the info for 1 record
    return \%data;
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
    $column = lc($column);  # In 'fields_medinsure.data', all elements of @fields are l.c.
    # DATA MUNGING ENDS HERE
    croak "Column (field) name requested does not exist in \@fields:  $!"
        unless (exists $fieldlabels{$column});
    my $sortorder = $fp{$column}[1];
    my $sorttype = $fp{$column}[2];
    
    # Analysis of $relation:  &_analyze_relation passed by reference from Data::Presenter
    ($relation, $inequality_ref) = &$_analyze_relation_subref($relation, $sorttype);

    # Analysis of @choices (partial)
    my $choice = '';
    my @corrected = ();
    my %seen = ();
    croak "Too many choices for less than\/greater than comparison:  $!"
        if (scalar(@$choicesref) > 1 && ${$inequality_ref}{$relation});
    foreach $choice (@$choicesref) {
        # DATA MUNGING STARTS HERE
        # Do data munging here as needed
        $choice = uc($choice);  # because all data in 'in.txt' is u.c.
        # DATA MUNGING ENDS HERE
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

Data::Presenter::Sample::Medinsure

=head1 VERSION

This document refers to version 1.03 of Data::Presenter::Sample::Medinsure, released February 10, 2008. 

=head1 DESCRIPTION

This package is a sample subclass of, and inherits from, Data::Presenter.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Sample::Medinsure.

As a sample package, Data::Presenter::Sample::Medinsure is intended to be used with the following files contained in this distribution:

=over 4

=item *

F<medinsure.txt>

=item *

F<fields.medinsure.data>

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

__END__
