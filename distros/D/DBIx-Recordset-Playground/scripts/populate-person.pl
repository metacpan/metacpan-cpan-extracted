require 'dbconn.pl';
use DBI;

use Data::Dumper;


my @data = (
	    [qw(bill   25 ru)],
	    [qw(bob    30 de)],
	    [qw(bob    30 ca)],
	    [qw(bob    30 nz)],
	    [qw(jane   18 us)],
	    [qw(jane   48 dk)],
	    [qw(jane   22 nw)],
	    [qw(lazlo  40 hu)],
	    [qw(tony   40 uk)],
	    [qw(tony   21 yg)],
	    [qw(tony   22 ie)]
	    );

### no insert whole array ref huh?

for (@data) {

    my %h = (
	     name      => $_->[0],
	     age       => $_->[1],
	     country   => $_->[2]
	     );

    warn Dumper(\%h);

  DBIx::Recordset -> Insert ({%h,
			      ('!DataSource'   =>  dbh(),
			       '!Table'        =>  'person')});
}
