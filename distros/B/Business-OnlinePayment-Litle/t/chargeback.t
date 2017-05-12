#!/usr/bin/perl -w

use Test::More qw(no_plan);
use Data::Dumper;
## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my $date = $ENV{'BOP_ACTIVITYDATE'} ? $ENV{'BOP_ACTIVITYDATE'} : '2012-09-13';

my @opts = ('default_Origin' => 'RECURRING');

my $basedir = $0;
$basedir =~ s/[^\/]+$//;

my $str = do { local $/ = undef; <DATA> };
my $data;
eval($str);

my $authed =
    $ENV{BOP_USERNAME}
    && $ENV{BOP_PASSWORD}
    && $ENV{BOP_MERCHANTID};

use_ok 'Business::OnlinePayment';

SKIP: {
    skip "No Auth Supplied", 3 if ! $authed;
    ok( $login, 'Supplied a Login' );
    ok( $password, 'Supplied a Password' );
    like( $merchantid, qr/^\d+/, 'Supplied a MerchantID');
}

my %orig_content = (
    login => $login,
    password => $password,
    merchantid => $merchantid,
);

my $chargeback_activity;
my $tx = Business::OnlinePayment->new("Litle", @opts);
$tx->test_transaction(1);

SKIP: {
    skip "chargeback_activity_request.  No Test Account setup",17 if ! $authed;
    ### list test
    print '-'x70;
    print "CHARGEBACK ACTIVITY TESTS\n";
    my %content = %orig_content;
    $content{'activity_date'} = $date;
    $tx->content(%content);
    $chargeback_activity = $tx->chargeback_activity_request();
    is( $tx->is_success, 1, "Chargeback activity request" );
    my $cnt = scalar(@{$chargeback_activity});
    is( $cnt > 0, 1, "Objectified all test cases" );
    if ( $tx->is_success && $cnt == 0 && ! defined $ENV{'BOP_ACTIVITYDATE'} ) {
        diag('-'x70);
        diag('$ENV{\'BOP_ACTIVITYDATE\'} not set, this probably caused your last test to fail.');
        diag('-'x70);
    }

    foreach my $resp ( @{ $chargeback_activity } ) {
        my ($resp_validation) = grep { $merchantid == $resp->merchant_id && $_->{'id'} == $resp->case_id } @{ $data->{'activity_response'} };
        response_check(
            $resp,
            desc => 'List Response Check',
            reason_code => $resp_validation->{'reasonCode'},
            reason_code_description => $resp_validation->{'reasonCodeDescription'},
            type => $resp_validation->{'chargebackType'},
        );
    }
}

SKIP: {
    skip "chargeback_update_request.  No Test Account setup",4 if ! $authed;
    my ($merchant_automated) = grep { $_->{'currentQueue'} eq 'Merchant Automated' } @{ $chargeback_activity };
    skip "No 'Merchant Automated' status found.",4 if ! defined $merchant_automated;

    skip "No caseid's have currentQueue = 'Merchant Automated'",3 if ! defined $merchant_automated;

    my %content = %orig_content;
    $content{'case_id'} = $merchant_automated->case_id;
    $content{'merchant_activity_id'} = time();
    $content{'activity'} = 'Assign To Merchant';

    $tx->content(%content);
    $tx->chargeback_update_request();
    is( $tx->is_success, 1, "Chargeback caseid update: " . $content{'case_id'} );
    is( $tx->result_code, '0', "result_code(): RESULT" );
    is( $tx->error_message, 'Valid Format', "error_message(): RESULT" );
}

SKIP: {
    skip "image files.  No Auth Supplied", $#{ $data->{'test_images'} } + 1 if ! $authed;
    foreach $filePTR ( @{ $data->{'test_images'} }, @{ $data->{'replace_images'} } ) {
        my $fullname = $basedir.'resources/'.$filePTR->{'filename'};
        open FILE, $fullname or die $fullname.' '.$!;
        binmode FILE;
        my $buf;
        while ( (read FILE, $buf, 4096) != 0) {
            $filePTR->{'filecontent'} .= $buf;
        }
        close(FILE);
        ok( length($filePTR->{'filecontent'}) > 250, "Loaded from disk: ".$fullname );
    }
}

my $chargeback_list = {};
my $caseid = 0;

# Litle says to use the following line... but it fails
#$caseid = $merchantid . '001'; # Litle says use this for the test case #1
SKIP: {
    skip "Test 1 case_id.  No Test Account setup",6 if ! $authed;
    my ($resp_validation) = grep { $_->{'currentQueue'} eq 'Merchant' } @{ $chargeback_activity };
    if (defined $resp_validation && $resp_validation->case_id) { $caseid = $resp_validation->case_id; }
    is( $caseid > 0, 1, "Caseid found: " . $caseid );
}
note "Test Case #1 ($caseid)";

# Litle cleanup, make sure no files we are about to upload already exist
clean_test($authed,$caseid,\%orig_content,$data,$tx);

# Litle test 1 upload all documents
SKIP: {
    skip "chargeback_upload_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    foreach $filePTR ( @{ $data->{'test_images'} } ) {
        $content{'filename'} = $filePTR->{'filename'};
        $content{'filecontent'} = $filePTR->{'filecontent'};
        $content{'mimetype'} = $filePTR->{'mimetype'};
        $tx->content(%content);
        $chargeback_list = $tx->chargeback_upload_support_doc();
        is( $tx->is_success, 1, "Chargeback upload: " . $content{'filename'} );
        is( $tx->result_code, '000', "result_code(): RESULT" );
        is( $tx->error_message, 'Success', "error_message(): RESULT" );
        if ($tx->result_code eq '005') {
            diag('-'x70);
            diag('Result code 005 means that someone probably aborted the last test sequence early');
            diag('-'x70);
        }
    }
}

# Litle test 2, verify all documents by doing a list
SKIP: {
    skip "chargeback_list_support_docs.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;
    $tx->content(%content);
    $chargeback_list = $tx->chargeback_list_support_docs();
    is( $tx->is_success, 1, "Chargeback list request" );
    my $cnt = scalar(keys %{$chargeback_list});
    my $needed = scalar(@{$data->{'test_images'}});
    is( $cnt == $needed, 1, "Chargeback list found $cnt files, needed $needed" );
    is( $tx->result_code, '000', "result_code(): RESULT" );
    is( $tx->error_message, 'Success', "error_message(): RESULT" );

    foreach my $filename ( keys %{ $chargeback_list } ) {
        my ($resp_validation) = grep { $_->{'filename'} eq $filename } @{ $data->{'list_response'} };
        is ( $filename, $resp_validation->{'filename'}, "Chargeback list found filename: " . $filename );
    }
}

# Litle test 3, retrieve all documents
SKIP: {
    skip "chargeback_retrieve_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    foreach $filePTR ( @{ $data->{'test_images'} } ) {
        $content{'filename'} = $filePTR->{'filename'};
        $tx->content(%content);
        $chargeback_list = $tx->chargeback_retrieve_support_doc();
        is( $tx->is_success, 1, "Chargeback retrieve: " . $content{'filename'} );
        is( $tx->result_code, '000', "result_code(): RESULT" );
        is( $tx->error_message, 'Success', "error_message(): RESULT" );
    }
}


# Litle test 4, replace one document
SKIP: {
    skip "chargeback_replace_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    foreach $filePTR ( @{ $data->{'replace_images'} } ) {
        $content{'filename'} = $filePTR->{'replace'};
        $content{'filecontent'} = $filePTR->{'filecontent'};
        $content{'mimetype'} = $filePTR->{'mimetype'};
        $tx->content(%content);
        $chargeback_list = $tx->chargeback_replace_support_doc();
        is( $tx->is_success, 1, "Chargeback replace: " . $content{'filename'} );
        is( $tx->result_code, '000', "result_code(): RESULT" );
        is( $tx->error_message, 'Success', "error_message(): RESULT" );
        last; # only need to replace one
    }
}

# Litle test 5, retrieve the replaced document
SKIP: {
    skip "chargeback_retrieve_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    foreach $filePTR ( @{ $data->{'replace_images'} } ) {
        $content{'filename'} = $filePTR->{'replace'};
        $tx->content(%content);
    my $data = $tx->{'fileContent'};
        $chargeback_list = $tx->chargeback_retrieve_support_doc();
        is( $tx->is_success, 1, "Chargeback retrieve: " . $content{'filename'} );
        is( $tx->result_code, '000', "result_code(): RESULT" );
        is( $tx->error_message, 'Success', "error_message(): RESULT" );
    }
}

# Litle test 6, delete a document
SKIP: {
    skip "chargeback_delete_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;
    # Note the delete test must run, or it will make the next "upload" test sequence fail

    $filePTR = $data->{'test_images'}[0];
    $content{'filename'} = $filePTR->{'filename'};
    $tx->content(%content);
    $chargeback_list = $tx->chargeback_delete_support_doc();
    is( $tx->is_success, 1, "Chargeback delete: " . $content{'filename'} );
    is( $tx->result_code, '000', "result_code(): RESULT" );
    is( $tx->error_message, 'Success', "error_message(): RESULT" );
}

# Litle test 7, verify successful deletion by doing a list
SKIP: {
    skip "chargeback_list_support_docs.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;
    $tx->content(%content);
    $chargeback_list = $tx->chargeback_list_support_docs();
    is( $tx->is_success, 1, "Chargeback list request" );
    my $cnt = scalar(keys %{$chargeback_list});
    my $needed = scalar(@{$data->{'test_images'}}) - 1;
    is( $cnt == $needed, 1, "Chargeback list found $cnt files, needed $needed" );
    is( $tx->result_code, '000', "result_code(): RESULT" );
    is( $tx->error_message, 'Success', "error_message(): RESULT" );

    foreach my $filename ( keys %{ $chargeback_list } ) {
        my ($resp_validation) = grep { $_->{'filename'} eq $filename } @{ $data->{'list_response'} };
        is ( $filename, $resp_validation->{'filename'}, "Chargeback list found filename: " . $filename );
    }
}

$caseid = 0;
# Litle says to use the following line... but it fails
#$caseid = $merchantid . '002'; # Litle says use this for the test case #1
SKIP: {
    skip "Test 2 case_id.  No Test Account setup",6 if ! $authed;
    my ($resp_validation) = grep { $_->{'currentQueue'} ne 'Merchant' } @{ $chargeback_activity };
    if (defined $resp_validation && $resp_validation->case_id) { $caseid = $resp_validation->case_id; }
    is( $caseid > 0, 1, "Caseid found: " . $caseid );
}
note "Test Case #2 ($caseid)";

# Litle cleanup, make sure no files we are about to upload already exist
clean_test($authed,$caseid,\%orig_content,$data,$tx);

# Litle Test case #2 parts 1 and 2
SKIP: {
    skip "chargeback_upload_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    foreach $filePTR ( @{ $data->{'test_images'} } ) {
        $content{'filename'} = $filePTR->{'filename'};
        $content{'filecontent'} = $filePTR->{'filecontent'};
        $content{'mimetype'} = $filePTR->{'mimetype'};
        $tx->content(%content);
        $chargeback_list = $tx->chargeback_upload_support_doc();
        is( $tx->is_success, 0, "Chargeback upload: " . $content{'filename'} );
        is( $tx->result_code, '010', "result_code(): RESULT" );
        is( $tx->error_message, 'Case not in valid cycle', "error_message(): RESULT" );
    last; # only need to upload one
    }
}

$caseid = 0;
# Litle says to use the following line... but it fails
#$caseid = $merchantid . '003'; # Litle says use this for the test case #1
SKIP: {
    skip "Test 3 case_id.  No Test Account setup",6 if ! $authed;
    my ($resp_validation) = grep { $_->{'currentQueue'} ne 'Merchant' } @{ $chargeback_activity };
    if (defined $resp_validation && $resp_validation->case_id) { $caseid = $resp_validation->case_id; }
    is( $caseid > 0, 1, "Caseid found: " . $caseid );
}
note "Test Case #3 ($caseid)";

# Litle cleanup, make sure no files we are about to upload already exist
clean_test($authed,$caseid,\%orig_content,$data,$tx);

# Litle Test case #3 parts 1 and 2
SKIP: {
    skip "chargeback_upload_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    $filePTR = $data->{'test_images'}[0];
    $content{'filename'} = $filePTR->{'filename'};
    $content{'filecontent'} = $filePTR->{'filecontent'};
    $content{'mimetype'} = $filePTR->{'mimetype'};
    $tx->content(%content);
    $chargeback_list = $tx->chargeback_upload_support_doc();
    is( $tx->is_success, 0, "Chargeback upload: " . $content{'filename'} );
    is( $tx->result_code, '004', "result_code(): RESULT" );
    is( $tx->error_message, 'Case Not In Merchant Queue', "error_message(): RESULT" );
}

$caseid = 0;
# Litle says to use the following line... but it fails
#$caseid = $merchantid . '004'; # Litle says use this for the test case #1
SKIP: {
    skip "Test 4 case_id.  No Test Account setup",6 if ! $authed;
    my ($resp_validation) = grep { $_->{'currentQueue'} eq 'Merchant' } @{ $chargeback_activity };
    if (defined $resp_validation && $resp_validation->case_id) { $caseid = $resp_validation->case_id; }
    is( $caseid > 0, 1, "Caseid found: " . $caseid );
}
note "Test Case #4 ($caseid)";

# Litle cleanup, make sure no files we are about to upload already exist
clean_test($authed,$caseid,\%orig_content,$data,$tx);

# Litle Test case #4 parts 1 and 2
SKIP: {
    skip "chargeback_upload_support_doc.  No caseid found",6 if $caseid == 0;
    my %content = %orig_content;
    $content{'case_id'} = $caseid;

    $filePTR = $data->{'test_images'}[0];
    $content{'filename'} = 'maxsize.tif';
    $content{'filecontent'} = $filePTR->{'filecontent'};
    $content{'mimetype'} = $filePTR->{'mimetype'};
    $tx->content(%content);
    $chargeback_list = $tx->chargeback_upload_support_doc();
    $chargeback_list = $tx->chargeback_upload_support_doc(); # run it twice because they don't have the file there already
    is( $tx->is_success, 0, "Chargeback upload: " . $content{'filename'} );
    is( $tx->result_code, '005', "result_code(): RESULT" );
    is( $tx->error_message, 'Document Already Exists', "error_message(): RESULT" );

    # Litel Test case 4 part 3 & 4
    $content{'filename'} = $filePTR->{'filename'};
    $content{'filecontent'} = $filePTR->{'filecontent'} . ' 'x3000000; # file greater then 2M
    $content{'mimetype'} = $filePTR->{'mimetype'};
    $tx->content(%content);
    eval { $chargeback_list = $tx->chargeback_upload_support_doc(); };
    is( $tx->is_success, 0, "Chargeback upload: " . $content{'filename'} );
    is( $tx->error_message, 'Filesize Exceeds Limit Of 2MB', "error_message(): RESULT" );

    # Litel Test case 4 part 5 & 6
    $content{'filename'} = $filePTR->{'filename'};
    $content{'filecontent'} = $filePTR->{'filecontent'};
    $content{'mimetype'} = $filePTR->{'mimetype'};
    foreach my $cnt ( 1 .. 10 ) {
        $content{'filename'} = $cnt.$filePTR->{'filename'};
        $tx->content(%content);
        $chargeback_list = $tx->chargeback_upload_support_doc(); # make sure we have to many files for this test
    }
    $content{'filename'} = '11'.$filePTR->{'filename'};
    $tx->content(%content);
    $tx->chargeback_upload_support_doc();
    $chargeback_list = $tx->chargeback_list_support_docs();
    is( $tx->is_success, 0, "Chargeback upload: " . $content{'filename'} );
    is( $tx->result_code, '008', "result_code(): RESULT" );
    is( $tx->error_message, 'Max Document Limit Per Case Reached', "error_message(): RESULT" );
}














#-----------------------------------------------------------------------------------
#
sub tx_check {
    my $tx = shift;
    my %o = @_;

    is( $tx->is_success, $o{is_success}, "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code, $o{result_code}, "result_code(): RESULT" );
    is( $tx->error_message, $o{error_message}, "error_message() / RESPMSG" );
    if( $o{authorization} ){
        is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    }
    if( $o{avs_code} ){
        is( $tx->avs_code, $o{avs_code}, "avs_code() / AVSADDR and AVSZIP" );
    }
    if( $o{cvv2_response} ){
        is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    }
    like( $tx->order_number, qr/^\w{5,19}/, "order_number() / PNREF" );
}

#
sub response_check {
    my $tx = shift;
    my %o = @_;

    is( $tx->reason_code, $o{reason_code}, "reason_code(): RESULT" );
    is( $tx->reason_code_description, $o{reason_code_description}, "reason_code_description(): RESULT" );
    is( $tx->hash->{'chargebackType'}, $o{type}, "type() / RESPMSG" );
}
sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(", $tx->is_success, ")",
            " order_number(", $tx->order_number, ")",
            " error_message(", $tx->error_message, ")",
            " result_code(", $tx->result_code, ")",
            " invoice_number(", $tx->invoice_number , ")",
        )
    );
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $year++; # So we expire next year.
    $year %= 100; # y2k? What's that?

    return sprintf("%02d%02d", $month, $year);
}

sub clean_test {
  my ($authed,$caseid,$orig_content,$data,$tx) = @_;
  SKIP: {
    skip "clean_tests.  No caseid found",1 if $caseid == 0;
    my %content = %$orig_content;
    $content{'case_id'} = $caseid;

    foreach $filePTR ( @{ $data->{'test_images'} } ) {
        $content{'filename'} = $filePTR->{'filename'};
        $tx->content(%content);
        $tx->chargeback_delete_support_doc();
    # we don't really care if this worked... it's just preperation for the test sweet below
    }

    foreach my $cnt ( '', 1 .. 11 ) {
        $content{'filename'} = $cnt.'maxsize.tif';
        $tx->content(%content);
        $tx->chargeback_delete_support_doc();
    }
    is( 1, 1, "Test files deleted, if they existed" );
  }
}

__DATA__
$data= {
'list_response' => [
    {
        'filename' => 'testImage.jpg',
    },
    {
        'filename' => 'testImage2.jpg',
    },
    {
        'filename' => 'default.pdf',
    },
#    {
#        'filename' => 'image1.gif',
#    },
    {
        'filename' => 'person.png',
    },
    {
        'filename' => 'zipper.tiff',
    },
],
'replace_images' => [
    {
        'filename' => 'testImage2.jpg',
        'replace'  => 'testImage.jpg',
        'mimetype' => 'image/jpeg',
    },
],
'test_images' => [
    {
        'filename' => 'testImage.jpg',
        'mimetype' => 'image/jpeg',
    },
    {
        'filename' => 'default.pdf',
        'mimetype' => 'application/pdf',
    },
#    {
#        'filename' => 'image1.gif',
#        'mimetype' => 'image/gif',
#    },
    {
        'filename' => 'person.png',
        'mimetype' => 'image/png',
    },
    {
        'filename' => 'zipper.tiff',
        'mimetype' => 'image/tiff',
    },
],
'activity_response' => [
    {
        id => '60700001',
        'chargebackType' => 'Deposit',
        'reasonCodeDescription' => 'Contact Litle & Co for Definition',
        'reasonCode' => '00A1',
    },
{
    id => '60700002',
    'fromQueue' => 'Merchant',
    'chargebackType' => 'Deposit',
    'reasonCodeDescription' => 'Contact Litle & Co for Definition',
    'reasonCode' => '00A1',
},
  {
    id => '60700003',
    'chargebackType' => 'Deposit',
    'reasonCodeDescription' => 'Contact Litle & Co for Definition',
    'reasonCode' => '00A1',
  },
  {
    id => '60700004',
    'fromQueue' => 'Merchant',
    'chargebackType' => 'Deposit',
    'reasonCodeDescription' => 'Contact Litle & Co for Definition',
    'reasonCode' => '00A1',
  },
  ],
        };
