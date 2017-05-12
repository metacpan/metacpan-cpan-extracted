use Test::More no_plan;
use File::Temp qw(tempfile);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Config::INIPlus;

my $filename = "$FindBin::Bin/../examples/example.ini";
my $eol      = qr/(?:\015?\012)/;

my $cfg = eval { Config::INIPlus->new( file => $filename ); };
is( $@, '', "Initial parse test using filename" );
$@ && diag("Failure: $@");

open my $fh, '<', $filename;
local $/ = undef;
my $string = <$fh>;
close $fh;

$cfg = eval { Config::INIPlus->new( string => $string ); };
is( $@, '', "Initial parse test using string in UNIX mode" );
$@ && diag("Failure: $@");

$string =~ s/$eol/\015\012/gs;

my $cfg_dos = eval { Config::INIPlus->new( string => $string ); };
is( $@, '', "Initial parse test using string in DOS mode" );
$@ && diag("Failure: $@");

is_deeply( $cfg->as_hashref, $cfg_dos->as_hashref,
    'Test if structure extracted in Unix mode is the same as DOS mode' );

( $fh, my $temp_filename ) = tempfile();
$fh->close;
eval { $cfg->write($temp_filename) };
is( $@, '', "Write INI file" );
$@ && diag("Failure: $@");

my $cfg_temp = eval { Config::INIPlus->new( file => $temp_filename ); };
is( $@, '', "Read in tempfile by filename" );
$@ && diag("Failure: $@");

is_deeply( $cfg->as_hashref, $cfg_temp->as_hashref,
    'Test if structure extracted from written file is identical to original'
);

