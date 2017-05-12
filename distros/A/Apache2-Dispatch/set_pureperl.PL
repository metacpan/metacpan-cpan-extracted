use strict;
use warnings FATAL => 'all';

use File::Spec::Functions;

my $pureperl=shift(@ARGV);

my $dispatch=catfile(qw(lib Apache Dispatch.pm));

my $fh;
open ($fh,$dispatch) || die "cannot read Dispatch.pm: $!";
my $code=join('',<$fh>);
close $fh;

chmod(0755,$dispatch);

$code =~ s{(\$Apache::Dispatch::PUREPERL\=)\d}{$1$pureperl};

open ($fh,">", $dispatch) || die "cannot write to Dispatch.pm: $!";
print $fh $code;
close $fh;

