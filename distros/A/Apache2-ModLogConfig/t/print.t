#!perl

use strict;
use Apache::Test;
use Apache::TestRequest 'GET_BODY_ASSERT';
use Apache::TestUtil qw/t_start_file_watch t_read_file_watch
			t_finish_file_watch/;

plan tests=>2;

sub t_file_watch_for {
    my ($name, $re, $timeout)=@_;
    local $/="\n";
    $re=qr/$re/ unless ref $re;
    $timeout*=10;
    while($timeout>=0) {
	my $line=t_read_file_watch $name;
	unless( defined $line ) { # EOF
	    select undef, undef, undef, 0.1;
	    $timeout--;
	    next;
	}
	return $line if $line=~$re;
    }
    return;
}

t_start_file_watch 'perl.log';
my $body=GET_BODY_ASSERT "/print";

ok $body eq '1 0';
ok t_file_watch_for 'perl.log', qr/hier/, 3;
