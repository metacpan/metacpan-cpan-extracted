#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::Minimal qw(:preload);

my $do_tests = [1..4];

my $test_subs = {
     1 => { -code => \&test_x_www,          -desc => 'preload decode application/x-www-form-urlencoded   ' },
     2 => { -code => \&test_sgml_form,      -desc => 'preload decode application/sgml-form-urlencoded    ' },
     3 => { -code => \&test_multipart_form, -desc => 'preload decode multipart/form-data                 ' },
     4 => { -code => \&test_truncation,     -desc => 'preload detect form truncation                     ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################

######################################################
# Test SGML form decoding                            #
######################################################

sub test_sgml_form {
    $ENV{'QUERY_STRING'}      = 'hello=testing;hello2=SGML+encoded+FORM;submit+button=submit';
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    CGI::Minimal::reset_globals;

    my $cgi = CGI::Minimal->new;

    my $string_pairs = { 'hello' => 'testing',
                        'hello2' => 'SGML encoded FORM',
                 'submit button' => 'submit',
    };
    my @form_keys   = keys %$string_pairs;
    my @param_keys  = $cgi->param;
    if ($#form_keys != $#param_keys) {
        return 'failed : Expected 3 parameters SGML form, found ' . ($#param_keys + 1);
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

######################################################
# Test simple form decoding                          #
######################################################

sub test_x_www {
    $ENV{'QUERY_STRING'}      = 'hello=testing&hello2=standard+encoded+FORM&submit+button=submit';
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

######################################################
# Test multiparm form decoding                       #
######################################################

sub test_multipart_form {
    my ($mode) = @_;
    $mode = '' unless (defined $mode);
    local $^W;

    my $basic_boundary = 'lkjsdlkjsd';
    my @boundaries_list = ();
    my $boundary_test_code = {};
    for (my $count = 0; $count < 128; $count ++) {
        next if ((10 == $count) or (13 == $count) or (26 == $count)); # Skip CR, LF and EOF (Ctrl-Z) characters for testing
        my $test_boundary = chr($count) . $basic_boundary;
        push (@boundaries_list,$test_boundary); 
        $boundary_test_code->{$test_boundary} = $count;
    }

    foreach my $boundary (@boundaries_list) {
        my $data = multipart_data($boundary);

        $ENV{'CONTENT_LENGTH'}    = length($data);
        if ($mode eq 'truncate') { $ENV{'CONTENT_LENGTH'}  = length($data) + 1; }
        $ENV{'CONTENT_TYPE'}      = "multipart/form-data; boundary=---------------------------$boundary";
        $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
        $ENV{'REQUEST_METHOD'}    = 'POST';

        my $test_file = "test-data.$$.data";
        open (TESTFILE,">$test_file") || return ("failed : could not open test file $test_file for writing: $!");
        binmode (TESTFILE);
        print TESTFILE $data;
        close (TESTFILE);
      
        # "Bad evil naughty Zoot"
        CGI::Minimal::reset_globals;
        open (STDIN,$test_file) || return ("failed : could not open test file $test_file for reading: $!");
        my $cgi = CGI::Minimal->new;
        close (STDIN);
        unlink $test_file;
   
        if ($mode eq 'truncate') {
            unless ($cgi->truncated) { return 'failed: did not detect truncated form'; }
        } else {
            if ($cgi->truncated) { return "failed: form falsely appeared truncated for boundary char " . $boundary_test_code->{$boundary}; }
        }
        my $string_pairs = { 'hello' => 'testing',
                            'hello2' => 'testing2',
                     'submit button' => 'submit',
        };
        my @form_keys   = keys %$string_pairs;
        my @param_keys  = $cgi->param;
        if ($#form_keys != $#param_keys) {
            return 'failed : Expected 3 parameters in multipart form, found '
                        . ($#param_keys + 1)
                        . ". testing codepoint " . $boundary_test_code->{$boundary}
                        . " "
                        . " for boundary $boundary $data";
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
        
    }

    # Success is an empty string (no error message ;) )
    return '';
}

######################################################
# tests for detection of truncated forms             #
######################################################

sub test_truncation { test_multipart_form('truncate'); }

######################################################
# multipart test data                                #
######################################################

sub multipart_data {
    my ($boundary) = @_;
    
    my $data =<<"EOD";
-----------------------------$boundary
Content-Disposition: form-data; name="hello"

testing
-----------------------------$boundary
Content-Disposition: form-data; name="hello2"

testing2
-----------------------------$boundary
Content-Disposition: form-data; name="submit button"

submit
-----------------------------$boundary--
EOD
    $data =~ s/\012/\015\012/gs;
    return $data;
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

