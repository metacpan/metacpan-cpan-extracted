use strict;
use warnings;
use Data::Dumper;
use IO::File;
use Grammar;
use Parse::RecDescent;

my $r = new Parse::RecDescent ( $grammar )  or die ;

sub check_file {
    my ($service, $remote, $file)  = @_;
    open (my $fh , $file)   or return ;
    my $ret;

    ## TODO:  FEED the entire file, not just one line at a time
    while (<$fh> )  {
	 next if /^[#\s]+/;
	 last  if $ret =  $r->Start( $_ , 0 , $service , $remote ) ;
    }
    $ret;
}


sub check {
    my ($service, $remote, $dir) = @_ ;

    (check_file  $service,  $remote,   $dir ||'.' . "/hosts.allow" )      ? 'allow' 
	 : (check_file  $service,  $remote,   $dir ||'.' . "/hosts.deny") ? undef
		 : 'allow';
}


1;
__END__
