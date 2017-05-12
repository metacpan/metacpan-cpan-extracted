package Apache::OWA;

use strict;
use Apache::DBI;
use DBI;
use Apache::Constants qw(OK NOT_FOUND SERVER_ERROR AUTH_REQUIRED);
use Apache::Request ();
use Data::Dumper;

use vars qw($VERSION %owa_mapping %owa_version);

my $DEBUG = 0;
$VERSION = '0.7';

my (@dbinfo, $sth, $sql, $r, $dbh, @pass_vars);

# i like to buffer and then flush... YMMV.
#local $| = 1;

###################################################################
sub auth_handler ($) {
	$r = Apache::Request->new( shift );

	($DEBUG) = $r->dir_config('DEBUG');

	$r->warn('Apache::OWA::auth_handler start.') if ($DEBUG > 1);

	my ($sent_pw, $user, $db);

	# get username & password
	(my $res, $sent_pw) = $r->get_basic_auth_pw;
	return $res if $res != OK;
	$user = $r->connection->user;

	# need both username & password
	unless ( $user && $sent_pw) {
		$r->note_basic_auth_failure;
		$r->warn('Apache::OWA::auth_handler exit(AUTH_REQUIRED)') if ($DEBUG > 1);
		return AUTH_REQUIRED;
	}

	# get configuration
	if ($r->dir_config('DB_AUTH')) {

		$r->dir_config('DB') ?
		  $db =  $r->dir_config('DB') :
		  $db = $ENV{'ORACLE_SID'};

		@dbinfo = ($db,$user,$sent_pw);

	}
	elsif ( $r->dir_config('DB_PROC_AUTH') ) {
		@dbinfo = split(/:/,$r->dir_config('DAD'));
	}

	# don't authenticate sub-requests
	if ( $r->is_main() ) {

		if ( $r->dir_config('DB_AUTH') ) {
			$dbh = DBI->connect("dbi:Oracle:$dbinfo[0]",$dbinfo[1],$dbinfo[2],
					    { PrintError => 0, RaiseError => 0, AutoCommit => 1 })
			  || return AUTH_REQUIRED;

		}
		elsif ( $r->dir_config('DB_PROC_AUTH') ) {
			my ( $proc ) = $r->dir_config('DB_PROC_AUTH');
			$dbh = DBI->connect("dbi:Oracle:$dbinfo[0]",$dbinfo[1],$dbinfo[2],
					    { PrintError => 0, RaiseError => 0, AutoCommit => 1 })
			  || return SERVER_ERROR;

			my $rv;
			$sql = 'begin :rv := $proc (:user, :pw); end;';
			$sth = $dbh->prepare($sql);
			#$sth = $dbh->prepare_cached($sql);
			$sth->bind_param(':user',  $user);
			$sth->bind_param(':pw',  $sent_pw);
			$sth->bind_param_inout(':rv',  \$rv, 2);
			$sth->execute || return SERVER_ERROR ;
			$sth->finish;
			$dbh->disconnect;
			return AUTH_REQUIRED if $rv != 0;
		}
		# support for owa.auth_scheme and owa.protection_realm
		# would pobably go here if i didn't think they were stupid...
	}
	# pass handling to the content handler
	$r->handler('perl-script');
	$r->push_handlers(PerlHandler=>\&handler );
	$r->warn('Apache::OWA::auth_handler exit(OK)') if ($DEBUG > 1);
	return OK;
}
#####################################################
#sub content_handler ($) {
sub handler ($) {
	$r = Apache::Request->new( shift );
	$DEBUG = $r->dir_config('DEBUG');
	$r->warn('Apache::OWA::content_handler start. DEBUG == '. $DEBUG )  if ( $DEBUG );

	# first check if the url refers to a file
	if ( -r $r->subprocess_env('SCRIPT_FILENAME') ) {
		$r->send_http_header;
		return OK if $r->header_only;
		open (TMP, $r->subprocess_env('SCRIPT_FILENAME') );
		$r->send_fd( \*TMP );
		close(TMP);
		return OK;
	}

	# get database-access config
	if ( $r->dir_config('DAD')) {
		@dbinfo = split(/:/,$r->dir_config('DAD'));
	}
	elsif (!@dbinfo) {
		error('You must provide either DAD or PerlAuthenHandler configuration for Apache::OWA','');
	}

	# connect to database
	$dbh = DBI->connect("dbi:Oracle:$dbinfo[0]",$dbinfo[1],$dbinfo[2],
			    { PrintError => 0, RaiseError => 0, AutoCommit => 1 })
	  || &error($DBI::errstr);

	# map uri to plsql precedure name.
	# could probably be done better...

  	my @plsql = split (/\//, $r->uri());
  	#my @plsql = split (/\//, $r->subprocess_env('SCRIPT_NAME') );
  	my $plsql = pop(@plsql);

	($plsql = $r->dir_config('SCHEMA') . '.' . $plsql)
	  if ( $r->dir_config('SCHEMA') );

	# uppercase all procedure names.
	$plsql =~ tr/a-z/A-Z/;

	# lowercase uri
	my $uri = $r->uri();
	$uri =~ tr/A-Z/a-z/;

	$r->warn( "uri: $uri, resolved to: $plsql, database: $dbinfo[0], user: $dbinfo[1]")
	  if ($DEBUG);

	# reset package, get owa toolkit version
	$sql = '
BEGIN
  dbms_session.reset_package;
  :version := owa.initialize;
END;
';
	$sth = $dbh->prepare($sql);

	$sth->bind_param_inout(':version', \$owa_version{$uri}, 1);
	$owa_mapping{$uri} = $plsql;
	$r->warn("executing: $sql") if ($DEBUG > 1);
	$sth->execute    || &error($DBI::errstr, $sql);
	$r->warn("executed OK") if ($DEBUG > 1);

	# setup CGI environment in Oracle
	my (@args, @bind_vars, $envVarCount);
	my ($declares, $defines);

	$declares .= "   cgi_var_val  owa.vc_arr;\n";
	$declares .= "   cgi_var_name owa.vc_arr;\n";

	# what variables to pass to Oracle.
	# these are sort of standard, i think...
	# you can change them to whatever you like.
	# for example:
	#(@pass_vars) = (keys %{ $r->subprocess_env });
	# would pass all viarables.

	(@pass_vars) = (
			'SERVER_SOFTWARE','SERVER_NAME',    'GATEWAY_INTERFACE',
			'REMOTE_HOST',    'REMOTE_ADDR',    'AUTH_TYPE',
			'REMOTE_USER',    'HTTP_ACCEPT',
			'HTTP_USER_AGENT','SERVER_PROTOCOL','SERVER_PORT',
			'SCRIPT_NAME',    'PATH_INFO',      'PATH_TRANSLATED',
			'HTTP_REFERER',   'HTTP_COOKIE');

	foreach (@pass_vars) {
		$defines .=
		  '   cgi_var_val(' .++$envVarCount . "):=?;\t" .
		  '   cgi_var_name(' . $envVarCount ."):='". $_ ."';\n";
		push @bind_vars, $r->subprocess_env($_) ;
	}
	push @bind_vars, $envVarCount;

	$sql =  "\nDECLARE\n"  . $declares;
	$sql .= "BEGIN\n" . $defines;
        $sql .= "   owa.init_cgi_env(?, cgi_var_name, cgi_var_val);\n";
	$sql .= "END;\n";
	$sth = $dbh->prepare($sql);
	$r->warn("executing: $sql") if ($DEBUG > 1);
	$sth->execute(@bind_vars) || &error($dbh->errstr, $sql);
	$r->warn("executed OK") if ($DEBUG > 1);
	$sth->finish;



	# reusing variables.
	@args=(); @bind_vars=(); $declares = ""; $defines = "";
	# start putting together procedure arguments, if there are any.
	if ( $r->param() ) {

		my %arg_name_type = &check_var_types( $plsql )
		  unless ( $r->dir_config('NEVER_USE_WEIRD_TYPES'));

		# loop through each arg, constructing SQL snippets as we go
		my @names =  $r->param();
		foreach my $name ( @names ) {

			$name =~ tr/a-z/A-Z/;
			my (@values) = $r->param($name);

			# is it a point?
			my ($basename, $coord);
			if ( ($basename,$coord) = ($name =~ /^(.*)\.([xy])$/i) ) {

				# only declare basename once
				unless ($declares =~ /$basename/) {
					$declares .=  "   $basename owa_image.point;\n";
					push @args, $basename . ' => ' . $basename;
				}

				# x or y?
				if ($coord =~ /x/i) {
					$defines .= "   " . $basename . "(1) := ?;\n";
					push @bind_vars, $values[0];
				} else {
					$defines .= "   " . $basename . "(2) := ?;\n";
					push @bind_vars, $values[0];
				}
			}

			# is it an array?
			# the only way to know if it is an array is to do the check
			# in &check_var_types
			elsif ( $arg_name_type{$name} ) {

				# we can not assume it is a owa_util.ident_arr,
				# the only way to know the array type is to do the check above.
 				# $declares .= "   $name owa_util.ident_arr;\n";
				$declares .= "   $name " . $arg_name_type{$name} . ";\n";
				push @args,     $name .' => '. $name ;

				for my $j (1 .. @values) {
					$values[$j-1] =~ s/'/''/g;
					$defines .= '   ' .  $name . "($j) := \'$values[$j-1]\' ;\n";
				}
			}

			# regular attr=value pair
			else {
				$declares .= "   $name varchar2(4096);\n";
				push @args,      $name .' => '. $name;
				$values[0] =~ s/'/''/g;
				$defines .= '   ' .  $name . " := ?;\n";
				push @bind_vars, $values[0];
			}
		}
	}

	$sql =  "\nDECLARE\n" . $declares;
	$sql .= "BEGIN\n" .   $defines;
	$sql .= "\n   " . $plsql ;
	($sql .= '(' . join(',', @args) . ')') if ( @args );
	$sql .= ";\nEND;\n";

	$sth = $dbh->prepare($sql);
	$r->warn("executing: $sql") if ($DEBUG > 1);
	$sth->execute(@bind_vars);
	$r->warn("executed OK") if ( ($DEBUG > 1) &! $dbh->err );

	if ( $dbh->err && $DEBUG ) {
		&helpful_error($dbh->err, $dbh->errstr, $sql,  $plsql, \@args, \@bind_vars);
	}
	elsif ($dbh->err == 6550) {
		$r->log_error( $r->subprocess_env('REMOTE_ADDR') . " " . $r->uri . " NOT FOUND");
		return NOT_FOUND;
	}
	elsif ( $dbh->err ) {
		$r->log_error( $r->subprocess_env('REMOTE_ADDR') . " " . $r->uri . " SERVER_SERROR");
		return SERVER_ERROR;
	}

	# get output from procedure.
	# we need to handle version <= 3 and 4 differently
	#
	# with 3 we can access htp.htbuf(:pos) directly
	# :pos is the position in the htp.htbuf we are currently at
	# it is set to 0 if :pos == htp.htbuf.count
	#
	# version is returned from owa.initialize as 256*major_version + minor_version

        if ($owa_version{$uri} <= 768) {
		$sql ='
  BEGIN
    :content := NULL;
    :rows := htp.htbuf.count;

    FOR i IN 1 .. htp.htbuf.count  LOOP
      :content := :content || htp.htbuf(:pos);
      :pos := :pos + 1;

        IF i > 126 THEN EXIT;
        END IF;

        IF ( :pos >= htp.htbuf.count )  THEN
          :pos := 0 ;
        EXIT;

      END IF;
    END LOOP;
  END;';
	}

	# with version 4 htp.htbuf is private and we have to use the procedure
	# htp.get_line to fetch te data.
	# :pos = 1 if there are more lines in htp.htbuf, 0 if empty.
	# sadly we never get to know how many rows there are in htp.htbuf.

	elsif ($owa_version{$uri} == 1024) {
		$sql ='
  BEGIN
    :content := NULL;
    :rows := 0;

    WHILE ( :pos > 0 AND  :rows < 127 ) LOOP
      :content := :content || htp.get_line(:pos);
      :rows := :rows + 1;
    END LOOP;
  END;';

	}

	else { 
		error('Unknown PL/SQL Toolkit version!');
	}

	my $content;
	my $pos = 1;
	my $rows = 0;
	my $numgets = 0;

	$sth = $dbh->prepare($sql);
	$sth->bind_param_inout(':rows', \$rows, 1);
	$sth->bind_param_inout(':pos', \$pos, 1);
	$sth->bind_param_inout(':content', \$content, { TYPE => 24 } ); # varchar2

	$r->content_type('text/html');
	$r->warn("executing: $sql") if ($DEBUG > 1);
	while ( $pos > 0) {
		$r->warn("executing: rows = $rows pos = $pos numgets = $numgets") 
		  if ($DEBUG > 1);
		$r->warn("executing again: rows = $rows pos = $pos numgets = $numgets") 
		  if ( ($DEBUG > 1) &&  ($numgets > 0) );
		$sth->execute      || &error($dbh->err,$sql);
		$numgets++;
		$r->print($content);
	}
	$r->warn("executed OK") if ($DEBUG > 1);
	$r->rflush;
	$sth->finish;
	$dbh->disconnect;
	$r->warn('Apache::OWA::content_handler exit(0)') if ($DEBUG);
}
#################################################################
sub error {
        my ($errstr, $sql) = @_;

	my $env_report;
	(@pass_vars) = (keys %{ $r->subprocess_env }) unless (@pass_vars);
	foreach ( sort(@pass_vars) ) {
		$env_report .= $_ . ' = ' . $r->subprocess_env($_) . "\n" ;
	}

	my ($args, $name);
	my @names = $r->param();
	foreach ( @names ) {
		$args .= $_ . ' = ' . $r->param($_) . '\n';
	}

	$r->warn('Apache::OWA::error: ' . $errstr);

	my $msg = '<HTML><HEAD><TITLE>Server Error</TITLE></HEAD>'
	  . '<BODY><h1>Server Error</h1><br>'
	  . '<h2>Apache::OWA '. $VERSION .'</h2><br><b>Oracle error:</b> <br>' 
	  . '<pre>' . $errstr . '</pre>';

	if ( $sql ) {
		$msg .= '<hr><b>while executing:</b><br>'
		  . '<pre>' . $sql. '</pre><br>'
		  . '<hr><b>arguments: </b><br>'
		  . '<pre>' . $args . '</pre>';
	}

	$msg .= '<hr><b>CGI environment: </b><br>'
	  . '<pre>' . $env_report . '</pre><br>'
	  . '<hr><b>Request data: </b><br>'
	  . '<pre>' . $r->as_string . '</pre><br>'
	  . '</pre><hr></BODY</HTML>';

	$r->custom_response(SERVER_ERROR,$msg);
        $dbh->disconnect;
        die;
}
#########################################################################
sub helpful_error {
	my ($err,$errstr,$old_sql,$plsql,$args,$bind_vars) = @_;

	# funky error checking
	#
	# error 6550 could mean that
	# 1 - the procedure doesn't exist
	# 2 - the arguments are wrong
	# 3 - no execute grant??
	# 4 - ??
	# try to find procedure and arguments in all_arguments
	# so we can get some nice debug-info.

	my @plsql = split(/\./,$plsql);

	# we have owner.package.procedure
	if ( @plsql == 3 ) {

		$sql = '
select OBJECT_NAME, PACKAGE_NAME, OBJECT_ID, ARGUMENT_NAME, DATA_TYPE
  from ALL_ARGUMENTS where
    OWNER = ? and
    PACKAGE_NAME = ? and
    OBJECT_NAME = ? and
    DATA_LEVEL=0
';
	}

	# we have package.procedure
	elsif ( @plsql == 2 ) {

		$sql = '
select OBJECT_NAME, PACKAGE_NAME, OBJECT_ID, ARGUMENT_NAME, DATA_TYPE
  from USER_ARGUMENTS where
  PACKAGE_NAME = ? and
  OBJECT_NAME = ? and
  DATA_LEVEL=0
';
	}

	# just procedure
	else {
		@plsql = ($plsql);
		$sql = '
select OBJECT_NAME, PACKAGE_NAME, OBJECT_ID, ARGUMENT_NAME, DATA_TYPE
  from USER_ARGUMENTS where
    OBJECT_NAME = ? and
    DATA_LEVEL=0
';
	}

	$sth = $dbh->prepare($sql);
	$sth->execute(@plsql) || &error($dbh->errstr, $sql); ;
	my $rows = $sth->fetchall_arrayref;

	# if it is really 6550, rows == 0
	if ($sth->rows == 0) {
		&error($errstr,$old_sql);
	}

	# something else is wrong
	else {
		my ($exp_args, $got_args);
		foreach ( @{$rows} ) {
			$exp_args .= $_->[3] . ' (' . $_->[4] .")\n";
		}
		my $i=0;
		foreach ( $r->param() ) {
			$got_args .= $_ . ' = ' . $r->param($_) ."\n";
			$i++;
		}
		my $msg =  "$errstr\n\n";
		$msg .= "You may need to remove \"PerlSetVar NEVER_USE_WEIRD_TYPES\" from httpd.conf\n\n"
		  if ( $r->dir_config('NEVER_USE_WEIRD_TYPES'));
		$msg .= "Expected ". $sth->rows ." argument(s):\n" . $exp_args . "\n"
		      . "Got " . $i             ." argument(s):\n" . $got_args . "\n"
		      . "Sql: \n"  . $old_sql . "\n"
		      . "args: \n" . join("\n", @{$args}) . "\n"
		      . "vars: \n" . join("\n", @{$bind_vars}) . "\n";

		&error($msg,$old_sql);
	}
}
#################################################################
# nasty stuff we need to do to check for weird PL/SQL Table datatypes.
# thanks to Slava Kalashnikov <slava@intes.odessa.ua>
# if you don't ever use PL/SQL Table datatypes,
# turn it off with "PerlSetVar NEVER_USE_WEIRD_TYPES 1"
sub check_var_types ($) {
	my $plsql = shift;
	my %arg_name_type;

	my @args = split(/\./, $plsql);

	$r->warn("checking for PL/SQL_Table datatype: ( $plsql ) ". join(',',@args) )
	  if ( $DEBUG ) ;


	# owner.package.procedure
	if ( @args == 3 ) {
		$sql = "
select argument_name,type_name,type_subname
  from all_arguments where
    owner =?
    and package_name =?
    and object_name=?
    and data_type='PL/SQL TABLE'";
	}

	# package.procedure
	elsif ( @args == 2 ) {
		$sql = "
select argument_name,type_name,type_subname
  from user_arguments where
    package_name =?
    and object_name=?
    and data_type='PL/SQL TABLE'";
	}

	# procedure
	else {
		$sql = "
select argument_name,type_name,type_subname 
  from user_arguments where 
    object_name=?
    and data_type='PL/SQL TABLE'";
	}

	$sth = $dbh->prepare($sql);
	$sth->execute(@args) || &error($dbh->errstr, $sql);

	while (my @row = $sth->fetchrow_array ) {
		$r->warn("     found $row[0] -> $row[1].$row[2]")
		  if ($DEBUG );
		$arg_name_type{$row[0]} = "$row[1].$row[2]";
	}

	$sth->finish;
	return %arg_name_type;
}



#################################################################
# stuff to insert into the "perl-status" page
sub owa_status_info ($$) {
	my($r,$q) = @_;
	my(@strings);
	unless (scalar  %Apache::OWA::owa_version) {
		push @strings , 'No information available';
	}
	else {
		push @strings, '<table border=1><tr><td align=right><b>URI</b></td>';
		push @strings, '<td align=right><b>PL/SQL Procedure</b></td>';
		push @strings, '<td align=right><b>PL/SQL Web Toolkit version</b></td></th>';
		foreach (keys %Apache::OWA::owa_version) {
			push @strings,  '<tr><td>'. $_ .'</td>';
			push @strings,  '<td>'. $Apache::OWA::owa_mapping{$_} .'</td>';
			push @strings,  '<td>', 
			  $Apache::OWA::owa_version{$_}/256, 
			    '(', $Apache::OWA::owa_version{$_}, ')', 
			      '</td></tr>';
		}
		push @strings, '</table>';
	}
	return \@strings;
}
#################################################################
Apache::Status->menu_item('OWA' => 'OWA info',\&owa_status_info) if Apache->module('Apache::Status');

1;
__END__


=head1 NAME

Apache::OWA - Run OWA applications under Apache/mod_perl

=head1 SYNOPSIS

Runs Oracle PL/SQL apllications written using Oracle's PL/SQL Web Toolkit under Apache/mod_perl.

=head1 REQUIREMENTS

DBI, DBD::Oracle, Apache::DBI, Apache::Request (libapreq), Oracle PL/SQL Web Toolkit (any version should work)

=head1 DESCRIPTION

Example configuration.

 <Location /scott/>
    SetHandler perl-script
    PerlHandler Apache::OWA;
    PerlSetVar DAD oracle:scott:tiger
 </Location>

This configuration means that calling "http://server/scott/print_cgi_env" executes the
pl/sql procedure "scott.print_cgi_env".


Other configuration options:

 PerlSetVar SCHEMA oas_public
    This lets you execute procedures under a different schema (user) 
    than the ones specified in the DAD-string.

 PerlSetVar DEBUG 1
    0 - No debugging. This is the default.
    1 - Light debugging and verbose errors sent to the browser.
        Useful while developing procedures.
    2 - Heavy debugging of Apache::OWA inetrnal stuff.

 PerlAuthenHandler Apache::OWA
    This invokes my special authentication handler that can do a few clever
    things. Then it passes control on to the content-handler, so if you
    use this you don't need to specify "PerlHandler Apache::OWA". It
    might also be useful in combination with "PerlSetVar SCHEMA".

 PerlSetVar DB_AUTH true
    Uses database uername and password to authenticate. If no DAD-string
    is set, it can also use the supplied username and password to execute
    your PL/SQL application.

 PerlSetVar DB_PROC_AUTH schema.function
    Uses an arbitrary PL/SQL procedure or function to authenticate.
    The procedure should take the username and password as arguments
    and return 0 for success and more than 0 for failure.

 PerlSetVar NEVER_USE_WEIRD_TYPES 1
    Only set this if you know that you never use multi-value CGI variables
    that need to be mapped to PL/SQL Table datatypes. Finding these datatypes
    is some extra work and will slow down executions a little bit.


For further documentation see the README.

=head1 AUTHOR

Svante Sormark, svinto@ita.chalmers.se.
Latest version available from http://www.ita.chalmers.se/~svinto/apache

Contibutions from:

 Slava Kalashnikov <slava@intes.odessa.ua>

 Gunnar Hellekson <g.hellekson@trilux.com> and
 Erich Morisse <e.morisse@trilux.com> of Trilux Internet Group, Ltd.


=head1 COPYRIGHT

The Apache::OWS module is free software; you can redistribute it and/or
modify it under the same terms as Perl or Apache.

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<DBI>, L<DBD::Oracle>, L<Apache::DBI>


=cut
