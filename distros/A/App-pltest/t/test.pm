use warnings;
use strict;

use Test::Simple tests => $::tests;
use IPC::Open3;

sub slurp($) {
    my( $ret, $n ) = '';
    while( $n = sysread $_[0], my $txt, 1024 ) {
	$ret .= $txt;
    }
    unless( defined $n ) {
	$ret .= "sysread: $!";
    }
    $ret;
}

# run pltest, expect $_
sub pltest(@) {
    my @cmd = ($^X, '-W', '../pltest', @_);
    if( $^O =~ /^MSWin/ ) {
	require Win32::ShellQuote;
	$cmd[2] = '..\pltest';
	@cmd = Win32::ShellQuote::quote_native( @cmd );
    }
    my $none = '';
    my $pid = open3( $none, my $fh, '', @cmd );
    my $ret = slurp $fh;

    ok $ret eq $_,
      join ' ', 'pltest', map /[\s*?()[\]{}\$\\'";|&]|^$/ ? "'$_'" : $_, @_
      or print "got: '$ret', expected: '$_'\n";
    waitpid $pid, 0;
}

# run pltest, expect shift
sub pl_e($@) {
    local $_ = shift;
    &pltest;
}

# run pltest, expect $_ altered by shift->()
sub pl_a(&@) {
    local $_ = $_;
    shift->();
    &pltest;
}

1;
