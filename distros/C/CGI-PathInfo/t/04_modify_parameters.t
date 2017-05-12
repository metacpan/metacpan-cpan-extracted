#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::PathInfo;

my $do_tests = [1..1];

my $test_subs = {
     1 => { -code => \&test_param_mod,           -desc => 'set standard parameter values   ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################

######################################################
# Test changing parameter values                     #
######################################################

sub test_param_mod {
    $ENV{'PATH_INFO'}      = 'hello-testing/hello2-SGML+encoded+FORM/submit+button-submit';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 

    my $cgi = CGI::PathInfo->new;

    my $string_pairs = { 'hello' => 'testing',
                        'hello2' => 'SGML encoded FORM',
                 'submit button' => 'submit',
    };
    my @form_keys   = keys %$string_pairs;
    my @param_keys  = $cgi->param;
    if ($#form_keys != $#param_keys) {
        return 'failed : Expected 3 parameters, found ' . ($#param_keys + 1);
    }

    {
        $string_pairs->{'hello'} = 'changed';
        $cgi->param('hello' => 'changed');
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
    }

    {
        $string_pairs->{'hello'} = 'changed2';
        $cgi->param({'hello' => 'changed2'});
        my %form_keys_hash = map {$_ => $string_pairs->{$_} } @form_keys;
        foreach my $key_item (@param_keys) {
            if (! defined $form_keys_hash{$key_item}) {
                return 'failed : Parameter names did not match after anon hash form change';
            }
            my $item_value = $cgi->param($key_item);
            if ($form_keys_hash{$key_item} ne $item_value) {
                return 'failed : Parameter values did not match';
            }
        }
    }

    # Multivalue parameters 
    eval {
        $cgi->param('a' => ['b','c']);
    }; 
    if ($@) {
        return 'failed: Attempt to set multivalue parameters failed';
    } 
    
    # Bad parameter mods
    eval {
        $cgi->param('a','b','c'); # Odd number of parameters is bad 
    }; 
    if (not $@) {
        return 'failed: Attempt to mis-set parameters not caught';
    } 
    
    # Bad parameter types
    eval {
        $cgi->param('a' => { 'a' => 'b' }); # only arrays and scalars allowed
    }; 
    if (not $@) {
        return 'failed: Attempt to set parameters with bad value not caught';
    } 
    
    
    # Success is an empty string (no error message ;) )
    return '';
}

######################################################
# Test parameter deletion                            #
######################################################

sub test_delete_parms {
    $ENV{'PATH_INFO'}      = 'hello-testing/hello2-standard+encoded+FORM/submit+button-submit';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 

    my $cgi = CGI::PathInfo->new;

    my $string_pairs = { 'hello' => 'testing',
                        'hello2' => 'standard encoded FORM',
                 'submit button' => 'submit',
    };
    my @form_keys   = keys %$string_pairs;
    my @param_keys  = $cgi->param;
    if ($#form_keys != $#param_keys) {
        return 'failed : Expected 3 parameters in x-www-form-urlencoded, found ' . ($#param_keys + 1);
    }

    delete $string_pairs->{'hello'};
    delete $string_pairs->{'hello2'};
    $cgi->delete('hello', 'hello2');
    @param_keys  = $cgi->param;
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
        

    $cgi->delete_all;
    my @parms = $cgi->param;
    unless (0 == @parms) {
        return 'failed : delete_all failed to remove all parameters';
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

