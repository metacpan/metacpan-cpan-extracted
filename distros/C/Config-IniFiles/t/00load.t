#!/usr/bin/perl
use strict;
use warnings;

# Should be 15
use Test::More tests => 15;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

use IO::File;

BEGIN
{
    # TEST
    use_ok('Config::IniFiles');
}

my $ini;

# a simple filehandle, such as STDIN
#** If anyone can come up with a test for STDIN that would be great
#   The following could be run in a separate file with data piped
#   in. e.g. ok( !system( "$^X stdin.pl < test.ini" ) );
#   But it's only good on platforms that support redirection.
#	use strict;
#	use Config::IniFiles;
#	my $ini = Config::IniFiles->new(-file => STDIN);
#	exit $ini ? 0; 1

local *CONFIG;

# TEST
# a filehandle glob, such as *CONFIG
if ( open( CONFIG, "<", t_file("test.ini") ) )
{
    $ini = Config::IniFiles->new( -file => *CONFIG );
    ok( $ini, q{$ini was initialized} );
    close CONFIG;
}
else
{
    ok( 0, "Could not open file" );
}

# TEST
# a reference to a glob, such as \*CONFIG
if ( open( CONFIG, "<", t_file("test.ini") ) )
{
    $ini = Config::IniFiles->new( -file => \*CONFIG );
    ok( $ini, q{$ini was initialized with a reference to a glob.} );
    close CONFIG;
}
else
{
    ok( 0, q{could not open test.ini} );
}

# an IO::File object
# TEST
if ( my $fh = IO::File->new( t_file("test.ini") ) )
{
    $ini = Config::IniFiles->new( -file => $fh );
    ok( $ini, q{$ini was initialized with an IO::File reference.} );
    $fh->close;
}
else
{
    ok( 0, "Could not open file" );
}    # endif

# TEST
# Reread on an open handle
if ( open( CONFIG, "<", t_file("test.ini") ) )
{
    $ini = Config::IniFiles->new( -file => \*CONFIG );
    ok( ( $ini && $ini->ReadConfig() ), qq{ReadConfig() was successful} );
    close CONFIG;
}
else
{
    ok( 0, "Could not open file" );
}

use File::Temp qw(tempdir);
use File::Spec ();

my $dir_name = tempdir( CLEANUP => 1 );
my $test01_fn = File::Spec->catfile( $dir_name, 'test01.ini' );

# TEST
if ( open( CONFIG, "<", t_file("test.ini") ) )
{
    $ini = Config::IniFiles->new( -file => \*CONFIG );
    $ini->SetFileName($test01_fn);
    $ini->RewriteConfig();
    close CONFIG;

    # Now test opening and re-write to the same handle
    if ( !open( CONFIG, "+<", $test01_fn ) )
    {
        die "Could not open " . $test01_fn . " for read/write";
    }
    $ini = Config::IniFiles->new( -file => \*CONFIG );
    my $badname = scalar( \*CONFIG );

    # Have to use open/close because -e seems to be always true!
    ok(
        $ini && $ini->RewriteConfig() && !( open( I, $badname ) && close(I) ),
        qq{Write to a new file name and write to it},
    );
    close CONFIG;

# In case it failed, remove the file
# (old behavior was to write to a file whose filename is the scalar value of the handle!)
    unlink $badname;
}
else
{
    ok( 0, "Could not open file" );
}    # end if

# the pathname of a file
$ini = Config::IniFiles->new( -file => t_file("test.ini") );

# TEST
ok( $ini, q{Opening with -file works} );

# A non-INI file should fail, but not throw warnings
local $@ = '';
my $ERRORS = '';
local $SIG{__WARN__} = sub { $ERRORS .= $_[0] };
eval { $ini = Config::IniFiles->new( -file => t_file("00load.t") ) };

# TEST
ok( !$@ && !$ERRORS && !defined($ini),
    "A non-INI file should fail, but not throw errors" );

$@ = '';
eval { $ini = Config::IniFiles->new( -file => \*DATA ) };

# TEST
ok( !$@ && defined($ini), "Read in the DATA file without errors" );

# Try a file with utf-8 encoding (has a Byte-Order-Mark at the start)
# TEST
$ini = Config::IniFiles->new( -file => t_file("en.ini") );
ok( $ini,
    "Try a file with utf-8 encoding (has a Byte-Order-Mark at the start)" );

# Create a new INI file, and set the name using SetFileName
$ini = Config::IniFiles->new();
my $filename = $ini->GetFileName;

# TEST
ok( ( !defined($filename) ), "Not defined filename on fresh Config::IniFiles" );

# TEST
$ini->SetFileName( t_file("test9_name.ini") );
$filename = $ini->GetFileName;
is( $filename, t_file("test9_name.ini"), "Check GetFileName method", );

$@ = '';
eval { $ini = Config::IniFiles->new( -file => t_file('blank.ini') ); };

# TEST
ok(
    ( !$@ && !defined($ini) ),
    "Make sure that no warnings are thrown for an empty file",
);

$@ = '';
eval {
    $ini =
        Config::IniFiles->new( -file => t_file('blank.ini'), -allowempty => 1 );
};

# TEST
ok(
    ( !$@ && defined($ini) ),
    "Empty files should cause no rejection when appropriate switch set",
);

$@ = '';
eval { $ini = Config::IniFiles->new( -file => t_file('bad.ini') ); };

# TEST
ok(
    ( !$@ && !defined($ini) && @Config::IniFiles::errors ),
    "A malformed file should throw an error message",
);

__END__
; File that has comments in the first line
; Comments are marked with ';'.
; This should not fail when checking if the file is valid
[section]
parameter=value


