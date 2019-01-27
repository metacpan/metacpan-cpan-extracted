package App::Perlambda::Util;

use strict;
use warnings;
use utf8;

use Getopt::Long qw(:config no_ignore_case posix_default gnu_compat permute);

use parent qw(Exporter);

our @EXPORT_OK = qw(
    parse_options
    get_current_perl_version
);

sub parse_options {
    my ($args, @spec) = @_;
    Getopt::Long::GetOptionsFromArray($args, @spec);
}

sub get_current_perl_version {
    if ($] !~ /\A5[.][0-9]([0-9]{2})/) {
        die "unsupported perl version: $]\n";
    }
    return "5.$1";
}

1;

