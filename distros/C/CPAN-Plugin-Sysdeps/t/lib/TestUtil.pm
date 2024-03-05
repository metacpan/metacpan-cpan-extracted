package
    TestUtil;

use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(require_CPAN_Distribution skip_on_darwin_without_homebrew skip_on_os);

sub require_CPAN_Distribution () {
    if (!eval { require CPAN::Distribution; 1 }) {
	require CPAN;
    }
}

sub skip_on_darwin_without_homebrew () {
    if ($^O eq 'darwin' && !-x '/usr/local/bin/brew') {
	Test::More::plan(skip_all => 'No homebrew installed here');
    }
}

sub skip_on_os ($;$) {
    my($os, $message) = @_;
    if ($^O eq $os) {
	$message ||= "Does not work on $os";
	Test::More::plan(skip_all => $message);
    }
}

1;
