#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::PathInfo;

my $do_tests = [1..1];

my $test_subs = {
  1 => { -code => \&test_calling_parms_table, -desc => 'generate calling parms table    ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################

sub reset_form {
    $ENV{'PATH_INFO'}      = 'hello-testing/hello2-SGML+encoded+FORM/submit+button-submit';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
}

###########################################################################################

sub test_calling_parms_table {
    my $calling_parms_table = eval {
        reset_form();
        $ENV{'PATH_INFO'} = '';
        my $cgi = CGI::PathInfo->new;
        return $cgi->calling_parms_table;
    };
    if ($@) {
        return "unexpected failure $@";
    }
    if ($calling_parms_table eq '') { return 'failed to generate calling parms table with no parms for decoding'; };

    $calling_parms_table = eval {
        reset_form();
        my $cgi = CGI::PathInfo->new;
        return $cgi->calling_parms_table;
    };
    if ($@) {
        return "unexpected failure $@";
    }
    if ($calling_parms_table eq '') { return 'failed to generate calling parms table'; };
    
    return '';
}

###########################################################################################
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

