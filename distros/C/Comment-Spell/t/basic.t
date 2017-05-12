
use strict;
use warnings;

use Test::More tests => 6;

# FILENAME: basic.t
# CREATED: 09/26/14 12:37:44 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test basic interface

# Single Hashed comment is shown
## Double Hashed comments get hidden

use Comment::Spell;
use Path::Tiny qw( path );
use IO::Scalar;

my $content = path($0)->openr_raw;

my $spell = Comment::Spell->new();

my $outstr = q[];

my $fh = IO::Scalar->new( \$outstr );
$spell->set_output_filehandle($fh);
$spell->parse_from_filehandle($content);
$spell->parse_from_file('./lib/Comment/Spell.pm');

like $outstr,   qr/Single Hashed comment/,                   "Single Hashed comment extracted";
unlike $outstr, qr/Double Hashed comment/,                   "Double Hashed comment excluided";
like $outstr,   qr/this comment is for self testing/,        "Single Hashed comment extracted in main pmfile";
unlike $outstr, qr/this comment is hidden for self testing/, "Double Hashed comment excluded in main pmfile";
unlike $outstr, qr/this comment appears later/,              "Later comment doesn't appear yet";

my $instr = path($0)->slurp_raw;
$instr .= "\n\n#this comment appears later\n\n";

$spell->parse_from_string($instr);

like $outstr, qr/this comment appears later/, "Later comment appears";
