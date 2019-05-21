#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 18-crypt.t 241 2019-05-07 16:23:14Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 5;

use File::Spec;
use CTK;
use CTK::Util qw/fsave randchars preparedir/;
use Digest::MD5;
use IO::File;

use CTK::Crypt qw/:all/;

use constant {
    FILENAME_SRC => 'test_src.tmp',
    FILENAME_DST => 'test_dst.tmp',
};

my $dst = File::Spec->catdir("src", "dst");
ok(preparedir($dst), "Prepare $dst");

# Create test file with 10 lines
my @pool;
for (1..10) { push @pool, sprintf("%02d %s", $_, randchars( 80 )) };
ok(fsave(FILENAME_SRC, join("\n", @pool)), "Save random file");

# Encrypt file
ok(tcd_encrypt(FILENAME_SRC, File::Spec->catfile($dst, FILENAME_SRC)), "Encrypt file")
    or diag( $CTK::Crypt::ERROR );
ok(tcd_decrypt(File::Spec->catfile($dst, FILENAME_SRC), FILENAME_DST), "Decrypt file")
    or diag( $CTK::Crypt::ERROR );


is(
    Digest::MD5->new->addfile(IO::File->new(FILENAME_SRC, "r"))->hexdigest,
    Digest::MD5->new->addfile(IO::File->new(FILENAME_DST, "r"))->hexdigest,
    "Files are identical"
);

1;

__END__

