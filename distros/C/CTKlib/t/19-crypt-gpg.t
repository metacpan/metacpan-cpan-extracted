#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 6;

use File::Spec;
use CTK;
use CTK::Util qw/fsave randchars preparedir/;
use Digest::MD5;
use IO::File;

use CTK::Crypt::GPG;

use constant {
    FILENAME_SRC        => 'test_src.tmp',
    FILENAME_ASC        => 'test_asc.tmp',
    FILENAME_DEC        => 'test_dec.tmp',
    PRIVATE_TEST_KEY    => 'myprivate.key',
    PUBLIC_TEST_KEY     => 'mypublic.key',
    PASSWORD            => 'test',
};

my $dst = File::Spec->catdir("src", "dst");
ok(preparedir($dst), "Prepare $dst");
my $asc_file = File::Spec->catfile($dst, FILENAME_ASC);
my $dec_file = File::Spec->catfile($dst, FILENAME_DEC);

# Create test file with 10 lines
my @pool;
for (1..10) { push @pool, sprintf("%02d %s", $_, randchars( 80 )) };
ok(fsave(FILENAME_SRC, join("\n", @pool)), "Save random file");

my $gpg = new_ok( 'CTK::Crypt::GPG', [(
        -publickey  => File::Spec->catfile("src", PUBLIC_TEST_KEY),
        -privatekey => File::Spec->catfile("src", PRIVATE_TEST_KEY),
        -password   => PASSWORD,
    )] );
exit 1 unless $gpg;
#note(explain($gpg));

# Encrypt file
ok($gpg->encrypt(
        -infile => FILENAME_SRC,
        -outfile=> $asc_file,
        -armor  => "yes",
    ), "Encrypt file") or diag( $gpg->error );
#note(explain($gpg));

# Decrypt file
ok($gpg->decrypt(
        -infile => $asc_file,
        -outfile=> $dec_file,
    ), "Decrypt file") or diag( $gpg->error );

is(
    Digest::MD5->new->addfile(IO::File->new(FILENAME_SRC, "r"))->hexdigest,
    Digest::MD5->new->addfile(IO::File->new($dec_file, "r"))->hexdigest,
    "Files are identical"
);

1;

__END__
