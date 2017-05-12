#!/usr/bin/env perl -w

# Creation date: 2004-01-31 21:13:11
# Authors: Don
# Change log:
# $Id: 01conf.t,v 1.1 2004/02/01 09:43:42 don Exp $

use strict;

# main
{
    use Test;
    BEGIN { plan tests => 5 }

    use lib '/owens_lib';
    use Class::Config;
    my $conf = Class::Config->new;

    # create temporary conf files and load them
    my $file1 = &get_unique_file_path();
    my $file2 = &get_unique_file_path();

    my $str1 = q{field1 => 'val1', field2 => 'val2', field3 => 'val3'};
    my $str2 = q{field2 => 'val2_2', field4 => 'val4', };
    $str2 .= q{field4_int => '[[say_hello]]', sub_check => 'sub_ref', };
    $str2 .= q{single_sub => 'single_sub_val'};

    &setup_file($file1, $str1);
    &setup_file($file2, $str2);
    
    my @files = ($file1, $file2);
    my $obj = $conf->load(\@files, undef, [ [ __PACKAGE__, 'interpolate_meth' ],
                                            [ \&sub_ref, 'is_subref' ],
                                            \&single_sub,
                                          ]);

    my $field1 = $obj->getField1;
    my $field2 = $obj->getField2;
    my $field3 = $obj->getField3;
    my $field4 = $obj->getField4;
    my $field4_int = $obj->getField4Int;
    my $sub_check = $obj->getSubCheck;
    my $single_sub = $obj->getSingleSub;

#     print "Got field1='$field1', field2='$field2', field3='$field3', field4='$field4'\n";
#     print "field4_int='$field4_int'\n";
#     print "sub_check='$sub_check'\n";
#     print "single_sub='$single_sub'\n";

    
    # can get values
    ok($field1 eq 'val1' and $field3 eq 'val3');
    
    # override inherited val
    ok($field2 eq 'val2_2' and $field4 eq 'val4');
    
    # filters
    
    # simple
    ok($field4_int eq 'interpolated_say_hello');
    # code reference with args
    ok($sub_check eq 'sub_ref_got_it_is_subref');
    # simple code reference
    ok($single_sub eq 'single_sub_val_got_single_sub');
    
    unlink $file1;
    unlink $file2;
}

exit 0;

###############################################################################
# Subroutines

sub single_sub {
    my ($val) = @_;

    if ($val eq 'single_sub_val') {
        $val .= '_got_single_sub';
    }

    return $val;
}

sub sub_ref {
    my ($val, $arg1) = @_;
    if ($val eq 'sub_ref') {
        $val .= "_got_it_$arg1";
    }

    return $val;
}

sub say_hello {
    return "say_hello";
}

sub interpolate_meth {
    my ($self, $value) = @_;
    
    if (ref($value) eq '') {
        $value =~ s/\[\[(\S+)\]\]/'interpolated_' . $self->$1()/eg;
    }
    
    return $value;
}

sub setup_file {
    my ($file, $str) = @_;

    local(*OUT);
    open(OUT, ">$file");
    print OUT '$info = {', "\n";
    print OUT $str, "\n};\n";
    print OUT "1;\n";
    close OUT;
}

sub get_unique_file_path {
    my $dir = '/tmp';

    my $name = '___' . $$ . '_' . time() . int(1000 + rand(9000)) . '.pm';
    my $path = "$dir/$name";
    while (-e $path) {
        sleep 1;
        $name = '___' . $$ . '_' . time() . int(1000 + rand(9000)) . '.pm';
        $path = "$dir/$name";
    }

    return $path;
}
