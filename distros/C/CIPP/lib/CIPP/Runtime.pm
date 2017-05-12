# $Id: Runtime.pm,v 1.2 2004/05/11 08:59:36 joern Exp $

package CIPP::Runtime;

$REVISION = q$Revision: 1.2 $;
$VERSION = "0.42";

use strict;
use FileHandle;
use Cwd;
use Carp;

sub debug {
	return;

	my @c = caller(1);
	$c[3] =~ m!::([^:]+)$!;
	my $sub = $1;
	$0 =~ m!/([^/]+)$!;
	my $file = $1;
	print STDERR "$$ $file\t$sub\t$_[0]\n";
}

sub init_request {
	return;
	use Cwd;
	debug("cwd=".cwd());
	debug("base config was: $cipp::back_prod_path/config/cipp.conf");
	debug("CIPP_Exec::cipp_config_dir=$CIPP_Exec::cipp_config_dir");
	debug("INC: ", join(",",@::INC));
}

sub Read_Config {
	my ($filename, $nocache) = @_;

	$nocache = 1;

	confess "CONFIG\tFile '$filename' not found\n".
		"working directory:".cwd()."\n".
		"\@INC = ".(join(",",@::INC))."\n"
		if not -f $filename;
	
	my $file_timestamp = (stat($filename))[9];
	
	if ( $nocache or not defined $CIPP::Runtime::cfg_timestamp{$filename} or
	     $CIPP::Runtime::cfg_timestamp{$filename} < $file_timestamp ) {
		my $fh = new FileHandle;
		open ($fh, $filename);
		eval join ('', "no strict;\n", <$fh>)."\n1;";
		confess "CONFIG\t$@" if $@;
		close $fh;
		$CIPP::Runtime::cfg_timestamp{$filename} = $file_timestamp;
		debug($filename);
	}
}

sub Exception {
	my ($die_message) = @_;

	my (@type) = split ("\t", $die_message);

	my $message = pop @type;

	if ( (scalar @type) == 0 ) {
		push @type, "general";
	}

	my $type = join ("::", @type);

	my $log_error = Log ("EXC", "TYPE=$type, MESSAGE=$message");
	if ( $log_error ) {
		$message .= "<P><BR><B>Unable to add this exception to the logfile!</B><BR>\n";
		$message .= "=> $log_error";
	}
	print "Content-type: text/html\n\n" if ! $CIPP_Exec::cipp_http_header_printed;
	print "<P>$CIPP_Exec::cipp_error_text<P>";

	if ( $CIPP_Exec::cipp_error_show ) {
		print "<P><B>EXCEPTION: </B>$type<BR>\n",
		      "<B>MESSAGE: </B>$message<P>\n";
		if ( $message =~ /compilation errors/ ) {
			print "<P>You will find the compiler error messages in the webserver error log<P>\n";
		}
	}

	eval {
		confess "CIPP::Runtime version $CIPP::Runtime::VERSION\nSTACK-BACKTRACE";
	};
	my $stack_trace = $@;
	Log ("EXC", "trace: $stack_trace");
	Log ("EXC", "INC:".join(",",@INC));

	if ( $CIPP_Exec::cipp_error_show ) {
		print "<p><pre>$stack_trace</pre>\n";
	}

	Close_Database_Connections();
#	die "TYPE=$type MESSAGE=$message";
}


sub Log {
	my ($type, $message, $filename, $throw) = @_;
	my $time = scalar (localtime);
	$message =~ s/\s+$//;

	my $program;
	if ( not $CIPP_Exec::apache_mod ) {
		$program = $0;
		$program =~ s!$CIPP_Exec::cipp_cgi_dir/!!;
		$program =~ s!/!.!g;
		$program =~ s!\.cgi$!!;
	} else {
		$program = $CIPP_Exec::apache_program;
	}
	my $msg = "$$\t$main::ENV{REMOTE_ADDR}\t$program\t$type\t$message";
	
	my $log_error;
	if ( not $CIPP_Exec::apache_mod ) {
		if ( $filename ne '' ) {
			# wenn relative Pfadangabe, dann relativ zum
			# prod/logs Verzeichnis anlegen
			if ( $filename !~ m!^/! ) {
				my $dir = $CIPP_Exec::cipp_log_file;
				$dir =~ s!/[^/]+$!!;
				$filename = "$dir/$filename";
			}
			
		} else {
			$filename = $CIPP_Exec::cipp_log_file;
		}

		if ( open (cipp_LOG_FILE, ">> $filename") ) {
			if ( ! print cipp_LOG_FILE "$time\t$msg\n" ) {
				$log_error = "Can't write data to '$filename'";
			}
			close cipp_LOG_FILE;
		} else {
			$log_error = "Can't write '$filename'";
		}
	} else {
		$CIPP_Exec::apache_request->log_error ("Log: $msg");
	}
	
	return $log_error;
}

sub HTML_Quote {
        my ($text) = @_;

        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
#       $text =~ s/>/&gt;/g;
        $text =~ s/\"/&quot;/g;

        return $text;
}

sub Field_Quote {
        my ($text) = @_;

	$text =~ s/&/&amp;/g;
        $text =~ s/\"/&quot;/g;

        return $text;
}

sub URL_Encode {
	my ($text) = @_;
	$text =~ s/(\W)/(ord($1)>15)?(sprintf("%%%x",ord($1))):("%0".sprintf("%lx",ord($1)))/eg;

	return $text;
}

sub Execute {
	my ($name, $output, $throw) = @_;

	$throw ||= 'EXECUTE';

	# Dateinamen zum CGI-Objekt-Namen ermitteln

	$name =~ s!\.!/!g;
	my $dir=$name;
	$dir =~ s!/[^/]+$!!;
	$dir = $CIPP_Exec::cipp_cgi_dir."/$dir";
	my $script = $CIPP_Exec::cipp_cgi_dir."/$name.cgi";

	# In das CGI Verzeichnis wechseln

	my $cwd_dir = cwd();
	chdir $dir
		or die "$throw\tUnable to chdir to '$dir'";

	# CGI-Script einlesen

	my $cgi_fh = new FileHandle;
	if ( ! open ($cgi_fh, $script) ) {
		chdir $cwd_dir;
		die "$throw\tUnable to open '$script'";
	}

	my $cgi_script = join ("", <$cgi_fh>);
	close $cgi_fh;

	# STDOUT retten

	my $save_fh = "save".(++$CIPP::Runtime::save_stdout);
	if ( ! open ($save_fh, ">&STDOUT") ) {
		chdir $cwd_dir;
		die "$throw\tUnable to dup STDOUT";
	}

	# Dateinamen für Ausgabe ermitteln:
	#	Wenn Ausgabe in Variable gesetzt werden soll:
	#	-> temp. Dateiname
	#
	#	Wenn Ausgabe in Datei umgelenkt werden soll:
	# 	-> der übergebene Dateiname

	my $catch_file;
	if ( ref ($output) eq 'SCALAR' ) {
		do {
			my $r = int(rand(424242));
			$catch_file = "/tmp/execute".$$.$r;
		} while ( -e $catch_file );
	} else {
		$catch_file = $output;
	}

	# STDOUT auf die Datei umleiten

	close STDOUT;
	if ( ! open (STDOUT, "> $catch_file") ) {
		open (STDOUT, ">&$save_fh")
			or die "$throw\tUnable to restore STDOUT";
		close $save_fh;
		chdir $cwd_dir;
		die "$throw\tCan't write '$catch_file'";
	}

	# Löschen des Error-Handlers und Setzen der Variablen
	# $_cipp_no_error_handler. Das verhindert bei dem eval des Scripts das
	# erneute Setzen des Error-Handlers

	$CIPP_Exec::_cipp_in_execute = 1;
	$CIPP_Exec::_cipp_no_http = 1;

	# CGI-Script ausführen, Error-Code merken, Error-Handler zurücksetzen

	eval $cgi_script;
	my $error = $@;

	$CIPP_Exec::_cipp_no_http = undef;
	$CIPP_Exec::_cipp_in_execute = undef;
	
	# wieder ins aktuelle Verzeichnis zurückwechseln

	chdir $cwd_dir;

	# Umleitungsdatei wieder schließen und STDOUT restaurieren

	close STDOUT;
	open (STDOUT, ">&$save_fh")
		or die "$throw\tUnable to restore STDOUT";
	close $save_fh;

	# Wenn Ergebnis in Variable soll, machen wir's doch
	# Vor allem muß das temp. File wieder gelöscht werden

	if ( ref ($output) eq 'SCALAR' ) {
		my $catch_fh = new FileHandle;
		open ($catch_fh, $catch_file)
			or die "$throw\tError reading the script output";
		$$output = join ("", <$catch_fh>);
		close $catch_fh;
		unlink $catch_file
			or die "$throw\tError deleting file '$catch_file': $!";
	}


#		$main::ENV{REQUEST_METHOD} = $save_request_method;
#		$main::ENV{QUERY_STRING} = $save_query_string;
#		$main::ENV{REQUEST_METHOD} = $save_request_method;
#		$main::ENV{QUERY_STRING} = $save_query_string;



	# Jetzt können wir auch eine Exception werfen, wenn bei der Ausführung
	# des Scripts was schief gelaufen ist (ohne restauriertes STDOUT
	# würde das nicht viel Sinn machen, da dann niemals was beim Benutzer
	# ankommen würde). In diesem Fall wird auch die Ausgabedatei gelöscht.

	if ( $error ne '' ) {
		if ( ref ($output) ne 'SCALAR' ) {
			unlink $catch_file;
		}
		die "$throw\t$error" if $error ne '';
	}

	return 1;
}

sub Get_Object_URL {
#
# INPUT:	1. Objekt
#		2. Exception
#
# OUTPUT:	1. Objekttyp
#
	my ($object, $throw) = @_;
	$throw ||= "geturl";
	
	my $object_name = $object;

	# Prüfen, ob es ein CGI ist

	$object =~ s/\./\//g;	# Punkte durch Slashes ersetzen

	# Projektnamen durch aktuelles Projekt ersetzen
	
	$object =~ s![^\/]*!$CIPP_Exec::cipp_project!;	
	
	# Ist es ein CGI?

	if ( -f "$CIPP_Exec::cipp_cgi_dir/$object.cgi" ) {
		return "$CIPP_Exec::cipp_cgi_url/$object.cgi";
	}
	
	# Dann kann es nur noch ein statisches Dokument sein
	
	my @filenames = <$CIPP_Exec::cipp_doc_dir/$object.*>;
	
	# wenn nicht eindeutig: Fehler!

	if ( scalar @filenames == 0 ) {
		die "$throw\tUnable to resolve object '$object_name'";
	} elsif ( scalar @filenames > 1 ) {
		die "$throw\tObject identifier '$object_name' is ambiguous";
	}

	my $file = $filenames[0];
	$file =~ s/^$CIPP_Exec::cipp_doc_dir\///;

	return "$CIPP_Exec::cipp_doc_url/$file";
}

my %DBH_CACHE;

sub Open_Database_Connection {
	my ($db_name, $apache_request) = @_;
	
	my $cache_key = "$CIPP_Exec::cipp_project-$db_name";

	if ( defined $DBH_CACHE{$cache_key} ) {
		my $dbh = $DBH_CACHE{$cache_key};
		if ( eval { $dbh->ping } ) {
			$CIPP_Exec::cipp_db_connection_cached = 1;
			return $dbh;
		}
	}

	$CIPP_Exec::cipp_db_connection_cached = 0;

	require DBI;

	my $pkg;
	($pkg = $db_name) =~ tr/./_/;
	$pkg = "CIPP_Exec::cipp_db_$pkg";

	my $data_source;
	my $user;       
	my $password;   
	my $autocommit; 
	my $init;       
	my $init_perl;
	my $cache_enable;

	if ( not $apache_request ) {
		# we are in new.spirit plain CGI environment, so read
		# the database configuration from file
		my $config_file = "$CIPP_Exec::cipp_config_dir/$db_name.db-conf";
		debug ("read db config: $config_file");
		croak "sql_open\tcan't read db config file '$config_file'"
			if not -r $config_file;
		do $config_file;
		no strict 'refs';
		$data_source  = \${"$pkg:\:data_source"};
		$user	      = \${"$pkg:\:user"};
		$password     = \${"$pkg:\:password"};
		$autocommit   = \${"$pkg:\:autocommit"};
		$init	      = \${"$pkg:\:init"};
		$init_perl    = \${"$pkg:\:init_perl"};
		$cache_enable = \${"$pkg:\:cache_enable"};

	} else {
		# we are in Apache::CIPP or CGI::CIPP environment
		# ok, lets read the datbase configuration from Apache
		# config resp. CGI::CIPP Config (which emulates the
		# Apache request object)
		$data_source = \$apache_request->dir_config ("db_${db_name}_data_source");
		$user	     = \$apache_request->dir_config ("db_${db_name}_user");
		$password    = \$apache_request->dir_config ("db_${db_name}_password");
		$autocommit  = \$apache_request->dir_config ("db_${db_name}_auto_commit");
		$init	     = \$apache_request->dir_config ("db_${db_name}_init");
	}

	debug ("$$data_source, $$user, $$password");

	my $dbh;
	eval {
		$dbh = DBI->connect (
			$$data_source, $$user, $$password,
			{
				PrintError => 0,
				AutoCommit => $$autocommit,
			}
		);
	};

	croak "sql_open\t$DBI::errstr\n$@" if $DBI::errstr or $@ or not $dbh;
	
	if ( defined $init and $$init ) {
		$dbh->do ( $$init );
		die "database_initialization\t$DBI::errstr" if $DBI::errstr;
	}

	if ( defined $init_perl and $$init_perl ) {
		eval_init_perl (
			code_sref => $init_perl,
			dbh       => $dbh,
		);
	}
	
	if ( defined $cache_enable and $$cache_enable ) {
		# cache handle, if caching is enabled
		$DBH_CACHE{$cache_key} = $dbh;

	} else {
		# no caching. push handle to 'close' list. all handles
		# registered here will be rollbacked and disconnected
		# on request exit.
		push @CIPP_Exec::cipp_close_db_list, $dbh;
	}

	return $dbh;
}

sub eval_init_perl {
	my %__par = @_;
	my ($__code_sref, $dbh) = @__par{'code_sref','dbh'};

	eval $$__code_sref;
	croak "sql_open\tError executing database initialization perl code!\n$@"
		if $@;

	1;
}

sub Close_Database_Connections {
	return if $CIPP_Exec::no_db_connect;

	# close all database connections, which are registered
	# in the 'close' dbh list (these are non-cached connections)
	foreach my $dbh ( @CIPP_Exec::cipp_close_db_list ) {
		# Log ("closing db connection: '$dbh'");
		if ( $dbh ) {
			eval { $dbh->rollback if not $dbh->{AutoCommit} };
			eval { $dbh->disconnect };
		}
	}

	# reset the 'close' dbh list
	@CIPP_Exec::cipp_close_db_list = ();

	# rollback transaction on cached db connections, which have
	# set AutoCommit to off.
	my ($name, $dbh);
	while ( ($name, $dbh) = each %DBH_CACHE ) {
		# Log ("close open transactions dbh='$dbh' db='$name'");
		if ( $dbh ) {
			eval { $dbh->rollback if not $dbh->{AutoCommit} };
		}
	}

	1;	
}
	
1;
