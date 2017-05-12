#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;
use FileHandle;

my $exec;
my $codefile;
my $parser = '';
my $writer = '';
my %trap = ();
my $help;
GetOptions(
	   "help|h"=>\$help,
	  );
if ($help) {
    system("perldoc $0");
    exit 0;
}


my $el = shift;
my $total = 0;
while (my $fn = shift @ARGV) {
    my $n = 0;
    my $H = Data::Stag->makehandler($el=>sub {
					$n++;
					return;
				    });
    my @pargs = (-file=>$fn, -format=>$parser, -handler=>$H);
    if ($fn eq '-') {
	if (!$parser) {
	    $parser = 'xml';
	}
	@pargs = (-format=>$parser, -handler=>$H, -fh=>\*STDIN);
    }
    my $nu = Data::Stag->parse(@pargs);
    print $nu->sxpr;
    print "$fn: $n\n";
    $total+=$n;
}
print "total:$total\n";

__END__

=head1 NAME

  stag-elcount

=head1 SYNOPSIS

  stag-elcount person/name myfile.xml

=head1 DESCRIPTION

gets a count of the number of elements

=over ARGUMENTS


=back

=cut
