package UChelp;

#use base 'Exporter';
use Test::More;

BEGIN {
    use Exporter();
    @ISA = qw(Exporter);
    @EXPORT=qw(&dumpstr &utf_eq_ok);
}
use strict;
use warnings;

sub dumpstr($)
{
	my $str=shift;
	if (defined $str) {
		my ($f,$u)=utf8::is_utf8($str) ? ('\\x{%04X}','utf8') : ('\\x%02X','bytes');
		(my $d=$str)=~s/([^\x20-\x7E])/sprintf($f,ord $1)/gse;
		return sprintf("[%s, %i chars] '%s'",$u,length($str),$d);
	} else {
		return 'undef';
	}
}

sub utf_eq_ok($$$)
{
	my ($a,$b,$msg)=@_;
	
	# I want to call Test::More routines in a way that makes this package invisible,
	# and shows the failed or passed line of the caller instead.
	# So I manipulate @_ and use goto \&func.

	(!defined($a) and !defined($b)) and return pass($msg);
	unless (defined($a) and defined($b)) {
		diag(defined($a) ? "Expected undef, got '$a'" : "Got undef, expected '$b'");			
		@_=($msg);
		goto \&fail;
		# see below for the reason of goto
	}

	if ($a eq $b) {
		@_=($msg);
		goto \&pass;
	}

	if ("\x{2a36}$a" eq "\x{2a36}$b") { # implicit upgrade to UTF8
		@_=($msg);
		goto \&pass;
	}

	@_=(dumpstr($a),'eq',dumpstr($b),$msg);
	goto \&cmp_ok;
}

1;
