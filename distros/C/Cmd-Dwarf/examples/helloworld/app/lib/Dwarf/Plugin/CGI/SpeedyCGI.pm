# Copyright (c) 2017  S2 Factory, Inc.  All rights reserved.
#
# CGI::SpeedyCGI 環境では、Perl の END ブロックは初回実行時のみにしか
# 呼び出されないので、END ブロックに依存しているモジュールは個別に対処
# する必要がある。
#
# 今のところ File::Temp の cleanup() 処理だけ。

package Dwarf::Plugin::CGI::SpeedyCGI;
use Dwarf::Pragma;
use Dwarf::Util qw/installed/;

sub init {
	my ($class, $c, $conf) = @_;
	return if not installed("CGI::SpeedyCGI");

	my $sp = CGI::SpeedyCGI->new;
	return if not $sp->i_am_speedy;

	$sp->register_cleanup(\&cleanup);
}

sub cleanup {
	# すでに use されている場合のみ明示的に cleanup() を呼び出す。
	if (0 < grep { m|File/Temp\.pm| } keys %INC) {
		# warn "Call File::Temp::cleanup() instead of END block.";
		File::Temp::cleanup();
	}
}

1;
