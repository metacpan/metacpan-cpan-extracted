#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');

BEGIN {
    $ENV{'MOD_PERL'} = 'mod_perl/1.29';
    $INC{'Apache.pm'} = 'inline-fake-apache';
}

use CGI::Minimal;

my $do_tests = [1..5];

my $test_subs = {
     1 => { -code => \&test_no_params,        -desc => 'no parameters                              ' },
     2 => { -code => \&test_x_www,            -desc => 'decode application/x-www-form-urlencoded   ' },
     3 => { -code => \&test_sgml_form,        -desc => 'decode application/sgml-form-urlencoded    ' },
     4 => { -code => \&test_repeated_params,  -desc => 'decode repeated parameter options          ' },
     5 => { -code => \&test_raw_buffer,       -desc => 'raw buffer                                 ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################


##############################################################
# Test raw buffer handling                                   #
##############################################################

sub test_raw_buffer {

    $ENV{'QUERY_STRING'}      = 'hello=first;hello=second;hello=third;hello=fourth';
    Apache->args($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    ############################
    # raw buffer tests
    {
        CGI::Minimal::reset_globals;
        my $raw_buffer = CGI::Minimal::raw();
        if (defined $raw_buffer) {
            return 'failed: reset globals failed to reset raw buffer';
        }
        my $cgi     = CGI::Minimal->new;
        $raw_buffer = CGI::Minimal::raw();
        unless (defined $raw_buffer) {
            return 'failed: raw buffer was undefined when it should not have been'
        }
   
    }
    # Success is an empty string (no error message ;) )
    return '';
}

##############################################################
# Test decoding of forms with no parameters                  #
##############################################################

sub test_no_params {

    ###########################
    # no parameters
    $ENV{'QUERY_STRING'}      = '';
    Apache->args($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    {
        CGI::Minimal::reset_globals;

        my $cgi = CGI::Minimal->new;

        my @params = $cgi->param;
        if (0 != @params) {
            return 'failed: Unexpected param keys found: ' . join(',',@params);
        }
    }
    # Success is an empty string (no error message ;) )
    return '';
}

##############################################################
# Test decoding of forms with multiple values for parameters #
##############################################################

sub test_repeated_params {

    ###########################
    # repeated parameter names
    $ENV{'QUERY_STRING'}      = 'hello=first;hello=second;hello=third;hello=fourth';
    Apache->args($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    {
        CGI::Minimal::_reset_globals;
        my $cgi1 = CGI::Minimal->new;
        my $cgi  = CGI::Minimal->new; # Second time around ;)
    
        my $string_pairs = { 'hello' => ['first', 'second', 'third', 'fourth'], };
        my @form_keys   = keys %$string_pairs;
        my @param_keys  = $cgi->param;
        if ($#form_keys != $#param_keys) {
            return 'failed : Expected 1 parameter name from SGML form, found ' . ($#param_keys + 1);
        }
    
        my %form_keys_hash = map {$_ => $string_pairs->{$_} } @form_keys;
        foreach my $key_item (@param_keys) {
            if (! defined $form_keys_hash{$key_item}) {
                return 'failed : Parameter names did not match';
            }
            my @item_values      = $cgi->param($key_item);
            my $n_found_items    = $#item_values + 1;
            my @expected_items   = @{$form_keys_hash{$key_item}};
            my $n_expected_items = $#expected_items + 1;
            if ($n_found_items != $n_expected_items) {
                return 'failed: Expected $n_expected_items parameter values, found $n_found_items';
            }
    
            for (my $count = 0; $count < $n_expected_items; $count++) {
                unless ($item_values[$count] eq $expected_items[$count]) {
                    return 'failed: Parameter lists mis-match (' . join(',',@item_values) . ') != (' . join(',',@expected_items) . ')';
                }
            }
            my $first_element = $cgi->param($key_item);
            unless ($first_element eq $expected_items[0]) {
                return 'failed: multiple item param failed to return first element in scalar context';
            }
        }
    }

    # Success is an empty string (no error message ;) )
    return '';
}

######################################################
# Test SGML form decoding                            #
######################################################

sub test_sgml_form {
    $ENV{'QUERY_STRING'}      = 'hello=testing;hello2=SGML+encoded+FORM;nullparm=;=nullkey;submit+button=submit';
    Apache->args($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    CGI::Minimal::reset_globals;

    my $cgi = CGI::Minimal->new;

    my $string_pairs = { 'hello'         => 'testing',
                         'hello2'        => 'SGML encoded FORM',
                         'nullparm'      => '',
                         ''              => 'nullkey',
                         'submit button' => 'submit',
    };
    my @form_keys   = keys %$string_pairs;
    my @param_keys  = $cgi->param;
    if ($#form_keys != $#param_keys) {
        my $n_expected_parms = $#form_keys + 1;
        return "failed : Expected $n_expected_parms parameters SGML form, found " . ($#param_keys + 1);
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
    # Unused parameter
    my $value = $cgi->param('no-such-parameter');
    if (defined $value) {
        return "failed: Got a value besides 'undef' for an undeclared parameter query";
    }

    # Success is an empty string (no error message ;) )
    return '';
}

######################################################
# Test simple form decoding                          #
######################################################

sub test_x_www {
    $ENV{'QUERY_STRING'}      = 'hello=testing&hello2=standard+encoded+FORM&submit+button=submit';
    Apache->args($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/x-www-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    CGI::Minimal::reset_globals;

    my $cgi = CGI::Minimal->new;

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
##########################################################################################
##########################################################################################
##########################################################################################
#
# Fake 'Apache' module to let us test the MOD_PERL support
#
package Apache;

use vars qw ($ARGS);
BEGIN {
    $ARGS = '';
}

sub request {
    my $proto = shift;
    my $package = __PACKAGE__;
    my $class = ref($proto) || $proto || $package;
    my $self  = bless {}, $class;
    return $self;
}

sub register_cleanup {

}

sub args {
    my $self = shift;

    if (@_ > 0) {
        my ($args) = @_;
        $ARGS = $args;
    } else {
        return $ARGS;
    }
}

1;
