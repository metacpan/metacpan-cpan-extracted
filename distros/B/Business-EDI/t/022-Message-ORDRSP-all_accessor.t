#!/usr/bin/perl
#

use strict; use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('Business::EDI');
    use_ok('Business::EDI::Test', qw/ordrsp_data/);
}

use vars qw/%code_hash $perl/;

my $debug = $Business::EDI::debug = @ARGV ? shift : 0;

my $edi = Business::EDI->new('d08a') or die "Business::EDI->new('d08a') failed";

sub parse_ordrsp {
    my ($top_nodes) = @_;
    my $type = 'ORDRSP';
    my $ordrsp;
    ok($ordrsp = $edi->detect_version($top_nodes), "EDI $type object via \$edi->detect_version");
    my @sg26 = $ordrsp->all_SG26;
    is(scalar(@sg26), 18, "\$ordrsp->all_SG26 returns 18 SG26 objects");
}

ok($perl = ordrsp_data(), "DATA handle read and decode" );
$perl or die "DATA handle not read and decoded successfully";

$Data::Dumper::Indent = 1;

foreach my $part (shift @{$perl->{body}}) { # just do the first one
    foreach my $key (keys %$part) {
        next unless ok($key eq 'ORDRSP', "EDI interchange message type == ORDRSP");
        parse_ordrsp($part->{$key});
    }
}

note("done");

