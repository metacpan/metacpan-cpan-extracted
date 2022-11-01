use strict;
use warnings;
use Test::More;
use Text::CSV qw(csv);
use FindBin qw( $RealBin );

my $NAME = 'ipchgmon';
my $invoke = "$^X $RealBin/../bin/$NAME";

subtest 'Debug option is valid' => sub {
    my $rtn = qx($invoke --debug 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No error message';
};

subtest 'Singleemail option is valid' => sub {
    my $rtn = qx($invoke --singleemail 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No error message';
};

subtest '4 option is valid' => sub {
    my $rtn = qx($invoke --4 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No error message';
};

subtest '6 option is valid' => sub {
    my $rtn = qx($invoke --6 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No error message';
};

subtest 'File option is valid' => sub {
    SKIP: {
        skip "Unable to write to $RealBin" unless -w $RealBin;
        my $fqname = $RealBin . '/test.txt';
        my $rtn = qx($invoke --debug --file $fqname 2>&1);
        unlike $rtn, qr/Unknown option/m, 'No option error message for file';

        $rtn = qx($invoke --debug --file 2>&1);
        like $rtn, qr/requires an argument/m, 'Argument error message appears for file';
        unlink $fqname or warn "Unable to delete $fqname at end of tests.";
    }
};

subtest 'Email option is valid' => sub {
    my $rtn = qx($invoke --debug --email 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No option error message for email';
    like $rtn, qr/requires an argument/m, 'Argument error message appears for email';
    
    $rtn = qx($invoke --debug --email invalid\@example.com 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No argument error message for email';
    $rtn = qx($invoke --debug --mailto invalid\@example.com 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No argument error message for mailto';
};

subtest 'Mailport option is valid' => sub {
    my $rtn = qx($invoke --debug --mailserver localhost --mailport 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No option error message for mailserver';
    like $rtn, qr/requires an argument/m, 
                               'Argument error message appears for mailserver';
    
    $rtn = qx($invoke --debug --mailserver localhost --mailport 25 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No argument error message for mailserver';
    $rtn = qx($invoke --debug --mailserver localhost --mailport localhost 2>&1);
    like $rtn, qr/number expected/m, 'Not numeric error message for mailserver';
    $rtn = qx($invoke --debug --mailport 25 2>&1);
    like $rtn, qr/Invalid option combination/m, 
                                'mailport option invalid without mailserver';
};

subtest 'Leeway option is valid' => sub {
    my $rtn = qx($invoke --debug --leeway 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No option error message for leeway';
    like $rtn, qr/requires an argument/m, 
                               'Argument error message appears for leeway';
    
    $rtn = qx($invoke --debug --leeway 86400 2>&1);
    unlike $rtn, qr/Unknown option/m, 'No argument error message for mailserver';
    $rtn = qx($invoke --debug --leeway localhost 2>&1);
    like $rtn, qr/number expected/m, 'Not numeric error message for mailserver';
};

my @stringopts = qw(server mailserver mailfrom mailsubject dnsname);
for my $opt (@stringopts) {
    subtest ucfirst($opt) . ' option is valid' => sub {
        my $cmd = "$invoke --debug --" . $opt . " 2>&1";
        my $rtn = qx($cmd);
        unlike $rtn, qr/Unknown option/m, "No option error message for $opt";
        like $rtn, qr/requires an argument/m, 
                                   "Argument error message appears for $opt";
        
        $cmd = "$invoke --debug --" . $opt . " foo 2>&1";
        $rtn = qx($cmd);
        unlike $rtn, qr/Unknown option/m, "No argument error message for $opt";
    }
}

done_testing;
