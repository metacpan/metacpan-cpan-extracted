#!/usr/bin/perl
#

use strict; use warnings;

use Test::More tests => 1349;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('UNIVERSAL::require');

    use_ok('Business::EDI');
    use_ok('Business::EDI::Test', qw/JSONObject2Perl ordrsp_data/);
    use_ok('Business::EDI::DataElement');
    use_ok('Business::EDI::Segment::RFF');
    use_ok('Business::EDI::Segment::BGM');
}

use vars qw/%code_hash $perl/;

my $debug = $Business::EDI::debug = @ARGV ? shift : 0;

my $edi = Business::EDI->new('d96a') or die "Business::EDI->new('d96a') failed";

sub parse_ordrsp {
    my ($top_nodes) = @_;
    my $type = 'ORDRSP';
    my $ordrsp;
    ok($ordrsp = $edi->message($type, $top_nodes), "EDI $type object via \$edi->message");
    my @lins;
    foreach my $node (@$top_nodes) {
        my ($tag, $segbody, @extra) = @$node;
        next unless ok($tag,     "EDI segment tag received (not empty)");
        next unless ok($segbody, "EDI segment '$tag' has body");
        if ($tag eq 'UNH') {
            return unless ok( ($segbody->{S009}->{'0065'} and $segbody->{S009}->{'0065'} eq $type), 
                "EDI $tag/S009/0065 ('" . ($segbody->{S009}->{'0065'} || '') . "') matches message type ($type)");
            ok( ($segbody->{S009}->{'0051'} and $segbody->{S009}->{'0051'} eq 'UN'), 
                "EDI segment $tag/S009/0051 designates 'UN' as controlling agency"
            );
        } elsif ($tag eq 'BGM') {
            my ($bgm, $msgtype, $codelist);
            $debug and print "BGM_dump: ", Dumper($segbody);
            ok( $bgm = Business::EDI::Segment::BGM->new($segbody), "Business::EDI::Segment::BGM->new");
            ok( $codelist = $bgm->part4343, "Business::EDI::Segment::BGM->new(...)->seg4343->codelist");
            ok( $msgtype = Business::EDI->codelist('ResponseTypeCode', $segbody->{4343}),
                sprintf("Business::EDI->codelist('ResponseTypeCode', \$X): $tag/4343 Response Type Code '%s' recognized", ($segbody->{4343} || ''))
            );
            is($msgtype->label, $bgm->seg4343->label, "Different constructor paths, same label");
            is($msgtype->value, $bgm->seg4343->value, "Different constructor paths, same value");
            is($msgtype->desc,  $bgm->seg4343->desc,  "Different constructor paths, same description"); 
            my $seg4343 = $bgm->seg4343;
            $debug and print 'ResponseTypeCode dump: ', Dumper($msgtype);
            $debug and print 'bgm->seg4343     dump: ', Dumper($seg4343);
            note(sprintf "Business::EDI->codelist('ResponseTypeCode', \$X): $tag/4343 response type: %s - %s (%s)", $msgtype->value, $msgtype->label, $msgtype->desc);
            note(sprintf "Business::EDI::Segment::BGM->new(...)->seg4343\ : $tag/4343 response type: %s - %s (%s)", $seg4343->value, $seg4343->label, $seg4343->desc);
            my $fcn = $bgm->seg1225;
            return unless ok( $fcn, 
                sprintf "EDI $tag/1225 Message Function Code '%s' is recognized", ($segbody->{1225} || ''));
        } elsif ($tag =~ /^SG\d+$/) {
            my $lin;
            ok($lin = $edi->segment_group("ORDERS/$tag", $segbody), "ORDERS/$tag object via \$edi->segment_group");
            $tag eq 'SG26' or next;     # we'll do the above constructor test for all, but the rest are for SG26
            $lin or next;
            # my @qty = $lin->xpath('all_QTY');   # $lin->all_QTY doesn't work
            # is(scalar(@qty), 5, "all_QTY returns 5 QTY objects") or print join(" ", $lin->part_keys), "\n";;
            my @chunks = @{$segbody};
            my $count = scalar(@chunks);
            foreach (@chunks) {
                my $label = $_->[0];
                my $body  = $_->[1];
                $label eq 'SG31' or next;
                foreach my $sg31 (@$body) {
                    my $one = $sg31->[0];
                    my $two = $sg31->[1];
                    $one eq 'RFF' or next;
                    my $obj;
                    ok($obj = $edi->segment('RFF', $two),    "ORDERS/$tag/$label/$one converts to an object");
                    my $compare = Business::EDI::Segment::RFF->new($two);
                    $compare->spec($obj->spec);  # force the spec to be the same
                    is_deeply($compare, $obj, "ORDERS/$tag/$label/$one matching constructors");
                    
                    ok($obj->partC506->seg1153,              "ORDERS/$tag/$label/$one/C506/seg1153 exists");
                    is($obj->partC506->seg1153->value, 'LI', "ORDERS/$tag/$label/$one/C506/seg1153 has value ('LI')") or print Dumper($obj->partC506->seg1153);
                    ok($obj->part1153,                       "ORDERS/$tag/$label/$one/part1153 exists (collapsable Composite)") or print "OBJ: " . Dumper($obj);
                    is($obj->part1153->value,          'LI', "ORDERS/$tag/$label/$one/part1153 has value ('LI') (collapsable Composite)") or print Dumper($obj->seg1153);
                }
            }
            # print Dumper($segbody); exit;
            push @lins, \@chunks;
        } else {
            # note("EDI: ignoring segment '$tag'");
        }
    }
    return @lins;
}

ok($perl = ordrsp_data(), "DATA handle read and decode" );
$perl or die "DATA handle not read and decoded successfully";

$Data::Dumper::Indent = 1;

ok($perl->{body},      "EDI interchange body");
ok($perl->{body}->[0], "EDI interchange body is a populated arrayref!");
is(scalar(@{$perl->{body}}), 3, "EDI interchange body has 3 messages");

my @li = ();
my $i = 0;
foreach my $part (@{$perl->{body}}) {
    $i++;
    next unless ok((ref $part and scalar keys %$part), "EDI interchange message $i has structure.");
    foreach my $key (keys %$part) {
        next unless ok($key eq 'ORDRSP', "EDI interchange message $i type == ORDRSP");
        my @li_chunk = parse_ordrsp($part->{$key});
        note("EDI $key parsing returned " . scalar(@li_chunk) . " line items");
        push @li, @li_chunk;
    }
}


my @rffs = ();
my @qtys = ();
foreach (@li) {
   my $count = scalar(@$_);
   is($count, 8, "->{SG26} has 8 pieces: ");
   $debug and note("\t\t" . join ' ', map {$_->[0]} @{$_});
   for (my $i = 0; $i < $count; $i++) {
        my $label = $_->[$i]->[0];
        my $body  = $_->[$i]->[1];
        $label eq 'QTY'  and push @qtys, $body;
        $label eq 'SG31' and push @rffs, $body->[0]->[1];
    }
}

is(scalar(@li  ),  58, " 58 LINs found");
is(scalar(@qtys), 174, "174 QTYs found");
is(scalar(@rffs),  58, " 58 RFFs found (inside LINs)");

# We want: RFF > C506 > 1154 where 1153 = LI
foreach my $rff (@rffs) {
    my $obj = $edi->segment('RFF', $rff);
    ok($obj, '$edi->segment("RFF", ...)');
    # print Dumper ($obj);
    $obj->C506() or next;
    $debug and print "RFF/C506     parts: ", join(", ", $obj->C506->part_keys), "\n";
    foreach my $key ($obj->C506->part_keys) {
        my $subrff = $obj->C506->part($key) or next;
        ok($subrff, "RFF/C506/$key object (via part method)");
        $debug and note("subrff->code: " . $subrff->code);
        $debug and print "RFF/C506/$key parts: ", join(", ", $subrff->part_keys), "\n";
        $debug and print "RFF/C506/$key ", Dumper ($subrff);
        foreach ($subrff->part_keys) {
            ok($subrff->part($_), "RFF/C506/$key/$_");
        }
        # my $x = Business::EDI::DataElement->new($subrff->code, $rff->{$key}->{$subrff->code});
        # my $x = Business::EDI::DataElement->new($subrff->code, $subrff->part($_));
        # print "$_ ", $x->label, " ", $x->value, " ";
        # ok($x, "Business::EDI::DataElement->new(" . $subrff->code() . ", ...)");
    }
}
note("done");

