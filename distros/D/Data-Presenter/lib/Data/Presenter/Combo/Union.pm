package Data::Presenter::Combo::Union;
#$Id: Union.pm 1218 2008-02-10 00:11:59Z jimk $
$VERSION = 1.03; # 02-10-2008
@ISA = qw(Data::Presenter::Combo);
use strict;
use warnings;
use Data::Dumper;

our %reserved_partial = (
    'fields'    => 1,
    'index'     => 1,
    'options'   => 1,
);

sub _merge_engine {
    my ($self, $mergeref) = @_;

    my %base                = %{${$mergeref}{base}};
    my %sec                 = %{${$mergeref}{secondary}};
    my %newbase             = %{${$mergeref}{newbase}};
    my %secneeded           = %{${$mergeref}{secfieldsneeded}};
    my %sharedfields        = %{${$mergeref}{sharedfields}};
    
    my @basefields  = @{$base{'fields'}};
    my %seen = ();

    # Build 2 look-up tables showing records found in base and sec
    my %seenbase = _build_lookup_table(\%base);
    my %seensec  = _build_lookup_table(\%sec);

    # Build 3 look-up tables showing whether fields were found in 
    # base only, sec only, or both
    # (At a future date, consider replacing with List::Compare methods)
    my %seenbaseonly = ();
    my %seenseconly = ();
    my %seenboth = ();
    foreach my $rec (keys %seenbase) {
        if (defined $seensec{$rec}) {
            $seenboth{$rec} = 1;
        } else {
            $seenbaseonly{$rec} = 1;
        }
    }
    foreach my $rec (keys %seensec) {
        $seenseconly{$rec} = 1 
            unless ($seenboth{$rec});
    }

    # Work thru the 3 look-up tables to assign values
    my $null = q{};
    foreach my $rec (keys %seenbaseonly) {
        my @values = _process_base(\%base, $rec);
       
        # If an individual record was only found in the base, then, by
        # definition, its 'entries' in the sec are all 'null'.
        # We only need to assign as many nulls as there are keys in
        # %secneeded.
        for (my $p=0; $p < scalar(keys %secneeded); $p++) {
            push(@values, $null);
        }
        $newbase{$rec} = [@values];
    }
    foreach my $rec (keys %seenseconly) {
        my @values;
        for (my $q=0; $q < scalar(@basefields); $q++) {
            my $bf = $basefields[$q];
            if ($sharedfields{$bf}) {
                $values[$q] = $sec{$rec}->[$sharedfields{$bf}[1]];
            } else {
                $values[$q] = $null;
            }
        }
        @values = _process_secneeded(\%secneeded, \%sec, $rec, \@values);
        $newbase{$rec} = [@values];
    }
    foreach my $rec (keys %seenboth) {
        # If a field is seen in both base and sec, we follow a rule that says
        # the base-value for that field gets assigned to the union -- not the
        # sec-value.
        my @values = _process_base(\%base, $rec);
        @values    = _process_secneeded(\%secneeded, \%sec, $rec, \@values);
        $newbase{$rec} = [@values];
    }
    return \%newbase;
}

sub _build_lookup_table {
    my $dataref = shift;
    my %lookup;
    foreach my $rec (keys %{$dataref}) {
        $lookup{$rec} = 1 unless ($reserved_partial{$rec}); # see package lexical above
    }
    return %lookup;
}

sub _process_base {
    my ($baseref, $rec) = @_;
    my @record = @{${$baseref}{$rec}};
    my @values;
    for (my $q=0; $q < scalar(@record); $q++) {
        $values[$q] = $record[$q];
    }
    return @values;
}

sub _process_secneeded {
    my ($secneededref, $secref, $rec, $valuesref) = @_;
    foreach my $r (sort {$a <=> $b} keys %{$secneededref}) {
        my $s = ${$secref}{$rec}->[$r];
        push(@{$valuesref}, $s);
    }
    return @{$valuesref};
}

1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Combo::Union

=head1 VERSION

This document refers to version 1.03 of Data::Presenter::Combo::Union, released February 10, 2008. 

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter::Combo.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo::Union.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 28, 2001.  Last modification date:  February 10, 2008.
Copyright (c) 2001-5 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the 
archive accompanying this documentation are dummy copy.  The data was 
entirely fabricated by the author for heuristic purposes.  Any resemblance 
to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as 
Perl itself.

=cut 

