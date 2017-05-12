#!/usr/bin/perl
#

use strict; use warnings;

use Test::More tests => 237;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('Business::EDI');
    use_ok('Business::EDI::Test', qw/ordrsp_data/);
}

use vars qw/%code_hash $perl/;

my $debug = $Business::EDI::debug = @ARGV ? shift : 0;

my %sg_counts = (
    all_SG1  => 1,
    all_SG3  => 3,
    all_SG8  => 1,
    all_SG26 => 18,
    line_detail   => 18,
   "all_SG26/LIN" => 18,
   "line_detail/line_reference" => 18,
   "line_detail/LIN"            => 18,
   "line_detail/all_QTY"        => 54,
   "line_detail/all_QTY/6063"   => 54,
   "all_SG26/all_LIN/1229"      => 18,
   "all_SG26/all_QTY"           => 54,
   "all_SG26/all_QTY/C186"      => 54,
   "all_SG26/all_QTY/C186/6063" => 54,
   "all_SG26/all_QTY/6063"      => 54,
);

my @qs = (
    [ 21 => 4 ], 
    [ 12 => 4 ], 
    [ 85 => 0 ], 
    [ 21 => 1 ], 
    [ 12 => 1 ], 
    [ 85 => 0 ], 
    [ 21 => 5 ], 
    [ 12 => 5 ], 
    [ 85 => 0 ], 
    [ 21 => 2 ], 
    [ 12 => 0 ], 
    [ 83 => 2 ], 
    [ 21 => 4 ], 
    [ 12 => 4 ], 
    [ 85 => 0 ], 
    [ 21 => 3 ], 
    [ 12 => 3 ], 
    [ 85 => 0 ], 
    [ 21 => 4 ], 
    [ 12 => 4 ], 
    [ 85 => 0 ], 
    [ 21 => 4 ], 
    [ 12 => 4 ], 
    [ 85 => 0 ], 
    [ 21 => 5 ], 
    [ 12 => 5 ], 
    [ 85 => 0 ], 
    [ 21 => 3 ], 
    [ 12 => 3 ], 
    [ 85 => 0 ], 
    [ 21 => 6 ], 
    [ 12 => 6 ], 
    [ 85 => 0 ], 
    [ 21 => 3 ], 
    [ 12 => 3 ], 
    [ 85 => 0 ], 
    [ 21 => 4 ], 
    [ 12 => 4 ], 
    [ 85 => 0 ], 
    [ 21 => 5 ], 
    [ 12 => 5 ], 
    [ 85 => 0 ], 
    [ 21 => 3 ],
    [ 12 => 3 ],
    [ 85 => 0 ],
    [ 21 => 4 ],
    [ 12 => 4 ],
    [ 85 => 0 ],
    [ 21 => 3 ],
    [ 12 => 0 ],
    [ 83 => 3 ],
    [ 21 => 4 ],
    [ 12 => 4 ],
    [ 85 => 0 ]
);

sub parse_ordrsp {
    my $ordrsp;
    ok($ordrsp = Business::EDI::Message->new(shift), "EDI object via Business::EDI::Message->new");
    $ordrsp or return;

    my $basic = @_ ? shift : 0;

    foreach (qw# UNH BGM DTM UNS CNT UNT UNH/0062 UNH/S009 #) {    # SG1 SG3 SG8
        ok($ordrsp->xpath($_), "self->xpath('$_')");
    }
    
    if (! $basic) {
        foreach (sort {($sg_counts{$a} <=> $sg_counts{$b}) || $a cmp $b} keys %sg_counts) {
            my @hits;
            # /line_reference/ and $Business::EDI::debug = 1;
            ok(@hits = $ordrsp->xpath($_),    "self->xpath('$_')");
            is(scalar(@hits), $sg_counts{$_}, "self->xpath('$_') returns expected number of elements ($sg_counts{$_})");
        }
        # $Business::EDI::debug = 1;
        foreach ($ordrsp->xpath("all_SG26/all_QTY/C186")) {
            my $sixty63 = $_->part('6063');
            my $sixty60 = $_->part('6060');
            my @pair = @{(shift @qs)};
            is($sixty63->value, $pair[0], sprintf("%40s", $sixty63->label) . " (code $pair[0])");
            is(($sixty60 ? $sixty60->value : 0) || 0, $pair[1], sprintf("%40s", $sixty63->label) . " (code $pair[0]): $pair[1]");
            # printf "%50s (%2d): %s\n", $sixty63->label, $sixty63->value, ($sixty60 ? $sixty60->value : '--');
        }
    }

    ok($ordrsp->xpath("all_SG26/all_QTY/C186/6063"),          q[self->xpath('all_SG26/all_QTY/C186/6063')]);
    ok($ordrsp->xpath("line_detail/all_QTY"),                 q[self->xpath('line_detail/all_QTY')]);
    ok($ordrsp->xpath("line_detail/all_QTY/6063"),            q[self->xpath('line_detail/all_QTY/6063')]);
    ok($ordrsp->xpath("line_detail/line_reference"),          q[self->xpath('line_detail/line_reference')]);
    ok($ordrsp->xpath("line_detail/line_reference/RFF"),      q[self->xpath('line_detail/line_reference/RFF')]);
    ok($ordrsp->xpath("line_detail/line_reference/RFF/1154"), q[self->xpath('line_detail/line_reference/RFF/1154')]);

    is_deeply([($ordrsp->xpath("all_SG26/all_QTY/C186/6063"))], 
              [($ordrsp->xpath("all_SG26/all_QTY/6063"     ))], 
              "self->xpath('all_SG26/all_QTY/C186/6063') === self->xpath('all_SG26/all_QTY/6063')");

    is_deeply([($ordrsp->xpath("line_detail/all_QTY"       ))], 
              [($ordrsp->xpath("all_SG26/all_QTY"          ))], 
              "self->xpath('line_detail/all_QTY')        === self->xpath('all_SG26/all_QTY')");

    is_deeply([($ordrsp->xpath("line_detail/all_QTY/6063"  ))], 
              [($ordrsp->xpath("all_SG26/all_QTY/6063"     ))], 
              "self->xpath('line_detail/all_QTY/6063')   === self->xpath('all_SG26/all_QTY/6063')");

    is_deeply([($ordrsp->xpath("line_detail/line_reference"))], 
              [($ordrsp->xpath("all_SG26/line_reference"     ))], 
              "self->xpath('line_detail/line_reference') === self->xpath('all_SG26/line_reference')");

    ok($ordrsp->xpath("line_detail"),                    q[self->xpath('line_detail')]                   );
    ok($ordrsp->xpath("line_detail/SG31"),               q[self->xpath('line_detail/SG31')]              );
    ok($ordrsp->xpath("line_detail/SG31/RFF"),           q[self->xpath('line_detail/SG31/RFF')]          );
    ok($ordrsp->xpath("line_detail/SG31/RFF/C506"),      q[self->xpath('line_detail/SG31/RFF/C506')]     );
    ok($ordrsp->xpath("line_detail/SG31/RFF/C506/1154"), q[self->xpath('line_detail/SG31/RFF/C506/1154')]);

    is_deeply([($ordrsp->xpath("line_detail/line_price"))], 
              [($ordrsp->xpath("all_SG26/line_price"     ))], 
              "self->xpath('line_detail/line_price')     === self->xpath('all_SG26/line_price')");
    ok($ordrsp->xpath_value("line_detail/line_reference/RFF/1154"), q[self->xpath_value('line_detail/line_reference/RFF/1154')]);

    
    if (! $basic) {
        my @val_1154 = $ordrsp->xpath_value("line_detail/line_reference/RFF/1154");
        subtest q[self->xpath_value('line_detail/line_reference/RFF/1154')] => sub {
            plan tests => 18;
            foreach (1..19) {
                @val_1154 or last;
                $_ == 5 and next;   # Test data skips 5
                my $rff = shift @val_1154;
                $rff =~ s#^.*/##;
                is($_, $rff, 'self->xpath_value("line_detail/line_reference/RFF/1154") ' . $_);
            }
        };

        my @vals = $ordrsp->xpath_value("line_detail/all_QTY/6063");
        subtest "self->xpath_value('line_detail/all_QTY/6063')" => sub {
            plan tests => 54;
            foreach ($ordrsp->xpath("line_detail/all_QTY/6063")) {
                my $val = shift(@vals);
                is($_->value, $val, "self->xpath_value('line_detail/all_QTY/6063') ($val)");
            }
        };
    }

    is($ordrsp->xpath_value('UNH/S009/0051'), 'UN',     "self->xpath_value('UNH/S009/0051')");
    is($ordrsp->xpath_value('UNH/S009/0052'), 'D',      "self->xpath_value('UNH/S009/0052')");
    is($ordrsp->xpath_value('UNH/S009/0065'), 'ORDRSP', "self->xpath_value('UNH/S009/0065')");
    is($ordrsp->xpath_value('UNH/S009/0054'), '96A',    "self->xpath_value('UNH/S009/0054')");
    # print Dumper($ordrsp->xpath('UNH/S009/0065'));
    # $debug and $debug > 1 and print Dumper $ordrsp;
}

ok($perl = ordrsp_data(), "DATA handle read and decode" );
$perl or die "DATA handle not read and decoded successfully";

$Data::Dumper::Indent = 1;

my $i = 0;

# We only have the data mapped out for the first message, so the other two use "basic" tests
foreach my $part (@{$perl->{body}}) {
    foreach my $key (keys %$part) {
        next unless ok($key eq 'ORDRSP', "EDI interchange message type == ORDRSP");
        parse_ordrsp($part->{$key}, $i);
        $i++;
    }
}

note("done");

