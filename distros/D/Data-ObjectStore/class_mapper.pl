#!/usr/bin/perl
use strict;
use warnings;
no warnings 'recursion';

use Data::ObjectStore;

my( %class2fields, %class2count, %seen );

#
# Add this to the database tool. Maybe make the database
# tool use the same remote interface that everything might.
#
# Add the reference check in Data::RecordStore
#

# examines non-vanilla objects in the store
sub examine {
    my $item = shift;
    return if $seen{$item}++;
    my $cls = ref( $item );
#    print STDERR ">>$cls $item\n";
    my $iscls = !( $cls =~ /^(ARRAY|HASH|Data::ObjectStore::Container|)$/ );
    if( $iscls ) {
        $class2count{$cls}++;
    }
    if( $cls eq 'ARRAY' ) {
        for my $val (@$item) {
            if( ref( $val ) && !$seen{$val} ) {
                examine( $val );
            }
        }
    } elsif( $cls eq 'HASH' ) {
        my $fields = [keys %$item];
        for my $field (@$fields) {
            my $val = $item->{ $field };
            if( ref( $val )  && !$seen{$val} ) {
                examine( $val );
            }
        }
    }
    else {
        my $fields = $item->fields;
        for my $field (@$fields) {
            if( $iscls ) {
                $class2fields{$cls}{$field}++;
            }
            my $val = $item->get( $field );
            if( ref( $val ) && !$seen{$val} ) {
                examine( $val );
            }
        }
    }
}

my $store = Data::ObjectStore->open_store( @ARGV );

examine( $store->load_root_container );

for my $cls (sort { $class2count{$b} <=> $class2count{$a} } keys %class2count ) {
    my $flds = $class2fields{$cls};
    my( @flds ) = sort { $flds->{$b} <=> $flds->{$a} } keys %$flds;
    print "$cls : ( $class2count{$cls} instances )\n";
    if( @flds == 0 ) {
        print "\tNo Fields\n";
    }
    for my $fld ( @flds ) {
        print "\t$fld $flds->{$fld}\n";
    }
    print "\n";
}

