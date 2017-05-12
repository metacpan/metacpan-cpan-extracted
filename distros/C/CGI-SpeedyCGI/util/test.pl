BEGIN {
    $SIG{PIPE} = 'IGNORE';
}
use strict;
use CGI qw/:compile/;
my $q = CGI->new;
use vars qw($num);

print 'p=', $q->param('p'), "\n";
