#$Id: $

package Apache::SdnFw::lib::Core;

use strict;
use Carp;
use Apache::SdnFw::lib::DB;
#use Apache::SdnFw::lib::Memcached;
use Apache::SdnFw::object::home;
use Template;
use LWP::UserAgent;
use Crypt::CBC;
use Crypt::Blowfish;
use XML::Dumper;
use XML::Simple;
use Net::SMTP::SSL;
use Net::FTP;
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw(encode_base64);
use MIME::QuotedPrint qw(encode_qp);
use Date::Format;
use Data::Dumper;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mime_type);

BEGIN {
	# preload all top level objects
	# where the hell are we when we startup?
	opendir(ROOT,$ENV{HTTPD_ROOT});
	while (my $scode = readdir(ROOT)) {
		if (-d "$ENV{HTTPD_ROOT}/$scode/object") {
			print STDERR "Loading $scode...";
			my $smem = `ps -o rss --no-heading -p $$` if ($ENV{MEM_CALC});
			my $s = {};
			my %db_object;
			my $base = $scode;
			my $objectpath = "$ENV{HTTPD_ROOT}/$base/object";
			#print STDERR "Objectpath = $objectpath\n";
			my %conf;
			my $cfile = "$ENV{HTTPD_ROOT}/conf/$scode.conf";
			if (-e $cfile) {
				open F, $cfile;
				while (my $l = <F>) {
					chomp $l;
					next if ($l =~ m/^#/);
					if ($l =~ m/^([^=]+)=(.+)$/) {
						$conf{$1} = $2;
					}
				}
				close F;
				#print STDERR "DB_STRING,USER=$conf{DB_STRING},$conf{DB_USER}\n";
				$s->{dbh} = db_connect($conf{DB_STRING},$conf{DB_USER});
				%db_object = db_q($s,"
					SELECT code, name
					FROM objects
					",'keyval');
			}
			if (-d $objectpath) {
				opendir(DIR,$objectpath);
				while (my $d = readdir(DIR)) {
					next if ($d =~ m/^\./);
					next if (!-f "$objectpath/$d" || !($d =~ m/\.pm$/i));
					$d =~ s/\.pm$//i;
					#print STDERR "Trying to load $d\n";
					eval "use $base\:\:object\:\:$d";
					if ($@) {
						print STDERR "$@\nSKIPPING PRELOAD OF $objectpath/$d.pm\n";
						undef $@;
						next;
					}

					# make sure to load the database tables with the objects we load
					if (defined($s->{dbh})) {
						unless($d =~ m/^(me|config|template)$/) {
							if (defined($db_object{$d})) {
								delete $db_object{$d};
							} else {
								my $config = "$base\:\:object\:\:$d\:\:config";
								no strict 'refs';
								if (defined(&{$config})) {
									db_insert($s,'objects',{
										code => $d,
										name => $d,
										});
									# also give admin access to all methods by default
									my $o = &{$config}($s);
									foreach my $f (keys %{$o->{functions}}) {
										my $action_id = db_insert($s,'actions',{
											name => "$d $f",
											a_object => $d,
											a_function => $f,
											},'action_id');
	
										db_insert($s,'group_actions',{
											group_id => "_raw:(SELECT group_id FROM groups WHERE admin IS TRUE)",
											action_id => $action_id,
											});
									}
								}
								use strict 'refs';
							}
						}
					}
				}
				closedir(DIR);
				
				# remove any objects we did not load
				if (defined($s->{dbh})) {
					foreach my $obj (keys %db_object) {
						db_q($s,"DELETE FROM objects WHERE code=?",
							undef, v => [ $obj ]);
					}
				}

				if ($ENV{MEM_CALC}) {
					my $emem = `ps -o rss --no-heading -p $$`;
					my $tmem = $emem-$smem;
					print "${tmem}k\n";
				}
			
				print STDERR "\n";
			} else {
				print STDERR "Could not locate $objectpath\n";
			}
		}
	}
}

sub _load_conf {
	my $scode = shift;

}

#########################
# NEW
#########################

=head2 new

 my $s = Apache::SdnFw::lib::Core->new(
 	in => incoming parameters
	env => hash of incoming data
	content_type => [required]
	cookies => cookie values
	uri => [required] - tells us what we are going to do in process
	args => raw args from $r->args
	remote_addr =>
 	);

=cut

sub new {
	my $class = shift;

	my %args = @_;

	my $s = {};
	bless $s, $class;

	# dump all incoming args into the object
	foreach my $k (keys %args) {
		$s->{$k} = $args{$k};
	}

	# some things are required
	croak "uri not defined" unless($s->{uri});
	croak "content_type not defined" unless($s->{content_type});
	croak "env/DOCUMENT_ROOT not defined" unless($s->{env}{DOCUMENT_ROOT});
	croak "env/DB_STRING not defined" unless($s->{env}{DB_STRING});
	croak "env/DB_USER not defined" unless($s->{env}{DB_USER});
	croak "env/BASE_URL not defined" unless($s->{env}{BASE_URL});
	croak "env/OBJECT_BASE not defined" unless($s->{env}{OBJECT_BASE});

	if ($s->{env}{HTTP_USER_AGENT} =~ m/iPhone/ && $s->{env}{IPHONE}) {
		$s->{agent} = 'iphone';
	}

	# add some common time things to the object
	$s->{datetime}{time} = time();
	$s->{datetime}{nice} = time2str('%m/%d/%y %l:%M%P %Z',$s->{datetime}{time});
	$s->{datetime}{ymd} = time2str('%Y-%m-%d',$s->{datetime}{time});
	$s->{datetime}{edi_ymd} = time2str('%Y%m%d',$s->{datetime}{time});
	$s->{datetime}{edi_hms} = time2str('%H%M%S',$s->{datetime}{time});
	$s->{datetime}{edi_hm} = time2str('%H%M',$s->{datetime}{time});
	$s->{datetime}{dow} = time2str('%w',$s->{datetime}{time});
	$s->{datetime}{ymdhms} = time2str('%Y%m%d%H%M%S',$s->{datetime}{time});
	($s->{datetime}{year},$s->{datetime}{month},$s->{datetime}{day}) = split '-', $s->{datetime}{ymd};

	# move a few of these into common spots
	$s->{obase} = $s->{env}{OBJECT_BASE};
	$s->{ubase} = $s->{env}{BASE_URL};
	$s->{cbase} = "$s->{env}{HTTPD_ROOT}/$s->{obase}";
	$s->{self_url} = ($s->{env}{FORCE_HTTPS} ? 'https' : 'http').'://'.
		$s->{server_name}.$s->{ubase};

	return $s;
}

#########################
# PROCESS
#########################

=head2 process
 
 $s->process();

 We should be sending back the following
 $s->{r} => (
	file_path => if we want to send back a file handle
	filename => to force the name of the file going back
	content => raw string data to dump back upstream
	error => error string to display or log
	return_code => to just send back a raw return code
	set_cookie => [
		array of cookies to send back
		],
	redirect => redirect to this url
 	)

=cut

sub process {
	my $s = shift;

	if ($s->{env}{FORCE_HTTPS} && !$s->{env}{HTTPS}) {
		$s->{r}{redirect} = "https://$s->{server_name}$s->{uri}";
		$s->{r}{redirect} .= "?$s->{args}" if ($s->{args});
		return;
	}

	# populate a unique variable that can be used on all form variables
	# to kill autocomplete

	$s->{acfb} = md5_hex("$s->{object}$s->{function}$s->{employee_id}".time);

	# the way this works is we look at the url, then decide if we need
	# to processes further by connecting to the database
	# or if we should just punt and return back a file handle
	if ($s->{uri} =~ m/^$s->{ubase}(.*)$/) {
		$s->{raw_path} = $1 || '/';
		$s->run();

		if ($s->{return_code}) {
			$s->{r}{return_code} = $s->{return_code};
			return;
		}

		if ($s->{in}{debug} && $s->{env}{DEV}) {
			#delete $s->{content};
			$s->{content} = Data::Dumper->Dump([$s]);
			$s->{content_type} = 'text/plain';
		}

		# always make the content type xml for api
		$s->{content_type} = 'text/xml' if ($s->{api} || $s->{o}{perl_dump});

		# move the content type back to the return hash
		$s->{r}{content_type} = $s->{content_type};

		# set some things for logging purposes
		$s->{r}{log_user} = $s->{log_user} || '-';
		$s->{r}{log_location} = $s->{log_location} || '-';

		if ($s->{redirect}) {
			# if we have any messages to display, dump them to session and then
			# pick them back up on the redirect
			if ($s->{message}) {
				$s->session_add('message',$s->{message});
			}
			$s->{r}{redirect} = $s->{redirect};
			return;
		}

		# add the top menu to everything unless for some reason we are not text/html
		if ($s->{content_type} eq 'text/html' && !$s->{in}{print}) {
			$s->{r}{content} = $s->_content_add_menu();

			# if the object has a template, then put the returned content
			# into that menu
			if (defined($s->{o}{template})) {
				my $out;
				$s->tt($s->{o}{template}, { s => $s },\$out);
				$s->{r}{content} .= $out;
			} else {
				$s->{r}{content} .= $s->{message} if ($s->{message});
				if ($s->{o}{footer}) {
					$s->tt($s->{o}{footer}, { s => $s });
				}
				$s->{r}{content} .= $s->{content};
			}
		} elsif ($s->{api}) {
			$s->{r}{content} = qq(<?xml version="1.0" ?>\n<response>\n);
			$s->{r}{content} .= "<object>$s->{object}</object>\n" if ($s->{object});
			$s->{r}{content} .= "<function>$s->{function}</function>\n" if ($s->{function});
			$s->{r}{content} .= $s->{message} if ($s->{message});
			$s->{r}{content} .= $s->{content};
			$s->{r}{content} .= '</response>';
		} elsif ($s->{o}{perl_dump}) {
			$s->{r}{content} = qq(<?xml version="1.0" ?>\n);
			my $dump = new XML::Dumper;
			$s->{r}{content} .= $dump->pl2xml(\%{$s->{perl_dump}});
		} else {
			$s->{r}{content} = $s->{content};
		}
		# add some stuff to head like stylesheet or other things 
		# which modules might have added, but only if our content type is still text/html
		if ($s->{content_type} eq 'text/html') {
			unless($s->{nohead}) {
				$s->{r}{head} = $s->_head_add_title();
				$s->{r}{head} .= $s->_head_add_css();
				$s->{r}{head} .= $s->_head_add_js();
			}
			$s->{r}{head} .= $s->{head} if ($s->{head});
			$s->{r}{head} .= $s->{o}{head} if ($s->{o}{head});
			$s->{r}{body} = $s->{body} if ($s->{body});

			if (defined($s->{o}{headers})) {
				foreach my $k (keys %{$s->{o}{headers}}) {
					$s->{r}{headers}{$k} = $s->{o}{headers}{$k};
				}
			}
		}

		return;
	} else {
		# use the server name to decide where to find content
		$s->{r}{file_path} = "$s->{env}{DOCUMENT_ROOT}/$s->{server_name}$s->{uri}";
		$s->{r}{file_path} .= "index.html" if ($s->{r}{file_path} =~ m/\/$/);

		unless(-e $s->{r}{file_path}) {
			$s->{r}{return_code} = "NOT_FOUND";
			return;
		}

		# override our content type because we are sending back a file
		$s->{r}{content_type} = $s->mime_type();
		return;
	}
}

sub tt {

=head2 tt

 $s->tt($fname,$args,[$string])

$fname can be a path to a file, or a string reference, $args is a hash ref with
values of information that is passed to template toolkit.  $string can be a 
reference to a string variable, or to an array ref, in which case the results
are pushed into that array.  If $string is not defined, then the results are
appended to $s->{content}.

 $s->tt('object/template.tt', { s => $s, hash => \%hash });
 $s->tt('object/template.tt', { s => $s, list => \@list },\$output);
 $s->tt(\$template, { s => $s },\@output);

=cut

	my $s = shift;
	my $fname = shift;
	my $args = shift;
	my $string = shift;

	#my $agentfname;
	#if ($s->{agent}) {
	#	($fname = $agentfname) =~ s/([^\/]+\.tt)$/$s->{agent}\/$1/;
	#}

	$fname .= '.xml' if ($s->{api});

	if (defined $string) {
		if (ref $string eq 'ARRAY') {
			my $tmp;
			$s->{tt}->process($fname,$args,\$tmp) || croak $s->{tt}->error();
			push @{$string}, $tmp;
		} else {
			$s->{tt}->process($fname,$args,$string) || croak $s->{tt}->error();
		}
	} else {
		$s->{tt}->process($fname,$args) || croak $s->{tt}->error();
	}

}

=head2 update_and_log

 $s->update_and_log(
 	table => tablename,
	idfield => idfield,
	object => object,
	id => id,
	existing => \%hash,
	update => \%hash);

=cut 

sub update_and_log {
	my $s = shift;
	my %args = @_;

	croak "Missing table" unless($args{table});
	croak "Missing idfield" unless($args{idfield});
	croak "Missing object" unless($args{object});
	croak "Missing id" unless($args{id});
	croak "Missing existing" unless(defined($args{existing}));
	croak "Missing update" unless(defined($args{update}));

	#croak "<pre>".Data::Dumper->Dump([\%{$args{update}}])."</pre>";
	my %update;
	foreach my $k (keys %{$args{update}}) {
		if (exists($args{existing}{$k})) {
			my $object;
			if ($args{update}{$k} =~ m/^(.+):(\d*)$/) {
				$object = $1;
				$args{update}{$k} = $2;
			}

			if ($args{update}{$k} ne $args{existing}{$k}) {
				$update{$k} = $args{update}{$k};
				my $old = $args{existing}{$k};
				my $new = $update{$k};
				my $field = $k;
				if ($object) {
					$field = $object;
					$old = $s->db_q("SELECT name
						FROM ${object}s_v_keyval
						WHERE id=?
						",'scalar',
						v => [ $args{existing}{$k} ])
						if ($args{existing}{$k});

					$new = $s->db_q("SELECT name
						FROM ${object}s_v_keyval
						WHERE id=?
						",'scalar',
						v => [ $update{$k} ])
						if ($update{$k});
				}

				$s->log($args{object},$args{id},
					"$args{object} $field changed from [$old] to [$new]");
			}
		} else {
			croak "Existing data for $args{object} field $k not defined";
		}
	}

	#croak "<pre>".Data::Dumper->Dump([\%update])."</pre>";
	if (keys %update) {
		$s->db_update_key($args{table},$args{idfield},$args{id},\%update);
	}
}

sub in_to_hash {

=head2 in_to_hash

 my %hash = $s->in_to_hash($identifier,[$noblanks]);

=cut 

	my $s = shift;
	my $identifier = shift;
	my $noblanks = shift;

	my %tmp;

	foreach my $key (keys %{$s->{in}}) {
		if ($key =~ m/^$identifier:(.+):(.+)$/) {
			if ($noblanks) {
				$tmp{$1}{$2} = $s->{in}{$key}
					unless($s->{in}{$key} eq '');
			} else {
				$tmp{$1}{$2} = $s->{in}{$key};
			}
		}
	}

	return %tmp;
}

sub log {

=head2 log

 $s->log($ref,$ref_id,$msg);

=cut 

	my $s = shift;
	my $ref = shift;
	my $ref_id = shift;
	my $msg = shift;

	$s->db_insert('logs',{
		employee_id => $s->{employee_id},
		ref => $ref,
		ref_id => $ref_id,
		log_msg => (substr $msg, 0, 255),
		});
}

sub xsave_pdf {

=head2 xsave_pdf

 $s->xsave_pdf($pdf_name,$fname,$args);

=cut

	my $s = shift;
	my $pdf_name = shift;
	my $fname = shift;
	my $args = shift;

	$s->xpdf($pdf_name,$fname,$args);

	delete $s->{r}{file_path};
	delete $s->{r}{filename};
	delete $s->{content_type}; 
}

sub save_pdf {

=head2 save_pdf

 $s->save_pdf($pdf_name,$fname,$args);

=cut

	my $s = shift;
	my $pdf_name = shift;
	my $fname = shift;
	my $args = shift;

	$s->pdf($pdf_name,$fname,$args);

	delete $s->{r}{file_path};
	delete $s->{r}{filename};
	delete $s->{content_type}; 
}

sub xpdf {

=head2 xpdf

 $s->xpdf($pdf_name,$fname,$args);

=cut

	my $s = shift;
	my $pdf_name = shift;
	my $fname = shift;
	my $args = shift;

	my $html;

	my $tmpfile = "/tmp/$pdf_name";
	my $outfile = "/tmp/$pdf_name.pdf";

	unlink $outfile if (-e $outfile);

	my $id = time;

	if (ref $args->{pages} eq 'ARRAY') {
		my $pages = scalar @{$args->{pages}};
		for my $i ( 0 .. $pages-1 ) {
			my $pg = $i+100;
			open F, ">$tmpfile-$id-$pg.html";
			print F $args->{pages}[$i];
			close F;
		}
	} else {
		$s->tt($fname, $args, \$html);
		open F, ">$tmpfile-$id-0.html";
		print F $html;
		close F;
	}

	my $opts = "--quiet --css /data/$s->{obase}/content/css/print.css";

	my $err;
	open ERR, "/usr/bin/xhtml2pdf $opts $tmpfile-$id-*.html $outfile 2>&1 |";
	while (<ERR>) {
		$err .= $_;
	}
	close ERR;

	unless (-e $outfile) {
		croak "Error creating print file $outfile\n$err";
	}

#	if ($err) {
#		croak "Error creating print file $outfile\n$err";
#	}

	`rm $tmpfile-*.html`;

	$s->{r}{file_path} = $outfile;
	$s->{r}{filename} = "$pdf_name.pdf";
	$s->{content_type} = $s->mime_type();
}

sub pdf {

=head2 pdf

 $s->pdf($pdf_name,$fname,$args);

=cut

	my $s = shift;
	my $pdf_name = shift;
	my $fname = shift;
	my $args = shift;

	my $html;

	my $tmpfile = "/tmp/$pdf_name";
	my $outfile = "/tmp/$pdf_name.pdf";

	unlink $outfile if (-e $outfile);

	my $id = time;

	if (ref $args->{pages} eq 'ARRAY') {
		my $pages = scalar @{$args->{pages}};
		#for my $i ( 0 .. $#{@{$args->{pages}}} ) {
		for my $i ( 0 .. $pages-1 ) {
			my $pg = $i+100;
			open F, ">$tmpfile-$id-$pg.html";
			print F $args->{pages}[$i];
			close F;
		}
	} else {
		$s->tt($fname, $args, \$html);
		open F, ">$tmpfile-$id-0.html";
		print F $html;
		close F;
	}

	my $opts = "--quiet --top 0.5in --bottom 0.5in --left 0.5in --right 0.5in ".
		"--webpage --bodyfont Helvetica --footer . --no-numbered ".
		"--outfile $outfile";

	my $err;
	open ERR, "/usr/bin/htmldoc $opts $tmpfile-$id-*.html 2>&1 |";
	while (<ERR>) {
		$err .= $_;
	}
	close ERR;

	unless (-e $outfile) {
		croak "Error creating print file $outfile\n$err";
	}

#	if ($err) {
#		croak "Error creating print file $outfile\n$err";
#	}

	`rm $tmpfile-*.html`;

	$s->{r}{file_path} = $outfile;
	$s->{r}{filename} = "$pdf_name.pdf";
	$s->{content_type} = $s->mime_type();
}

sub alert {

=head2 alert

 $s->alert($message,$croak);

=cut

	my $s = shift;
	my $message = shift;
	my $croak = shift;

	my $alert;

	if ($croak && !$s->{env}{DEV}) {
		# check and see if this is a common database error we just want to capture and report
		# in a different way
		if ($croak =~ m/^ERROR:\s+invalid input syntax for type date:\s+"(.+)"/) {
			$message = "'$1' is not a valid date";
			$croak = 0;
		} elsif ($croak =~ m/^ERROR:\s+null value in column "(.+)" violates not-null constraint/) {
			$message = "The database field '$1' can not be null/empty.  Is there a for field that you left blank that needed to be filled in?";
			$croak = 0;
		} elsif ($croak =~ m/^ERROR:\s+invalid input syntax for integer: "(.+)"/) {
			$message = "'$1' is not a valid integer";
			$croak = 0;
		}

	}

	if ($s->{raw_message}) {
		$s->{raw_message} .= "\n";
	}
	$s->{raw_message} .= $message;

	my $class = ($croak) ? 'alert' : 'warning';

	if ($s->{o}{perl_dump}) {
		$s->{perl_dump}{error} = $message;
	} elsif (!defined($s->{tt})) {
		print "alert: $message\n";
		$s->{message} .= $message;
	} else {
		if ($s->{quiet_errors} && $croak) {
			$message = "Sorry an error has occured";
		}
		$s->tt('alert.tt', { s => $s, message => $message, class => $class }, \$alert);
		$s->{message} .= $alert;
	}


	# add some debugging information so we know where the error is getting called from
	#$s->{message} .= "<pre>".Carp::longmess('Stack-Trace')."</pre>";

	if ($croak && $s->{object} ne 'e') {
		$s->send_error($croak);
	}
}

sub send_error {

=head2 send_error

 $s->send_error($msg);

=cut

	my $s = shift;
	my $msg = shift;

	# make sure we do not report errors to ourself, otherwise we go into a circular loop!
	# if this was a croak, it means that we should record this error into the main error
	# recording system
	my $error = $s->escape($msg);
	my $employee = '<employee>'.$s->escape("$s->{employee_id} $s->{employee}{name}").
		'</employee>' if ($s->{employee_id});
	my $in = $s->escape(Data::Dumper->Dump([\%{$s->{in}}]));
	my $env = $s->escape(Data::Dumper->Dump([\%{$s->{env}}]));
	my $session = $s->escape(Data::Dumper->Dump([\%{$s->{session_data}}]));
	my $uri = $s->escape($s->{uri});

	my $xml = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<error>
	<message>$error</message>
	$employee
	<var_in>$in</var_in>
	<uri>$uri</uri>
	<var_env>$env</var_env>
	<remote_addr>$s->{remote_addr}</remote_addr>
	<server_name>$s->{server_name}</server_name>
	<session_data>$session</session_data>
</error>
END

	my $ua = new LWP::UserAgent;
	$ua->timeout(5);
	my $req = new HTTP::Request('POST' => "http://erp.smalldognet.com/sdnerp/e");
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($xml);

	$ua->request($req);
}	

sub lwp_xml {
	my $s = shift;
	my $url = shift;

	my $ua = new LWP::UserAgent;
	my $req = new HTTP::Request('GET' => $url);
	my $resp = $ua->request($req);

	if ($resp->is_success) {
		my $content = $resp->content;
		my $xml = eval { XMLin($content); };
		if ($@) {
			croak "Failed to eval returned xml: $@";
		} else {
			return $xml;
		}
	} else {
		croak "Request to $url failed";
	}
}

sub confirm {

=head2 confirm

 $s->confirm($msg);

=cut

	my $s = shift;
	my $message = shift;

	$s->tt('confirm.tt', { s => $s, message => $message });
}

sub notify {

=head2 notify

 $s->notify($msg);

=cut

	my $s = shift;
	my $message = shift;

	if ($s->{employee_id}) {
		my $notify;
		$s->tt('notify.tt', { s => $s, message => $message}, \$notify);
	
		$s->{message} .= $notify;
	}
}

sub run {
	my $s = shift;

	# first we need a database connection but not for our database debug option
	$s->{dbh} = db_connect($s->{env}{DB_STRING},$s->{env}{DB_USER})
		unless($s->{object} eq 'dbdb');

	#get_memd($s);

	# figure out where our base code directory is so we can use templates
	# and other things
	foreach my $i (@INC) {
		if (-d "$i/Apache/SdnFw") {
			$s->{plib} = "$i/Apache/SdnFw";
			last;
		}
	}

	my @path;
	if ($s->{agent}) {
		push @path, "$ENV{HTTPD_ROOT}/$s->{obase}/tt/$s->{agent}";
		push @path, "$ENV{HTTPD_ROOT}/$s->{obase}/object";
		push @path, "$ENV{HTTPD_ROOT}/$s->{obase}/tt";
		push @path, "$s->{plib}/tt/$s->{agent}";
		push @path, "$s->{plib}/tt";
		push @path, "$s->{plib}/object";
	} else {
		push @path, "$ENV{HTTPD_ROOT}/$s->{obase}/object";
		push @path, "$ENV{HTTPD_ROOT}/$s->{obase}/tt";
		push @path, "$s->{plib}/tt";
		push @path, "$s->{plib}/object";
	}
	push @path, "/data/$s->{obase}";
	$s->{tt} = Template->new(
		INCLUDE_PATH => \@path,
		INTERPOLATE => 1,
		RELATIVE => 1,
		EVAL_PERL => 1,
		COMPILE_DIR => '/tmp/tt_cache',
		COMPILE_EXT => '.cache',
		# remove leading and trailing whitespace and newlines
		#PRE_CHOMP => 2,
		#POST_CHOMP => 2,
		#STAT_TTL => 1,
		OUTPUT => \$s->{content},
		);

	#$s->{content} .= "<pre>".Data::Dumper->Dump([$s])."</pre>"; return;
	#$s->{content} .= "<pre>".Data::Dumper->Dump([\@INC])."</pre>"; return;

#	if ($s->{raw_path} eq '/logout') {
#		return unless($s->_authenticate());
#	}

	# if we barf below anywhere we do not want to show anything but the raw error so set this
	$s->{nomenu} = 1; 

	# at this point, we need to look for $object
	# and from there $function
	# and make it into a path that we can then run
	# $object will be things like /objectname
	# or /objectname/function
	# and will only go two levels deep
	@{$s->{path}} = split '/', $s->{raw_path};
	shift @{$s->{path}}; # get rid of the blank due to starting with /
	if (scalar @{$s->{path}} < 1) {
		# set home if we did not explicitly call a object
		push @{$s->{path}}, 'home';
	}

	# make sure we are not trying to call strange stuff
	foreach my $v (@{$s->{path}}) {
		croak "invalid path value '$v'" unless($v =~ m/^[a-z0-9_\.]+$/);
	}

	croak "invalid path (more than 2 keys)" if (scalar @{$s->{path}} > 2);
	$s->{object} = $s->{path}[0];
	$s->{function} = $s->{path}[1] || 'list';

	# this is a stupid hack because I could not create an object called return
	$s->{object} = 'oreturn' if ($s->{object} eq 'return');

	if ($s->{object} eq 'logout') {
		$s->_authenticate();
		$s->{function} = 'home' if ($s->{function} eq 'list');
		$s->redirect(object => $s->{function},
			function => 'list');
		return;
	}

	if ($s->{env}{DEV} && $s->{object} eq 'debug') {
		$s->{content} = Data::Dumper->Dump([$s]);
		$s->{content_type} = 'text/plain';
		return;
	}

	no strict 'refs';
	if ($s->{object} ne 'help') {
		$s->{obj_base} = $s->{obase}.'::object::'.$s->{object};
		my $config = $s->{obj_base}.'::config';
	
		# make sure we can find the object
		unless(defined(&{$config})) {
			# see if there is a generic object defined
			$s->{obj_base} = 'Apache::SdnFw::object::'.$s->{object};
			eval "use $s->{obj_base}";
			$config = $s->{obj_base}.'::config';
			unless(defined(&{$config})) {
				$s->alert("Sorry, I have no idea what a $s->{object} is, or how to $s->{function} it ($config)");
				return;
			} else {
				$s->{generic_object} = 1;
			}
		}

		$s->{o} = &{$config}($s);
	}

	# clear the no menu now
	delete $s->{nomenu};

	unless ($s->{o}{public}) {
		# then we need to authenticate the person
		return unless($s->_authenticate());
	} else {
		# a public interface, but we still need to authorize them
		# but they are not an employee
		if ($s->{o}{auth}) {
			return unless($s->_interface_auth());
		} elsif ($s->{o}{local_auth}) {
			my $auth = $s->{obj_base}.'::auth';
			return unless(&{$auth}($s));
		}
		# so we don't show anything but the raw html that the public thing spits out
		$s->{nomenu} = 1; 
	}

	if ($s->{object} eq 'home' && $s->{function} eq 'list' && $s->{api}) {
		_api_calls($s);
		return;
	}

	$s->{log_user} = $s->{employee_id} if ($s->{employee_id});

	$s->session_load();

	#croak "<pre>".Data::Dumper->Dump([$s])."</pre>";

	# make sure we actually have functions defined
	if ($s->{object} ne 'help') {
		unless(defined($s->{o}{functions})) {
			$s->alert("Sorry, there were no functions defined for $s->{object}");
			return;
		}
	}

	if ($s->{object} eq 'help') {
		return unless($s->help());
	} elsif ($s->{function} eq 'permission') {
		return unless($s->permission());
	} else {
		# confirm access to this function by this person
		if ($s->{o}{public}) {
			1;
		} elsif ($s->{object} eq 'me') {
			# just confirm we have an employee_id
			unless($s->{employee_id}) {
				$s->alert("Missing or invalid employee_id");
				return;
			}
		} else {
			return unless($s->access($s->{function}));
		}

		# run our pre logic
		my $pre = $s->{obase}.'::object::config::pre';
		if (defined(&{$pre})) {
			return unless(&{$pre}($s));
		}

		my $addhelp;
		if ($s->{employee}{admin}) {
			$addhelp = 1; # add a help link for admin
		} else {
			if (-e "/data/$s->{obase}/template/help/$s->{object}.tt") {
				$addhelp = 1;
			}
		}

		$s->add_action(object => 'help',
			title => 'help',
			function => $s->{object}) if ($addhelp && !$s->{agent});

		return unless($s->call($s->{function}));
	}

	if ($s->{object} ne 'help') {
		# do any post processing
		my $post = $s->{obase}.'::object::config::post';
		if (defined(&{$post})) {
			&{$post}($s);
		}
	}

	#$s->{content} .= "<pre>".Data::Dumper->Dump([$s])."</pre>";
}

sub call {
	my $s = shift;
	my $f = shift;

	# make sure it's a valid function
	unless(defined($s->{o}{functions}{$f})) {
		$s->alert("Sorry, $f is not defined for $s->{object}");
		return 0;
	}

	my $function = $s->{obj_base}.'::'.$f;

	no strict 'refs';
	# do a final check to see if the function is valid
	# and maybe call the generic function
	unless (defined(&{$function})) {
		$function = 'generic_'.$f;
		unless(defined(&{$function})) {
			$s->alert("Sorry, you can not $f a $s->{object}");
			return 0;
		}
	}

	# setup some convience variables so we have to type less
	$s->{uof} = "$s->{ubase}/$s->{object}/$s->{function}";
	$s->{uo} = "$s->{ubase}/$s->{object}";

	if ($s->{o}{log_stderr}) {
		my $dd = Data::Dumper->new([\%{$s->{in}}],[qw(data)]);
		$dd->Indent(0);
		$s->db_insert('object_debug',{
			o => $s->{object},
			f => $s->{function},
			i => $dd->Dump(),
			});
	}

	# actually call the function
	eval {
		&{$function}($s);
		};

	if ($@) {
		# force text/html just in case so we always return html....
		$s->{content_type} = 'text/html';
		if ($s->{dbh}->{AutoCommit} == 0) {
			$s->{dbh}->rollback;
		}
		# check for database errors and report them differently.....
		if ($@ =~ m/^ERROR:\s+alert:(.+)/) {
			$s->alert($1);
		} elsif ($@ =~ m/^alert:(.+)/) {
			my $msg = $1;
			$msg =~ s/ at \/usr.+$//g;
			$s->alert($msg);
		} elsif ($s->{api}) {
			$s->alert($@,$@);
		} else {
			$s->alert("<pre>$@</pre>",$@);
		}
	}
}

sub build_x12 {

=head2 build_x12

 my %hash = $s->build_x12($doctype,\%vendor,\%data);

This function looks for a perl parser file for the specific vendor
for the specific $doctype (850, 855, 856, 810, etc) and returns 
a hash which can then be fed into format_x12.

=cut

	my $s = shift;
	my $doctype = shift;
	my $vendor = shift;
	my $data = shift;

#	my $function = $s->{obj_base}.'::'.$f;

	croak "Unknown vendor code" unless($vendor->{code});
	croak "Missing doctype" unless($doctype);

	#croak "vendor=".Data::Dumper->Dump([$vendor]);
	#croak "data=".Data::Dumper->Dump([$data]);

	my $base = $s->{obase} || $s->{env}{OBJECT_BASE};
	my $package = $base.'::edimap::'.$vendor->{code}.'::'.$doctype;

	no strict 'refs';

	eval "use $package";

	my $function = $package.'::build';

	my %return = &{$function}($s,$vendor,$data);

	return %return;
}

sub format_x12 {

=head2 format_x12

 my $x12 = $s->format_x12($vendor_edi_document_id,\%data);

=cut

	my $s = shift;
	my $vendor_edi_document_id = shift;
	my $data = shift;

	my @list = $s->db_q("
		SELECT segment_code, segment_order, element_code,
			element_order, name, element_type, min_length,
			max_length, segment_option
		FROM vendor_edi_segment_elements_v
		WHERE vendor_edi_document_id=?
		ORDER BY segment_order, element_order
		",'arrayhash',
		v => [ $vendor_edi_document_id ]);

	unless(defined($data->{vendor})) {
		croak "Missing vendor information in data";
	}

	my %work;
	foreach my $ref (@list) {
		my $segment_code = $ref->{segment_code};
		unless(defined($work{segment}{$segment_code})) {
			push @{$work{segments}}, $segment_code;
			$work{segment}{$segment_code}{loop} = $ref->{segment_option};
		}

		push @{$work{segment}{$segment_code}{elements}}, {
			element_code => $ref->{element_code},
			element_order => $ref->{element_order},
			name => $ref->{name},
			element_type => $ref->{element_type},
			min_length => $ref->{min_length},
			max_length => $ref->{max_length},
			};
	}

#	croak "test".Data::Dumper->Dump([\%work]);
	my %loops_completed;
	my $output;
	foreach my $seg (@{$work{segments}}) {
		if ($work{segment}{$seg}{loop}) {
			my $loop = $work{segment}{$seg}{loop};
			next if (defined($loops_completed{$loop}));
			# our segment is within a loop, so lets look in that loop instead
			# but only if we have not visited the loop before
			next unless(defined($data->{$loop}));
			foreach my $loop_ref (@{$data->{$loop}}) {
				my $loop_seg = $loop_ref->{key};
				croak "Missing key in loop segment" unless($loop_seg);
				my $elements = $work{segment}{$loop_seg}{elements};
				$output .= _output_x12_segment($s,$elements,$loop_seg,$loop_ref);
				$output .= $data->{vendor}{segment_term}."\n";
			}
			$loops_completed{$loop} = 1;
		} elsif (defined($data->{$seg})) {
			my $elements = $work{segment}{$seg}{elements};
			$output .= _output_x12_segment($s,$elements,$seg,\%{$data->{$seg}});
			$output .= $data->{vendor}{segment_term}."\n";
		}
	}

	return $output;
}

sub _output_x12_segment {
	my $s = shift;
	my $elements = shift;
	my $seg_code = shift;
	my $hashref = shift;

	my $max_order = _max_order($hashref);

	my @list;
	push @list, $seg_code;
	foreach my $eref (@{$elements}) {
		next if ($eref->{element_order} > $max_order); # do not do elements higher
		my $n = $eref->{element_order};
		my $value = (defined($hashref->{$n}))
			? $hashref->{$n}
			: '';
		$value =~ s/\*//g;

		if ($eref->{element_type} eq 'DT') {
			if ($eref->{min_length} == 6) {
				$value =~ s/^20//;
			}
			$value =~ s/-//g;
		}

		if ($eref->{element_type} eq 'TM') {
			$value =~ s/\D//;
		}

		if (defined($hashref->{$n})) {
			if ($eref->{min_length} > 1) {
				if (length $value < $eref->{min_length}) {
					if ($eref->{element_type} eq 'AN') {
						while (length $value < $eref->{min_length}) {
							$value .= ' ';
						}
					} else {
						while (length $value < $eref->{min_length}) {
							$value = "0$value";
						}
					}
				}
			}
		}

		if ($eref->{max_length}) {
			if (length $value > $eref->{max_length}) {
				$value = substr $value, 0, $eref->{max_length};
			}
		}
		push @list, $value;
	}
	
	my $output = (join '*', @list);
	return $output;
}

sub _max_order {
	my $hashref = shift;

	my $order = 0;
	foreach my $k (keys %{$hashref}) {
		$order = $k if ($k > $order);
	}
	return $order;
}

sub verify_x12 {
	my $s = shift;
	my $vendor = shift;
	my $dataref = shift;

	# all we do here right now is make sure our header envelope matches who we think
	# is sending to use, and who they thing they are sending to....

	my %check = (
		partner_edi_identifier => 'ISA08',
		partner_edi_qualifier => 'ISA07',
		vendor_code => 'ISA06',
		vendor_code_qual => 'ISA05',
		);

	foreach my $k (keys %check) {
		my $value = $dataref->{$check{$k}};
		$value =~ s/\s//g;
		croak "No $k to compare" unless($vendor->{$k});
		croak "Database $k value $vendor->{$k} != X12 $check{$k} value $value"
			if ($vendor->{$k} ne $value);
	}
}

sub parse_x12 {
	my $s = shift;
	my $vendor = shift;
	my $input = shift;

#print "Input=$input\n";

	$vendor->{element_sep} = '\*' if ($vendor->{element_sep} eq '*');
	# kill cr
	$input =~ s/\r//g;
	if ($vendor->{segment_term}) {
		# if we have an actual character terminator, then kill all newlines
		$input =~ s/\n//g unless($vendor->{segment_term} eq "\n");
	} else {
		# use newline as our terminator
		$vendor->{segment_term} = "\n";
	}

#print "Input2=$input\n";
	my @data;
	foreach my $seg (split $vendor->{segment_term}, $input) {
		my @e = split $vendor->{element_sep}, $seg;
		push @data, [ @e ];
	}

#print " ".Data::Dumper->Dump([\@data]);

	my %x;
	my %work;
	unless($vendor->{partner_edi_identifier} && $vendor->{partner_edi_qualifier}) {
		croak "Partner $vendor->{partner_id}} has unknown identifier or qualifier";
	}

	my $dt;
	my $i_ref = undef;
	my $g_ref = undef;
	my $s_ref = undef;
	foreach my $seg (@data) {
		#print "Processing $seg->[0]\n" if ($args{v});
		unless(defined($i_ref)) {
			if ($seg->[0] eq 'ISA') {
				%x = _x12_map($s,$vendor->{edi_version_id},'ISA',$seg);
				if ($x{error}) {
					croak $x{error};
				}
				$x{groups} = [];
				$i_ref = $x{groups};
				$x{group_count} = 0;
				#print $seg->[0].": ".Data::Dumper->Dump([\%x]) if ($args{v});
				next;
			} else {
				croak "ISA not found";
			}
		}

		if ($seg->[0] eq 'IEA') {
			$dt = 'HEAD';
			#		print $seg->[0].": ".Data::Dumper->Dump([\%tmp]) if ($args{v});
			my %tmp = _x12_map($s,$vendor->{edi_version_id},'IEA',$seg);
			if ($tmp{error}) {
				croak $tmp{error};
			} elsif ($tmp{IEA01} != $x{group_count}) {
				$x{error} = "Group count in IEA ($tmp{IEA01}) ne groups ($x{group_count})";
			} elsif ($tmp{inter_control_num} ne $x{inter_control_num}) {
				$x{error} = "IEA control num ne ISA control number";
			}
			last;
		}
	
		if ($seg->[0] eq 'GE') {
			$dt = 'HEAD';
			# we need to count ourself
			#$g_ref->{set_count}++;
			my %tmp = _x12_map($s,$vendor->{edi_version_id},'GE',$seg);
			#print $seg->[0].": ".Data::Dumper->Dump([\%tmp]) if ($args{v});
			if ($tmp{error}) {
				$g_ref->{error} = $tmp{error};
			} elsif ($tmp{GE01} != $g_ref->{set_count}) {
				$g_ref->{error} = "Set count in GE ($tmp{GE01}) ne sets ($g_ref->{set_count})";
			} elsif ($tmp{group_control_num} ne $g_ref->{group_control_num}) {
				$g_ref->{error} = "GE control num ne GS control number";
			}
			$g_ref = undef;
			next;
		}

		if ($seg->[0] eq 'SE') {
			$dt = 'HEAD';
			# we need to count ourself
			$s_ref->{segment_count}++;
			my %tmp = _x12_map($s,$vendor->{edi_version_id},'SE',$seg);
			#print $seg->[0].": ".Data::Dumper->Dump([\%tmp]) if ($args{v});
			#print Data::Dumper->Dump([$s_ref]);
			if ($tmp{error}) {
				$s_ref->{error} = $tmp{error};
			} elsif ($tmp{SE01} != $s_ref->{segment_count}) {
				$s_ref->{error} = "Segment count in SE ($tmp{SE01}) ne segments ($s_ref->{segment_count})";
			} if ($tmp{SE02} ne $s_ref->{ST02}) {
				$s_ref->{error} = "SE control num $tmp{SE02} ne ST control number $s_ref->{ST02}";
			}
			$s_ref = undef;
			next;
		}

		unless(defined($g_ref)) {
			if ($seg->[0] eq 'GS') {
				my %tmp = _x12_map($s,$vendor->{edi_version_id},'GS',$seg);
				if ($tmp{error}) {
					croak $tmp{error};
				}
				#print $seg->[0].": ".Data::Dumper->Dump([\%tmp]) if ($args{v});
				$tmp{sets} = [];
				$tmp{set_count} = 0;
				# make sure they are sending to the right person
#				unless($tmp{GS03} eq $work{partner}{edi_identifier}) {
#					# kill this group because we did not match
#					# our Data Interchange Control Number is GS06
#					$tmp{error} = "Document Identifier $tmp{GS03} does not match partner identifier $work{partner}{edi_identifier}";
#				}
	
				push @{$i_ref}, { %tmp };
				$g_ref = $i_ref->[$x{group_count}];
				$x{group_count}++;
	
				#	croak "test: ".Data::Dumper->Dump([\%tmp]);
				# now that we have the group, we need to load the
				# rest of the data matching this version and for this
				# vendor/partner
				#_loadmap($tmp{GS08},$tmp{GS02});
				next;
			} else {
				croak "GS not found";
			}
		}
	
		unless(defined($s_ref)) {
			if ($seg->[0] eq 'ST') {
				$dt = 'HEAD';
				my %tmp = _x12_map($s,$vendor->{edi_version_id},'ST',$seg);
				if ($tmp{error}) {
					croak $tmp{error};
				}
				# do we have this document for this vendor, and is it the right version?
			#	unless(defined($work{vendor_documents}{$tmp{ST01}}) &&
			#		$g_ref->{GS08} eq $work{vendor_documents}{$tmp{ST01}}{version_code}) {
			#		$tmp{error} = "Document $tmp{ST01}/$g_ref->{GS08} not defined for vendor";
			#	}
				#croak "test: ".Data::Dumper->Dump([\%tmp]);
				$tmp{segments} = [];
				$tmp{segment_count} = 1;
				push @{$g_ref->{sets}}, { %tmp };
				$s_ref = $g_ref->{sets}[$g_ref->{set_count}];
				$g_ref->{set_count}++;
				$dt = $tmp{ST01};
				next;
			} else {
				croak "ST not found";
			}
		}

		my %hash = _x12_map($s,$vendor->{edi_version_id},$seg->[0],$seg);
#		print $seg->[0].": ".Data::Dumper->Dump([\%hash]) if ($args{v});
		push @{$s_ref->{segments}}, { %hash } if (keys %hash);
		$s_ref->{segment_count}++;
	}

	return %x;
}

sub _x12_map {
	my $s = shift;
	my $version = shift;
	my $type = shift;
	my $arrayref = shift;

	# load up our segment information first
	# if it is not defined yet
	unless(defined($s->{x12map}{$type})) {
		%{$s->{x12map}{$type}} = $s->db_q("
			SELECT s.segment_code, se.element_order, e.*,
				s.segment_code || to_char(se.element_order,'FM00') as key
			FROM edi_segments s
				JOIN edi_segment_elements se ON s.edi_segment_id=se.edi_segment_id
				JOIN edi_elements e ON se.element_code=e.element_code
			WHERE s.segment_code=?
			AND s.edi_version_id=?
			",'hashhash',
			k => 'element_order',
			v => [ $type, $version ]);

	#	unless(keys %{$s->{x12map}{$type}}) {
	#		croak "No keys found for segment $type version $version";
	#	}
	}

	my $mapref = $s->{x12map}{$type};

	my %hash;
	my %error;

	for my $i ( 1 .. $#{$arrayref}) {
		next unless(defined($mapref->{$i}));
	
		my $value = $arrayref->[$i];
		my $length = length $value;
		my $key = $mapref->{$i}{key};

		# does a required field have values?
		if ($mapref->{$i}{option} eq 'M' && $length == 0) {
			$error{error} = "required field $key ($i) missing data";
			return %error;
		}

		if ($length && $mapref->{$i}{min}) {
			my $min = $mapref->{$i}{min};
			my $max = $mapref->{$i}{max};
			# is the value the correct length
			if ($length < $min || $length > $max) {
				$error{error} = "field $key ($i) length invalid ($min < $length < $max)";
				return %error;
			}
		}

		if ($length) {
			# only test the rest of this if we actually have a value
			if ($mapref->{$i}{element_type} =~ m/^N(\d)$/) {
				if ($1 && $value ne '') {
					if ($1 == 1 && $value =~ m/^-?\d+\d{1}$/) {
						$value = sprintf "%.1f", $value/10;
					} elsif ($1 == 2 && $value =~ m/^-?\d+\d{2}$/) {
						$value = sprintf "%.2f", $value/100;
					} else {
						$error{error} = "field $key ($i) [$value] not type $mapref->{$i}{element_type}";
						return %error;
					}
				} elsif ($value ne '') {
					unless($value =~ m/^-?\d+$/) {
						$error{error} = "field $key ($i) [$value] not type $mapref->{$i}{element_type}";
						return %error;
					}
				}
			}
	
			if ($mapref->{$i}{element_type} eq 'DT') {
				# DATE
				if ($value =~ m/^(\d{4})(\d{2})(\d{2})$/) {
					$value = "$1-$2-$3";
				} elsif ($value =~ m/^(\d{2})(\d{2})(\d{2})$/) {
					$value = "20$1-$2-$3";
				} else {
					$error{error} = "field $key ($i) [$value] not type DT";
					return %error;
				}
			}
	
			if ($mapref->{$i}{element_type} eq 'TM') {
				if ($value =~ m/^(\d{2})(\d{2})(\d{0,2})$/) {
					$value = "$1:$2";
					$value .= ":$3" if ($3);
				} else {
					$error{error} = "field $key ($i) [$value] not type TM";
					return %error;
				}
			}
		}

		$hash{$key} = $value;
	}

	return %hash;
}

sub send_x12_ack {
	my $s = shift;
	my $vendor = shift;
	my $dataref = shift;
	my $edi_trans_id = shift;

	my %doc = $s->db_q("
		SELECT *
		FROM vendor_edi_documents_v
		WHERE edi_vendor_id=?
		AND document_code='997'
		",'hash',
		v => [ $vendor->{edi_vendor_id} ]);

	unless($doc{vendor_edi_document_id}) {
		croak "Can not find 997 document for vendor $vendor->{edi_vendor_id}";
	}

	my %out;

	$s->x12_add_isa($vendor,\%out,$edi_trans_id);
	$s->x12_add_gs('FA',$vendor,\%out,$edi_trans_id);
	
	croak "No Groups" unless (ref $dataref->{groups} eq 'ARRAY');
	croak "More than 1 Group" if (scalar @{$dataref->{groups}} > 1);

	$s->x12_add_st('997',$dataref->{ISA13},\%out);

	# process everything now

	foreach my $gref (@{$dataref->{groups}}) {
		croak "No Sets in group" unless (ref $gref->{sets} eq 'ARRAY');
		$out{AK1}{1} = $gref->{GS01}; # these are things like IM, PO, etc
		$out{AK1}{2} = $gref->{GS06};
		$out{AK9}{2} = 0; # number of sets
		$out{AK9}{3} = 0; # received
		$out{AK9}{4} = 0; # accepted
		if (scalar @{$gref->{sets}} ne $gref->{set_count}) {
			croak "Sets array does not equal set count";
		}
		foreach my $sref (@{$gref->{sets}}) {
			$out{AK9}{2}++;
			$out{AK9}{3}++;
			$out{AK9}{4}++;
			croak "No Segments in set" unless (ref $sref->{segments} eq 'ARRAY');
			push @{$out{loop}}, {
				key => 'AK2',
				1 => $sref->{ST01},
				2 => $sref->{ST02},
				};
			$out{SE}{1}++; 
			push @{$out{loop}}, {
				key => 'AK5',
				1 => 'A',
				};
			$out{SE}{1}++; 
		}
		# accept if we had no errors
		$out{AK9}{1} = 'A' if ($out{AK9}{2} == $out{AK9}{4}); # accepted
		$out{AK9}{1} = 'P' if ($out{AK9}{2} > $out{AK9}{4} && $out{AK9}{4}); # partial accept
		$out{AK9}{1} = 'R' unless ($out{AK9}{4}); # reject all
		$out{SE}{1}++; # for the AK1
		$out{SE}{1}++; # for the AK9
	}

	#print Data::Dumper->Dump([\%out]);
 	my $x12 = $s->format_x12($doc{vendor_edi_document_id},\%out);
	#print $x12;
	$s->send_x12('997',$x12,$vendor->{edi_vendor_id},$edi_trans_id);
}

sub x12_add_isa {
	my $s = shift;
	my $vendor = shift;
	my $out = shift;

	my $edi_trans_id = $s->db_insert('edi_transactions',{
		filename => 'n/a',
		},'edi_trans_id');

	$out->{vendor} = $vendor;
	$out->{edi_trans_id} = $edi_trans_id;

	if ($s->{env}{DEV}) {
		foreach my $k (qw(vendor_code vendor_code_qual)) {
			$vendor->{$k} = $vendor->{"test_$k"}
				if ($vendor->{"test_$k"});
		}
	}

	$out->{ISA}{1} = '00';
	$out->{ISA}{2} = '';
	$out->{ISA}{3} = '00';
	$out->{ISA}{4} = '';
	$out->{ISA}{5} = $vendor->{partner_edi_qualifier};
	$out->{ISA}{6} = $vendor->{partner_edi_identifier};
	$out->{ISA}{7} = $vendor->{vendor_code_qual};
	$out->{ISA}{8} = $vendor->{vendor_code};
	$out->{ISA}{9} = $s->{datetime}{ymd};
	$out->{ISA}{10} = (substr $s->{datetime}{ymdhms},8,2).
		(substr $s->{datetime}{ymdhms},10,2);
	$out->{ISA}{11} = 'U';
	$out->{ISA}{12} = '00401';
	$out->{ISA}{13} = $edi_trans_id; #control number
	$out->{ISA}{14} = '0'; # acknowledge (0,1)?
	$out->{ISA}{15} = ($s->{env}{DEV}) ? 'T' : 'P'; # usage (T = test, P = production)
	$out->{ISA}{16} = $vendor->{subelement_sep};

	$out->{IEA}{1} = 0; # populate our footer, so other things can count up as needed
	$out->{IEA}{2} = $out->{ISA}{13};
}

sub x12_add_gs {
	my $s = shift;
	my $groupid = shift;
	my $vendor = shift;
	my $out = shift;

	my $gs_id = $s->db_insert('edi_gs',{
		group_identifier => $groupid,
		edi_trans_id => $out->{edi_trans_id},
		edi_vendor_id => $vendor->{edi_vendor_id},
		},'edi_gs_id');

	$out->{edi_gs_id} = $gs_id;

	if ($s->{env}{DEV}) {
		foreach my $k (qw(vendor_code)) {
			$vendor->{$k} = $vendor->{"test_$k"}
				if ($vendor->{"test_$k"});
		}
	}

	$out->{GS}{1} = $groupid;
	$out->{GS}{2} = $vendor->{partner_edi_identifier};
	$out->{GS}{3} = $vendor->{vendor_code};
	$out->{GS}{4} = $s->{datetime}{ymd};
	$out->{GS}{5} = (substr $s->{datetime}{ymdhms},8,2).
		(substr $s->{datetime}{ymdhms},10,2);
	$out->{GS}{6} = $gs_id;
	$out->{GS}{7} = 'X';
	$out->{GS}{8} = '004010';

	$out->{IEA}{1}++;

	$out->{GE}{1} = 0; # populate our trailing group
	$out->{GE}{2} = $out->{GS}{6};
}

sub x12_add_st {
	my $s = shift;
	my $document = shift;
	my $id = shift;
	my $out = shift;

	my $st_id = $s->db_insert('edi_st',{
		edi_gs_id => $out->{edi_gs_id},
		document => $document,
		document_id => $id,
		},'edi_st_id');

	$out->{ST}{1} = $document;
	$out->{ST}{2} = $st_id;
	$out->{GE}{1}++;

	$out->{SE}{1} = 2; # include the ST and SE to start with
	$out->{SE}{2} = $st_id;
}

sub x12_add_segment {
	my $s = shift;
	my $code = shift;
	my $data = shift;
	my $out = shift;

	croak "Missing code" unless($code);
	croak "Data is not hash ref" unless(ref $data eq 'HASH');
	
	$data->{key} = $code;
	push @{$out->{segments}}, $data;

	$out->{SE}{1}++;
}

sub sync_x12 {
	my $s = shift;
	my $vendor = shift;

	croak "Unknown ftp type for that vendor" unless ($vendor->{ftp_type});
	croak "Unknown local working directory for that vendor" unless($vendor->{local_path});
	croak "Could not find local inbox for vendor" unless(-e "$vendor->{local_path}/inbox");
	#croak "Could not find local outbox for vendor" unless(-e "$vendor->{local_path}/outbox");

	my $ftp;
	if ($vendor->{ftp_type} eq 'ftps') {
		eval "use Net::FTPSSL";
		if ($@) { croak "$@"; }

		my ($server,$port) = split ':', $vendor->{ftp_server};
		print "Logging into $server : $port : $vendor->{ftp_username} : $vendor->{ftp_password}\n" if ($s->{v});
		$port = '21' unless($port);
		$ftp = Net::FTPSSL->new($server,
			Port => $port,
			useSSL => 1,
			Debug => 2,
			) 
			|| die "Can not connect to $vendor->{ftp_server}: $@";
		$ftp->login($vendor->{ftp_username},$vendor->{ftp_password}) 
			|| die "Login failed to $vendor->{ftp_server}: $@";

		print "Connected\n" if ($s->{v});
		my @dirs = $ftp->nlst();

		foreach my $d (@dirs) {
			if ($d =~ m/^(outbox|outgoing)$/i) {
				$ftp->cwd($d) || die "Error cwd to $d: ", $ftp->message;
				foreach my $f ($ftp->nlst()) {
					print "Downloading $f to inbox\n" if ($s->{v});
					$ftp->get($f,"$vendor->{local_path}/inbox/$f") || die "Error get $f: ",
						$ftp->message;
					$ftp->delete($f) || die "Error delete $f: ",
						$ftp->message;
				}
			}
		}
	} elsif ($vendor->{ftp_type} eq 'ftp') {
		print "Logging into $vendor->{ftp_server}\n" if ($s->{v});
		$ftp = Net::FTP->new($vendor->{ftp_server}) 
			|| die "Can not connect to $vendor->{ftp_server}: $@";
		$ftp->login($vendor->{ftp_username},$vendor->{ftp_password}) 
			|| die "Login failed to $vendor->{ftp_server}: $@";
	
		print "Connected\n" if ($s->{v});
		my @dirs = $ftp->ls();

		foreach my $d (@dirs) {
			if ($d =~ m/^(outbox|outgoing)$/i) {
				$ftp->cwd($d) || die "Error cwd to $d: ", $ftp->message;
				foreach my $f ($ftp->ls()) {
					print "Downloading $f to inbox\n" if ($s->{v});
					$ftp->get($f,"$vendor->{local_path}/inbox/$f") || die "Error get $f: ",
						$ftp->message;
					$ftp->delete($f) || die "Error delete $f: ",
						$ftp->message;
				}
			}
		}
	} else {
		croak "Unknwon ftp type $vendor->{ftp_type}";
	}

}

sub send_x12 {
	my $s = shift;
	my $document_code = shift;
	my $text = shift;
	my $edi_vendor_id = shift;
	my $edi_trans_id = shift;

	if (!$edi_trans_id && $document_code ne '997') {
		$edi_trans_id = $s->db_insert('edi_transactions',{
			filename => 'n/a',
			},'edi_trans_id');
	}

	croak "Missing edi_vendor_id" unless($edi_vendor_id);
	#croak "Missing edi_trans_id" unless($edi_trans_id);
	croak "Missing document_code" unless($document_code);
	croak "No text to send" unless($text);

	my %hash = $s->db_q("
		SELECT *
		FROM edi_vendors_v
		WHERE edi_vendor_id=?
		",'hash',
		v => [ $edi_vendor_id ]);

	croak "Invalid edi_vendor $edi_vendor_id" unless($hash{edi_vendor_id});

	if ($s->{env}{DEV}) {
		foreach my $k (qw(ftp_username ftp_server ftp_password ftp_path)) {
			$hash{$k} = $hash{"test_$k"} if ($hash{"test_$k"});
		}
	}

	my $ext = $hash{fileext} || '.edi';
	my $filename = "$hash{filepre}$document_code-$edi_trans_id-$s->{datetime}{ymdhms}$ext";

	if ($hash{ftp_type} eq 'ftps') {
		open F, ">/tmp/$filename";
		print F $text;
		close F;

		eval { _ftps_file(\%hash,$filename); };

		if ($@) {
			print STDERR "$@";
			$s->db_q("UPDATE edi_transactions SET error_msg=?, filename=?
				WHERE edi_trans_id=?
				",undef,
				v => [ $@, $filename, $edi_trans_id ])
				unless($document_code eq '997');
		} else {
			$s->db_q("UPDATE edi_transactions SET success=TRUE, filename=?
				WHERE edi_trans_id=?
				",undef,
				v => [ $filename, $edi_trans_id ])
				unless($document_code eq '997');
		}

		unlink "/tmp/$filename";
	} elsif ($hash{ftp_type} eq 'ftp') {
		open F, ">/tmp/$filename";
		print F $text;
		close F;

		eval { _ftp_file(\%hash,$filename); };
		if ($@) {
			print STDERR "$@";
			$s->db_q("UPDATE edi_transactions SET error_msg=?, filename=?
				WHERE edi_trans_id=?
				",undef,
				v => [ $@, $filename, $edi_trans_id ])
				unless($document_code eq '997');
		} else {
			$s->db_q("UPDATE edi_transactions SET success=TRUE, filename=?
				WHERE edi_trans_id=?
				",undef,
				v => [ $filename, $edi_trans_id ])
				unless($document_code eq '997');
		}

		unlink "/tmp/$filename";
	} elsif ($hash{local_path}) {
		open F, ">/$hash{local_path}/outbox/$filename";
		print F $text;
		close F;

		$s->db_q("UPDATE edi_transactions SET success=TRUE, filename=?
			WHERE edi_trans_id=?
			",undef,
			v => [ "$hash{local_path}/outbox/$filename", $edi_trans_id ])
			unless($document_code eq '997');
	} else {
		print $text;
	}
}

sub _ftps_file {
	my $hash = shift;
	my $filename = shift;

	eval "use Net::FTPSSL";
	if ($@) { croak "$@"; }

	my ($server,$port) = split ':', $hash->{ftp_server};
	$port = '21' unless($port);
	my $ftp = Net::FTPSSL->new($server,
		Port => $port,
		) 
		|| die "Can not connect to $hash->{ftp_server}: $@";
	$ftp->login($hash->{ftp_username},$hash->{ftp_password}) 
		|| die "Login failed to $hash->{ftp_server}: $@";

	if ($hash->{ftp_path}) {
		print "CWD $hash->{ftp_path}\n";
		$ftp->cwd($hash->{ftp_path}) || die "Error cwd to $hash->{ftp_path}: ",$ftp->message;
	}

	my @dirs = $ftp->nlst();

	foreach my $f (@dirs) {
		$f =~ s/^\.\///;
		if ($f =~ m/^(inbox|incoming)$/i) {
			$ftp->cwd($f) || die "Error cwd to $f: ", $ftp->message;
			#print "was going to put $filename to $hash->{ftp_server}\n";
			$ftp->put("/tmp/$filename") || die "Failed to put $filename: ", $ftp->message;
			return 1;
		}
	}

	die "Did not find inbox/incoming on $hash->{ftp_server}";
}

sub _ftp_file {
	my $hash = shift;
	my $filename = shift;

	my $ftp = Net::FTP->new($hash->{ftp_server}) || die "Can not connect to $hash->{ftp_server}: $@";
	$ftp->login($hash->{ftp_username},$hash->{ftp_password}) || die "Login failed to $hash->{ftp_server}: $@";

	if ($hash->{ftp_path}) {
		#print "CWD $hash->{ftp_path}\n";
		$ftp->cwd($hash->{ftp_path}) || die "Error cwd to $hash->{ftp_path}: ",$ftp->message;
	}

	my @dirs = $ftp->ls();

	foreach my $f (@dirs) {
		$f =~ s/^\.\///;
		#print "Checking $f\n";
		if ($f =~ m/^(inbox|incoming)$/i) {
			$ftp->cwd($f) || die "Error cwd to $f: ", $ftp->message;
			#print "was going to put $filename to $hash->{ftp_server}\n";
			$ftp->put("/tmp/$filename") || die "Failed to put $filename: ", $ftp->message;
			return 1;
		}
	}

	die "Did not find inbox/incoming on $hash->{ftp_server}";
}

sub edi_post {

=head2 edi_post

 my $data = $s->edi_post($ref,$url,$data);

=cut

	my $s = shift;
	my $ref = shift;
	my $url = shift;
	my $data = shift;

	my $server = ($s->{env}{DEV})
		? $ref->{sdn_dev_url}
		: $ref->{sdn_url};
	
	croak "Unknown sdn_url" unless($server);

	my $ua = new LWP::UserAgent;
	$ua->timeout(5);
	my $dump = new XML::Dumper;
	my $xml = $dump->pl2xml($data);
	my $req = new HTTP::Request('POST' => "$server$url");
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('<?xml version="1.0" encoding="UTF-8"?>'.$xml);
	my $resp = $ua->request($req);
	my $rxml;
	if ($resp->is_success) {
		my $rxml = $dump->xml2pl($resp->content);
		if (defined($rxml->{data})) {
			return $rxml->{data};
		} elsif (defined($rxml->{error})) {
			$s->alert("Error from $server: $rxml->{error}");
			return undef;
		}
	} else {
		$s->alert("Connection error to $server$url: ".$resp->status_line);
		return undef;
	}
}

sub edi_get {

=head2 edi_get

 my $data = $s->edi_post($ref,$url);

=cut

	my $s = shift;
	my $ref = shift;
	my $url = shift;

	my $server = ($s->{env}{DEV})
		? $ref->{sdn_dev_url}
		: $ref->{sdn_url};
	
	croak "Unknown sdn_url" unless($server);

	my $ua = new LWP::UserAgent;
	$ua->timeout(5);
	my $req = new HTTP::Request('GET' => "$server$url");
	my $resp = $ua->request($req);
	my $rxml;
	if ($resp->is_success) {
		my $dump = new XML::Dumper;
		my $rxml = $dump->xml2pl($resp->content);
		if (defined($rxml->{data})) {
			return $rxml->{data};
		} elsif (defined($rxml->{error})) {
			$s->alert("Error from $server: $rxml->{error}");
			return undef;
		}
	} else {
		$s->alert("Connection error to $server$url: ".$resp->status_line);
		return undef;
	}
}

sub access {
	my $s = shift;
	my $function = shift;

	# check and see if we have an entry for this object/function
	my %hash = $s->db_q("
		SELECT a.action_id, a.name, a.a_object, a.a_function,
			concat(ga.group_id) as groups
		FROM actions_v a
			LEFT JOIN group_actions ga ON a.action_id=ga.action_id
		WHERE a.a_object=?
		AND a.a_function=?
		GROUP BY 1,2,3,4
		",'hash',
		v => [ $s->{object}, $function ]);

	#croak "<pre>".Data::Dumper->Dump([\%hash])."</pre>";

	# if we do not, then add the object/function to the admin group
	unless($hash{action_id}) {
		$hash{groups} = $s->_set_default_access($s->{object},$function);
	}

	# we have a problem here....how do we deal with people who
	# we do not want to to have access to "everything"?
	# if someone has "strict_perms", then skip this everyone check

	# if there are no groups listed, then it's open to everyone
	if (!$hash{groups} && !$s->{employee}{strict_perms}) {
		# set a flag so we know we can skip location checking as well
		$s->{no_location_check} = 1;
		return 1;
	}

	# otherwise check and see which group this person belongs to
	foreach my $g (split ',', $hash{groups}) {
		foreach my $eg (split ',', $s->{employee}{groups}) {
			return 1 if ($g eq $eg);
		}
	}

	my $alert;
	$s->tt('noaccess.tt', { s => $s, 
		message => "Sorry, you do not have access to $function a $s->{object}" }, \$alert);

	$s->{message} .= $alert;
	return 0;
}

sub _set_default_access {
	my $s = shift;
	my $object = shift;
	my $function = shift;

	my $action_id = $s->db_insert('actions', {
		a_object => $object,
		a_function => $function,
		name => (ucfirst $function).' '.(ucfirst $object).'s',
		},'action_id');

	# and add this action to the admin group
	my $groups = $s->db_q("
		SELECT group_id
		FROM groups
		WHERE admin IS TRUE
		",'scalar');

	$s->db_q("INSERT INTO group_actions (group_id, action_id)
		SELECT g.group_id, $action_id
		FROM groups g
		WHERE g.group_id IN (?)
		",undef,
		v => [ $groups ]);

	return $groups;
}

sub _api_calls {
	my $s = shift;

	delete $s->{object};
	delete $s->{function};

	if (-d "$ENV{HTTPD_ROOT}/$s->{obase}/object") {
		my $base = $s->{obase};
		my $objectpath = "$ENV{HTTPD_ROOT}/$base/object";
		if (-d $objectpath) {
			opendir(DIR,$objectpath);
			while (my $d = readdir(DIR)) {
				next if ($d =~ m/^\./);
				next if (!-f "$objectpath/$d" || !($d =~ m/\.pm$/i));
				$d =~ s/\.pm$//i;
				$s->{obj_base} = $s->{obase}.'::object::'.$d;
				my $config = $s->{obj_base}.'::config';
				no strict 'refs';

				if (defined(&{$config})) {
					my $o = &{$config}($s);
					$s->tt('api_object.tt', { s => $s, o => $o, name => $d });
				}
			}
			closedir(DIR);
		}
	}
}

sub object_link {
	my $s = shift;
	my %args = @_;

	my $object = $args{object} || $s->{object};
	my $function = $args{function};
	my $params = $args{params};
	my $title = $args{title} || $function;

	# this nice little thing uppercases each word of the title
	$title = join ' ', map {ucfirst} split / /, $title;

	$params = '?'.$params if ($params);

	my $html;
	$s->tt('objectlink.tt', { s => $s, args => {
		object => $object,
		function => $function,
		params => $params,
		title => $title }
		}, \$html);

	return $html;
}

sub set_dbparams {
	my $s = shift;
	my %args = @_;

	foreach my $k (keys %args) {
		if ($k eq 'limit') {
			if ($s->{in}{limit} =~ m/^\d{1,3}$/) { # max limit is 999
				$s->{limit} = $s->{in}{limit};
			} else {
				$s->{limit} = $args{$k};
			}
		} elsif ($k eq 'offset') {
			if ($s->{in}{offset} =~ m/^\d+$/) { 
				$s->{offset} = $s->{in}{offset};
			} else {
				$s->{offset} = $args{$k};
			}
		} elsif ($k eq 'orderdir') {
			if ($s->{in}{orderdir} eq 'desc') {
				$s->{orderdir} = 'desc';
			} elsif ($s->{in}{orderdir} eq 'asc') {
				$s->{orderdir} = 'asc';
			} else {
				$s->{orderdir} = $args{$k};
			}
		} else {
			if ($s->{in}{orderby}) {
				$s->{in}{orderby} =~ s/[^a-z_]//g;
			}
			$s->{orderby} = $s->{in}{orderby} || $args{$k};
		}
	}
}

sub verify_date {

=head2 verify_date

 my $truefalse = $s->verify_date($date,$mindays,$maxdays);

Make sure a date is in a given range of days from today.

=cut

	my $s = shift;
	my $date = shift;
	my $mindays = shift;
	my $maxdays = shift;

	return 1 unless($date);

	my $ok = $s->db_q("
		SELECT CASE WHEN date(?) BETWEEN date(now() + interval '$mindays day')
			AND date(now() + interval '$maxdays day') THEN TRUE ELSE FALSE END
		",'scalar',
		v => [ $date ]);

	return $ok;
}

sub verify_zipcode {

=head2 verify_zipcode

 my $truefalse = $s->verify_zipcode(\$zip,[\$state],[\$city],[\$country]);

Check the zipcode database for the given zipcode.  If optional references
are included in call and zipcode is valid, these scalar references are
populated with the database information.

=cut

	my $s = shift;
	my $ref = shift;
	my $state = shift;
	my $city = shift;
	my $country = shift;

	$$ref =~ s/^\s+//;
	$$ref =~ s/\s+$//;
	$$ref = uc $$ref;

	if ($$ref =~ m/^([A-Z]\d[A-Z])(\d[A-Z]\d)$/) {
		# canada zipcode, add space in between
		$$ref = "$1 $2";
	}

	my %hash = $s->db_q("
		SELECT z.zipcode, z.state, z.city
		FROM zipcodes z
		WHERE z.zipcode=?
		",'hash',
		v => [ $$ref ]);

	if ($hash{zipcode}) {
		$$state = $hash{state} if (defined($state));
		if (defined($city)) {
			$$city = $hash{city} unless($$city);
		}
		return 1;
	} elsif (defined($country)) {
		my %c = $s->db_q("
			SELECT *
			FROM countries
			WHERE country=?
			",'hash',
			v => [ $$country ]);
		if ($$ref eq '' && $c{country}) {
			return 1;
		} else {
			return 0;
		}
	} else {
		return 0;
	}
}

sub verify_email {

=head2 verify_email

 my $truefalse = $s->verify_email($email);

=cut

	my $s = shift;
	my $ref = shift;

	$$ref =~ s/^\s+//;
	$$ref =~ s/\s+$//;
	$$ref = lc $$ref;

	if ($$ref =~ /^[\.a-zA-Z&0-9_-]*\@(.*\.[a-zA-Z]*)$/) {
		return 1;
	} else {
		return 0;
	}
}

sub verify_regex {

=head2 verify_regex

 my $truefalse = $s->verify_regex($regex);

=cut

	my $s = shift;
	my $regex = shift;

	eval {
		my $reg = qr/^$regex$/;
		};
	
	if ($@) {
		return 0;
	} else {
		return 1;
	}
}

sub verify_phone {

=head2 verify_phone 

 my $truefalse = $s->verify_phone(\$number,[\$other]);

Checks that $number is only numbers and it 10 digits.  Changes
input scalar reference to clean it up.  If $other scalar reference
is provided, and nothing is in $number, then function returns true
which is somewhat of a bypass for non 10 digit phone verification.

=cut

	my $s = shift;
	my $ref = shift;
	my $other = shift;

	$$ref =~ s/\D//g;

	if (length($$ref) == 0 && defined($other)) {
		if ($$other ne '') {
			$$ref = 0;
			return 1;
		}
	}

	return 0 unless(length($$ref) == 10);

	return 1;
}

sub html_orderby {

=head2 html_orderby

 my $html = $s->html_orderby($key,[desc || asc],$params);

=cut

	my $s = shift;
	my $key = shift;
	my $direction = shift;
	my $params = shift;

	if ($s->{in}{"$key $direction"}) {
		return '';
	} elsif ($direction eq 'desc') {
		return $s->html_a("$s->{ubase}/$s->{object}/$s->{function}?ob=$key $direction&$params",'v');
	} elsif ($direction eq 'asc') {
		return $s->html_a("$s->{ubase}/$s->{object}/$s->{function}?ob=$key $direction&$params",'^');
	}
}

sub html_font {

=head2 html_font

 my $html = $s->html_font($text,$size);

=cut

	my $s = shift;
	my $text = shift;
	my $size = shift;

	return qq(<font size="$size">$text</font>);
}

sub html_a {

=head2 html_a

 my $html = $s->html_a($url,$name,[$class]);

=cut

	my $s = shift;
	my $url = shift;
	my $name = shift;
	my $class = shift;

	my $str = qq(<a href="$url");
	$str .= qq( class="$class") if ($class);
	$str .= qq(>$name</a>);

	return $str;
}

sub html_submit {

=head2 html_submit

 my $html = $s->html_submit($name,[$class]);

=cut

	my $s = shift;
	my $name = shift;
	my $class = shift;

	my $c = qq( class="$class") if ($class);

	return qq(<input type="submit" value="$name"$c>);
}

sub html_radio {

=head2 html_radio

 my $html = $s->html_radio($key,$value,[$checked],[$desc],[$id]);

=cut

	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $checked = shift;
	my $desc = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input type="radio" name="$key" value="$value");
	$str .= ' checked' if ($checked eq $value);
	$str .= qq( id="$id") if ($id);
	$str .= '>';
	$str .= " $desc" if ($desc);

	return $str;
}

sub html_checkbox {

=head2 html_checkbox

 my $html = $s->html_checkbox($key,$value,[$checked],[$desc],[$id]);

=cut

	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $checked = shift;
	my $desc = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input type="checkbox" name="$key" value="$value");
	$str .= ' checked' unless ($checked eq undef);
	$str .= qq( id="$id") if ($id);
	$str .= '>';
	$str .= " $desc" if ($desc);

	return $str;
}

sub html_password {

=head2 html_password

 my $html = $s->html_password($key,$value,[$size]);

=cut

	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $size = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input type="password" name="$key" value="$value" autocomplete="off");
	$str .= qq( size="$size") if ($size);
	$str .= '>';

	return $str;
}

sub html_upload {

=head2 html_upload

 my $html = $s->html_upload($key,[$size],[$class],[$id]);

=cut

	my $s = shift;
	my $key = $s->escape(shift);
	my $size = shift;
	my $class = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input type="file" name="$key");
	$str .= qq( size="$size") if ($size);
	$str .= qq( id="$id") if ($id);
	$str .= qq( class="$class") if ($class);
	$str .= '>';

	return $str;
}

sub html_input_email {

=head2 html_input_email

 my $html = $s->html_input_email($key,$value,[$size]);

=cut
	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $size = shift;
	my $class = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input type="email" name="$key" value="$value" autocomplete="off");
	$str .= qq( size="$size") if ($size);
	$str .= qq( id="$id") if ($id);
	$str .= qq( class="$class") if ($class);
	$str .= '>';

	return $str;
}

sub html_input_number {

=head2 html_input_number

 my $html = $s->html_input_number($key,$value,[$size]);

=cut
	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $size = shift;
	my $class = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input type="number" name="$key" value="$value" autocomplete="off");
	$str .= qq( size="$size") if ($size);
	$str .= qq( id="$id") if ($id);
	$str .= qq( class="$class") if ($class);
	$str .= '>';

	return $str;
}

sub html_input {

=head2 html_input

 my $html = $s->html_input($key,$value,[$size]);

=cut
	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $size = shift;
	my $class = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(<input name="$key" value="$value" autocomplete="off");
	$str .= qq( size="$size") if ($size);
	$str .= qq( id="$id") if ($id);
	$str .= qq( class="$class") if ($class);
	$str .= '>';

	return $str;
}

sub html_textarea {

=head2 html_textarea

 my $html = $s->html_input($key,$value,[$cols || 40],[$row || 3],[$class]);

=cut

	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $cols = shift || 40;
	my $rows = shift || 3;
	my $class = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	$class = qq( class="$class") if ($class);
	my $str = qq(<textarea name="$key"$class cols="$cols" rows="$rows">$value</textarea>);

	return $str;
}

sub html_hidden {

=head2 html_hidden

 my $html $s->html_hidden($key,$value,[$desc],[$id]);

=cut

	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);
	my $desc = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $idfield = qq( id="$id") if ($id);
	my $str = qq(<input$idfield type="hidden" name="$key" value="$value">);
	$str .= $desc if ($desc);
	
	return $str;
}

sub html_thtd {

=head2 html_thtd

 my $html = $s->html_thtd($th,$td);

=cut

	my $s = shift;
	my $th = shift;
	my $td = shift;

	return qq(\n<tr>\n\t<th>$th</th>\n\t<td>$td</td>\n</tr>);
}

sub html_thead {

=head2 html_thead

 my $html = $s->html_thead(@list);

=cut

	my $s = shift;
	my @list = @_;

	my $str = qq(\n\t<thead>\n\t\t<tr>\n);
	
	foreach my $k (@list) {
		$str .= qq(\t\t\t<th>$k</th>\n);
	}

	$str .= qq(\t\t</tr>\n\t</thead>);

	return $str;
}

sub html_select_basic {

=head2 html_select_basic

 my $html = $s->html_select_basic(\@list,$key,[$existing],[$showblank]);

=cut

	my $s = shift;
	my $data = shift;
	my $key = shift;
	my $existing = shift;
	my $showblank = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(\n<select name="$key">);
	if ($showblank) {
		$str .= qq(\n\t<option value=""></option>);
	}
	foreach my $value (@{$data}) {
		$str .= qq(\n\t<option value="$value");
		$str .= qq( selected) if ($value eq $existing);
		$str .= qq(>$value</option>);
	}

	$str .= qq(\n</select>);
}

sub html_select {

=head2 html_select

 my $html = $s->html_select(\@arrayhash,$key,$idkey,$idname,[$existing],[$showblank]);

=cut

	my $s = shift;
	my $data = shift;
	my $key = shift;
	my $idkey = shift;
	my $idname = shift;
	my $existing = shift;
	my $showblank = shift;
	my $class = shift;
	my $id = shift;

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $str = qq(\n<select name="$key");
	$str .= qq( id="$id") if ($id);
	$str .= qq( class="$class") if ($class);
	$str .= '>';
	if ($showblank) {
		$str .= qq(\n\t<option value=""></option>);
	}

	foreach my $ref (@{$data}) {
		$str .= qq(\n\t<option value="$ref->{$idkey}");
		$str .= qq( selected) if ($ref->{$idkey} eq $existing);
		$str .= qq(>$ref->{$idname}</option>);
	}

	$str .= qq(\n</select>);
}

sub html_tbody {

=head2 html_tbody 

 my $html = $s->html_tbody(\@arrayhash,@cols);

=cut

	my $s = shift;
	my $data = shift;
	my @cols = @_;

	my $str = qq(\n\t<tbody>\n\t\t<tr>\n);

	foreach my $ref (@{$data}) {
		$str .= qq(\t\t<tr>\n);
		foreach my $k (@cols) {
			$str .= qq(\t\t\t<td>$ref->{$k}</td>\n);
		}
		$str .= qq(\t\t</tr>\n);
	}

	$str .= qq(\t\t</tr>\n\t</tbody>);

	return $str;
}

sub escape {
	my $s = shift;
	my $string = shift;

	$string =~ s/&([^#])/&amp;$1/g; 
	$string =~ s/"/&quot;/g;
	$string =~ s/>/&gt;/g;
	$string =~ s/</&lt;/g;
	# &apos; is a valid XML entity, but not a valid HTML entity.
	# @todo: the ' character is valid HTML and shouldn't need to be escaped.
	#        However, a lot of the code uses value='' instead of "" so we need
	#        to leave this in for now.
	$string =~ s/'/&#39;/g;

	return $string;
}

sub address_display {

=head2 address_display

 my $html = $s->address_display(\%hash,$wrap);

=cut

	my $s = shift;
	my $ref = shift;
	my $wrap = shift;
	my $commercial = shift; # puts the first last name after the company

	return '' unless(ref $ref eq 'HASH');

	my $return;
	unless($commercial) {
		$return .= $s->display_wrap("$ref->{first_name} $ref->{last_name}",$wrap)
			if ($ref->{first_name} || $ref->{last_name});
	}

	$return .= $s->display_wrap($ref->{company},$wrap) if ($ref->{company});

	foreach my $k (qw(address address2)) {
		$return .= $s->display_wrap($ref->{$k},$wrap) if ($ref->{$k});
	}

	if ($ref->{zipcode} && $ref->{state}) {
		$return .= $s->display_wrap("$ref->{city}, $ref->{state} $ref->{zipcode}",$wrap);
	} elsif ($ref->{zipcode} && $ref->{state_name}) {
		$return .= $s->display_wrap("$ref->{city}, $ref->{state_name} $ref->{zipcode}",$wrap);
	} elsif ($ref->{zipcode} && $ref->{city}) {
		$return .= $s->display_wrap("$ref->{city} $ref->{zipcode}",$wrap);
	}

	if ($ref->{country_name}) {
		$return .= $s->display_wrap($ref->{country_name},$wrap);
	}

	if ($commercial) {
		$return .= $s->display_wrap("$ref->{first_name} $ref->{last_name}",$wrap)
			if (($ref->{first_name} || $ref->{last_name}) && $commercial ne 'nocontact');
	}

	if ($ref->{phone}) {
		$return .= $s->display_wrap($s->format_phone($ref->{phone}),$wrap);
	}

	return $return;
}

sub display_wrap {
	my $s = shift;
	my $string = shift;
	my $wrap = shift;

	if ($string) {
		return "$string$wrap";
	} else {
		return '';
	}
}

sub format_csv {
	my $s = shift;
	my $string = shift;

	$string =~ s/"/""/g;
	return qq("$string");
}

sub format_text {

=head2 format_text

 my $string = $s->format_text($string);

Converts newlines to <br>, tabs and 8 spaces to 4 nbsp;.  Also does an escape.

=cut

	my $s = shift;
	my $string = shift;

	$string = $s->escape($string);

	$string =~ s/\n/<br>\n/g;
	$string =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
	$string =~ s/\s{8}/&nbsp;&nbsp;&nbsp;&nbsp;/g;

	return $string;
}

sub format_accounting {

=head2 format_accounting

 my $string = $s->format_accounting($string);

takes things like 1234 and returns 1,234, and -1234 and returns (1,234)

=cut

	my $s = shift;
	my $string = shift;

	my ($h,$d) = split '\.', $string;

	my @c = split '', $h;
	my @out;
	my $n = 0;
	foreach my $char (reverse @c) {
		if ($char =~ m/\d/) {
			if ($n == 3) {
				unshift @out, ',';
				$n = 0;
			}
			unshift @out, $char;
			$n++;
		} else {
			# for things like negative signs
			1; #unshift @out, $char;
		}
	}

	$string = join '', @out;
	$string .= ".$d" if (($d || $d eq '00') && $string ne '');

	if ($h =~ m/^-/) {
		return "($string)";
	}

	return $string;

}

sub format_number {

=head2 format_number

 my $string = $s->format_number($string);

Adds commas to numbers.  1234 becomes 1,234.

=cut

	my $s = shift;
	my $string = shift;

	my ($h,$d) = split '\.', $string;

	my @c = split '', $h;
	my @out;
	my $n = 0;
	foreach my $char (reverse @c) {
		if ($char =~ m/\d/) {
			if ($n == 3) {
				unshift @out, ',';
				$n = 0;
			}
			unshift @out, $char;
			$n++;
		} else {
			# for things like negative signs
			unshift @out, $char;
		}
	}

	$string = join '', @out;
	$string .= ".$d" if (($d || $d eq '00') && $string ne '');

	return $string;

}

sub format_time {

=head2 format_time

 my $string = $s->format_time($string);

Takes a timestamp and returns HH:MM:SS

=cut

	my $s = shift;
	my $timestamp = shift;

	if ($timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})/) {
		return "$4:$5:$6";
	} else {
		return $timestamp;
	}
}
sub format_ts {

=head2 format_ts

 my $string = $s->format_ts($string);

Takes a timestamp and returns MM/DD/YYYY HH:MM

=cut

	my $s = shift;
	my $timestamp = shift;

	if ($timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2})/) {
		return "$2/$3/$1&nbsp;$4:$5";
	} else {
		return $timestamp;
	}
}

sub translate_date {

=head2 translate_date

 $s->translate_date(\$date);

Takes 102202 and returns 10/22/02

=cut

	my $s = shift;
	my $ref = shift;

	if ($$ref =~ m/^(\d{2})(\d{2})(\d{2})$/) {
		$$ref = "$1/$2/$3";	
	}
}

sub format_date {

=head2 format_date 

 my $string = $s->format_date($string);

Given YYYY-MM-DD (or a timestamp with YYYY-MM-DD HH...) and
returns MM/DD/YYYY.

=cut

	my $s = shift;
	my $timestamp = shift;

	if ($timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})\s/) {
		return "$2/$3/$1";
	} elsif ($timestamp =~ m/^(\d{4})-(\d{2})-(\d{2})$/) {
		return "$2/$3/$1";
	} else {
		return $timestamp;
	}
}

sub format_phone {

=head2 format_phone

 my $string = $s->format_phone($number);

Returns 123-123-1234 if $number is 10 digits.

=cut

	my $s = shift;
	my $number = shift;

	return $number unless($number =~ m/^\d{10}$/);

	$number =~ s/^(\d{3})(\d{3})(\d{4})$/$1-$2-$3/;

	return $number;
}

sub format_boolean {

=head2 format_boolean

 my $string = $s->format_boolean($value);

Returns Yes for true value, No for false value, and '' for empty value.

=cut

	my $s = shift;
	my $value = shift;

	return $value if ($value eq '');
	return 'Yes' if ($value);
	return 'No' if (!$value);
}

sub format_percent {

=head2 format_percent

 my $string = $s->format_percent($number);

Given 0.123, returns 12.3%.

=cut

	my $s = shift;
	my $number = shift;
	my $d = shift;

	$d = 1 unless(defined($d));

	return $number unless($number);

	$number = (sprintf "%.${d}f", $number*100).'%';

	return $number;
}

sub csv_to_array {

=head2 csv_to_array

 my @array = $s->csv_to_array($text,[$onerow]);

=cut

	my $s = shift;
	my $text = shift;
	my $onerow = shift;

	my @rows = ();
	$text =~ s/\s+$//s;
	my $row = [];
	while ($text=~ m/(  (?!")[^,\r\n]*      # Handle normal fields
					| "(?:["\\]"|[^"])*?" # Handle quoted fields, escaped quotes as "" or \"
					)(\r?\n|,|$)
					/sgx) {
		my $val = defined $1 ? $1 : '';
		my $eol = $2;

		if ($val =~ m/^"(.*)"$/s) {
			$val = defined $1 ? $1 : '';
			$val =~ s/["\\]"/"/sg;
		}

		push @{$row}, $val;

		if ((!$eol || $eol ne ',') && scalar(@{$row}) > 0) {
			push @rows, $row;
			$row = [];
			last if ($onerow);
		}

		last unless($eol);
	}

	if ($onerow) {
		return @{$rows[0]};
	}

	return @rows;
}

sub mime_type {
	my $s = shift;

	return unless($s->{r}{file_path});
	return 'text/html' if ($s->{r}{file_path} =~ m/\.html?$/i);
	return 'image/jpeg' if ($s->{r}{file_path} =~ m/\.jpg$/i);
	return 'image/png' if ($s->{r}{file_path} =~ m/\.png$/i);
	return 'image/gif' if ($s->{r}{file_path} =~ m/\.gif$/i);
	return 'text/xml' if ($s->{r}{file_path} =~ m/\.x(m|s)l$/i);
	return 'text/css' if ($s->{r}{file_path} =~ m/\.css$/i);
	return 'application/pdf' if ($s->{r}{file_path} =~ m/\.pdf$/i);
	return 'text/plain' if ($s->{r}{file_path} =~ m/\.txt$/i);
}

sub session_delete {
	my $s = shift;
	my $key = shift;

	if ($key) {
		# just delete one key
		if (defined($s->{session_data}{$key})) {
			delete $s->{session_data}{$key};
			_session_update($s);
		}
	} else {
		# delete entire session
		$s->{session_data} = undef;
		$s->db_q("
			DELETE FROM employee_sessions
			WHERE employee_id=?
			",undef,
			v => [ $s->{employee_id} ]);
	}
}

sub session_add {
	my $s = shift;
	my $key = shift;
	my $value = shift;

	my $insert = 1 unless(defined($s->{session_data}));

	$s->{session_data}{$key} = $value;
	_session_update($s,$insert);
}

sub _session_update {
	my $s = shift;
	my $insert = shift;

	Data::Dumper->Purity(1);
	Data::Dumper->Deepcopy(1);
	my $dd = Data::Dumper->new([\%{$s->{session_data}}],['$s->{session_data}']);

	if ($insert) {
		$s->db_insert('employee_sessions',{
			employee_id => $s->{employee_id},
			data => $dd->Dump(),
			});
	} else {
		$s->db_q("
			UPDATE employee_sessions SET data=?, last_update_ts=now()
			WHERE employee_id=?
			",undef,
			v => [ $dd->Dump(), $s->{employee_id} ]);
	}
}

sub session_load {
	my $s = shift;

	my $data = $s->db_q("
		SELECT data
		FROM employee_sessions
		WHERE employee_id=?
		",'scalar',
		v => [ $s->{employee_id} ]);

	if ($data) {
		eval $data;
		if ($@) {
			croak "Error in eval of session data: $@";
		}
	
		# pre-populate any messages which are in the session, then remove them
		if ($s->{session_data}{message}) {
			$s->{message} .= $s->{session_data}{message};
			$s->session_delete('message');
		}
	} else {
		$s->{session_data} = undef;
	}

}

sub check_location_id {
	my $s = shift;
	my $location_id = shift;

	croak "location_id is not set in session_data or is invalid"
		unless($s->{session_data}{location_id} =~ m/^\d+$/);

	# this is a function to make sure the current location matches
	# whatever value we are passing into this function

	if (ref $location_id eq 'ARRAY') {
		foreach my $id (@{$location_id}) {
			croak "Invalid location_id passed into check_location_id ($id)"
				unless($id =~ m/^\d+$/);
		
			return 1 if ($id eq $s->{session_data}{location_id});
		}
	} else {
		croak "Invalid location_id passed into check_location_id"
			unless($location_id =~ m/^\d+$/);
	
		return 1 if ($location_id eq $s->{session_data}{location_id});
	}

	$s->alert("Sorry the location of the $s->{object} you are trying to access does not match your current location");

	return 0;
}

sub check_in_id {
	my $s = shift;
	my $idfield = shift || $s->{o}{id};

	if ($s->{o}{idstring}) {
		return 1 if ($s->{in}{$idfield});

		# sometimes we are not sure what the paramter of the ID field should be
		# so we pass in "id" instead, so if "id" exists, then just switch it over and
		# then return true
		if ($s->{in}{id}) {
			$s->{in}{$idfield} = delete $s->{in}{id};
			return 1;
		}
	} else {
		return 1 if ($s->{in}{$idfield} =~ m/^\d+$/);
	
		# sometimes we are not sure what the paramter of the ID field should be
		# so we pass in "id" instead, so if "id" exists, then just switch it over and
		# then return true
		if ($s->{in}{id} =~ m/^\d+$/) {
			$s->{in}{$idfield} = delete $s->{in}{id};
			return 1;
		}
	}


	$s->alert("invalid or missing $idfield");
	
	return 0;
}

sub add_bucket {
	my $s = shift;
	my %args = @_;

	my $object = $args{object} || $s->{object};
	my $function = $args{function};
	my $params = $args{params};
	my $id = $args{id};
	my $title = $args{title} || $id;

	return unless($id);

	my $class = ($s->{in}{b} eq $id) ? 'currentbucket' : 'bucket';

	# this nice little thing uppercases each word of the title
	$title = join ' ', map {ucfirst} split / /, $title;

	$params .= '&' if ($params);
	$params .= "b=$id";
	$params = '?'.$params if ($params);

	push @{$s->{buckets}}, {
		url => "$s->{ubase}/$object/$function$params",
		title => $title,
		id => $id,
		class => $class,
		};
}

sub redirect {
	my $s = shift;
	my %args = @_;

	my $object = $args{object} || $s->{object};
	my $function = $args{function} || 'display';
	my $params = $args{params};

	if (!$params && $s->{in}{$s->{o}{id}}) {
		$params = "$s->{o}{id}=$s->{in}{$s->{o}{id}}";
	}

	# this is a little helper function to make life easier in
	# setting the redirect if we just call with nothing, then
	# we assume we want to redirect to the display function

	$params = "?$params" if ($params);

	$s->{redirect} = "$s->{ubase}/$object/$function$params";
}

sub add_tab {
	my $s = shift;
	my $object = shift;
	my $title = shift;

	if (defined($s->{employee}{object}{$object})) {
		return qq(<li><a href="$s->{ubase}/$object">$title</a></li>);
	}
}

sub add_jump {
	my $s = shift;
	my %args = @_;

	my $object = $args{object} || $s->{object};
	my $function = $args{function};
	my $params = $args{params};
	my $title = $args{title} || "Go";

	if (defined($s->{employee}{object}{$object})) {
		if (defined($s->{employee}{object}{$object}{$function})) {

			my $form = qq(<div class="jump"><form method="POST" action="$s->{ubase}/$object/$function">);
			foreach my $k (keys %{$params}) {
				$form .= $s->html_hidden($k,$params->{$k});
			}
	
			$form .= qq(<input name="$args{input}" size="5">);	
			$form .= qq(<input type="submit" value="$title"></form></div>);
	
			push @{$s->{actions}}, { jump => $form, };
		}
	}
}

sub add_action {
	my $s = shift;
	my %args = @_;

	my $object = $args{object} || $s->{object};
	my $function = $args{function};
	my $params = $args{params};
	my $title = $args{title} || $function;
	my $class = $args{class} || 'action';

	if ($function =~ m/^(edit|delete|display)$/ && !$params) {
		# if we do not include params on edit or delete, then use the default
		# ones, that hopefully are in "in"
		$params = "$s->{o}{id}=$s->{in}{$s->{o}{id}}";
	}

	# this nice little thing uppercases each word of the title
	$title = join ' ', map {ucfirst} split / /, $title;

	$params = '?'.$params if ($params);

	# do we want to skip if we already exist?
	if ($args{unless_exist}) {
		return if (defined($s->{action_lookup}{$object}{$function}));
	}

	# so we can keep track if we have already added this thing
	$s->{action_lookup}{$object}{$function} = 1;

	if ($object eq 'logout') {
		push @{$s->{actions}}, {
			url => "$s->{ubase}/$object/$function",
			title => $title,
			class => $class,
			};
		
		return;
	}

	if ($args{require_perm}) {
		# only show if we have the require permission level defined
		# for this object.  Mostly for overriding type things
		if (defined($s->{employee}{object}{$object}{$args{require_perm}})) {
			push @{$s->{actions}}, {
				url => "$s->{ubase}/$object/$function$params",
				title => $title,
				class => $class,
				};
		}

		return;
	}

	if ($args{nourl}) {
		push @{$s->{actions}}, {
			title => $title,
			class => $class,
			};
	} else {
		if ($object =~ m/^(me|help)$/ || !$s->{employee_id}) {
			push @{$s->{actions}}, {
				url => "$s->{ubase}/$object/$function$params",
				title => $title,
				class => $class,
				};
			return;	
		} elsif (defined($s->{employee}{object}{$object})) {
			if (defined($s->{employee}{object}{$object}{$function})) {
				push @{$s->{actions}}, {
					url => "$s->{ubase}/$object/$function$params",
					title => $title,
					class => $class,
					};
				return;	
			}
		}

		push @{$s->{actions}}, {
			title => $title,
			class => 'greyout',
			};
	}
}

sub check_permission {
	my $s = shift;
	my $object = shift;
	my $function = shift;

	return 1 if ($object eq 'logout');

	if (defined($s->{employee}{object}{$object})) {
		if (defined($s->{employee}{object}{$object}{$function})) {
			return 1;
		}
	}

	return 0;
}

sub action_html {

=head2 action_html

 my $string = $s->action_html($object,$function,$title,$params,[$class || 'action']);

=cut

	my $s = shift;
	my $object = shift;
	my $function = shift;
	my $title = shift;
	my $params = shift;
	my $class = shift || 'action';

	if ($s->check_permission($object,$function)) {
		$params = "?$params" if ($params);
		return qq(<a href="$s->{ubase}/$object/$function$params" class="$class">$title</a>);
	}

	return qq(<span class="greyout">$title</span>);
}

sub export_data {
	my $s = shift;
	my $data = shift;
	my $cols = shift;
	my $type = shift;
	my $filename = shift;

	croak "Missing filename" unless($filename);
	croak "Missing type" unless($type);
	croak "Missing columns" unless(ref $cols eq 'ARRAY');

	open F, ">/tmp/$filename";
	print F '"'.(join '","', @{$cols}).'"'."\n";
	foreach my $ref (@{$data}) {
		my @row;
		foreach my $c (@{$cols}) {
			$ref->{$c} =~ s/"/""/g;
			push @row, $ref->{$c};
		}
		print F '"'.(join '","', @row).'"'."\n";
	}
	close F;

	$s->{content_type} = 'application/csv' if ($type eq 'csv');
	$s->{content_type} = 'text/plain' if ($type ne 'csv');

	$s->{r}{file_path} = "/tmp/$filename";
	$s->{r}{filename} = $filename;
}

sub encrypt {
	my $s = shift;
	my $data = shift;

	my $k = $s->{env}{CRYPT_KEY} || 'ilikegreeneggsandhamsamiam';
	my $cipher = new Crypt::CBC($k,'Blowfish');
	my $out = $cipher->encrypt($data) if ($data);

	my @tmp;
	foreach my $c (split '', $out) {
		push @tmp, unpack('c',$c);
	}

	return join '|', @tmp;
}

sub decrypt {
	my $s = shift;
	my $data = shift;

	my $tmp;
	foreach my $c (split /\|/, $data) {
		$tmp .= pack('c',$c);
	}

	my $k = $s->{env}{CRYPT_KEY} || 'ilikegreeneggsandhamsamiam';
	my $cipher = new Crypt::CBC($k,'Blowfish');
	my $out = $cipher->decrypt($tmp) if ($tmp);

	return $out;
}

sub help {
	my $s = shift;

	# we use our function to look for help
	$s->{function} = 'home' if ($s->{function} eq 'list');

	my $path = "$s->{function}.tt";

	if ($s->{function} eq 'system') {
		unless($s->{employee}{admin}) {
			$s->alert("Sorry, you are not an admin, you can't look at that");
			return;
		}

		# show our system help file, disaster recovery type information
		$s->{nomenu} = 1;
		my $debug = "<pre>".Data::Dumper->Dump([$s])."</pre>";
		$s->tt('system.tt', { s => $s });
		#$s->{content} .= $debug;
		return;
	}

	if ($s->{in}{f} eq 'save' && $s->{employee}{admin}) {
		open F, ">/data/$s->{obase}/template/help/$s->{function}.tt";
		$s->{in}{help_text} =~ s/\r//g;
		print F $s->{in}{help_text};
		close F;
	}

	if (-e "/data/$s->{obase}/template/help/$path") {
		if ($s->{employee}{admin}) {
			$s->add_action(function => $s->{function},
				title => 'edit',
				params => "f=edit");

			if ($s->{in}{f} eq 'edit') {
				open F, "/data/$s->{obase}/template/help/$s->{function}.tt";
				while (my $line = <F>) {
					$s->{help_text} .= $s->escape($line);
				}
				close F;

				$s->tt('help_edit.tt', { s => $s, });		
				return;	
			}
		} else {
			$s->add_action(
				title => 'edit',
				class => 'greyout',
				nourl => 1);
		}

		my $help;
		$s->tt("template/help/$s->{function}.tt", { s => $s }, \$help);
		$help =~ s/\n\n/<br><br>/g;
		$s->{help_text} = $help;
		$s->tt('help.tt', { s => $s });
	} else {
		if ($s->{employee}{admin}) {
			$s->add_action(function => $s->{function},
				title => 'add',
				params => "f=add");
			
			if ($s->{in}{f} eq 'add') {
				$s->tt('help_add.tt', { s => $s, });		
				return;
			}
		} else {
			$s->add_action(
				title => 'add',
				class => 'greyout',
				nourl => 1);
		}
		$s->{content} = "Sorry no help file found for $s->{function}";
	}

	if ($s->{employee}{admin}) {
		$s->add_action(function => 'system',
			title => 'emergency information');
	}

	#$s->{content} = "<pre>".Data::Dumper->Dump([$s])."</pre>";
}

sub permission {
	my $s = shift;

	# manage permissions on an object.  This should only be accessable
	# with thos who are part of an admin group
	unless($s->{employee}{admin}) {
		$s->alert("You are not an admin.   You can not do this!");
		return 0;
	}

	$s->add_action(function => 'list') if (defined($s->{o}{functions}{list}));

	# before we get down to looking at the current permissions, lets make sure
	# we have defined them all in the database first
	my %check = $s->db_q("
		SELECT a_function, action_id
		FROM actions_v
		WHERE a_object=?
		",'keyval',
		v => [ $s->{object} ]);

	foreach my $f (keys %{$s->{o}{functions}}) {
		unless(defined($check{$f})) {
			$s->_set_default_access($s->{object},$f);
		}
	}

	my %existing = $s->db_q("
		SELECT a.a_function, a.action_id, concat(ga.group_id) as gids 
		FROM actions_v a
			LEFT JOIN group_actions_v ga ON a.action_id=ga.action_id
		WHERE a.a_object=?
		GROUP BY 1,2
		",'hashhash',
		k => 'a_function',
		v => [ $s->{object} ]);

	foreach my $f (keys %existing) {
		foreach my $id (split ',', $existing{$f}{gids}) {
			$existing{$f}{groupids}{$id} = $id;
		}
	}

	my @groups = $s->db_q("
		SELECT *
		FROM groups
		ORDER BY name
		",'arrayhash');

	if ($s->{in}{update}) {
		foreach my $f (keys %{$s->{o}{functions}}) {
			if ($s->{in}{"f:all:$f"}) {
				# by clearing all actions, we give everyone permission
				$s->db_q("
					DELETE FROM group_actions
					WHERE action_id=?
					",undef,
					v => [ $check{$f} ]);
			} else {
				foreach my $g (@groups) {
					if ($s->{in}{"f:$g->{group_id}:$f"} 
						&& !defined($existing{$f}{groupids}{$g->{group_id}})) {

						# we need to create a new entry
						$s->db_insert('group_actions',{
							action_id => $check{$f},
							group_id => $g->{group_id},
							});

					} elsif (!defined($s->{in}{"f:$g->{group_id}:$f"})
						&& defined($existing{$f}{groupids}{$g->{group_id}})) {
						# we need to delete an entry
						$s->db_q("
							DELETE FROM group_actions
							WHERE action_id=?
							AND group_id=?
							",undef,
							v => [ $check{$f}, $g->{group_id} ]);
					}
				}
			}
		}

		$s->notify("Permissions updated");
		if ($s->{in}{return}) {
			$s->redirect(function => $s->{in}{return},
				params => $s->{in}{return_args});
		}
		return;
	}

	#croak "<pre>".Data::Dumper->Dump([\%existing])."</pre>";

	$s->tt('permission.tt', { s => $s, groups => \@groups, existing => \%existing });
}

sub sendmail {
	my $s = shift;
	my %info = @_;

	my %from;
	my $nodev;
	if ($info{from}) {
		$nodev = 1;
		$from{email} = $info{from};
	} else {
		%from = $s->db_q("
			SELECT *
			FROM employees_v
			WHERE employee_id=?
			",'hash',
			v => [ $s->{employee_id} ]);
	
		croak "Unknown email address for you...." unless($from{email});
	
		$info{from} = qq("$from{name}" <$from{email}>) unless($info{from});
		#$info{bcc} = qq("$from{name}" <$from{email}>);
	}

	# Check to make sure we are getting passed all the information we need;
	foreach my $key (qw(to from subject)) {
		croak "Missing '$key' parameter on sendmail call" unless($info{$key});
	}

	foreach my $key (qw(to cc bcc)) {
		# make sure and put spaces around any email addresses
		if ($info{$key}) {
			$info{$key} =~ s/,/, /g;
		}
	}

	my @attachments;
	# if we have an attachment, check all the files first
	if (defined($info{attachment})) {
		foreach my $a (@{$info{attachment}}) {
			croak "Could not find /tmp/$a" unless (-e "/tmp/$a");
			push(@attachments,$a);
		}
	}

	if ($s->{env}{DEV} && !$nodev) {
		$info{subject} .= " (normally for $info{to})";
		$info{to} = $info{from};
		delete $info{bcc};
	}

	my $data;
	$data .= "From: $info{from}\n";
	$data .= "To: $info{to}\n";
	$data .= "Cc: $info{cc}\n" if ($info{cc});
	$data .= "Bcc: $info{bcc}\n" if ($info{bcc});
	$data .= "Subject: $info{subject}\n";

	my $boundary = md5_hex("$info{from}$info{subject}".time);

	$data .= qq(Mime-Version: 1.0\n);
	$data .= qq(Content-Type: multipart/mixed;\n\tboundary="$boundary"\n);

	$data .= "\nThis is a multi-part message in MIME format.\n";
	$data .= "\n--$boundary\n";
	$data .= "Content-Type: text/plain; charset=iso-8859-1\n";
	$data .= "Content-Transfer-Encoding: 7bit\n";
	$data .= "\n$info{body}\n";

	foreach my $a (@attachments) {
		if (-e "/tmp/$a" && $a) {
			my $ct;
			$ct = 'text/html' if ($a =~ m/\.html?$/i);
			$ct = 'image/jpeg' if ($a =~ m/\.jpg$/i);
			$ct = 'image/png' if ($a =~ m/\.png$/i);
			$ct = 'image/gif' if ($a =~ m/\.gif$/i);
			$ct = 'text/xml' if ($a =~ m/\.x(m|s)l$/i);
			$ct = 'text/css' if ($a =~ m/\.css$/i);
			$ct = 'application/pdf' if ($a =~ m/\.pdf$/i);
			$ct = 'text/plain' if ($a =~ m/\.txt$/i);

			my $content;
			open F, "/tmp/$a";
			while (<F>) {
				$content .= $_;
			}
			close F;

			$data .= "\n--$boundary\n";
			$data .= qq(Content-Type: $ct; name="$a"\n);
			$data .= qq(Content-Transfer-Encoding: base64\n);
			$data .= qq(Content-Disposition: attachment; filename="$a"\n\n);
			$data .= encode_base64($content)."\n";
		}
	}

	$data .= "\n--$boundary--\n";

#	open TMP, ">/tmp/sendmail.txt";
#	print TMP $data;
#	close TMP;

	if ($from{gauth} || ($s->{env}{GUSER} && $s->{env}{GAUTH} && $s->{send_google})) {
		return if (_send_gmail($s,\%from,\%info,$data));
	}

	open (MAIL, qq(|/usr/sbin/sendmail -f $from{email} -t)) or
		croak "Could not send mail. $!";
	print MAIL $data;
	close MAIL;
}

sub _send_gmail {
	my $s = shift;
	my $from = shift;
	my $info = shift;
	my $data = shift;

	# write to the database table, then the cron job will send things out

	my $queue = $s->db_q("SELECT tablename FROM pg_tables WHERE tablename='gmail_queue'",'scalar');

	if ($queue) {
		$s->db_insert('gmail_queue',{
			gauth => $from->{gauth},
			email => $from->{email},
			env_guser => $s->{env}{GUSER},
			env_gauth => $s->{env}{GAUTH},
			email_to => $info->{to},
			email_cc => $info->{cc},
			email_bcc => $info->{bcc},
			email_data => $data,
			});
	
		return 1;
	}

	my $smtp = Net::SMTP::SSL->new('smtp.gmail.com', Port => 465, Debug => 0) || croak "$@"; 
	#return 0;
	if ($from->{gauth}) {
		$smtp->auth($from->{email},$from->{gauth}) 
			|| croak "Auth failed while trying to send through smtp.gmail.com"; #return 0;
	} else {
		$smtp->auth($s->{env}{GUSER},$s->{env}{GAUTH}) 
			|| croak "Auth failed while trying to send through smtp.gmail.com via $s->{env}{GUSER}"; #return 0;
	}
	$smtp->mail($from->{email}."\n");
	$smtp->to("$info->{to}\n");
	$smtp->cc("$info->{cc}\n") if ($info->{cc});
	$smtp->bcc("$info->{bcc}\n") if ($info->{bcc});
	$smtp->data();
	unless($from->{gauth}) {
		$smtp->datasend("Reply-To: $from->{email}\n");
	}
	$smtp->datasend($data);
	$smtp->dataend();
	$smtp->quit;

	return 1;
}

#########################
# GENERIC FUNCTIONS
#########################
sub generic_display {
	my $s = shift;

	return unless($s->check_in_id());

	my %hash = $s->db_q("SELECT * FROM $s->{o}{view} WHERE $s->{o}{id}=?",'hash',
		v => [ $s->{in}{$s->{o}{id}} ]);

	$s->add_action(function => 'list') if (defined($s->{o}{functions}{list}));

	unless($hash{$s->{o}{id}}) {
		$s->alert("$s->{object} $s->{in}{$s->{o}{id}} not found");
		return;
	}

	if (defined($s->{o}{relations})) {
		foreach my $ref (@{$s->{o}{relations}}) {
			my $ob = $ref->{s} || '1';
			@{$hash{relation}{$ref->{t}}} = $s->db_q("
				SELECT * FROM $ref->{t}_v
				WHERE $s->{o}{id}=?
				ORDER BY $ob",
				'arrayhash',
				v => [ $s->{in}{$s->{o}{id}} ]);
		}
	}

	$s->add_action(function => 'create') if (defined($s->{o}{functions}{create}));
	$s->add_action(function => 'edit',
		params => "$s->{o}{id}=$hash{$s->{o}{id}}") if (defined($s->{o}{functions}{edit}));
	$s->add_action(function => 'delete',
		params => "$s->{o}{id}=$hash{$s->{o}{id}}") if (defined($s->{o}{functions}{delete}));

	if (defined($s->{o}{subs})) {
		foreach my $sub (@{$s->{o}{subs}}) {
			my $nf = $sub->{nf} || $sub->{n};
			@{$hash{sub}{$sub->{t}}} = $s->db_q("
				SELECT $sub->{k}, $nf
				FROM $sub->{t}
				WHERE $s->{o}{id}=?
				ORDER BY $sub->{n}",
				'arrayhash',
				v => [ $s->{in}{$s->{o}{id}} ]);

			$s->add_action(function => 'create', 
				object => $sub->{o},
				title => "Add ".ucfirst $sub->{o},
				params => "$s->{o}{id}=$hash{$s->{o}{id}}")
				unless($sub->{no_add});
		}
	}

	if (defined($s->{o}{display_functions})) {
		foreach my $function (@{$s->{o}{display_functions}}) {
			my $title = $function;
			$title =~ s/_/ /g;
			$s->add_action(function => $function, 
				title => $title, 
				params => "$s->{o}{id}=$hash{$s->{o}{id}}");
		}
	}

	#croak "<pre>".Data::Dumper->Dump([\%hash])."<pre>";

	$s->tt('display.tt',{ s => $s, hash => \%hash });
}

sub generic_addnote {
	my $s = shift;

	return unless($s->check_in_id());

	if ($s->{in}{note_text}) {
		$s->db_insert('notes',{
			employee_id => $s->{employee_id},
			ref => $s->{object},
			ref_id => $s->{in}{$s->{o}{id}},
			note_text => $s->{in}{note_text},
			});

		$s->{redirect} = "$s->{ubase}/$s->{object}/display?$s->{o}{id}=$s->{in}{$s->{o}{id}}";
	} else {
		$s->add_action(function => 'display',
			params => "$s->{o}{id}=$s->{in}{$s->{o}{id}}");

		$s->tt('addnote.tt',{ s => $s, });
	}
}

sub generic_search {
	my $s = shift;

	$s->add_action(function => 'list') if (defined($s->{o}{functions}{list}));

	my @search;
	my $id;
	foreach my $f (@{$s->{o}{fields}}) {
		if ($f->{search} && $s->{in}{$f->{k}}) {
			push @search, { k => $f->{k}, v => $s->{in}{$f->{k}} };
		}
	}

	if ($s->{in}{$s->{o}{id}} =~ m/^\d+$/) {
		# if they gave us an id, then skip everything else
		undef @search;
		push @search, { k => $s->{o}{id}, v => $s->{in}{$s->{o}{id}} };
	}

	if (scalar @search) {
		$s->{content} = "<pre>".Data::Dumper->Dump([\@search])."</pre>";
	} else {
		$s->tt('search.tt',{ s => $s, });
	}
}

sub generic_note {
	my $s = shift;

	return unless($s->check_in_id());

	my @list = $s->db_q("
		SELECT *
		FROM notes_v
		WHERE ref=?
		AND ref_id=?
		",'arrayhash',
		v => [ $s->{object}, $s->{in}{$s->{o}{id}} ]);

	foreach my $ref (@list) {
		$ref->{note_text} =~ s/\n/<br>/g;
	}

	$s->add_action(function => 'display',
		params => "$s->{o}{id}=$s->{in}{$s->{o}{id}}");

	$s->tt('note.tt',{ s => $s, list => \@list });
}

sub generic_log {
	my $s = shift;

	return unless($s->check_in_id());

	my $ref = $s->{o}{log_ref} || $s->{object};

	my @list = $s->db_q("
		SELECT *
		FROM logs_v
		WHERE ref=?
		AND ref_id=?
		",'arrayhash',
		v => [ $ref, $s->{in}{$s->{o}{id}} ]);

	$s->add_action(function => 'display',
		params => "$s->{o}{id}=$s->{in}{$s->{o}{id}}") if (defined($s->{o}{functions}{display}));

	$s->tt('log.tt',{ s => $s, list => \@list });
}

sub generic_delete {
	my $s = shift;

	return unless($s->check_in_id());

	my %hash = $s->db_q("SELECT * FROM $s->{o}{view} WHERE $s->{o}{id}=?",'hash',
		v => [ $s->{in}{$s->{o}{id}} ]);

	$s->db_q("DELETE FROM $s->{o}{table}
		WHERE $s->{o}{id}=?
		",undef,
		v => [ $s->{in}{$s->{o}{id}} ]);

	# figure out where we should take them next?
	my $continue;
	if ($s->{o}{subof}) {
		foreach my $f (@{$s->{o}{fields}}) {
			if ($f->{r} eq $s->{o}{subof}) {
				$continue = $s->object_link(
					object => $f->{r},
					function => 'display',
					params => "$f->{i}=$hash{$f->{i}}",
					title => 'Continue');
				last;
			}
		}	
	}

	$continue = $s->object_link(function => 'list',
		title => 'Continue') unless($continue);

	$s->notify("$s->{object} $s->{in}{$s->{o}{id}} deleted. $continue");
}

sub generic_save {
	my $s = shift;

	my %hash;
	my ($city, $state);
	foreach my $ref (@{$s->{o}{fields}}) {
		my $kname = $ref->{i} || $ref->{k};
		next if ($ref->{noedit} && $s->{in}{$s->{o}{id}} =~ m/^\d+$/);

		# if a boolean field is NOT NULL, then make sure it's set to false
		# otherwise the database will blow a cork below on the update statement
		if ($ref->{boolean} && $ref->{notnull} && !defined($s->{in}{$ref->{k}})) {
			$s->{in}{$ref->{k}} = 0;
		}

		$hash{$kname} = $s->{in}{$kname};

		if ($ref->{verify} eq "zipcode" && $hash{$kname}) {
			unless($s->verify_zipcode(\$hash{$kname},\$state,\$city)) {
				croak "$hash{$kname} is not a valid zipcode";
			}
		}

		if ($ref->{verify} eq 'regex' && $hash{$kname}) {
			unless($s->verify_regex($hash{$kname})) {
				croak "$hash{$kname} is not a valid regular expression";
			}
		}

		if ($ref->{verify} eq "phone" && $hash{$kname}) {
			unless($s->verify_phone(\$hash{$kname})) {
				croak "$hash{$kname} is not a valid phone number";
			}
		}

		if ($ref->{verify} eq "email" && $hash{$kname}) {
			unless($s->verify_email(\$hash{$kname})) {
				croak "$hash{$kname} is not a valid email";
			}
		}
	}

	$hash{city} = $city if (defined($hash{city}) && $city);
	$hash{state} = $state if (defined($hash{state}) && $state);

	$s->{dbh}->begin_work;

	if ($s->{in}{$s->{o}{id}} =~ m/^\d+$/) {
		# save an existing record
		$s->db_update_key($s->{o}{table},$s->{o}{id},$s->{in}{$s->{o}{id}},\%hash);
	} else {
		# create a new record
		if (defined($s->{o}{create_session_extra})) {
			my $key = $s->{o}{create_session_extra};
			$hash{$key} = $s->{session_data}{$key};
		}
		$s->{in}{$s->{o}{id}} = $s->db_insert($s->{o}{table},\%hash,$s->{o}{id});
	}

	if ($s->{o}{relations}) {
		foreach my $ref (@{$s->{o}{relations}}) {
			my %existing = $s->db_q("
				SELECT $ref->{k}, $ref->{n} FROM $ref->{t}_v
				WHERE $s->{o}{id}=?",
				'keyval',
				v => [ $s->{in}{$s->{o}{id}} ]);
			# delete rows
			foreach my $id (keys %existing) {
				unless(defined($s->{in}{"$ref->{t}:$id"})) {
					$s->db_q("
						DELETE FROM $ref->{t}
						WHERE $s->{o}{id}=?
						AND $ref->{k}=?
						",undef,
						v => [ $s->{in}{$s->{o}{id}}, $id ]);
				}
			}
			# insert new rows
			foreach my $k (keys %{$s->{in}}) {
				if ($k =~ m/^$ref->{t}:(\S+)$/) {
					my $id = $1;
					unless(defined($existing{$id})) {
						$s->db_insert($ref->{t}, {
							$s->{o}{id} => $s->{in}{$s->{o}{id}},
							$ref->{k} => $id,
							});
					}
				}
			}
		}
	}

	$s->{dbh}->commit;

	$s->{redirect} = "$s->{ubase}/$s->{object}/display?$s->{o}{id}=$s->{in}{$s->{o}{id}}";
}

sub update_lookup_table {
	my $s = shift;
	my %args = @_;

	$args{in_regex} = $args{table} unless($args{in_regex});

	my %existing;
	my ($k1,$k2);
	if ($args{id} =~ m/^(.+):(.+)$/) {
		$k1 = $1;
		$k2 = $2;
		%existing = $s->db_q("
			SELECT $args{k}, $args{k} 
			FROM $args{table}
			WHERE $k1=?
			AND $k2=?
			",'keyval',
			v => [ $s->{in}{$k1}, $s->{in}{$k2} ]);
	} else {
		%existing = $s->db_q("
			SELECT $args{k}, $args{k} 
			FROM $args{table}
			WHERE $args{id}=?
			",'keyval',
			v => [ $s->{in}{$args{id}} ]);
	}

	# delete rows
	foreach my $id (keys %existing) {
		unless(defined($s->{in}{"$args{in_regex}:$id"})) {
			if ($k1) {
				$s->db_q("
					DELETE FROM $args{table}
					WHERE $args{k}=?
					AND $k1=?
					AND $k2=?
					",undef,
					v => [ $id, $s->{in}{$k1}, $s->{in}{$k2} ]);
			} else {
				$s->db_q("
					DELETE FROM $args{table}
					WHERE $args{k}=?
					AND $args{id}=?
					",undef,
					v => [ $id, $s->{in}{$args{id}} ]);
			}
		}
	}
	# insert new rows
	foreach my $k (keys %{$s->{in}}) {
		if ($k =~ m/^$args{in_regex}:(\S+)$/) {
			my $id = $1;
			unless(defined($existing{$id})) {
				if ($k1) {
					$s->db_insert($args{table}, {
						$args{k} => $id,
						$k1 => $s->{in}{$k1},
						$k2 => $s->{in}{$k2},
						});
				} else {
					$s->db_insert($args{table}, {
						$args{k} => $id,
						$args{id} => $s->{in}{$args{id}},
						});
				}
			}
		}
	}
}

sub generic_create {
	my $s = shift;

	foreach my $ref (@{$s->{o}{fields}}) {
		if ($ref->{kv}) {
			@{$s->{o}{menu}{$ref->{k}}} = $s->db_q("
				SELECT id, name
				FROM $ref->{kv}
				ORDER BY name
				",'arrayhash');
		} elsif ($ref->{r}) {
			my $table = $ref->{r};
			if ($table ne $s->{object}) {
				eval {
				@{$s->{o}{menu}{$ref->{k}}} = $s->db_q("
					SELECT id, name
					FROM ${table}s_v_keyval
					ORDER BY name
					",'arrayhash');
					};
			}
		}
	}

	#croak "<pre>".Data::Dumper->Dump([\%{$s->{o}}])."<pre>";

	$s->add_action(function => 'list') if (defined($s->{o}{functions}{list}));

	$s->tt('create.tt',{ s => $s, });
}

sub generic_edit {
	my $s = shift;

	return unless($s->check_in_id());

	my %hash = $s->db_q("SELECT * FROM $s->{o}{view} WHERE $s->{o}{id}=?",'hash',
		v => [ $s->{in}{$s->{o}{id}} ]);

	foreach my $ref (@{$s->{o}{fields}}) {
		if ($ref->{w}) {
			@{$hash{menu}{$ref->{r}}} = $s->db_q("
				SELECT $ref->{i} as id, name
				FROM $ref->{r}s
				WHERE $ref->{w}=?
				ORDER BY name
				",'arrayhash',
				v => [ $hash{$ref->{w}} ]);
		} elsif ($ref->{kv}) { 
			@{$hash{menu}{$ref->{r}}} = $s->db_q("
				SELECT id, name
				FROM $ref->{kv}
				ORDER BY name
				",'arrayhash');
		} elsif ($ref->{r}) {
			my $table = $ref->{r};
			@{$hash{menu}{$ref->{r}}} = $s->db_q("
				SELECT id, name
				FROM ${table}s_v_keyval
				ORDER BY name
				",'arrayhash');
		}
	}

	if (defined($s->{o}{relations})) {
		foreach my $ref (@{$s->{o}{relations}}) {
			@{$hash{relation}{$ref->{t}}} = $s->db_q("
				SELECT * FROM $ref->{t}_v_$s->{object}
				WHERE $s->{o}{id}=?
				ORDER BY 1",
				'arrayhash',
				v => [ $s->{in}{$s->{o}{id}} ]);
		}
	}

	#croak "<pre>".Data::Dumper->Dump([\%hash])."</pre>";

	$s->add_action(function => 'list') if (defined($s->{o}{functions}{list}));
	$s->add_action(function => 'display',
		params => "$s->{o}{id}=$hash{$s->{o}{id}}") if (defined($s->{o}{functions}{display}));
	$s->add_action(function => 'delete',
		params => "$s->{o}{id}=$hash{$s->{o}{id}}") if (defined($s->{o}{functions}{delete}));

	$s->tt('edit.tt',{ s => $s, hash => \%hash });
}

sub generic_import {
	my $s = shift;

	my $localfile = "/tmp/import_$s->{object}_$s->{employee_id}.csv";

	if ($s->{o}{subof}) {
		# means we need a parent type ID to carry through everywhere, 
		# so we need to load the details of that object
		no strict 'refs';
		my $config = $s->{obase}.'::object::'.$s->{o}{subof}.'::config';
		$s->{o}{sub_object} = &{$config}($s);

		return unless($s->check_in_id($s->{o}{sub_object}{id}));

		$s->{subof_key} = $s->{o}{sub_object}{id};
		$s->{subof_id} = $s->{in}{$s->{subof_key}};
	}

	if (defined($s->{in}{file}{Contents})) {
		#unless ($s->{in}{file}{'Content-Type'} =~ m/^(text|application)\/(csv|vnd\.ms-excel)$/) {
		#	$s->alert("Sorry, file must be a CSV file.  This one is a $s->{in}{file}{'Content-Type'}");
		#	return;
		#}

		# save the contents to disk, then give them options on the import to map 
		# the fields to the right spot
		$s->{in}{file}{Contents} =~ s/\r/\n/g;
		$s->{in}{file}{Contents} =~ s/\n\n/\n/g;

		my @header = $s->csv_to_array((split "\n", $s->{in}{file}{Contents})[0],1);
		open F, ">$localfile";
		print F $s->{in}{file}{Contents};
		close F;

		foreach my $ref (@{$s->{o}{fields}}) {
			if ($ref->{r}) {
				my $table = $ref->{r};
				@{$s->{menu}{$ref->{r}}} = $s->db_q("
					SELECT id, name
					FROM ${table}s_v_keyval
					ORDER BY name
					",'arrayhash');
			}
		}
		
		# try and process the file
		#croak "<pre>".Data::Dumper->Dump([\%{$s->{in}}])."</pre>";
		#croak "dump\n".Data::Dumper->Dump([\@header]);
		$s->tt('map_import.tt', { s => $s, header => \@header });
		return;
	}

	if ($s->{in}{process}) {
		#croak "<pre>".Data::Dumper->Dump([\%{$s->{in}}])."</pre>";
		# load the file
		unless(-e $localfile) {
			$s->alert("Sorry, can't find import file $localfile");
			return;
		}
		my $file;
		open F, $localfile;
		while (<F>) {
			$file .= $_;
		}
		close F;

		my %fmap;
		foreach my $f (keys %{$s->{in}}) {
			if ($f =~ m/^f:(\d+)$/) {
				$fmap{$1} = $s->{in}{$f} if ($s->{in}{$f});
			}
		}
		
		unless(keys %fmap) {
			$s->alert("No fields where defined to map import file into");
			return;
		}

		$s->{dbh}->begin_work;

		my $data_import_id = $s->db_insert('data_imports',{
			table_name => $s->{o}{table},
			employee_id => $s->{employee_id},
			count => 0,
			},'data_import_id');

		if ($s->{in}{clear}) {
			my $where;
			if ($s->{subof_key}) {
				$where = " WHERE $s->{subof_key}=$s->{subof_id}";
			}
			if (defined($s->{o}{create_session_extra})) {
				my $key = $s->{o}{create_session_extra};
				$where = " WHERE $key = $s->{session_data}{$key}";
			}
			eval { $s->db_q("DELETE FROM $s->{o}{table}$where"); };
			if ($@) {
				$s->alert("Sorry, could not delete all the existing $s->{object}s");
				return;
			}
		}

		my @r = $s->csv_to_array($file);
		my $count;
		my %default;
		foreach my $k (keys %{$s->{in}}) {
			if ($k =~ m/^default:([^:]+)$/) {
				my $fn = $1;
				if ($s->{in}{"default:$fn:null"}) {
					# override only null values
					$default{null}{$fn} = $s->{in}{$k} if ($s->{in}{$k});
				} else {
					# only override everyting
					$default{all}{$fn} = $s->{in}{$k} if ($s->{in}{$k});
				}
			}
		}

		if (defined($s->{o}{create_session_extra})) {
			my $key = $s->{o}{create_session_extra};
			$default{all}{$key} = $s->{session_data}{$key};
		}

		#$s->alert("<pre>".Data::Dumper->Dump([\%default])."</pre>");
		#return;

		#my @debug;
		for my $i ( 1 .. $#r ) {
			my %import;
			foreach my $n (keys %fmap) {
				$import{$fmap{$n}} = $r[$i][$n-1];
			}

			# clean up....
			foreach my $k (keys %import) {
				$import{$k} =~ s/(\s+|,)$//; # strip trailing spaces and other crap like commas
				$import{$k} =~ s/^\s+//; # strip leading
			}

			# verify....
			foreach my $f (@{$s->{o}{fields}}) {
				if ($import{$f->{k}} && $f->{verify}) {
					if ($f->{verify} eq 'phone') {
						unless($s->verify_phone(\$import{$f->{k}})) {
							$import{$f->{k}} = '';
						}
					} elsif ($f->{verify} eq 'email') {
						unless($s->verify_email(\$import{$f->{k}})) {
							$import{$f->{k}} = '';
						}
					} elsif ($f->{verify} eq 'zipcode') {
						unless($s->verify_zipcode(\$import{$f->{k}},\$import{state},\$import{city})) {
							$import{$f->{k}} = '';
							$import{state} = '';
							$import{city} = '';
						}
					}
				}
			}

			# override values from the file it they were defined
			# in the default values area
			foreach my $k (keys %{$default{all}}) {
				$import{$k} = $default{all}{$k};
			}

			foreach my $k (keys %{$default{null}}) {
				$import{$k} = $default{null}{$k} unless($import{$k});
			}


			#push @debug, { %import };
			$import{data_import_id} = $data_import_id;

			# add any required subof key
			$import{$s->{subof_key}} = $s->{subof_id} if ($s->{subof_key});
			eval { $s->db_insert($s->{o}{table},\%import); };
			if ($@) {
				$s->alert("Error while processing line $i of file: $@\n".
					"<pre>".Data::Dumper->Dump([\%import])."</pre>");
				$s->{dbh}->rollback;
				return;
			} else {
				$count++;
			}
		}

		#croak "process dump\n".Data::Dumper->Dump([\@r]);
		$s->db_update_key('data_imports','data_import_id',$data_import_id,{
			count => $count
			});

		$s->{dbh}->commit;

		unlink $localfile;

		if ($s->{subof_key}) {
			$s->notify("File imported successfully. $count rows processed. ".
				$s->object_link(function => 'display',
					object => $s->{o}{subof},
					params => "$s->{subof_key}=$s->{subof_id}",
					title => 'Continue'));
		} else {
			$s->notify("File imported successfully. $count rows processed. ".
				$s->object_link(function => 'list',
				title => 'Continue'));
		}

		#$s->{content} .= "<pre>".Data::Dumper->Dump([\@debug])."</pre>";
		return;
	}

	# before we can do anything, make sure we have a data_import_id field on this 
	# table, otherwise we can not roll this back or delete what we just imported
	eval {
		$s->db_q("SELECT data_import_id
			FROM $s->{o}{table}
			LIMIT 1
			");
		};
	if ($@) {
		$s->alert("Sorry, you can not import into this object because it does not have a ".
			"data_import_id field in the database table");
		return;
	}

	$s->tt('import.tt', { s => $s, });
}

sub generic_list {
	my $s = shift;

	my $ob = $s->{o}{list_orderby} || 1;
	my @list = $s->db_q("SELECT * FROM $s->{o}{view} ORDER BY $ob",'arrayhash');

	$s->add_action(function => 'create') if (defined($s->{o}{functions}{create}));
	$s->add_action(function => 'sync') if (defined($s->{o}{functions}{sync}));
	$s->add_action(function => 'import') if (defined($s->{o}{functions}{import}));
	$s->add_action(function => 'search') if (defined($s->{o}{functions}{search}));

	$s->tt('list.tt',{ s => $s, list => \@list });
}

sub calendar {
	my $s = shift;
	my $start_day = shift || $s->{datetime}{ymd};
	my $months = shift || 1;

	croak "invalid calendar months value: $months" unless($months =~ m/^\d+$/);
	$months = 12 if ($months > 12);

	my @list = $s->db_q("
		SELECT d.stat_date, extract('dow' from d.stat_date) as dow,
			to_char(d.stat_date, 'Month YYYY') as month_name,
			to_char(d.stat_date, 'DD') as day,
			to_char(d.stat_date, 'YYYY-MM') as month,
			CASE WHEN d.stat_date < date(now()) THEN TRUE ELSE FALSE END as past
		FROM date_values(date(date_trunc('month',date(?))),
			date(date_trunc('month',date(?)) + interval '$months month' - interval '1 day')) d
		ORDER BY d.stat_date
		",'arrayhash',
		v => [ $start_day, $start_day ]);

	my @weeks;
	my %week;
	foreach my $ref (@list) {
		if (keys %week) {
			if ($ref->{dow} == 0) {
				push @weeks, { %week };
				%week = ();
			} elsif ($ref->{month_name} ne $week{month_name}) {
				push @weeks, { %week };
				%week = ();
			}
		}

		$week{month_name} = $ref->{month_name};
		$week{month} = $ref->{month};
		$week{days}{$ref->{dow}}{day} = $ref->{day};
		$week{days}{$ref->{dow}}{date} = $ref->{stat_date};
	}

	push @weeks, { %week };

	my %calendar = (
		weeks => \@weeks,
		dow => {
			0 => { s => 'S', m => 'Sun', l => 'Sunday' },
			1 => { s => 'M', m => 'Mon', l => 'Monday' },
			2 => { s => 'T', m => 'Tue', l => 'Tuesday' },
			3 => { s => 'W', m => 'Wed', l => 'Wednesday' },
			4 => { s => 'T', m => 'Thu', l => 'Thursday' },
			5 => { s => 'F', m => 'Fri', l => 'Friday' },
			6 => { s => 'S', m => 'Sat', l => 'Saturday' },
			},
		);
	return %calendar;
}

####################################
# PRIVATE STUFF
####################################
sub _content_add_menu {
	my $s = shift;

	if ($s->{nomenu}) {
		if ($s->{o}{interface} && $s->{$s->{o}{id}}) {
			my $menu;
			$s->tt('interface_menu.tt', { s => $s }, \$menu)
				unless($s->{nomenu_interface});
			return $menu;
		} else {
			return '';
		}
	} else {
		if ($s->{employee}{admin} && !($s->{object} =~ m/^(me|help)$/)) {
			$s->{employee}{object}{$s->{object}}{permission} = 1;
			(my $args = $s->{args}) =~ s/=/%3D/g;
			$s->add_action(function => 'permission',
				params => "return=$s->{function}&return_args=".$s->escape($args)) 
				unless($s->{env}{HIDE_PERMISSION} || $s->{agent});
		}

		# if we are in autocommit still at this point
		# then it probably means there was an error, so we need
		# to rollback before we can do this query below
		if ($s->{dbh}->{AutoCommit} == 0) {
			$s->{dbh}->rollback;
		}

		# load tabs
		@{$s->{tabs}} = $s->db_q("
			SELECT code, COALESCE(tab_name, name) as name
			FROM objects
			WHERE tab_order IS NOT NULL
			ORDER BY tab_order
			",'arrayhash');

		my $menu;
		$s->tt($s->{o}{menutemplate} || 'menu.tt', { s => $s }, \$menu);
		return $menu;
	}
}

sub _head_add_css {
	my $s = shift;

	return if ($s->{no_css});

	my $stylefile = 'style';
	if ($s->{agent}) {
		$stylefile = "$s->{agent}/$stylefile";
	}

	# in order to help with load times, just include the css directly
	# instead of having them call the request the file separatly
	my $sfile = "/data/$s->{obase}/content/css/$stylefile.css"; 

	# if our object has a specific style file, then use that instead
	$sfile = "/code/$s->{obase}/css/$s->{o}{css}.css" if ($s->{o}{css});


	my $return;
	if (-e $sfile) {
		$return = "<style>";
		open F, $sfile;
		while (<F>) {
			chomp;
			$return .= $_;
		}
		close F;
		$return .= "</style>\n";
	}
	return $return;

#	my $v = (stat("$s->{plib}/css/$stylefile.css"))[9];
#	my $return = qq(\t<link rel="stylesheet" href="/css/$stylefile-r$v.css" />\n);
#
#	# check for a custom stylesheet
#	my $cv = (stat("/data/$s->{obase}/content/custom.css"))[9];
#	if ($cv) {
#		$return .= qq(\t<link rel="stylesheet" href="/custom-r$cv.css" />\n);
#	}
#
#	if ($s->{agent} eq 'iphone') {
#		my $scale = ($s->{allow_zoom}) ? 'yes' : 'no';
#		$return .= qq(\t<meta name="viewport" content="user-scalable=$scale, width=device-width" />\n);
#	}
#
#	return $return;
}

sub add_js {
	my $s = shift;
	my $type = shift;

	$s->{add_js}{$type} = 1;

	return '';
}

sub _head_add_js {
	my $s = shift;

	if (defined($s->{add_js})) {
		# always add prototype
		$s->{add_js}{prototype} = 1;
	}

	my $return = qq(\n<script type="text/javascript" src="/js/prototype.js"></script>\n)
		if ($s->{add_js}{prototype});

	foreach my $k (keys %{$s->{add_js}}) {
		next if ($k eq 'prototype');
		if ($k eq 'scriptaculous') {
			$return .= qq(<script type="text/javascript" src="/js/scriptaculous.js?effects,controls"></script>\n);
		} elsif ($k eq 'calendar') {
			$return .= qq(<script type="text/javascript" src="/js/calendar_date_select/calendar_date_select.js"></script>\n).
			qq(<script type="text/javascript" src="/js/calendar_date_select/format_iso_date.js"></script>\n);
		} else {
			$return .= qq(<script type="text/javascript" src="/js/$k.js"></script>\n);
		}
	}

	$return .= join "\n", @{$s->{head_js}} if (defined($s->{head_js}));

	return $return;
}

sub html_caption_scroll {
	my $s = shift;
	my $caption = shift;
	my $scroll = shift;
	my $title = shift || 'scroll';
	my $bmargin = shift || 5;

	return qq|<div class="floatleft">$caption</div><div id="clink" class="captionlink"><a href="#" onClick="javascript:dscroll(\$('$scroll'),$bmargin); \$('clink').style.display = 'none'; return true;" class="action">$title</a></div>|;
}

sub html_display_link {
	my $s = shift;
	my $object = shift;
	my $id = shift;
	my $name = shift;
	my $keyfield = shift || 'id';

	return $s->html_a("$s->{ubase}/$object/display?$keyfield=$id",$name);
}

sub html_input_calendar {
	my $s = shift;
	my $key = $s->escape(shift);
	my $value = $s->escape(shift);

	$key = "$s->{acfb}::$key" if ($s->{acfb});

	my $cal = $s->add_calendar($key);
	my $str = qq(<input $cal name="$key" value="$value" autocomplete="off" size="12">);

	return $str;
}

sub add_calendar {
	my $s = shift;
	my $id = shift;

	$s->add_js('calendar');

	return qq|id="$id" onclick="javascript: new CalendarDateSelect( \$('$id'), {close_on_click: true, embedded:true, year_range:1} );"|;
}

sub _head_add_title {
	my $s = shift;

	if (ref $s->{title} eq 'ARRAY') {
		my $t = join ' :: ', @{$s->{title}};
		$s->{title} = $t;
	}

	if ($s->{env}{TITLE}) {
		if ($s->{title}) {
			$s->{title} = "$s->{env}{TITLE} :: $s->{title}";
		} else {
			$s->{title} = $s->{env}{TITLE};
		}
	}

	$s->{title} = $s->{uri} unless($s->{title});

	return "<title>$s->{title}</title>\n";
}

sub _interface_auth {
	my $s = shift;

	# make sure we have some things
	croak "id not defined in object $s->{object}" unless($s->{o}{id});
	croak "table not defined in object $s->{object}" unless($s->{o}{table});
	croak "view not defined in object $s->{object}" unless($s->{o}{view});
	croak "interface not defined in object $s->{object}" unless($s->{o}{interface});

	if ($s->{object} eq 'logout' && $s->{cookies}{IL}) {
		$s->db_q("
			UPDATE $s->{o}{table} SET interface_cookie=NULL
			WHERE interface_cookie=?
			",undef,
			v => [ $s->{cookies}{IL} ],
			);

		#$s->{raw_path} = '/';
		#$s->{uri} =~ s/logout//;
	}

	SWITCH: {
		last if ($s->_interface_check_cookie());
		last if ($s->_interface_check_login());
	}

	#$s->{content} .= "<pre>".Data::Dumper->Dump([$s])."</pre>";

	return 1 if ($s->{$s->{o}{id}});

	$s->{nomenu} = 1; 
	$s->{title} = 'Login';

	$s->tt('interface_login.tt',{ s => $s });

	return 0;
}

sub _interface_check_login {
	my $s = shift;

	if ($s->{in}{interface_email} && $s->{in}{interface_password}) {
		$s->{in}{interface_email} = lc $s->{in}{interface_email};
		my %hash = $s->db_q("
			SELECT *
			FROM $s->{o}{view}
			WHERE interface_email=?
			",'hash',
			v => [ $s->{in}{interface_email} ],
			);

		my $md5pass;
		if ($s->{env}{DEV}) {
			# skip password checking on dev
			$md5pass = $hash{interface_password};
		} else {
			$md5pass = md5_hex($hash{interface_email}.$s->{in}{interface_password});
		}

		if ($md5pass eq $hash{interface_password}) {
			my $cookie = $s->_interface_cookie_key(
				id => $hash{$s->{o}{id}},
				password => $hash{interface_password},
				);
			$s->{$s->{o}{id}} = $hash{$s->{o}{id}};
			$s->{$s->{o}{interface}} = { %hash };
			push @{$s->{r}{set_cookie}}, "IL=$cookie; path=/;";
			$s->db_update_key($s->{o}{table},$s->{o}{id},$hash{$s->{o}{id}},{
				interface_cookie => $cookie,
				});
			return 1;
		} else {
			$s->{error}{login} = "Invalid password";
		}
	}

	return 0;
}

sub _interface_check_cookie {
	my $s = shift;

	if ($s->{cookies}{IL}) {
		my %hash = $s->db_q("
			SELECT *
			FROM $s->{o}{view}
			WHERE interface_cookie=?
			",'hash',
			v => [ $s->{cookies}{IL} ],
			);

		if ($hash{$s->{o}{id}}) {
			my $validate = $s->_interface_cookie_key(
				id => $hash{$s->{o}{id}},
				password => $hash{interface_password},
				);

			if ($validate eq $s->{cookies}{IL}) {
				$s->{$s->{o}{id}} = $hash{$s->{o}{id}};
				$s->{$s->{o}{interface}} = { %hash };
				return 1;
			} else {
				push @{$s->{r}{set_cookie}}, 'IL=; path=/;';
				$s->db_update_key($s->{o}{table},$s->{o}{id},$hash{$s->{o}{id}},{
					interface_cookie => '',
					});
			}
		} else {
			push @{$s->{r}{set_cookie}}, 'IL=; path="/";';
		}
	}

	return 0;
}

sub _interface_cookie_key {
	my $s = shift;
	my %args = @_;

	my $expire;
	if ($s->{env}{ETERNAL_COOKIE}) {
		$expire = $s->{server_name}; # just add a little more to try and make this unique
	} else {
		$expire = time2str('%x',time());
	}
	return md5_hex("84Fw$args{id}YouSuck$args{passwd}7f2$expire");
}

sub _employee_permissions {
	my $s = shift;

	# build a data structure we can use in add_action to determine if
	# we should even show something to someone

	# first get a list of all actions that are not assigned to a group
	# which means everyone can do them
	# then append to this the actions that this specific person can do
	my @list = $s->db_q("
		SELECT a.a_object, a.a_function
		FROM actions a
			LEFT JOIN group_actions ga ON a.action_id=ga.action_id
		WHERE ga.group_id IS NULL
		UNION
		SELECT a.a_object, a.a_function
		FROM employee_groups eg
			JOIN group_actions ga ON eg.group_id=ga.group_id
			JOIN actions a ON ga.action_id=a.action_id
		WHERE eg.employee_id=?
		",'arrayhash',
		c => "employeepermission$s->{employee_id}",
		cache_for => '60',
		v => [ $s->{employee_id} ]);

	# now, from this list, lets make a data structure we can use
	foreach my $ref (@list) {
		$s->{employee}{object}{$ref->{a_object}}{$ref->{a_function}} = 1;
	}
}

sub _authenticate {
	my $s = shift;

	if ($s->{in}{forgot_email}) {
		if ($s->verify_email(\$s->{in}{forgot_email})) {
			my %employee = $s->db_q("
				SELECT *
				FROM employees
				WHERE email=?
				",'hash',
				v => [ $s->{in}{forgot_email} ]);

			if ($employee{employee_id}) {
				my $new = int(rand(1)*100000);
				$s->db_q("
					UPDATE employees SET passwd=?
					WHERE employee_id=?
					",undef,
					v => [ $new, $employee{employee_id} ]);

				$s->sendmail(to => $employee{email},
					from => 'root@'.$s->{server_name},
					subject => 'Password Reset',
					body => "Your password at $s->{server_name} has has been reset\n\n".
						"username: $employee{login}\n".
						"password: $new\n\n".
						"Please login, and then go change your password.");

				$s->{error}{login} = "Your password has been reset and sent to $employee{email}";
			} else {
				$s->{error}{login} = "Unknown email";
				$s->{in}{forgot} = 1;
			}
		} else {
			$s->{error}{login} = "That is not a valid email";
			$s->{in}{forgot} = 1;
		}
	}	

	if ($s->{object} eq 'logout' && $s->{cookies}{L}) {
		$s->db_q("
			UPDATE employees SET cookie=NULL
			WHERE cookie=?
			",undef,
			v => [ $s->{cookies}{L} ],
			);

		#$s->{raw_path} = '/';
		#$s->{uri} =~ s/logout//;
	}

	SWITCH: {
		last if ($s->_check_api());
		last if ($s->_check_cookie());
		last if ($s->_check_login());
	}

	#$s->{content} .= "<pre>".Data::Dumper->Dump([$s])."</pre>";

	return 1 if ($s->{employee_id});

	$s->{nomenu} = 1; 
	$s->{title} = 'Login';

	unless($s->{in}{ori_args}) {
		$s->{in}{ori_args} = $s->{args};
	}

	if ($s->{in}{forgot}) {
		$s->tt('forgot.tt',{ s => $s });
	} else {
		$s->tt('login.tt',{ s => $s });
	}

	return 0;
}

sub _check_login {
	my $s = shift;

	if ($s->{in}{login} && $s->{in}{passwd}) {
		my %hash = $s->db_q("
			SELECT *
			FROM employees_v_login
			WHERE lower(login)=lower(?)
			",'hash',
			v => [ $s->{in}{login} ],
			);

		my $md5pass = md5_hex($hash{login}.$s->{in}{passwd});
		if ($md5pass eq $hash{passwd} && !$hash{account_expired}) {
			my $cookie = $s->_cookie_key(
				employee_id => $hash{employee_id},
				passwd => $hash{passwd},
				);
			$s->{employee_id} = $hash{employee_id};
			$s->{employee} = { %hash };
			_employee_permissions($s);
			push @{$s->{r}{set_cookie}}, "L=$cookie; path=/;";
			$s->db_update_key('employees','employee_id',$hash{employee_id},{
				cookie => $cookie,
				});
			# now, populate args
			if ($s->{in}{ori_args}) {
				foreach my $kv (split '&', $s->{in}{ori_args}) {
					my ($k,$v) = split '=', $kv;
					$v =~ tr/+/ /;
					$v =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
					$s->{in}{$k} = $v;
				}
			}

			return 1;
		} else {
			$s->{error}{login} = "Invalid password or login";
		}
	} elsif ($s->{env}{IP_LOGIN}) {
		my %hash = $s->db_q("
			SELECT *
			FROM employees_v_login
			WHERE ip_addr>>=?
			",'hash',
			v => [ $s->{remote_addr} ],
			);

		if ($hash{employee_id} && !$hash{account_expired}) {
			my $cookie = $s->_cookie_key(
				employee_id => $hash{employee_id},
				passwd => $hash{passwd} || $hash{ip_addr},
				);
			$s->{employee_id} = $hash{employee_id};
			$s->{employee} = { %hash };
			_employee_permissions($s);
			push @{$s->{r}{set_cookie}}, "L=$cookie; path=/;";
			$s->db_update_key('employees','employee_id',$hash{employee_id},{
				cookie => $cookie,
				});
			# now, populate args
			if ($s->{in}{ori_args}) {
				foreach my $kv (split '&', $s->{in}{ori_args}) {
					my ($k,$v) = split '=', $kv;
					$v =~ tr/+/ /;
					$v =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
					$s->{in}{$k} = $v;
				}
			}

			return 1;
		}
	}

	return 0;
}

sub _check_api {
	my $s = shift;

	if ($s->{in}{key}) {
		my $employee_id = $s->db_q("
			SELECT employee_id
			FROM employees
			WHERE apikey=?
			AND COALESCE(expired_ts,now()) >= now()
			",'scalar',
			c => "apikey$s->{in}{key}",
			cache_for => '60',
			v => [ $s->{in}{key} ]);

		if ($employee_id) {
			$s->{employee_id} = $employee_id;
			%{$s->{employee}} = $s->db_q("
				SELECT *
				FROM employees_v_login
				WHERE employee_id=?
				",'hash',
				c => "login$employee_id",
				cache_for => '60',
				v => [ $s->{employee_id} ]);
			$s->{api} = 1;
			_employee_permissions($s);
			delete $s->{in}{key};
			return 1;
		} else {
			$s->{error}{login} = "Invalid key";
			return 0;
		}	
	}
}

sub _check_cookie {
	my $s = shift;

	if ($s->{cookies}{L}) {
		my %hash = $s->db_q("
			SELECT *
			FROM employees_v_login
			WHERE cookie=?
			",'hash',
			v => [ $s->{cookies}{L} ],
			);

		if ($hash{employee_id}) {
			my $validate = $s->_cookie_key(
				employee_id => $hash{employee_id},
				passwd => $hash{passwd} || $hash{ip_addr},
				);

			if ($validate eq $s->{cookies}{L} && !$hash{account_expired}) {
				$s->{employee_id} = $hash{employee_id};
				$s->{employee} = { %hash };
				_employee_permissions($s);
				return 1;
			} else {
				push @{$s->{r}{set_cookie}}, 'L=; path=/;';
				$s->db_update_key('employees','employee_id',$hash{employee_id},{
					cookie => '',
					});
			}
		} else {
			push @{$s->{r}{set_cookie}}, 'L=; path="/";';
		}
	}

	return 0;
}

sub _cookie_key {
	my $s = shift;
	my %args = @_;

	# should we make the cookie expire today, or allow them to stay logged in
	# forever?  Default to today unless we have a site config that says otherwise

	my $expire;

	if ($s->{env}{ETERNAL_COOKIE}) {
		$expire = $s->{server_name}; # just add a little more to try and make this unique
	} else {
		$expire = time2str('%x',time());
	}

	return md5_hex("23xf$args{employee_id}wwcl8w4$args{passwd}hqs$expire");
}

1;
