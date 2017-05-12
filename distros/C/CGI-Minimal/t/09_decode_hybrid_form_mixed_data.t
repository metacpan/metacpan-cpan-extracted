#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::Minimal;

my $do_tests = [1..8];

my $test_subs = {
     1 => { -code => \&test_x_www,            -desc => 'decode application/x-www-form-urlencoded   ' },
     2 => { -code => \&test_sgml_form,        -desc => 'decode application/sgml-form-urlencoded    ' },
     3 => { -code => \&test_repeated_params,  -desc => 'decode repeated parameter options          ' },
     4 => { -code => \&test_raw_buffer,       -desc => 'raw buffer                                 ' },
     5 => { -code => \&test_no_params,        -desc => 'no parameters                              ' },
     6 => { -code => \&test_truncation,       -desc => 'detect form truncation                     ' },
     7 => { -code => \&test_multipart_form,   -desc => 'decode multipart/form-data                 ' },
     8 => { -code => \&test_post_form,        -desc => 'decode ordinary POST form data             ' },
};
#     3 => { -code => \&test_bad_form,         -desc => 'detect bad calls                           ' },

run_tests($test_subs,$do_tests);

exit;

###########################################################################################


##############################################################
# Test raw buffer handling                                   #
##############################################################

sub test_raw_buffer {

    $ENV{'QUERY_STRING'}      = 'hello=first;hello=second;hello=third;hello=fourth';
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    ############################
    # raw buffer tests
    {
        CGI::Minimal::reset_globals;
        CGI::Minimal::allow_hybrid_post_get(1);
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
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    {
        CGI::Minimal::reset_globals;
        CGI::Minimal::allow_hybrid_post_get(1);

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
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    {
        CGI::Minimal::reset_globals;
        CGI::Minimal::allow_hybrid_post_get(1);
        my $cgi = CGI::Minimal->new;
    
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
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'GET';

    CGI::Minimal::reset_globals;
    CGI::Minimal::allow_hybrid_post_get(1);

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
# Test bad form decoding                             #
######################################################

sub test_bad_form {

    $ENV{'QUERY_STRING'}      = 'hello=testing&hello2=standard+encoded+FORM&submit+button=submit';
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/x-www-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'TRACE';

    eval {
        CGI::Minimal::reset_globals;
        CGI::Minimal::allow_hybrid_post_get(1);
        my $cgi = CGI::Minimal->new;
    };
    unless ($@) {
        return 'failed: Failed to catch unsupported request method';
    }

    # Success is an empty string (no error message ;) )
    return '';
}

######################################################
# Test simple form decoding                          #
######################################################

sub test_x_www {
    $ENV{'QUERY_STRING'}      = 'hello=testing&hello2=standard%20encoded+FORM&hello%31=1&hello3=&&=test&submit+button=submit';
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'CONTENT_TYPE'}      = 'application/x-www-form-urlencoded';

    foreach my $request_method ('GET','HEAD') {
	    $ENV{'REQUEST_METHOD'} = $request_method;
	
	    CGI::Minimal::reset_globals;
        CGI::Minimal::allow_hybrid_post_get(1);
	
	    my $cgi = CGI::Minimal->new;
	
	    my $string_pairs = { 'hello' => 'testing',
	                        'hello2' => 'standard encoded FORM',
	                        'hello3' => '',
                            'hello1' => '1',
                            ''       => 'test',
                            ''       => '',
	                 'submit button' => 'submit',
	    };
	    my @form_keys   = keys %$string_pairs;
        my $expected_keys = $#form_keys + 1;
	    my @param_keys  = $cgi->param;
	    if ($#form_keys != $#param_keys) {
	        return "failed : Expected $expected_keys parameters in x-www-form-urlencoded, found " . ($#param_keys + 1);
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

    {
        local $^W;
        $ENV{'QUERY_STRING'}      = undef;
        $ENV{'CONTENT_LENGTH'}    = 0;
        $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
        $ENV{'CONTENT_TYPE'}      = 'application/x-www-form-urlencoded';
        CGI::Minimal::reset_globals;
        CGI::Minimal::allow_hybrid_post_get(1);
	    my $cgi = CGI::Minimal->new;
        my @parms = $cgi->param;
        if ($#parms > -1) {
            return 'failed: should have been no parms from undef QUERY_STRING - but is was not';
        }
	}

    # Success is an empty string (no error message ;) )
    return '';
}

######################################################
# Test hybrid POST/GET form decoding                 #
######################################################

sub test_post_form {

    local $^W;

    my $data = 'hello2=standard%20encoded+FORM&hello%31=1&hello3=&&=test&submit+button=submit';
    $ENV{'CONTENT_LENGTH'}    = length($data);
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1'; 
    $ENV{'REQUEST_METHOD'}    = 'POST';
    $ENV{'QUERY_STRING'}      = 'hello=testing';

    foreach my $mode ('normal','max_size','zero_size') {
        foreach my $content_type ('application/x-www-form-urlencoded', undef) {
            $ENV{'CONTENT_TYPE'}      = $content_type;
            my $test_file = "test-data.$$.data";
            open (TESTFILE,">$test_file") || return ("failed : could not open test file $test_file for writing: $!");
            binmode (TESTFILE);
            print TESTFILE $data;
            close (TESTFILE);
                
            # "Bad evil naughty Zoot"
            CGI::Minimal::reset_globals;
            CGI::Minimal::allow_hybrid_post_get(1);
            if ($mode eq 'max_size') {
                CGI::Minimal::max_read_size(10);
            } elsif ($mode eq 'zero_size') {
                CGI::Minimal::max_read_size(0);
            }
            open (STDIN,$test_file) || return ("failed : could not open test file $test_file for reading: $!");
            my $cgi = CGI::Minimal->new;
            close (STDIN);
            unlink $test_file;
    
            if (($mode eq 'max_size') or ($mode eq 'zero_size')) {
                unless ($cgi->truncated) {
                    return 'failed: max read size not honored';
                }
                next;
            }
    	    my $string_pairs = { 'hello' => 'testing',
    	                        'hello2' => 'standard encoded FORM',
    	                        'hello3' => '',
                                'hello1' => '1',
                                ''       => 'test',
                                ''       => '',
    	                 'submit button' => 'submit',
    	    };
    	    my @form_keys   = keys %$string_pairs;
            my $expected_keys = $#form_keys + 1;
    	    my @param_keys  = $cgi->param;
    	    if ($#form_keys != $#param_keys) {
    	        return "failed : Expected $expected_keys parameters in x-www-form-urlencoded, found " . ($#param_keys + 1);
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
    }
    return '';
}

######################################################
# Test multiparm hybrid form decoding                #
######################################################

sub test_multipart_form {
    my ($mode) = @_;
    $mode = '' unless (defined $mode);
    local $^W;

    $ENV{'QUERY_STRING'} = 'hello=testing&otherthing=alpha';

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
        CGI::Minimal::allow_hybrid_post_get(1);
        open (STDIN,$test_file) || return ("failed : could not open test file $test_file for reading: $!");
        my $cgi = CGI::Minimal->new;
        close (STDIN);
        unlink $test_file;
   
        if ($mode eq 'truncate') {
            unless ($cgi->truncated) { return 'failed: did not detect truncated form'; }
        } else {
            if ($cgi->truncated) { return "failed: form falsely appeared truncated for boundary char " . $boundary_test_code->{$boundary}; }
        }
        my $string_pairs = { 'hello' => '<data>also testing</data>',
                            'hello2' => 'testing2',
                            'hello3' => '-----------------------------20lkjsdlkjsd',
                     'submit button' => 'submit',
                     'otherthing'    => 'alpha',
        };
        my %mime_types = (
                'hello'         => 'application/xml',
                'hello2'        => 'text/html',
                'hello3'        => 'text/html',
                'submit button' => 'text/plain',
                'otherthing'    => 'text/plain',
        );
        my %filenames = (
                'hello'         => 'hello1.xml',
                'hello2'        => 'example',
                'hello3'        => 'example3',
                'submit button' => '',
                'otherthing'    => '',
        );

        {
            my @form_keys   = keys %$string_pairs;
            my @param_keys  = $cgi->param;
            my $expected_n  = $#form_keys + 1;
            if ($#form_keys != $#param_keys) {
                return "failed : Expected $expected_n parameters in multipart form, found "
                            . ($#param_keys + 1)
                            . ". testing codepoint " . $boundary_test_code->{$boundary}
                            . " "
                            . " for boundary $boundary $data";
            }
        
            my %form_keys_hash  = map {$_ => $string_pairs->{$_} } @form_keys;
            foreach my $key_item (@param_keys) {
                if (! defined $form_keys_hash{$key_item}) {
                    return 'failed : Parameter names did not match';
                }
                my $item_value = $cgi->param($key_item);
                if ($form_keys_hash{$key_item} ne $item_value) {
                    return "failed : Parameter values for '$key_item' did not match (expected '$form_keys_hash{$key_item}', got '$item_value')";
                }
                my $item_mime_type = $cgi->param_mime($key_item);
                unless ($item_mime_type eq $mime_types{$key_item}) {
                    return "failed : Parameter MIME types did not match (expeced '$mime_types{$key_item}', got '$item_mime_type'";
                }
                my $item_filename = $cgi->param_filename($key_item);
                unless ($item_filename eq $filenames{$key_item}) {
                    return 'failed : Parameter filenames did not match';
                }
            }
        }

        {
            my @form_keys   = keys %$string_pairs;
            my @param_keys  = $cgi->param_mime;
            my $n_expected  = $#form_keys + 1;
            if ($#form_keys != $#param_keys) {
                return "failed : Expected $n_expected parameters in mime params for multipart form, found "
                            . ($#param_keys + 1)
                            . ". testing codepoint " . $boundary_test_code->{$boundary}
                            . " "
                            . " for boundary $boundary $data";
            }
        
            my %form_keys_hash  = map {$_ => $string_pairs->{$_} } @form_keys;
            foreach my $key_item (@param_keys) {
                if (! defined $form_keys_hash{$key_item}) {
                    return 'failed : MIME Parameter names did not match';
                }
            }
        }

        {
            my @form_keys   = keys %$string_pairs;
            my @param_keys  = $cgi->param_filename;
            my $n_expected  = $#form_keys + 1;
            if ($#form_keys != $#param_keys) {
                return "failed : Expected $n_expected parameters in filename params for multipart form, found "
                            . ($#param_keys + 1)
                            . ". testing codepoint " . $boundary_test_code->{$boundary}
                            . " "
                            . " for boundary $boundary $data";
            }
        
            my %form_keys_hash  = map {$_ => $string_pairs->{$_} } @form_keys;
            foreach my $key_item (@param_keys) {
                if (! defined $form_keys_hash{$key_item}) {
                    return 'failed : filename Parameter names did not match';
                }
            }
        }

        my @multihello_mimes = $cgi->param_mime('hello');
        if (1 != $#multihello_mimes) {
            return 'failed: unexpected number of parameter MIME types for repeated values';
        }
        my @multihello2_mimes = $cgi->param_mime('hello2');
        if (0 != $#multihello2_mimes) {
            return 'failed: unexpected number of parameter MIME types for single value';
        }
        my @multihello_filenames = $cgi->param_filename('hello');
        if (1 != $#multihello_filenames) {
            return 'failed: unexpected number of parameter filenames for repeated values';
        }
        my @multihello2_filenames = $cgi->param_filename('hello2');
        if (0 != $#multihello2_filenames) {
            return 'failed: unexpected number of parameter filenames for single value';
        }
        eval {
            $cgi->param_mime('one','two');
        };
        unless ($@) {
            return 'failed: failed to catch invalid number of param_mime parameters';
        }

        my @null_parms = $cgi->param_mime('one');
        unless (-1 == $#null_parms) {
            return 'failed: failed to handle undefined mime parameter request correctly in array context';
        }

        my $null_parm = $cgi->param_mime('one');
        if (defined $null_parm) {
            return 'failed: failed to handle undefined mime parameter request correctly in scalar context';
        }

        @null_parms = $cgi->param_filename('one');
        unless (-1 == $#null_parms) {
            return 'failed: failed to handle undefined filename parameter request correctly in array context';
        }
        $null_parm = $cgi->param_filename('one');
        if (defined $null_parm) {
            return 'failed: failed to handle undefined filename parameter request correctly in scalar context';
        }
        eval {
            $cgi->param_filename('one','two');
        };
        unless ($@) {
            return 'failed: failed to catch invalid number of param_filename parameters';
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
Content-Disposition: form-data; name="hello"; filename="hello1.xml"
Content-Type: application/xml

<data>also testing</data>
-----------------------------$boundary
Content-Disposition: form-data; name="hello2"; filename="example"
Content-Type: text/html

testing2
-----------------------------$boundary
Content-Disposition: form-data; name="hello3"; filename="example3"
Content-Type: text/html

-----------------------------20lkjsdlkjsd
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

