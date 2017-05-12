package Apache::DBI::Cache::mysql;

use 5.008;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.06';

BEGIN {
  die "Please load Apache::DBI::Cache before"
    unless defined &Apache::DBI::Cache::plugin;

  require DBD::mysql;

  Apache::DBI::Cache::plugin
      (
       'mysql',
       sub {			# Idx generator $ctx
	 my ($dsn, $user, $passwd, $attr)=@_;
	 $Apache::DBI::Cache::LOG->(3, "mysql plugin: got dsn=$dsn");
	 $attr={%{$attr||{}},
		'user' => $user,
		'password' => $passwd,
	       };
	 DBD::mysql->_OdbcParse($dsn, $attr,
				['database', 'host', 'port']);
	 if( exists $attr->{host} ) {
	   $attr->{port}=3306 unless( exists $attr->{port} );
	 }
	 $attr->{AutoCommit}=1 unless( exists $attr->{AutoCommit} );
	 $dsn=join(';',
		   map( {length $attr->{$_}
			 ? $_."=".$attr->{$_}
			 : ()} (qw/host port/)));
	 my $ctx={};
	 $ctx->{database}=$attr->{database} if( length $attr->{database} );
	 ($user, $passwd)=delete @{$attr}{qw/user password host port database/};

	 $Apache::DBI::Cache::LOG->(3, "mysql plugin: returning dsn=$dsn");
	 return ($dsn, $user, $passwd, $attr, $ctx);
       },
       sub {			# connection reinit: issue 'use db'
	 my ($dbh, $dsn, $user, $passwd, $attr, $ctx)=@_;
	 if( exists $ctx->{database} ) {
	   $Apache::DBI::Cache::LOG->(3, "mysql plugin: use database $ctx->{database}");
	   my $rc=eval {
	     $dbh->{mysql_auto_reconnect}=0;
	     $dbh->do('USE '.$ctx->{database});
	   };
	   $Apache::DBI::Cache::LOG->(0, "mysql: USE $ctx->{database} failed".($@?": $@":length($_=$dbh->errstr)?": $_":""))
	     unless($rc);
	   return $rc;
	 } else {
	   $Apache::DBI::Cache::LOG->(3, "mysql plugin: no database specified");
	   return 1;
	 }
       }
      );
}

1;

__END__

=head1 NAME

Apache::DBI::Cache::mysql - a Apache::DBI::Cache plugin

=head1 SYNOPSIS

  use Apache::DBI::Cache plugin=>'Apache::DBI::Cache::mysql',
                         ...;
 or

  use Apache::DBI::Cache;
  use Apache::DBI::Cache::mysql;

=head1 DESCRIPTION

B<NOTE:> Read L<Apache::DBI::Cache> before.

C<DBD::mysql> allows many different DSN syntaxes for connecting to the
same database server and the same database. This plugin transforms them
to a standard format thus allowing better DBI handle caching. Further,
if C<port> is omitted the standard port 3306 is inserted. The actual database
is deleted from the DSN and replaced by a C<USE database> command.

So, DBI connects to the following DSNs as the same user
at different times are actually performed with the same DSN
C<host=server;port=3306>. Subsequently C<USE db[1-3]> commands are
issued before passing the handle to the caller.

  dbi:mysql:dbname=db1;host=server
  dbi:mysql:db2:server:3306
  dbi:mysql:port=3306;database=db3;host=server

Apache::DBI::Cache can cache them all under the same key. So only one
real database connection is needed instead of 3 without the plugin.

Furthermore, C<mysql_auto_reconnect> is turned off.

=head1 SEE ALSO

=over 4

=item L<Apache::DBI::Cache>

=back

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

With suggestions from

=over 4

=item Z<>

Andreas Nolte E<lt> andreas dot nolte at bertelsmann dot de E<gt>

=item Z<>

Dietmar Hanisch E<lt> dietmar dot hanisch at bertelsmann dot de E<gt> and

=item Z<>

Ewald Hinrichs E<lt> ewald dot hinrichs at bertelsmann dot de E<gt>

=back

=head1 SPONSORING

Sincere thanks to Arvato Direct Services (http://www.arvato.com/) for
sponsoring this module and providing a test platform with several
thousand DBI connections.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
