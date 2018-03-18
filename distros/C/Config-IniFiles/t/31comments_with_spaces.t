#!/usr/bin/perl

# This test attempts to reproduce
# https://sourceforge.net/tracker/?func=detail&aid=3388382&group_id=6926&atid=106926

use strict;
use warnings;

use Test::More tests => 4;
use File::Spec;

use Config::IniFiles;

my $ini_filename =
    File::Spec->catfile( File::Spec->curdir(), "t", 'test31.ini' );

{
    open my $ini_fh, '>', $ini_filename
        or die "Cannot open '$ini_filename' - $!";
    print {$ini_fh} <<'EOT';
[section]
value1 = xxx ; My Comment
value2 = xxx ; My_Comment
EOT
    close($ini_fh);
}

my $ini = Config::IniFiles->new(
    -file                    => $ini_filename,
    -handle_trailing_comment => 1,
    -commentchar             => ';',
    -allowedcommentchars     => ';#'
);

# TEST
is( $ini->val( 'section', 'value1' ), 'xxx' );

# TEST
is( $ini->GetParameterTrailingComment( 'section', 'value1' ), 'My Comment' );

# TEST
is( $ini->val( 'section', 'value2' ), 'xxx' );

# TEST
is( $ini->GetParameterTrailingComment( 'section', 'value2' ), 'My_Comment' );

unlink($ini_filename);
