#!/usr/bin/perl
#

use strict; use warnings;

use Test::More tests => 17;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('Business::EDI');
    use_ok('Business::EDI::Segment::RFF');
}

my $verbose = @ARGV ? shift : 0;
$Business::EDI::debug = $verbose;
$Business::EDI::Segment::RFF::debug = $verbose;
$Business::EDI::CodeList::verbose   = $verbose;

my $data = {
    'C506' => {
        '1154' => '4640',
        '1153' => 'LI'
    }
};

$Data::Dumper::Indent = 1;

use vars qw/%code_hash $rff $codemap/;

note "data: " . Dumper($data);

ok($rff = Business::EDI::Segment::RFF->new($data), 'Business::EDI::Segment::RFF->new');
$verbose and print "RFF: ", Dumper($rff);
ok($rff->C506, "C506 Autoload accessor");
my $seg1153 = $rff->C506->seg1153;
isa_ok($seg1153, "Business::EDI::CodeList::ReferenceCodeQualifier", "RFF->C506->seg1153");
is_deeply($seg1153, $rff->partC506->part(1153),    "partC506->part(1153) accessor");
is_deeply($seg1153, $rff->part('C506')->part(1153),"part('C506')->part(1153) accessor");
is_deeply($seg1153, $rff->part('C506')->part1153,  "part('C506')->part1153 Autoload accessor");
$verbose and note("RFF->segC506->value: " . $rff->segC506->value);

ok($codemap = $rff->segC506->codemap, "Business::EDI::Segment::RFF->new(...)->segC506->codemap");

foreach my $key (keys %$data) {
    my ($msgtype);
    ok($msgtype = Business::EDI->subelement({$key => $data->{$key}}),
        "Business::EDI->subelement({$key => $data->{$key}}): Code $key recognized"
    );
    note "ref(subelement): " . ref($msgtype);
    if ($key =~ /^C\d{3}$/) {
        TODO: {
            my @keys = keys %{$data->{$key}};
            todo_skip "Unimplemented - direct access to unique element grouped under Composite", scalar(@keys) ;
            foreach (@keys) {
                ok($msgtype->part($_), "Extra test for direct access to element grouped under $key/$_");
            }
        }
    }
    is_deeply($msgtype, $rff->part($key),        "Different constructor paths, identical object");
    is($msgtype->code,  $rff->part($key)->code , "Different constructor paths, same code");
    is($msgtype->label, $rff->part($key)->label, "Different constructor paths, same label");
    is($msgtype->value, $rff->part($key)->value, "Different constructor paths, same value");
    $verbose and note(ref($msgtype)  . ' dump: ' . Dumper($msgtype));
}

# ok($slurp = join('', <DATA>),     "Slurped data from DATA handle");

# note("ref(\$obj): " . ref($perl));
# note("    \$obj : " .     $perl );

note("done");

