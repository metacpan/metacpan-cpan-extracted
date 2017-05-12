package CGI::Application::Demo::Basic::Util::LogDispatchDBI;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use base qw/Log::Dispatch::DBI CGI::Application::Demo::Basic::Base/;
use strict;
use warnings;

our $VERSION = '1.06';

# --------------------------------------------------

sub create_statement
{
	my($self) 	= @_;
	my($sql)	= $self -> db_vendor eq 'ORACLE'
		? "insert into $$self{'table'} (id, lvl, message, timestamp) values (log_seq.nextval, ?, ?, localtimestamp)"
		: $self -> db_vendor eq 'SQLITE'
		? "insert into $$self{'table'} (lvl, message, timestamp) values (?, ?, 'now')"
		: "insert into $$self{'table'} (lvl, message, timestamp) values (?, ?, now() )"; # MySQL, Postgres.

	return $$self{'dbh'} -> prepare($sql);

}	# End of create_statement.

# --------------------------------------------------

1;
