#!perl -T
#
# Test Archive::StringToZip as documented
#
# $Id: zipString.t 10 2006-05-22 18:21:21Z tom $

use strict;

use Test::Exception;
use Test::More tests => 14;

my $class = 'Archive::StringToZip';
use_ok $class;

my $unzipped_text = <<'END';
Zip me baby
ONE MORE TIME!
END

# Use method calls advertised in the documentation
{
    my $stz     = $class->new();
    isa_ok      $stz, $class;
    throws_ok   { $stz->zipString() }
                    qr/\ACannot archive an undefined string/,
                    'zipString dies with no arguments';
    throws_ok   { $stz->zipString(undef, 'FILENAME') }
                    qr/\ACannot archive an undefined string/,
                    'zipString dies with a filename but no string';
    lives_ok    { $stz->zipString('') }
                    'Can archive an empty string';
}

# Use the OO interface
{
    my $stz     = $class->new();
    my $zip     = $stz->zipString($unzipped_text, 'output.file_TEST');
    is          substr($zip, 0, 2), 'PK',
                    'Looks like a ZIP';
    like        $zip, qr/output\.file_TEST/,
                    'Specifying the filename probably works';

    # Check we can reuse an object
    throws_ok   { $stz->zipString() }
                    qr/\ACannot archive an undefined string/,
                    'zipString dies with no arguments';
    my $zip2    = $stz->zipString($unzipped_text);
    is          substr($zip2, 0, 2), 'PK',
                    'Looks like a ZIP when reusing an object';
    like        $zip2, qr/file\.txt/,
                    'Not specifying the filename probably works';
}

# Test non-OO interface
{
    throws_ok { zipString($unzipped_text, 'myFILENAME') }
        qr/\AUndefined subroutine /ms,
        'Cannot call zipString without importing it';
    $class->import('zipString');
    my $zip     = zipString($unzipped_text, 'myFILENAME');
    is          substr($zip, 0, 2), 'PK',
                    'Looks like a ZIP';
    like        $zip, qr/myFILENAME/,
                    'Specifying the filename probably works';

    no strict 'refs';   # needed for the line below
    my $zip2    = &{"$class\::zipString"}($unzipped_text, 'myFILENAME');
    is          $zip, $zip2,
                'Fully qualified name behaves the same as imported name';
}
