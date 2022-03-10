package App::Greple::wordle::util;

use v5.14;
use warnings;

use Data::Dumper;

use Exporter 'import';
our @EXPORT_OK = qw(uniqword);

sub uniqword {
    state @re;
    my $len = length $_[0] or die;
    my $re = $re[$len] //=
	join('', '^(.)',
	     map {
		 sprintf "(%s.)", join '', map "(?!\\$_)", 1 .. $_;
	     } 1 .. $len - 1);
    grep /^$re/i, @_;
}

1;
