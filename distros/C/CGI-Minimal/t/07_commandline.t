#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::Minimal;

my $do_tests = [1..1];

my $test_subs = {
     1 => { -code => \&test_x_www,  -desc => 'decode from command line                   ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################

########################################################
# Test simple form decoding via command line interface #
########################################################

sub test_x_www {

    local  $^W;

    # "Bad evil naughty Zoot"

    my $test_file = "test-data.$$.data";
    my $data      = 'hello=testing&hello2=standard+encoded+FORM&submit+button=submit';

    open (TESTFILE,">$test_file") || return ("failed : could not open test file $test_file for writing: $!");
    binmode (TESTFILE);
    print TESTFILE $data;
    close (TESTFILE);

    CGI::Minimal::reset_globals;
    open (STDIN,$test_file) || return ("failed : could not open test file $test_file for reading: $!");
    my $cgi = CGI::Minimal->new;
    close (STDIN);
    unlink $test_file;

    my $string_pairs = { 'hello' => 'testing',
                        'hello2' => 'standard encoded FORM',
                 'submit button' => 'submit',
    };
    my @form_keys   = keys %$string_pairs;
    my @param_keys  = $cgi->param;
    if ($#form_keys != $#param_keys) {
        return 'failed : Expected 3 parameters in x-www-form-urlencoded, found ' . ($#param_keys + 1);
    }

    my %form_keys_hash = map {$_ => $string_pairs->{$_} } @form_keys;
    foreach my $key_item (@param_keys) {
        if (! defined $form_keys_hash{$key_item}) {
            return 'failed : Parameter names did not match';
        }
        my $item_value = $cgi->param($key_item);
        if ($form_keys_hash{$key_item} ne $item_value) {
            return 'failed : Parameter values did not match';
        }
    }
        

    # Success is an empty string (no error message ;) )
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

