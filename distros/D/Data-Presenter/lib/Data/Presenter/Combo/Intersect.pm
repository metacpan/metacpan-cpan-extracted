package Data::Presenter::Combo::Intersect;
#$Id: Intersect.pm 1218 2008-02-10 00:11:59Z jimk $
$VERSION = 1.03; # 02-10-2008
@ISA = qw(Data::Presenter::Combo);
use strict;
use warnings;
use Data::Dumper;

our %reserved_partial = (
    'fields'   => 1,
    'index'    => 1,
    'options'  => 1,
);

sub _merge_engine {
    my ($self, $mergeref) = @_;

    my %base                = %{${$mergeref}{base}};
    my %sec                 = %{${$mergeref}{secondary}};
    my %newbase             = %{${$mergeref}{newbase}};
    my %secneeded           = %{${$mergeref}{secfieldsneeded}};
    
    my %seenboth = ();

    # Work thru the entries in the base ...
    foreach my $i (keys %base) {
        # reserved entry qw| parameters | gets built here without any fuss
        # reserved entries qw| fields index options | get built in Combo.pm
        unless ($reserved_partial{$i}) {
            # and build up a look-up table %seenboth where each key is an entry
            # in the base found in BOTH base and sec 
            # i.e., the intersection of base and sec
            foreach my $j (keys %sec) {
                if ($i eq $j) {
                    $seenboth{$i} = 1;
                    last;
                }
            }
        }
    }
    
    # Work thru the look-up table ...
    my $null = q{};
    foreach my $rec (keys %seenboth) {
        my (@basevalues, @secvalues);
        # 1.  Assign the values encountered first in base
        my @record = @{$base{$rec}};
        for (my $q=0; $q < scalar(@record); $q++) {
            $basevalues[$q] = $record[$q];
        }
        # 2.  Assign the values encountered first in sec
        # (%secneeded's keys are numbers:  field's subscripts in sec
        foreach my $i (sort {$a <=> $b} keys %secneeded) {
            push @secvalues, $sec{$rec}[$i];
        }
        $newbase{$rec} = [@basevalues, @secvalues];
    }
    return \%newbase;
    # Note:  This is actually newbase less the 'fields' and 'index' entries
}
            
1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Combo::Intersect

=head1 VERSION

This document refers to version 1.03 of Data::Presenter::Combo::Intersect, released February 10, 2008. 

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter::Combo.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo::Intersect.

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

