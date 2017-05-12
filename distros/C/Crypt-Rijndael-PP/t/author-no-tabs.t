
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Crypt/Rijndael/PP.pm',
    'lib/Crypt/Rijndael/PP.pod',
    'lib/Crypt/Rijndael/PP/Debug.pm',
    'lib/Crypt/Rijndael/PP/GF.pm',
    't/00-compile.t',
    't/01-input_to_state.t',
    't/02-SubBytes.t',
    't/03-ShiftRows.t',
    't/04-MixColumns.t',
    't/05-KeyExpansion.t',
    't/06-AddRoundKey.t',
    't/07-encrypt_block.t',
    't/08-InvShiftRows.t',
    't/09-InvSubBytes.t',
    't/10-InvMixColumns.t',
    't/11-decrypt_block.t',
    't/12-full_cycle_block.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/gf_multiplication/01-gf_multiply.t',
    't/lib/Test/Crypt/Rijndael.pm',
    't/lib/Test/Crypt/Rijndael/Constant.pm',
    't/mode/01-ECB-Electronic_Code_Book.t',
    't/mode/02-CBC-Chaining_Block_Cipher.t',
    't/mode/03-CTR-Counter.t',
    't/mode/04-CFB-Cipher_Feedback.t',
    't/mode/05-OFB-Output_Feedback.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
