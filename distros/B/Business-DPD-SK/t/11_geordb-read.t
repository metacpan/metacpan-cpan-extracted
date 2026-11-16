use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use IO::Compress::Zip qw(zip $ZipError);

use Business::DPD::SK::GeoRDB;

my @lines = (
    '#FILE;GeoRDB_26110211_B016;',
    '#VERSION;26110211;',
    '#DEF:GEOROUTING:VERSION;VERSIONNUMBER;VALIDFROM;VALIDTO;BARCODEID;;',
    '#DEF:GEOROUTING:COUNTRY;COUNTRYCODE;ISONUMCOUNTRYCODE;ISOALPHA3COUNTRYCODE;DESTINATIONLANGUAGES;FLAGPOSTCODENO;POSTCODEPATTERN;FLAGNEEDSTATE;POSTCODEVALIDATION;CITYVALIDATION;FREETRADEAREA;DUMMYCOUNTRYCODE;;',
    '#DEF:GEOROUTING:POSTALCODE;COUNTRYCODE;BEGINPOSTCODE;ENDPOSTCODE;POSTCODETYPE;;',
    'VERSION;26110211;20261102;20261206;%;',
    'COUNTRY;SK;703;SVK;SK;0;NNNNN;0;VB;NO;EU;;',
    'COUNTRY;MT;470;MLT;MT,EN;0;,AAANNNN;0;VI;NO;EU;;',
    'POSTALCODE;SK;01001;;;',
    'POSTALCODE;SK;83101;83104;;',
    'POSTALCODE;CZ;19992;;D;',
    '#END',
);

sub write_zip {
    my ($dir, $content) = @_;
    my $path = File::Spec->catfile($dir, 'GeoRDB_26110211_B016.zip');
    zip(\$content => $path, Name => 'GeoRDB_26110211_B016') or die $ZipError;
    return $path;
}

my $dir = tempdir(CLEANUP => 1);
my $geordb = Business::DPD::SK::GeoRDB->new(
    data_dir => $dir,
    file     => write_zip($dir, join("\r\n", @lines, '')),
);

subtest 'each_row maps columns from #DEF headers' => sub {
    my @rows;
    my $summary = $geordb->each_row('POSTALCODE', sub {push @rows, $_[0]});
    is(scalar(@rows), 3, 'three postal code rows');
    is_deeply(
        $rows[1],
        {COUNTRYCODE => 'SK', BEGINPOSTCODE => '83101', ENDPOSTCODE => '83104', POSTCODETYPE => ''},
        'row hash keyed by column names, CR stripped'
    );
    is($rows[2]{POSTCODETYPE}, 'D', 'type column kept');
    is_deeply($summary, {rows => 3, complete => 1}, 'summary reports rows and #END');
};

subtest 'each_row keeps empty leading pattern elements' => sub {
    my %pattern;
    $geordb->each_row('COUNTRY', sub {$pattern{$_[0]{COUNTRYCODE}} = $_[0]{POSTCODEPATTERN}});
    is_deeply(\%pattern, {SK => 'NNNNN', MT => ',AAANNNN'}, 'patterns as in the file');
};

subtest 'version returns the VERSION row' => sub {
    is_deeply(
        $geordb->version,
        {VERSIONNUMBER => '26110211', VALIDFROM => '20261102', VALIDTO => '20261206', BARCODEID => '%'},
        'version row'
    );
};

subtest 'missing #END is reported as incomplete' => sub {
    my $dir2 = tempdir(CLEANUP => 1);
    my $partial = Business::DPD::SK::GeoRDB->new(
        data_dir => $dir2,
        file     => write_zip($dir2, join("\r\n", @lines[0 .. 9], '')),
    );
    my $summary = $partial->each_row('POSTALCODE', sub { });
    is($summary->{complete}, 0, 'not complete without #END');
};

subtest 'corrupt zip dies while reading' => sub {
    my $dir3 = tempdir(CLEANUP => 1);
    my $path = write_zip($dir3, join("\r\n", @lines, '') x 50);
    open(my $fh, '+<:raw', $path) or die $!;
    seek($fh, 60, 0);
    print {$fh} 'XXXXXXXX';
    close($fh);
    my $broken = Business::DPD::SK::GeoRDB->new(data_dir => $dir3, file => $path);
    throws_ok {$broken->each_row('POSTALCODE', sub { })} qr/error reading/, 'dies on damaged data';
};

subtest 'each_row without a stored zip dies' => sub {
    my $empty = Business::DPD::SK::GeoRDB->new(data_dir => tempdir(CLEANUP => 1));
    throws_ok {$empty->each_row('COUNTRY', sub { })} qr/no GeoRDB file/, 'clear error';
};

done_testing();
