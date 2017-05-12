#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use constant PRINTF => '%y\t%m\t%M\t%n\t%U\t%u\t%G\t%g\t%s\t%TY-%Tm-%Td '.
					'%TH:%TM\t%T@\t%CY-%Cm-%Cd %CH:%CM\t%C@\t%h\t%f\t%p\n';
use constant PRINTF_FIELDS => qw(type mode perms links uid owner gid
	group size mtime unixmtime ctime unixctime path filename absfile);

my %data;

my $cmd = sprintf('find . -printf "%s"',PRINTF);
open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!";
while (local $_ = <PH>) {
	chomp;
	my %tmp;
	@tmp{PRINTF_FIELDS()} = split(/\t/,$_);
	$data{$tmp{absfile}} = \%tmp;
}
close(PH) || warn "Unable to close file handle PH for command '$cmd': $!";

print Dumper(\%data);
exit;

__END__

