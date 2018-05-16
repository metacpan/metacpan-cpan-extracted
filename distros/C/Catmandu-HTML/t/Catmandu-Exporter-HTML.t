#!perl

use strict;
use warnings;
use Test::More;
use Catmandu;
use Catmandu::Importer::HTML;
use Digest::MD5 qw(md5_hex);

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::HTML';
    use_ok $pkg;
};

require_ok $pkg;

my $html = '';
my $exporter = $pkg->new(file => \$html);

isa_ok $exporter, $pkg;

my $importer = Catmandu::Importer::HTML->new(file => 't/muse.html');
my $record  = $importer->first;

ok $exporter->add($record);

ok $exporter->commit;

utf8::encode($html);

like $html , qr{^<html><body>};

my $digest = md5_hex($html);

is $digest , '221a66bba1ee68f922db22d26b99e0c4';

$exporter = $pkg->new(file => 't/muse.html.out');
$importer = Catmandu::Importer::HTML->new(file => 't/muse.html');

$exporter->add_many($importer);
$exporter->commit;

my $fh;
open $fh , 't/muse.html.out';
$digest = Digest::MD5->new->addfile($fh)->hexdigest;
is $digest , '221a66bba1ee68f922db22d26b99e0c4';
close($fh);

unlink 't/muse.html.out';

done_testing;
