#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::PathInfo;

my $do_tests = [1..1];

my $test_subs = {
     1 => { -code => \&test_url_encoding,     -desc => 'url encoding                    ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################
###############################################################
# Test URL encoding/decoding per RFC 2396                     #
# RFC2396 _requires_ escaping all characters                  #
# with the exceptions of a-zA-Z0-9-_.!~*'()                   #
#                                                             #
# It permits 'overencoding' characters, and                   #
# in fact we do encode -_!~*'()                               #
###############################################################

sub test_url_encoding {
    my @encoding_table = ();
    foreach my $character_number(0..255) {
        my $character = chr($character_number);
        $character =~ s/([\000-\377])/"\%".unpack("H",$1).unpack("h",$1)/egs;
        push (@encoding_table, $character);
    }
    
    my @failed_encoding_code_points = ();
    foreach my $character_number (0..255) {
        my $character = chr($character_number);
        my $encoded_form = CGI::PathInfo->url_encode($character);
        if ($character =~ m/[a-zA-Z0-9]/) {
            unless ($encoded_form eq $character) {
                push (@failed_encoding_code_points, chr($character_number));
            }
        } else {
            unless ($encoded_form eq $encoding_table[$character_number]) {
                push (@failed_encoding_code_points, chr($character_number));
            }

        }
        if (0 < @failed_encoding_code_points) {
            return "failed to handle encoding " . join(' ',@failed_encoding_code_points); 
        }
    }

    my @failed_decoding_code_points = ();
    for (my $counter = 0; $counter < 256; $counter++) {
        my $encoded_char = $encoding_table[$counter];
        my $decoded_char = CGI::PathInfo->url_decode($encoded_char);
        unless (chr($counter) eq $decoded_char) {
            push (@failed_decoding_code_points, $encoded_char);
        }
    }
    unless (CGI::PathInfo->url_decode('+') eq '') {
        push (@failed_decoding_code_points, '+');
    }
    if (0 < @failed_encoding_code_points) {
        return "failed to handle decoding " . join(' ',@failed_decoding_code_points); 
    }

    my $null_string = CGI::PathInfo->url_decode;
    unless (defined $null_string) {
        return 'url_decode failed to upgrade an undefined value to an defined string';
    }
    unless ('' eq $null_string) {
        return 'url_decode failed to reify an undefined value as an empty string';
    }

    $null_string = CGI::PathInfo->url_encode;
    unless (defined $null_string) {
        return 'url_encode failed to upgrade an undefined value to an defined string';
    }
    unless ('' eq $null_string) {
        return 'url_encode failed to upgrade an undefined value to an empty string';
    }

    return '';
}

###########################################################################################

sub run_tests {
    my ($test_subs,$do_tests) = @_;

    print @$do_tests[0],'..',@$do_tests[$#$do_tests],"\n";
    print STDERR "\n";
    my $n_failures = 0;
    foreach my $test (@$do_tests) {
        my $sub  = $test_subs->{$test}->{-code};
        my $desc = $test_subs->{$test}->{-desc};
        my $failure = '';
        eval { $failure = &$sub; };
        if ($@) {
            $failure = $@;
        }
        if ($failure ne '') {
            chomp $failure;
            print "not ok $test\n";
            print STDERR "    $desc - $failure\n";
            $n_failures++;
        } else {
            print "ok $test\n";
            print STDERR "    $desc - ok\n";

        }
    }
    
    print "END\n";
}

