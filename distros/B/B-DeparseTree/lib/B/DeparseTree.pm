package B::DeparseTree;

use rlib '.';
use strict;
use vars qw(@ISA $VERSION);

$VERSION = '3.0.0';

use Config;
my $is_cperl = $Config::Config{usecperl};

my $module;
if ($] >= 5.016 and $] < 5.018) {
    # 5.16 and 5.18 are the same for now
    $module = "P518";
} elsif ($] >= 5.018 and $] < 5.020) {
    $module = "P518";
} elsif ($] >= 5.020 and $] < 5.022) {
    $module = "P520";
} elsif ($] >= 5.022 and $] < 5.024) {
    $module = "P522";
} elsif ($] >= 5.024 and $] < 5.026) {
    $module = "P524";
} elsif ($] >= 5.026) {
    $module = "P526";
} else {
    die "Can only handle Perl 5.16..5.26";
}

$module .= 'c' if $is_cperl;

require "B/DeparseTree/${module}.pm";
*compile = \&B::DeparseTree::Common::compile;

require Exporter;

@ISA = ("Exporter", "B::DeparseTree::$module");
our @EXPORT = qw(is_cperl);

1;

__END__
