package CGI::CIPP;

$VERSION = "0.07";
$REVISION = q$Revision: 1.8 $;

use strict;
use Carp;
use FileHandle;
use Config;
use File::Path;
use Fcntl ':flock';

# this global hash holds the timestamps of the compiled perl
# subroutines for this instance

%CGI::CIPP::compiled = ();

sub request {
	my $type = shift;
	my %par = @_;
	
	my $path_info = $ENV{PATH_INFO};

	# if the request accesses a directory, we add the directory
	# index name
	
	if ( $path_info =~ m!/$! ) {
		$path_info .= $par{directory_index};
	}

	$par{debug} && print STDERR "path_info=$path_info\n";

	# first bless the object, we need the lookup_uri
	# method to resolve the PATH_INFO and to set up
	# all filename attributes of the object

	my $self = bless {
		document_root		=> $par{document_root},
		directory_index 	=> $par{directory_index},
		cache_dir 		=> $par{cache_dir},
		databases 		=> $par{databases},
		default_database 	=> $par{default_database},
		filename 		=> undef,
		uri 			=> $path_info,
		error			=> undef,
		debug			=> $par{debug} || 0,
		lang			=> $par{lang},
		status => {
			pid => $$
		},
	}, $type;

	# resolve PATH_INFO to physical filename
	my $filename = $self->resolve_uri ($path_info);
	$self->{filename} = $filename;

	$self->{debug} && print STDERR "filename=$filename\n";

	# now set sub_filename, sub_name, err_filename and
	# dep_filename
	$self->set_sub_filename;
	$self->set_sub_name;
	$self->{err_filename} = $self->{sub_filename}.".err";
	$self->{dep_filename} = $self->{sub_filename}.".dep";

	# now process the request, if the file exists
	if ( -f $filename and -r $filename ) {
		if ( not $self->process ) {
			$self->error;
		}
	} else {
		print "Content-type: text/plain\n\n";
		print "File $path_info not found!\n";
		return;
	}

	return 1;
}

sub process {
	my $self = shift;
	
	$self->{debug} && print STDERR "processing...\n";
	$self->preprocess or return;

	$self->{debug} && print STDERR "compiling...\n";
	$self->compile or return;

	$self->{debug} && print STDERR "executing...\n";
	$self->execute or return;
	
	return 1;
}

sub preprocess {
	my $self = shift;

	if ( $self->file_cache_ok ) {
		return not $self->has_cached_error;
	}

	my $sub_filename = $self->{sub_filename};
	my $sub_name = $self->{sub_name};
	my $filename = $self->{filename};

	# CIPP Parameter
	my $perl_code = "";
	
	my $source = $filename;
	my $target = \$perl_code;
	my $project_hash = undef;
	
	my $db_href = $self->{databases};

	my $db;
	my $database_hash;
	foreach $db (keys %{$db_href}) {
		$database_hash->{$db} = "CIPP_DB_DBI";
	}
	my $default_db = $self->{default_database};

	my $mime_type = "text/html";
	my $call_path = $self->{uri};
	my $skip_header_line = undef;
	my $debugging = 0;
	my $result_type = "cipp";
	my $use_strict = 1;
	my $persistent = 0;
	my $apache_mod = $self;
	my $project = undef;
	my $use_inc_cache = 0;
	my $lang = $self->{lang};

	require "CIPP.pm";
	my $CIPP = new CIPP (
		$source, $target, $project_hash, $database_hash, $mime_type,
		$default_db, $call_path, $skip_header_line, $debugging,
		$result_type, $use_strict, $persistent, $apache_mod, $project,
		$use_inc_cache, $lang
	);
	$CIPP->{print_content_type} = 0;
	
	if ( not $CIPP->Get_Init_Status ) {
		$self->{error} = "cipp\tcan't initialize CIPP preprocessor";
		return;
	}

	$CIPP->Preprocess;

	if ( not $CIPP->Get_Preprocess_Status ) {
		my $aref = $CIPP->Get_Messages;
		$self->{error} = "cipp-syntax\t".join ("\n", @{$aref});
		$self->{cipp_debug_text} = $CIPP->Format_Debugging_Source ();
		return;
	}

	# Wegschreiben
	$perl_code =
		"# mime-type: $CIPP->{mime_type}\n".
		"sub $sub_name {\nmy (\$cipp_apache_request) = \@_;\n".
		$perl_code.
		"}\n";

	$self->write_locked ($sub_filename, \$perl_code);
	
	# Cache-Dependency-File updaten
	$self->set_dependency ($CIPP->Get_Used_Macros);

	# Perl-Syntax-Check

	my %env_backup = %main::ENV;	# SuSE 6.0 Workaround
	%main::ENV = ();

	my $error = `$Config{perlpath} -c -Mstrict $sub_filename 2>&1`;

	%main::ENV = %env_backup;

	if ( $error !~ m/syntax OK/) {
		$error = "perl-syntax\t$error" if $error;
		$self->{error} = $error;
		return;
	}

	return 1;
}

sub set_dependency {
	my $self = shift;
	
	my ($href) = @_;
	
	my $dep_filename = $self->{dep_filename};
	
	my @list;
	push @list, $self->{filename};

	if ( defined $href ) {
		my $uri;
		foreach $uri (keys %{$href}) {
			push @list, $self->resolve_uri($uri);
		}
	}

	$self->write_locked ($dep_filename, join ("\t", @list));
}

sub compile {
	my $self = shift;

	return 1 if $self->sub_cache_ok;

	my $sub_name = $self->{sub_name};
	my $sub_filename = $self->{sub_filename};
	
	my $sub_sref = $self->read_locked ($sub_filename);
	
	# cut off fist line (with mime type)
	$$sub_sref =~ s/^(.*)\n//;
	
	# extract mime type
	my $mime_type = $1;
	$mime_type =~ s/^#\s*mime-type:\s*//;

	# compile the code
	eval $$sub_sref;

	if ( $@ ) {
		$self->{error} = "compilation\t$@";
		$CGI::CIPP::compiled{$sub_name} = undef;
		return;
	}
	
	$CGI::CIPP::compiled{$sub_name} = time;
	$CGI::CIPP::mime_type{$sub_name} = $mime_type;
	
	unlink $self->{err_filename};

	return 1;
}

sub execute {
	my $self = shift;

	my $sub_name = $self->{sub_name};
	
	if ( $CGI::CIPP::mime_type{$sub_name} ne 'cipp/dynamic' ) {
		$CIPP::REVISION =~ /(\d+\.\d+)/;
		my $cipp_revision = $1;
		$CGI::CIPP::REVISION =~ /(\d+\.\d+)/;
		my $cipp_handler_revision = $1;

		print "Content-type: text/html\n\n";
		print "<!-- generated by CIPP $CIPP::VERSION/$cipp_revision with ".
		   "CGI::CIPP $CGI::CIPP::VERSION/$cipp_handler_revision ".
		   "-->\n";
	}

	no strict 'refs';
	eval { &$sub_name ($self) };

	if ( $@ ) {
		$self->{error} = "runtime\t$@";
		return;
	}

	return 1;
}


sub error {
	my $self = shift;
	
	my $sub_filename = $self->{sub_filename};
	my $err_filename = $self->{err_filename};
	my $error = $self->{error};
	my $uri = $self->{uri};

	my ($type) = split ("\t", $error);

	if ( $type eq 'cipp-syntax' ) {
		$self->write_locked ($err_filename, $error);
	} else {
		unlink $sub_filename;
		unlink $err_filename;
	}

	$error =~ s/^([^\t]+)\t//;
	
	print "Content-type: text/html\n\n";
	print "<HTML><HEAD><TITLE>Error executing $uri</TITLE></HEAD>\n";
	print "<BODY BGCOLOR=white>\n";

	print "<P>Error executing <B>$uri</B>:\n";
	print "<DL><DT><B>Type</B>:</DT><DD><TT>$type</TT></DD>\n";
	print "<P><DT><B>Message</B>:</DT><DD><PRE>$error</PRE></DD></DL>\n";

	if ( $self->{cipp_debug_text} ) {
		print ${$self->{cipp_debug_text}};
	}

	1;	
}

sub debug {
	my $self = shift;
	
	my $sub_name = $self->{sub_name};
	my $sub_filename = $self->{sub_filename};
	
	my ($k, $v);
	my $str = "cache=$sub_filename sub=$sub_name";
	while ( ($k, $v) = each %{$self->{status}} ) {
		$str .= " $k=$v";
	}

	return;
	
	while ( ($k, $v) = each %CGI::CIPP::sub_cnt ) {
		$self->{debug} && print STDERR ("$k: $v\n");
	}

	1;
}

# Helper Functions ----------------------------------------------------------------

sub set_sub_filename {
	my $self = shift;
	
	my $filename = $self->{uri};
	my $cache_dir = $self->{cache_dir};
	
	my $dir = $filename;
	$dir =~ s!/[^/]+$!!;
	$dir = $cache_dir.$dir;
	
	( mkpath ($dir, 0, 0770) or die "can't create $dir" ) if not -d $dir;
	
	$filename =~ s!^/!!;
	$self->{sub_filename} = "$cache_dir/$filename.sub";
	
	return 1;
}

sub set_sub_name {
	my $self = shift;
	
	my $uri = $self->{uri};
	$uri =~ s!^/!!;
	$uri =~ s/\W/_/g;
	
	$self->{sub_name} = "CIPP_Pages::process_$uri";
	
	return 1;
}

sub file_cache_ok {
	my $self = shift;
		
	$self->{status}->{file_cache} = 'dirty';

	my $cache_file = $self->{sub_filename};
	
	if ( -e $cache_file ) {
		my $cache_time = (stat ($cache_file))[9];

		my $dep_filename = $self->{dep_filename};
		my $data_sref = $self->read_locked ($dep_filename);
		my @list = split ("\t", $$data_sref);

		my $path;
		foreach $path (@list)  {
			my $file_time = (stat ($path))[9];
			return if $file_time > $cache_time;
		}
	} else {
		# check if cache_dir exists and create it if not
		mkdir ($self->{cache_dir},0770)	if not -d $self->{cache_dir};
		return;
	}

	$self->{status}->{file_cache} = 'ok';

	return 1;
}

sub sub_cache_ok {
	my $self = shift;

	$self->{status}->{sub_cache} = 'dirty';

	my $cache_file = $self->{sub_filename};
	my $sub_name = $self->{sub_name};
	
	my $cache_time = (stat ($cache_file))[9];
	my $sub_time = $CGI::CIPP::compiled{$sub_name};

	if ( not defined $sub_time or $cache_time > $sub_time ) {
		$CGI::CIPP::sub_cnt{$sub_name} = 0;
		return;
	}

	$self->{status}->{sub_cache} = 'ok';
	
	++$CGI::CIPP::sub_cnt{$sub_name};
	
	return 1;
}

sub has_cached_error {
	my $self = shift;
	
	my $err_filename = $self->{err_filename};
	
	if ( -e $err_filename ) {
		my $error_sref = $self->read_locked ($err_filename);

		$self->{'error'} = $$error_sref;
		$self->{status}->{cached_error} = 1;
		
		return 1;
	}

	return;
}

sub resolve_uri {
	my $self = shift;

	my ($uri) = @_;
	my $filename;
	
	if ( $uri =~ m!^/! ) {
		$filename = $self->{document_root}.$uri;
	} else {
		my $uri_dir = $self->{uri};
		$uri_dir =~ s!/[^/]+$!!;
		$filename = $self->{document_root}.$uri_dir."/".$uri;
	}

	$self->{'debug'} && print STDERR "lookup_uri: base=$self->{uri}: '$uri' -> '$filename'\n";

	return $filename;
}

sub write_locked {
	my $self = shift;
	
	my ($filename, $data) = @_;
	
	my $data_sref;
	if ( not ref $data ) {
		$data_sref = \$data;
	} else {
		$data_sref = $data;
	}
	
	my $fh = new FileHandle;

	open ($fh, "+> $filename") or croak "can't write $filename";
	binmode $fh;
	flock $fh, LOCK_EX or croak "can't exclusive lock $filename";
	seek $fh, 0, 0 or croak "can't seek $filename";
	print $fh $$data_sref or croak "can't write data $filename";
	truncate $fh, length($$data_sref) or croak "can't truncate $filename";
	close $fh;
}

sub read_locked {
	my $self = shift;
	
	my ($filename) = @_;

	my $fh = new FileHandle;
	open ($fh, $filename) or croak "can't read $filename";
	binmode $fh;
	flock $fh, LOCK_SH or croak "can't share lock $filename";
	my $data = join ('', <$fh>);
	close $fh;

	return \$data;
}

# Apache::Request compatibility routines

sub dir_config {
	my $self = shift;
	
	my ($par) = @_;

	my $value;

	# check if a db_ parameter is requested
	
	if ( $par =~ /^db_([^_]+)_(.*)/ ) {
		my ($db, $db_par) = ($1, $2);
		$value = $self->{databases}->{$db}->{$db_par};
	}

	return $value;
}

sub lookup_uri {
	my $self = shift;
	my ($uri) = @_;

	my $filename = $self->resolve_uri ($uri);

	return bless \$filename, "CGI::CIPP::Lookup";
}	

sub content_type {
	my $self = shift;
	
	my ($content_type) = @_;
	
	$self->{content_type} = $content_type;
	
	1;
}

sub header_out {
	my $self = shift;
	my %par = @_;
	
	$self->{header_out} = \%par;
	
	1;
}

sub send_http_header {
	my $self = shift;
	
	my $content_type = $self->{'content_type'} || 'text/html';

	print "Content-type: $content_type\n";
	
	if ( defined $self->{'header_out'} ) {
		my ($k,$v);
		while ( ($k,$v) = each %{$self->{'header_out'}} ) {
			print "$k: $v\n";
		}
	}
	print "\n";
	
	1;
}

sub internal_redirect {
	my $self = shift;

	my ($url) = @_;

	my ($path_info, $query_string) = split (/\?/, $url, 2);

	my $old_path_info = $ENV{PATH_INFO};
	my $old_query_string = $ENV{QUERY_STRING};
	my $old_request_method = $ENV{REQUEST_METHOD};
	
	$ENV{PATH_INFO} = $path_info;
	$ENV{QUERY_STRING} = $query_string;
	$ENV{REQUEST_METHOD} = "GET";
	
#	print STDERR "query_string=$query_string\n";
	
	# so werden keine Datenbankverbindungen vom
	# aufgerufenen Script geöffnet oder geschlossen
	$CIPP_Exec::no_db_connect = 1;

	CGI::CIPP->request ( %{$self} );

	# Flag wieder zurücksetzen
	$CIPP_Exec::no_db_connect = 0;
	
	$ENV{PATH_INFO} = $old_path_info;
	$ENV{QUERY_STRING} = $old_query_string;
	$ENV{REQUEST_METHOD} = $old_request_method;
	
	1;
}


package CGI::CIPP::Lookup;

sub filename {
	return ${$_[0]};
}

1;
__END__

=head1 NAME

CGI::CIPP - Use CIPP embedded HTML Pages in a CGI environment

=head1 DESCRIPTION

CGI::CIPP is a Perl module which enables you to use CIPP on every
CGI capable webserver. It is based on a central wrapper script, which
does all the preprocessing. It executes the generated Perl code
directly afterwards.

Additionally, it implements a filesystem based
cache for the generated code. Preprocessing is done only when the
corresponding CIPP source code changed on disk, otherwise this step
is skipped.

=head1 WHAT IS CIPP?

CIPP is a Perl module for translating CIPP sources to pure
Perl programs. CIPP defines a HTML embedding language also
called CIPP which has powerful features for CGI and database
developers.

Many standard CGI and database operations (and much more)
are covered by CIPP, so the developer does not need to code
them again and again.

CIPP is not part of this distribution, please download it
from CPAN.

=head1 SIMPLE CIPP EXAMPLE

To give you some imagination of what you can do with CIPP:
here is a (really) simple example of using CIPP in a HTML
source to retrieve some information from a database. Think
this as a HTML page which is "executed" on the fly by
your webserver.

Note: there is no code to connect to the database. This is
done implicitely. The configuration is taken from the central
CGI::CIPP wrapper srcipt.

  # print table of users who match the given parameter
  
  <?INTERFACE INPUT="$search_name">

  <HTML>
  <HEAD><TITLE>tiny litte CIPP example</TITLE></HEAD>
  <BODY>
  <H1>Users matching '$search_name'</H1>
  <P>

  <TABLE BORDER=1>
  <TR><TD>Name</TD><TD>Adress</TD><TD>Phone</TD></TR>
  <?SQL SQL="select name, adress, phone
             from   people
	     where  name like '%' || ? || '%'"
        PARAMS="$search_name"
	MY VAR="$n, $a, $p">
    <TR><TD>$n</TD><TD>$a</TD><TD>$p</TD></TR>
  <?/SQL>
  </TABLE>

  </BODY>
  </HTML>

=head1 SYNOPSIS

Create a CGI program in a directory, where CGI programs usually
reside on your server (e.g. /cgi-bin/cipp), or configure this
program another way to be a CGI program (see sections beyond
for details).

This program is the central CGI::CIPP wrapper. It only consists of
a single function call to the CGI::CIPP module, with a hash of
parameters for configuration. This is a example:

  #!/usr/local/bin/perl

  use strict;
  use CGI::CIPP;

  # this program has the URL /cgi-bin/cipp

  CGI::CIPP->request (
	document_root  => '/www/cippfiles',
	directoy_index => 'index.cipp',
	cache_dir      => '/tmp/cipp_cache',
	databases      => {
		test => {
			data_source => 'dbi:mysql:test',
			user        => 'dbuser',
			password    => 'dbpassword',
			auto_commit => 1
		},
		foo => {
			...
		}
	}
	default_database => 'test',
	lang => 'EN'
  );

A brief description of the parameters passed to the
CGI::CIPP->request call follows:

=over 8

=item B<document_root>

This is the base directory where all your CIPP files resides.
You will place CIPP programs, Includes and Config files inside
this subdirectory. Using subdirectories is permitted. If you
use the Apache webserver you should point this to your Apache
DocumentRoot and set up a extra handler for CIPP. See the Apache
chapter beyond for details.

=item dB<irectory_index>

If you want CGI::CIPP to treat a special filename as a directory
index file, pass this filename here. If you access a directory
with CGI::CIPP and a according index file is found there,
it will be executed.

=item B<cache_dir>

This names the directory where CGI::CIPP can store the
preprocessed CIPP programs. If the directory does not exist
it will be created. Aware, that the directory must have write
access for the user under which your webserver software is running.

=item B<databases>

This parameter contains a hash reference, which defines several
database configurations. The key of this hash is the CIPP internal
name of the database, which can be addressed by the DB parameter
of all CIPP SQL commands. The value is a hash reference with the 
following keys defined.

=item B<  data_source>

This must be a DBI conforming data source string. Please refer
to the DBI documentation for details about this.

=item B<  user>

This is the username CIPP uses to connect to the database

=item B<  password>

This password is used for the database user.

=item B<  auto_commit>

This parameter sets the initial state of the AutoCommit flag.
Please refer to the description of the <?AUTOCOMMIT> command or
the DBI documentation for details about AutoCommit.

=item B<default_database>

This takes the name of the default database. This database is
always used, if a CIPP SQL command ommits the DB parameter.
The value passed here must be a defined key in the databases
hash.

=item B<lang>

CIPP has multilanguage support for its error messages, actually
english ('EN') and german ('DE') are supported.

=back

The CGI wrapper program uses the CGI feature PATH_INFO to determine
which page should be executed. To execute the CIPP page 'test.cipp'
located in '/www/htdocs/cippfiles/foo/test.cipp' you must specify
the following URL (assuming the configuration of the example above):

  http://somehost/cgi-bin/cipp/foo/test.cipp

You simply add the path of your page (relative to the path you
specified with the document_root parameter) to the URL of the CGI
wrapper.

Be aware of the real URL of your page if you use relative URL's
to non CIPP pages in your CIPP page. In the above example relative
URL's must consider that the CGI wrapper program is located in a
different location as the directory you declared as the CIPP document
root. This implies that it is not possible to place CIPP program
files and traditional static HTML documents or images into the
same directory.

=head1 APACHE CONFIGURATION

If you're using the Apache webserver (what is always recommended :)
you can avoid the above stated disadvantages. In this case you
should configure your CIPP CGI wrapper program as a extra handler.

Simply add the following directives to your appropriate Apache
config file:

  AddHandler x-cipp-execute cipp
  Action x-cipp-execute /cgi-bin/cipp

The CGI wrapper program is still located in a extra cgi-bin directory.
But now all files with the extension .cipp are handled through
it.

The CGI::CIPP configuration slightly changes, we reasign the
document_root:

  document_root	/www/htdocs

We now declare the Apache DocumentRoot also to be the document_root of
CGI::CIPP, so no special subdirectory is needed.

This is a example URL for a CIPP page located in /www/htdocs/foo/test.cipp

  http://somehost/foo/test.cipp

Now you are able to place CIPP files on your webserver wherever you want,
because there is no special CIPP directory anymore. Only the suffix
.cipp is relevant, due to the AddHandler directive above. So you can mix
traditional static documents with CIPP files and relative URL adressing
is no problem at all.

=head2 Security Hint

To prevent users from viewing your Include or Config files, you should
configure your webserver to forbid access to these files. In case of
Apache add the following contatiner to your Apache configuration:

  <Location ~ "\.(conf|inc)$">
    Order allow,deny
    Deny from all
  </Location>  

This assumes that you name your Config files *.conf and your Include
*.inc. CIPP does not care about the extensions of your Config and
Include files. To make your life easier, you should ;)

=head1 CGI::SpeedyCGI and CIPP::CGI

There exists a really nice module called CGI::SpeedyCGI, which is
available freely via CPAN. It implements a nifty way of making Perl
CGI processes persistent, so subseqeuent CGI calls are answered much
more faster.

Using CIPP::CGI together with CGI::SpeedyCGI is easy. Simply replace
the perl interpreter path in the shebang line
C<#!/usr/local/bin/perl>
with the according path to the speedy program, e.g.:
C<#!/usr/local/bin/speedy>.

Refer to the CGI::SpeedyCGI documentation for details about configuring
SpeedyCGI. I recommend the usage of the C<-r> and C<-t> switch, so you are
able to control the number of parallel living speedy processes, e.g.

  #!/usr/local/bin/speedy -- -r30 -t120

Each speedy process now answeres a maximum of 30 requests and then dies.
If a process is idle for longer than 120 secs it dies also.

=head1 AUTHOR

Joern Reder <joern@dimedis.de>

=head1 COPYRIGHT

Copyright 1998-1999 Joern Reder, All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), CIPP(3pm), Apache::CIPP(3pm), CGI::SpeedyCGI(3pm)
