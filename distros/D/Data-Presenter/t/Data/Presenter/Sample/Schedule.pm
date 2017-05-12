package Data::Presenter::Sample::Schedule;
#$Id: Schedule.pm 1218 2008-02-10 00:11:59Z jimk $
$VERSION = 1.03; # 02-10-2008
@ISA = qw(Data::Presenter);
use strict;

sub _init {
    my ($self, $msobject, $fieldsref, $paramsref, $index, $reservedref) = @_;
    my @fields = @$fieldsref;       # for convenience
    my %parameters = %$paramsref;   # for convenience
    my @paramvalues = ();
    my (%data, %reprocess_subs, %seen);
    my %reserved = %$reservedref;      # for convenience
    $data{'fields'} = [@fields];
    for (my $i = 0; $i < scalar(@fields); $i++) {
            push @paramvalues, \@{$parameters{$fields[$i]}};
    }
    $data{'parameters'} = [@paramvalues];
    $data{'index'} = $index;
    
    my %events = %$msobject;
    my ($k, $v);
    
    # on a first pass we won't do any munging or correcting except to get rid of
    # the 'linecount' key
    while ( ($k, $v) = each %events ) {
        next if ($k eq 'linecount' or $k eq 'options');
        my @temp = ($k, @$v);
        my @corrected = ();
        foreach (@temp) {
            if (/!/) {
                die "The character '!' is reserved for internal use and cannot appear\nin data being processed by Data::Presenter:  $!";
            } else {
                push @corrected, $_;
            }
        }
        $seen{$corrected[$index]}++;
        die "You have attempted to use $corrected[$index] as the index key\n    for more than 1 entry in the data source.\n    Each entry in the data must have a unique value\n    in the index column:  $!"
            if $seen{$corrected[$index]} > 1;
        if (! $reserved{$corrected[$index]}) {
            $data{$corrected[$index]} = \@corrected;
        } else {
            die "The words 'fields', 'parameters', 'index' and 'options'\n    cannot be used as the unique index to a data record\n    in this program.  $!";
        }
    }
    my $pkg = __PACKAGE__;    # per Benjamin Goldberg on comp.lang.perl.misc 10/28/02
    {
        no strict 'refs';
        foreach (sort keys %{ $pkg . "::" } ) {  # per BG on c.l.p.m. 10/29/02
          $reprocess_subs{$_}++ if
             $_ =~ /^reprocess_/ and defined *{$_}{CODE};
        }
    }
    $data{'options'}{'subs'} = \%reprocess_subs;
    foreach (keys %{$events{'options'}{'sources'}}) {
        $data{'options'}{'sources'}{$_} = $events{'options'}{'sources'}{$_};
    }
    return \%data;    #  is now a hash of references to arrays, each of which stores the info for 1 record
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
    $column = lc($column);  # In 'fields_schedule.data', all elements of @fields are l.c.
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
#        $choice = uc($choice);  # because all data in 'census.txt' is u.c.
        # DATA MUNGING ENDS HERE
        push(@corrected, $choice);
        $seen{$choice} = 1;
    }

    # Strip out non-matching rows:  &_strip_non_matches passed by reference from Data::Presenter
    $dataref = &$_strip_non_matches_subref(
        \%objdata, \%fieldlabels, $column, $relation, \@corrected, \%seen);
    return $dataref;
}

sub _reprocessor {
    my ($self, $line_raw, $sdref) = @_;
    my ($line_temp);

    # for readability during development
    my %substr_data = %$sdref;
    
    $line_temp = $line_raw;
    
    # Need to apply the reprocessing right-to-left on the formed line 
    # Hence we need an array where the elements of @$reprocessref are 
    # arranged by decreasing order of the insertion point

    foreach (sort {$b <=> $a} keys %substr_data) {
        my $line_temp1 = $line_temp;
        my $field = $substr_data{$_}[0];
        my $subname = 'reprocess_' . $field;
        my $initial_length = $substr_data{$_}[1];
        my $original = substr ($line_temp1, $_, $initial_length);
        my $fixed_length   = $substr_data{$_}[2];
        my %this_source  = %{$substr_data{$_}[3]};
        my %all_sources  = %{$substr_data{$_}[4]};
        no strict 'refs';
        substr($line_temp, $_, $initial_length) = 
            &$subname($initial_length, $original, 
                $fixed_length, \%this_source, \%all_sources);
    }
    return $line_temp;
}

sub reprocess_timeslot {
    my ($initial_length, $original, $fixed_length, $sourceref, 
        $dataref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    my %data = %$dataref;
    if (exists $sources{$keyword}) {
        my $start_time = ${$sources{$keyword}}[1];
        $replacement = ${$sources{$keyword}}[0] . ', ' . $start_time;
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_instructor {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        if (${$sources{$keyword}}[1]) {
            # last name only would be:
            # $replacement = ${$sources{$keyword}}[0];
            # but now we're using:  last name, first name
            $replacement = 
                ${$sources{$keyword}}[0] . ', ' . ${$sources{$keyword}}[1];
        } else {
            $replacement = ${$sources{$keyword}}[0];
        }
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_room {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        if (${$sources{$keyword}}[1]) {
            $replacement = ${$sources{$keyword}}[1] . ' ' .         # mall
                           ${$sources{$keyword}}[0];                # room no.
        } else {
            $replacement = ${$sources{$keyword}}[0];
        }
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_discipline {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|([\s\d]\d)\b\s*$|;
    my $temp = $1 if (defined $1);
    $temp =~ s|^\s+||;
    $keyword = $temp;
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        $replacement = ${$sources{$keyword}}[0];
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_ward_department {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        $replacement = ${$sources{$keyword}}[0];
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub _length_adjuster {
    my ($replacement, $fixed_length) = @_;
    my $len = length($replacement);
    if ($len < $fixed_length) {
        $replacement .= ' ' x ($fixed_length - $len);
    } elsif ($len > $fixed_length) {
        $replacement = substr($replacement, 0, $fixed_length);
    }
    return $replacement;
}

sub _reprocessor_delimit {
    my ($self, $record, $reprocessing_ref, $cols_ref) = @_;
    my $dataref = \%{$self};
    my @outputs = @{$record};
    foreach my $repcol (@{$reprocessing_ref}) {
        no strict 'refs';
        my $sub = q{reprocess_delimit_} . $repcol;
        $outputs[$cols_ref->{$repcol}] = &$sub (
            repcol      => $repcol,
            cols        => $cols_ref,
            output      => \@outputs,
            data        => $dataref,
        );
    }
    return \@outputs;
}

sub reprocess_delimit_timeslot {
    my %args = @_;
    my $el      = $args{cols}->{$args{repcol}};
    my $datum   = $args{output}->[$el];
    my @coldata = @{$args{data}->{options}{sources}{$args{repcol}}{$datum}};
    return join q{, }, @coldata[0,1];
}

sub reprocess_delimit_instructor {
    my %args = @_;
    my $el      = $args{cols}->{$args{repcol}};
    my $datum   = $args{output}->[$el];
    my @coldata = @{$args{data}->{options}{sources}{$args{repcol}}{$datum}};
    return join q{, }, @coldata[0,1];
}

sub reprocess_delimit_ward_department {
    my %args = @_;
    my $el      = $args{cols}->{$args{repcol}};
    my $datum   = $args{output}->[$el];
    $datum ? return ${$args{data}}{options}{sources}{$args{repcol}}{$datum}[0] 
           : return q{};
}

sub reprocess_delimit_room {
    my %args = @_;
    my $el      = $args{cols}->{$args{repcol}};
    my $datum   = $args{output}->[$el];
    my @coldata = @{$args{data}->{options}{sources}{$args{repcol}}{$datum}};
    return 'Mall ' .  @coldata[0,1] .  q{, Room } . $datum;
}

1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Sample::Schedule

=head1 VERSION

This document refers to version 1.03 of Data::Presenter::Sample::Schedule, released February 10, 2008. 

=head1 SYNOPSIS

Create a Data::Presenter::Sample::Schedule object.  The first argument passed to the constructor for this object is a reference to an anonymous hash which has been created outside of Data::Presenter for heuristic purposes only.  For illustrative purposes, this variable is contained in a separate file which is C<require>d into the script.

    use Data::Presenter;
    use Data::Presenter::Sample::Schedule;
	our ($ms);
	my $hashfile = 'reprocessible.txt';
	require $hashfile;

Then do the usual preparation for a Data::Presenter::[subclass] object.

    our @fields = ();
    our %parameters = ();
    our $index = '';
    my ($fieldsfile, $count, $outputfile, $title, $separator);
    my @columns_selected = ();
    my $sorted_data = '';
    my @objects = ();
    my ($column, $relation);
    my @choices = ();

    $fieldsfile = 'fields_schedule.data';
    do $fieldsfile;

Finally, create a Data::Presenter::Sample::Schedule object, passing the hash reference as the first argument.

    my $dp = Data::Presenter::Sample::Schedule->new(
                 $ms, \@fields, \%parameters, $index);

To use sorting, selecting and output methods on a Data::Presenter::Sample::Schedule object, please consult the Data::Presenter documentation.

=head1 DESCRIPTION

This package is a subclass of Data::Presenter intended to illustrate how certain Data::Presenter methods provide additional functionality.  These subroutines include:

=over 4

=item *

C<&writeformat_with_reprocessing>

=item *

C<&writeformat_deluxe>

=item *

C<&writedelimited_with_reprocessing>

=item *

C<&writedelimited_deluxe>

=back

To learn how to use Data::Presenter::Sample::Schedule, please first consult the Data::Presenter documentation.

=head1 INTERNAL FEATURES

=head2 The Data::Presenter::Sample::Schedule Object

Unlike some other Data::Presenter::[package1] subclasses (I<e.g.,> Data::Presenter::Census), the source of the data processed by Data::Presenter::Sample::Schedule is not a database report coming from a legacy database system through a filehandle.  Rather, it is a hash of arrays representing the current state of an object at a particular point in a script (suitably modified to carry Data::Presenter metadata).  The hash of arrays used for illustrative purposes in this distribution was generated by the author from a module, Mall::Schedule, which is not part of the Data::Presenter distribution.  Mall::Schedule schedules therapeutic treatment groups into particular rooms and time slots and with particular instructors.  The time slots and instructors are identified in the underlying database by unique IDs, but it is often preferable to have more human-readable strings appear in output rather than these IDs.  The IDs need to be 'reprocessed' into more readable strings.  This is the task solved by Data::Presenter::Sample::Schedule.  Since we are not here concerned with the creation of a Mall::Schedule object, all we need is the anonymous hash blessed into that object and the reprocessing methods.

=head2 Data::Presenter::Sample::Schedule Internal Subroutines

Like all Data::Presenter::[package1] classes, Data::Presenter::Sample::Schedule necessarily contains two subroutines:

=over 4

=item *

C<&_init>:  Initializes the Data::Presenter::Sample::Schedule object by processing data contained in the Mall::Sample::Schedule object and returning a reference to a hash which is then further processed and blessed by the Data::Presenter constructor.

=item *

C<&_extract_rows>:  Customizes the operation of C<&Data::Presenter::select_rows> to the data found in the C<Data::Presenter::Sample::Schedule> object.

=back

Like many Data::Presenter::[package1] classes, Data::Presenter::Sample::Schedule offers the possibility of using C<&Data::Presenter::writeformat_with_reprocessing> and C<&Data::Presenter::writeformat_deluxe>.  As such Data::Presenter::Sample::Schedule defines the following additional internal subroutines:

=over 4

=item *

C<&_reprocessor>:  Customizes the operation of C<&Data::Presenter::writeformat_with_reprocessing> to the data found in the C<Data::Presenter::Sample::Schedule> object.

=item *

C<&reprocess_timeslot>:  Takes a timeslot code (as found in C<@{$ms{'options'}{'sources'}{'timeslot'}>) and substitutes for it a string containing the day of the week and the starting time.

=item *

C<&reprocess_instructor>:  Takes an instructor's unique ID (as found in C<@{$ms{'options'}{'sources'}{'instructor'}}>) and substitutes for it a string containing the instructor's last name and first name.

=item *

C<&reprocess_room>:  Takes a room number (as found in C<@{$ms{'options'}{'sources'}{'room'}}>) and substitutes for it a string containing mall number and the room number.

=item *

C<&reprocess_discipline>:  Takes the code number for a discipline (as found in C<@{$ms{'options'}{'sources'}{'discipline'}}>) and substitutes for it a string containing name of the discipline.

=item *

C<&reprocess_ward_department>:  Takes the code number for a ward or department (as found in C<@{$ms{'options'}{'sources'}{'ward_department'}}>) and substitutes for it a string containing name of the ward or department.

=back

In addition, Data::Presenter::Sample::Schedule now offers the possibility of using C<&Data::Presenter::writedelimit_with_reprocessing>.  As such Data::Presenter::Sample::Schedule defines the following additional internal subroutines:

=over 4

=item *

C<&_reprocessor_delimit>: Customizes the operation of C<&Data::Presenter::writedelimit_with_reprocessing> to the data found in the C<Data::Presenter::Sample::Schedule> object.

=item *

C<&reprocess_delimit_instructor>:  Takes an instructor's unique ID (as found in C<@{$ms{'options'}{'sources'}{'instructor'}}>) and substitutes for it a string containing the instructor's last name and first name.

=item *

C<&reprocess_delimit_timeslot>:  Takes a timeslot code (as found in C<@{$ms{'options'}{'sources'}{'timeslot'}}>) and substitutes for it a string containing the day of the week and the starting time.

=item *

C<&reprocess_delimit_room>:  Takes a room number (as found in C<@{$ms{'options'}{'sources'}{'room'}}>) and substitutes for it a string containing mall number and the room number.

=back

=head1 PREREQUISITES

None.

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


