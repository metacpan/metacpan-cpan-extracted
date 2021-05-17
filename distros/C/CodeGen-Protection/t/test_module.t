#!/usr/bin/env perl

use Test::Tester;
use Test::Most;
use Test::CodeGen::Protection;
use File::Temp qw(tempfile);
use CodeGen::Protection ':all';

subtest 'Protected documents must have start and end markers' => sub {
    check_test(
        sub {
            is_protected_document_ok 'Perl', '...', 'This should fail';
        },
        {
            ok   => 0,
            name => 'This should fail',
            diag =>
              qr(Could not find the Perl start and end markers in existing_code),
        },
    );
};

subtest 'Protected documents with valid start and end documents should pass' =>
  sub {
    check_test(
        sub {
            is_protected_document_ok 'Perl', get_protected_code_sample(),
              'This should pass';
        },
        {
            ok   => 1,
            name => 'This should pass',
            diag => '',
        },
    );
  };

subtest 'Valid protected documents with altered code should fail' => sub {
    my $code = get_protected_code_sample();

    explain
      'We have altered the code and this will cause the checksums to not match the body content';
    $code =~ s/foreach/for/;
    check_test(
        sub {
            is_protected_document_ok 'Perl', $code, 'This should fail';
        },
        {
            ok   => 0,
            name => 'This should fail',
            diag =>
              qr/Checksum \([0-9a-f]{32}\) did not match expected checksum \([0-9a-f]{32}\)/,
        },
    );
};

subtest 'Testing non-existent files is not fatal' => sub {
    check_test(
        sub {
            is_protected_file_ok 'Perl', 'no such file',
              'We should not be able to read non-existent files';
        },
        {
            ok   => 0,
            name => 'We should not be able to read non-existent files',
            diag => qr/Cannot open 'no such file' for reading/,
        }
    );
};

subtest 'Testing valid files with non-protected code should fail' => sub {
    my ( $fh, $filename ) = tempfile();
    print {$fh} 'not protected code';
    check_test(
        sub {
            is_protected_document_ok 'Perl', $filename, 'Not protected code';
        },
        {
            ok   => 0,
            name => 'Not protected code',
            diag =>
              qr/Could not find the Perl start and end markers in existing_code for document/,
        },
    );
};

done_testing;

sub get_protected_code_sample {
    my $code = '
    sub sum {
        my $total = 0;
        $total += $_ foreach @_;
        return $total;
    }';
    return create_protected_code( type => 'Perl', protected_code => $code );
}
