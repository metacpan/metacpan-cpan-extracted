package TestHttpd;
use strict;
use warnings;
use lib qw(t lib);
use parent 'Apache::Defaults';
use MockHttpd;
use File::Temp qw(tempfile);

sub new {
    my $class = shift;
    local %_ = @_;
    if (my $env = $_{environ}) {
	my ($fh, $name) = tempfile();
	while (my ($k,$v) = each %$env) {
	    $v =~ s/(["\\])/\\$1/g;
	    print $fh "$k=\"$v\"\n";
	    print $fh "export $k\n";
	}
	close $fh;
	$_{environ} = $name;
    }
    $class->SUPER::new(server => "$^X ".$INC{'MockHttpd.pm'}, %_);
}

1;
