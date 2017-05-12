#!/usr/bin/perl

use Test::More;
use Config::TinyDNS;

my $Filters = Config::TinyDNS::_filter_hash;
%$Filters = ();

*filt = \&Config::TinyDNS::filter_tdns_data;

my $data = <<'DATA';
=foo.com:1.2.3.4
+bar.org:2.3.4.5:::lo
# comment

# comment:with:colons
DATA

is filt($data), <<WANT,                 "no filters";
=foo.com:1.2.3.4
+bar.org:2.3.4.5:::lo
# comment
# comment:with:colons
WANT

is filt($data, sub { return }), "",     "empty filter";

my @data;
my $record = sub { push @data, [$_, @_]; return };

filt($data, $record);
is_deeply \@data, [
    [qw/= foo.com 1.2.3.4/],
    [qw/+ bar.org 2.3.4.5/, "", "", "lo"],
    ["#", " comment"],
    ["#", " comment:with:colons"],
],                                      "filter passes correct args";

my $null = sub { [$_, @_] };
my $uc   = sub { [$_, map uc, @_] };

is filt($data, $null), <<WANT,          "null filter";
=foo.com:1.2.3.4
+bar.org:2.3.4.5:::lo
# comment
# comment:with:colons
WANT

is filt($data, $uc), <<WANT,            "uc filter";
=FOO.COM:1.2.3.4
+BAR.ORG:2.3.4.5:::LO
# COMMENT
# COMMENT:WITH:COLONS
WANT

@data = ();
filt($data, $uc, $record);
is_deeply \@data, [
    [qw/= FOO.COM 1.2.3.4/],
    [qw/+ BAR.ORG 2.3.4.5/, "", "", "LO"],
    ["#", " COMMENT"],
    ["#", " COMMENT:WITH:COLONS"],
],                                      "second filter gets correct args";

is filt($data, $uc, $null), <<WANT,     "uc -> null filter";
=FOO.COM:1.2.3.4
+BAR.ORG:2.3.4.5:::LO
# COMMENT
# COMMENT:WITH:COLONS
WANT

{
    local $_ = "splurgle";
    filt($data, $uc);
    is $_, "splurgle",                  "filter doesn't corrupt \$_";
}

$Filters->{uc} = $uc;

is filt($data, "uc"), <<WANT,           "named filter";
=FOO.COM:1.2.3.4
+BAR.ORG:2.3.4.5:::LO
# COMMENT
# COMMENT:WITH:COLONS
WANT

$Filters->{args} = \sub { $_[0] eq "uc" ? $uc : $null };
is filt($data, ["args", "uc"]) . filt($data, ["args", "null"]), 
    <<WANT,                             "named filter w/args";
=FOO.COM:1.2.3.4
+BAR.ORG:2.3.4.5:::LO
# COMMENT
# COMMENT:WITH:COLONS
=foo.com:1.2.3.4
+bar.org:2.3.4.5:::lo
# comment
# comment:with:colons
WANT

done_testing;
