#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use CGI::Minimal;

my $do_tests = [1..2];

my $test_subs = {
  1 => { -code => \&test_calling_parms_table, -desc => 'generate calling parms table               ' },
  2 => { -code => \&test_rfc1123_date,        -desc => 'generate RFC 1123 date                     ' },
};

run_tests($test_subs,$do_tests);

exit;

###########################################################################################

sub reset_form {
    $ENV{'QUERY_STRING'}      = 'hello=testing;hello2=SGML+encoded+FORM;submit+button=submit';
    $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
    $ENV{'CONTENT_TYPE'}      = 'application/sgml-form-urlencoded';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
    $ENV{'REQUEST_METHOD'}    = 'GET';
    CGI::Minimal::reset_globals;
}

###########################################################################################

sub test_calling_parms_table {
    my $calling_parms_table = eval {
        reset_form();
        $ENV{'QUERY_STRING'} = '';
        $ENV{'CONTENT_LENGTH'}    = length($ENV{'QUERY_STRING'});
        my $cgi = CGI::Minimal->new;
        return $cgi->calling_parms_table;
    };
    if ($@) {
        return "unexpected failure $@";
    }
    if ($calling_parms_table eq '') { return 'failed to generate calling parms table with no parms for decoding'; };

    $calling_parms_table = eval {
        reset_form();
        my $cgi = CGI::Minimal->new;
        return $cgi->calling_parms_table;
    };
    if ($@) {
        return "unexpected failure $@";
    }
    if ($calling_parms_table eq '') { return 'failed to generate calling parms table'; };
    
    $calling_parms_table = eval {
        reset_form();
        my $cgi = generate_and_read_multipart_form();;
        return $cgi->calling_parms_table;
    };
    if ($@) {
        return "unexpected failure $@";
    }
    if ($calling_parms_table eq '') { return 'failed to generate calling parms table for multipart form'; };

    return '';
}

###########################################################################################

sub test_rfc1123_date {
    my $rfc_date = eval {
        reset_form();
        return CGI::Minimal->date_rfc1123(0);
    };
    if ($@) {
        return "unexpected failure $@";
    }
    unless ($rfc_date eq 'Thu, 01 Jan 1970 00:00:00 GMT') {
        return "Generated unexpected date of $rfc_date for epoch date '0'";
    }
    return '';
}

###########################################################################################

sub generate_and_read_multipart_form {
    local $^W;

    my $basic_boundary = 'lkjsdlkjsd';

    my $data = multipart_data($basic_boundary);

    $ENV{'CONTENT_LENGTH'}    = length($data);
    $ENV{'CONTENT_TYPE'}      = "multipart/form-data; boundary=---------------------------$basic_boundary";
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
   
    return $cgi;
}

######################################################
# multipart test data                                #
######################################################

sub multipart_data {
    my ($boundary) = @_;
    
    my $data =<<"EOD";
-----------------------------$boundary
Content-Disposition: form-data; name="hello"; filename="hello1.txt"

testing
-----------------------------$boundary
Content-Disposition: form-data; name="hello"; filename="hello1.xml"
Content-Type: application/xml 

<data>also testing</data>
-----------------------------$boundary
Content-Disposition: form-data; name="hello2"; filename="example"
Content-Type: text/html

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

