#!perl

use strict;
use Apache::Test;
use Apache::TestRequest 'GET_BODY_ASSERT';
use Apache::TestUtil qw/t_start_file_watch t_read_file_watch
			t_finish_file_watch/;

plan tests=>7;

sub t_file_watch_for ($$$) {
    my ($name, $re, $timeout)=@_;
    local $/="\n";
    $re=qr/$re/ unless ref $re;
    $timeout*=10;
    my $buf='';
    while($timeout>=0) {
	my $line=t_read_file_watch $name;
	unless( defined $line ) { # EOF
	    select undef, undef, undef, 0.1;
	    $timeout--;
	    next;
	}
	$buf.=$line;
	next unless $buf=~/\n$/; # incomplete line

	# found a complete line
	$line=$buf;
	$buf='';

	return $line if $line=~$re;
    }
    return;
}

t_start_file_watch 'perl.log';
my $body=GET_BODY_ASSERT "/redir", content=>scalar(("x" x 60)."\n") x 40;
ok $body eq scalar(("x" x 60)."\n") x 40;

my $line=t_file_watch_for 'perl.log', qr/^\d+\s\d+\s\d+\s\d+$/, 3;
my ($in, $init, $redir, $out)=split ' ', $line;

ok $in>61*40;
ok $out>61*40;
ok $init==1;
ok $redir==0;

$line=t_file_watch_for 'perl.log', qr/^>>>/, 3;
(undef, my ($in1, $out1))=split ' ', $line;

ok $in==$in1;
ok $out==$out1;
