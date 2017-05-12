use CGI;
$COUNTER++;

BEGIN { $SIG{USR1} = 'IGNORE'; $SIG{TERM} = sub {"COMPILE TERM"} }

$SIG{USR1} = 'IGNORE';
$SIG{TERM} = sub {"RUN TERM"};

my $q = CGI->new;

chomp(my $greeting = <DATA>);

print $q->header, $greeting, scalar $q->param('name'), " counter=$COUNTER";

exit $q->param('exit_status') || 0;

__DATA__
Hello 
