package App::optex::debug;

=head1 NAME

debug - debug module for optex

=head1 SYNOPSIS

optex -Mdebug

=cut

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my %switch = (
    getopt => \$Getopt::EX::Loader::debug,
    debug  => \$main::debug,
    );

for my $key (keys %switch) {
    ${$switch{$key}} = 1;
}

my %dump = (
    loader => \$main::rcloader,
    );

sub dump {
    $Data::Dumper::Indent = 1;
    while (my($key, $val) = splice @_, 0, 2) {
	next unless $val;
	if ($key eq 'all') {
	    @_ = map { ($_ => 1) } keys %dump;
	    next;
	}
	if (not exists $dump{$key}) {
	    warn __PACKAGE__ . ": Unknown key: $key\n";
	    next;
	}
	local $_ = Dumper $dump{$key};
	$_ = compact($_);
	s/^\$VAR1/\$$key/;
	print;
    }
}

sub compact {
    local $_ = shift;
    my $re_str = qr/'[^']*'/;
    my $re_strlist = qr/\[ \s* (?: $re_str , \s*)* $re_str \s* \]/x;
    s/($re_strlist)/_compact($1)/ge;
    $_;
}

sub _compact {
    local $_ = shift;
    s/ ,  \s+ '     /, '/xg;
    s/ ([\[\{]) \s+ /$1 /xg;
    s/ \s+ ([\]\}]) / $1/xg;
    $_;
}

1;
