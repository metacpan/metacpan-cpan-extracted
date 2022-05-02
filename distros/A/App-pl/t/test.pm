use warnings;
use strict;

use Test::Simple tests => $::tests;
use IPC::Open3;

system 'env >/run/shm/env; p -3i > /run/shm/p';
my $windows = $^O =~ /^MSWin/;

sub slurp($) {
    my( $ret, $n ) = '';
    while( $n = sysread $_[0], my $txt, 1024 ) {
	$ret .= $txt;
    }
    unless( defined $n ) {
	$ret .= "sysread: $!";
    }
    $ret =~ tr/\r//d if $windows;
    $ret;
}

# remember outermost caller, so ok() will show original location
my $at;
sub at {
    $at //= sprintf '#line %d "%s"', (caller 1)[2, 1];
}

# name and result to compare with $_
sub test($$) {
    at;
    my( $name, $ret ) = @_;
    if( $ret eq $_ ) {
	ok 1, $name;
    } elsif( $ENV{HARNESS_ACTIVE} ) { # make cpan tester show result
	$ret =~ s/\e/\\e/g;
	s/\e/\\e/g;
	eval $at . q{
	  ok 0, "$name'\ngot: '$ret'\nexpected: '$_";
	};
    } else {
	eval $at . q{
	  ok 0, $name;
	};
	print qq{#   got: "$ret"\n#   expected: "$_"\n\n}
    }
    undef $at;
}

# run pl, expect $_
sub pl(@) {
    at;
    my @cmd = ($^X, '-W', '../pl', @_);
    my $name = join ' ', 'pl', map /[\s*?()[\]{}\$\\'";|&]|^$/ ? "'$_'" : $_, @_;
    if( $windows ) {
	require Win32::ShellQuote;
	$cmd[2] = '..\pl';
	@cmd = $name = Win32::ShellQuote::quote_native( @cmd );
    }
    my $none = '';
    my $pid = open3( $none, my $fh, '', @cmd );
    test $name,
      slurp $fh;
    waitpid $pid, 0;
}

# run pl, expect shift
sub pl_e($@) {
    at;
    local $_ = shift;
    &pl;
}

# run pl, expect $_ altered by shift->()
sub pl_a(&@) {
    at;
    local $_ = $_;
    shift->();
    &pl;
}

1;
