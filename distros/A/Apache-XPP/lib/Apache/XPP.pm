# Apache::XPP
# -------------
# $Revision: 1.32 $
# $Date: 2002/02/15 05:00:01 $
# -----------------------------------------------------------------------------
=head1 NAME

XPP (XPML Page Parser) - An embedded perl language designed to co-exist with HTML

=cut

package Apache::XPP;

=head1 SYNOPSIS

 use Apache::XPP;
 my $xpp = Apache::XPP->new( Apache->request );
 $xpml->run;

=head1 REQUIRES

 Apache
 Apache::Constants
 File::stat
 FileHandle
 HTTP::Request
 LWP::UserAgent

=cut

use Carp;
use strict;
use vars qw( $AUTOLOAD $debug $debuglines );

BEGIN {
    $Apache::XPP::REVISION       = (qw$Revision: 1.32 $)[-1];
    $Apache::XPP::VERSION        = '2.02';
}

use Apache::XPP::Cache;
use Apache::XPP::PreParse;

if ($INC{ 'Apache.pm' }) {
	eval q{
		use Apache();
		use Apache::Constants qw(:response);
	};
}


use Carp;
use File::stat;
use FileHandle;
use HTTP::Request;
use LWP::UserAgent;

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Apache::XPP is an HTML parser which on run time compiles and runs embedded perl code.

=head1 CLASS VARIABLES

=over

=item C<$Apache::XPP::main_class>

XPP sub-classes must set $Apache::XPP::main_class to the name of the
sub-class. This will allow xinclude/include to work properly.

=cut

$Apache::XPP::main_class = 'Apache::XPP';

=item C<$debug>

Activates debugging output.  All debugging output is sent to STDERR.

At present there are only 4 levels of debugging :
 0 - no debugging (default)
 1 - some debugging
 2 - verbose debugging
 3 - adds some Data::Dumper calls

=item C<$debuglines>

Optionally, you can activate the $debuglines, which will cause all
debugging output to include the line numbers (in this file) of the debugging.

=back

=cut

$debug		= 0;
$debuglines	= 0;

=head1 METHODS

=over

=item C<handler> ( $r )

The Apache handler hook. This is the entry point for the Apache module.  It
takes the Apache request object ($r) as its parameter and builds a new XPP
object to handle the request. In order to support the procedural nature
of include() and xinclude() a global is defined. If you subclass Apache::XPP
replace the value of the global L<"$Apache::XPP::main_class"> with your class name.

=cut

sub handler ($$) {
	my $class	= shift;
	my $r		= shift;
	
	# handle things other than GET or POST gracefully here
	unless ($r->method eq 'GET' || $r->method eq 'POST') {
		return NOT_IMPLEMENTED();
	}

	# Prevent browser caching
	$r->no_cache(1);

	# Get the file and build a new XPP object
	warn "\nxpp: handler called" . ($debuglines ? '' : "\n") if ($debug);
	
	my $xpp	= $class->new( {
							filename			=> $r->filename,
							r					=> $r,
							is_main				=> 1,
							server_name			=> $r->get_server_name,
							XPMLHeaders			=> $r->dir_config( 'XPMLHeaders' ),
							XPMLFooters			=> $r->dir_config( 'XPMLFooters' ),
							XPPIncludeDir		=> $r->dir_config( 'XPPIncludeDir' ),
							XPPVHostIncludeDir	=> $r->dir_config( 'XPPVHostIncludeDir' )
						} );
	
	if (ref($xpp)) {
		eval {
			$xpp->run;
		};
		if ($@) {
			warn "Bad things happened. XPP page didn't compile: $@";
			return SERVER_ERROR();
		}
	} else {
		$r->log_error("[client " . $r->get_remote_host . "] [Apache::XPP] File not accessible: " . $r->filename());
		return NOT_FOUND();
	}
	return OK();
} # END method handler

=item C<new> ( \%params | $filename )

Creates a new XPP object. Valid parameter keys are:

=over 4

=item *
 source    - A block of xpp code to be parsed

=item *
 filename  - A filename/url specifying a code block

=back

All other parameters will be stashed in the xpp object.

=cut
{ # BEGIN private codeblock
my %cache;
sub new {
	my $proto		= shift;
	my ($params, $class);
	
	if (ref($proto)) {
		$class		= ref($proto);
		my %params	= %{ $proto };
		delete $params{ 'source' };
		delete $params{ 'filename' };
		
		@params{ keys %{ $params } }	= ( values %{ $params } );
		$params		= \%params;
	} else {
		$class		= $proto;
		my $data	= shift;
		$params		= ref($data) ? \%{ $data } : { filename => $data };
	}
	
	$params->{ 'server_name' }	= 'localhost' unless exists($params->{ 'server_name' });
	$params->{ 'XPPIncludeDir' }	||= exists($ENV{'XPPIncludeDir'}) ? $ENV{'XPPIncludeDir'} : ($proto->XPPIncludeDir or './');
	
	my $specifier;
	# $specifier is the unique hash key to store the XPP object in the %cache. XPP objects representing
	# files will have the specifier "file:$filename", while XPP objects representing XPP source will use
	# a checksum (uhhh, CRC?) as a unique string in "source:$checksum". Both of these methods should be
	# the same for another request.
	
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# There needs to be a way to expunge objects representing XPP source, as the $specifier will change
# when the source changes. This will strand the cached XPP object in the %cache hash. Maybe source shouldn't
# be cached, or maybe XPP should periodically expunge cached source objects... The call to C<runtime> in the
# run method was an attempt to expire objects in this way (never finished though).
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	if ($params->{ 'filename' }) {
		$specifier	= 'file:' . $params->{ 'filename' };
	} elsif ($params->{ 'source' }) {
		# for source cache specifiers, use a checksum of the source
		$specifier	= 'source:' . (unpack("%32C*", $params->{ 'source' }) % 65535);
	} else {
		warn "no filename or source specified in xpp object construction" . ($debuglines ? '' : "\n") if ($debug);
		return undef;
	}
	
	if (my $xcache = $cache{ $specifier }) {
		warn "xpp:\tmodification time: " . scalar( localtime( $proto->mtime( $params->{ 'filename' } ) ) ) . "\n" if ($debug >= 2);
		warn "xpp:\tcache compiled at: " . scalar( localtime( $xcache->compiletime ) ) . "\n" if ($debug >= 2);
		if ($proto->mtime( $params->{ 'filename' } ) < $xcache->compiletime) {
			warn "xpp: using cached xpp object" . ($debuglines ? '' : "\n") if ($debug);
			return $xcache;
		} else {
			warn "xpp: expunging expired cached xpp object" . ($debuglines ? '' : "\n") if ($debug);
			delete $cache{ $specifier };
		}
	}

	warn "xpp: creating new xpp object" . ($debuglines ? '' : "\n") if ($debug);
	
	$params->{ 'preparsers' }	= [];
	
	my $self		= bless($params, $class);
	my $source		= ( exists $params->{'source'} )
						? $params->{ 'source' }
						: $self->load( $params->{'filename'} );
	
	my $r = $self->r();
	### Below corresponds to bugfix in r() regarding subrequests
	$r->register_cleanup(sub { delete $self->{'r'}; }) if (ref $params->{'r'});

	#We want to be caching these too. So there aren't conflicts, I'm going to use the header:
	#and :footer cache specifier.
	my ($header, $footer)	= ('') x 2;
	# This code is essentially the same for $header and $footer, so we use a small loop
	foreach ({XPMLHeaders => \$header}, {XPMLFooters => \$footer}) {
		my($dirconf, $headorfoot) = %{$_};
		
		my @files	= ref($r) ? split( ':', $self->$dirconf() ) : ();
		foreach my $filename (@files) {
			my ($hfxpp, $hfcache);
			if ($hfcache = $cache{ (($dirconf eq 'XPMLHeaders') ? 'header:' : 'footer:') .$filename }) {
				if ($proto->mtime( $filename ) > $hfcache->compiletime) {
					warn "xpp: expunging expired cached header object" 
						. ($debuglines ? '' : "\n") if ($debug);
					delete $cache{ $hfcache };
					$hfxpp = bless($params, $class);
					$$headorfoot .= $hfxpp->load( $filename );
				} else {	
					warn "xpp: using cached header object" 
						. ($debuglines ? '' : "\n") if ($debug);
					$$headorfoot .= $hfcache;
				}	
			} else {
				warn "xpp: caching new header object" 
					. ($debuglines ? '' : "\n") if ($debug);
				$hfxpp = bless($params, $class);
				$$headorfoot .= $hfxpp->load( $filename );
			}
		}
	}	

	$source = $header . $source . $footer;
	
	$self->parse( $self->preparse( $source ) );
	
	$self->compiletime( time );
	
	$cache{ $specifier }	= $self;
} # END constructor new
} # END private codeblock

=item C<preparse> (  )

Pre-Parses the object's code, converting TAGS to text and xpp code.  This method passes a 
reference to the xpp source to each preparser returned by the preparse class's C<parses>
method.  (The preparse class is returned by the C<preparseclass> method).

=cut
sub preparse {
	my $self			= shift;
	my $class			= ref($self) || return undef;
	my $source			= shift;
	warn "xpp: preparsing source" . ($debuglines ? '' : "\n") if ($debug);
	foreach my $pparser (@{ $class->preparseclass->parsers() }) {
		warn "xpp: \t$pparser" . ($debuglines ? '' : "\n") if ($debug);
		$class->preparseclass->$pparser( \$source );
	}
	return $self->source( $source );
} # END method preparse


=item C<parse> (  )

Parses the object's xpp source code, populating the object's C<code> attribute
with a subroutine reference which when run (with the C<run> method), will result
in the printing of the xpp page.

=cut
sub parse {
	my $self			= shift;
	my $class			= ref($self) || return undef;
	my $string			= $self->source;
	warn "xpp: parsing source" . ($debuglines ? '' : "\n") if ($debug);

	my @codesrc;
	{
		if ($debug >= 3) {
			eval "use Data::Dumper;";
			local($Data::Dumper::Indent)	= 0;
		}
		warn "xpp: parsing source:\n<<\n$string\n>>" . ($debuglines ? '' : "\n") if ($debug);

#		The regex in the while() statement below is somewhat complex. It was placed in one line for efficiency,
#		but this is how it came to be:
#		my $re_b		= q{<\?(?:xpp)?(=)?((?:(?!<\?|\?>).)*};	# only q{} and not qr{} because there is an imbalanced paren matched in the next line
#		my $re_e		= q{(?:(?!\?>).)*)\?>};					# only q{} and not qr{} because there is an imbalanced paren matched in the previous line
#		my $double_xpp	= qr{${re_b}(?:${re_b}${re_e})?${re_e}}so;
#		my $regex		= qr(^((?:(?!<\?).)*)$double_xpp)s;

#		# this was the old xpp parsing regex (which didn't handle embedded tags).
#		while (($string =~ s/^(.*?)\<\?(?:xpp)?(=)?(.*?\s*)\?\>//so) || ($string =~ s/^(.+)$//so)) {
		while (($string =~ s/^((?:(?!<\?).)*)<\?(?:xpp)?(=)?((?:(?!<\?|\?>).)*(?:<\?(?:xpp)?(?:=)?(?:(?!<\?|\?>).)*(?:(?!\?>).)*\?>)?(?:(?!\?>).)*)\?>//so) || ($string =~ s/^(.+)$//so)) {
			my $text	= $1;
			my $print	= $2 ? 1 : 0;
			my $code	= $3;
			warn Data::Dumper->Dump([$text,$code], [qw(text code)]) if ($debug >= 3);
			
			$text =~ s#\\#\\\\#gso;
			$text =~ s#\'#\\\'#gso;
			
			if ($text) {
				if ($self->is_main() && !$self->r()->notes('headersaway')) {
					push(@codesrc, "\$xpp->r()->send_http_header();\n");
					$self->r()->notes(headersaway => 1);
				}
				my $textsrc	= 'print ' . join(qq{ . "\\n"\n\t. }, map { qq{'$_'} } (split(/\n/, $text,-1))) . ";";
				push(@codesrc, $textsrc);			}
			if (defined $code) {
				if ($print) {
					push(@codesrc, qq{print ($code);});
				} else {
					push(@codesrc, $code);
				}
			}
 		}
	}
	
	my $type			= (ref($self->r()) ? $self->r()->content_type() : '');
	my $filename		= defined($self->filename()) ? $self->filename() : '';
	my $joined			= join('', (@codesrc));
	my $codesrc			= qq{
		sub {
			package Apache::XPP::Page;
			my \$xpp = shift;
			if (ref(\$xpp->r())) {
				\$xpp->r()->content_type( "${type}" );
			}
#line 0 ${filename}
			${joined}
		}
	};

	warn "xpp: source:\n" . $codesrc . ($debuglines ? '' : "\n") if ($debug >= 2);

	my $code			= eval $codesrc;
	if ($@) {
		warn "*** XPP COMPILE ERROR: $@";
		return undef;
	} else {
		return $self->code( $code );
	}
} # END method parse


=item C<run> ( @arguments )

Runs the XPP code (set by the C<parse> method), passing any arguments supplied to the code.
This should have the effect of printing the xpp page to STDOUT.

=cut
sub run {
	my $self	= shift;
	my $class	= ref($self) || return undef;
	warn "xpp: running xpp code" . ($debuglines ? '' : "\n") if ($debug);
	if (ref($self->code)) {
		
		# just testing...
		$self->runtime( time );
		
		
		$self->code->( $self, @_ );
		return 1;
	} else {
		return undef;
	}
} # END method run


=item C<returnrun> ( @arguments )

Calls C<run> with @arguments as specified, catching all output destined for STDOUT, and
returning the results as a string.

=cut
sub returnrun {
	my $self	= shift;
	my $class	= ref($self) || return undef;
	local(*XPP_TIE);
	warn "xpp: tying STDOUT" . ($debuglines ? '' : "\n") if ($debug);
	my $tieobj	= tie(*XPP_TIE, 'XPP::Tie');
	
	my $fh	= select( XPP_TIE );
	$self->run( @_ );
	select( $fh );
	
	my $content	= $tieobj->content();
#	untie(*XPP_TIE);
	return $content;
} # END method returnrun


=item C<load> ( $filename )

Returns the code specified by $filename.  If $filename begins with a url specifier
(e.g. http://), LWP::UserAgent will be used to retrieve the file.  If $filename
begins with a '/', it will be treated as a rooted filename.  Otherwise the filename
will be as a file relative to XPPIncludeDir

=cut
sub load {
	my $self		= shift;
	my $filename	= shift;
	my $counter		= shift;	# don't recurse
	warn "xpp: loading source ($filename)" . ($debuglines ? '' : "\n") if ($debug);
	
	if ((substr($filename,0,1) eq '/') or ((substr($filename,0,2) eq './') and ($counter))) {
		my $fh = new FileHandle;
		warn "xpp:\tattempting to load $filename" . ($debuglines ? '' : "\n") if ($debug);
#		if (($filename =~ m{^(/[/\-\w\.]+)$}) && ($fh->open($1))) {
		if ($fh->open($filename)) {
			local($/)	= undef;
			return <$fh>;
		} else {
			warn "xpp:\tfailed to load file $filename ($!)" . ($debuglines ? '' : "\n");
			return undef;
		}
	} elsif ($filename =~ m{^(?:.+)?://(?:.+)$}) {
		my $ua	= LWP::UserAgent->new;
		my $req	= HTTP::Request->new( 'GET', $filename );
		my $res	= $ua->request( $req );
		warn "xpp:\tattempting to load $filename from LWP::UserAgent" . ($debuglines ? '' : "\n") if ($debug);
		if ($res->is_success) {
			return $res->content;
		} else {
			warn "xpp:\tfailed to load file $filename ($!)" . ($debuglines ? '' : "\n");
			return undef;
		}
	} else {
		my $qualified	= $self->qualify( $filename );
		warn "xpp:\tqualifying filename, and attempting to load '${qualified}'" . ($debuglines ? '' : "\n") if ($debug);
		return $self->load( $qualified, 1 ) unless ($counter);
		return undef;
	}
} # END method load


sub mtime {
	my $self		= shift;
	my $filename	= ref($self) ? $self->filename : shift;
	my $counter		= shift;
	warn "xpp: checking mtime of file ($filename)" . ($debuglines ? '' : "\n") if ($debug);
	
	if (substr($filename,0,1) eq '/') {
		my $mtime = undef;
		unless (-f $filename) {
			return undef;
		}
		
		my $st = stat($filename);	# using File::stat
		if (ref($st) && $st->can('mtime')) {
			return $st->mtime;
		} else {
			warn "xpp:\tcannot stat file ($filename): $!" . ($debuglines ? '' : "\n") if ($debug);
			return undef;
		}
	} elsif ($filename =~ m{^((?:.+)?://(?:.+))$}) { 
		my $ua	= LWP::UserAgent->new;
		my $req	= HTTP::Request->new( 'GET', $filename );
		my $res	= $ua->request( $req );
		if (my $headers = $res->headers) {
			return $headers->last_modified;
		} else {
			warn "xpp:\tfailed to get mtime for url ($!)" . ($debuglines ? '' : "\n") if ($debug);
			return undef;
		}
	} else {
		warn "xpp:\tattempting to qualify filename, and mtime again '${filename}'" . ($debuglines ? '' : "\n") if ($debug);
		return $self->mtime( $self->qualify( $filename ), 1 ) unless ($counter);
		return undef;
	}
} # END method mtime


=item C<qualify> ( $filename )

Qualifies the passed name to a fully rooted filename by using either C<incdir> or C<docroot>.

=cut
sub qualify {
	my $self		= shift;
	my $filename	= shift;
	carp "xpp: qualifying filename ($filename)" . ($debuglines ? '' : "\n") if ($debug);
	
	if (substr($filename,0,1) eq '/') {
		warn "xpp:\tqualifying document rooted file" . ($debuglines ? '' : "\n") if ($debug >= 2);
		if ($filename =~ m{^(/[/\-\w\.]+)$}) {
			return join('', $self->docroot, $1);
		}
	} elsif ($filename =~ m{^((?:.+)?://(?:.+))$}) {
		warn "xpp:\tassuming URL is already qualified" . ($debuglines ? '' : "\n") if ($debug >= 2);
		return $1;
	} else {
		warn "xpp:\tqualifying include rooted file" . ($debuglines ? '' : "\n") if ($debug >= 2);
		warn "xpp:\tfilename: $filename" . ($debuglines ? '' : "\n") if ($debug >= 2);;
		if ($filename =~ m{^([/\-\w\.]+)$}) {
			my $r = $self->r();
			my $incdir = $self->incdir($r);
			return ($incdir) ? join('/', $incdir, $1) : $1;
		}
	}
	
	warn "xpp: qualify failed on filename '$filename'!" . ($debuglines ? '' : "\n") if ($debug);
	return undef;
} # END method qualify


=item C<incdir> (  )

Returns the include directory from which C<include> and C<xinclude> will retrieve source
from by default.  See C<include>, C<xinclude>, and C<load> for more documentation on this
process.

=cut
sub incdir {
	my $self	= shift;
	my $r		= (ref $self) ? $self->r : shift;
	#Not cleaning up for now, why not cache for the life of a process.
	#$r->register_cleanup(sub {undef $Apache::XPP::_cache::incdir}) unless (defined $Apache::XPP::_cache::incdir);
	my $incdir;
	unless ( $incdir = $Apache::XPP::_cache::incdir{ $self->server_name } ) {
		if ($incdir = $self->XPPVHostIncludeDir) {
			my @parts = split(/\./, $r->get_server_name);
 			my($segment, $replacement, $startpt, $endpt);
 			while ($incdir =~ m/\%([p\d\+\-\.]+)/) {
 				$segment = $1;
 				if ($segment eq 'p') {
 					$incdir =~ s/\%p/$self->server_name/e;
 					next;
 				}
 				if ($segment eq '0') {
 					$incdir =~ s/\%0/$self->server_name/e;
 					next;
 				}
 				if ($segment =~ /^-(\d)/) {
 					$endpt = scalar(@parts) - $1;
 					$startpt = ($incdir =~ /\+$/) ? 0 : $endpt;
 				} elsif ($segment =~ /^(\d)/) {
 					$startpt = $1 - 1;
 					$endpt = ($incdir =~ /\+$/) ? $#parts : $startpt;
 				}
				if ( ($startpt > $#parts) || ($endpt > $#parts) || ($startpt < 0) || ($endpt < 0) ) {
					$replacement = '_';
				} else {
 					$replacement = join('.', @parts[$startpt..$endpt]);
				}
 				$incdir =~ s/\%$segment/$replacement/;
 			}
		} else {
			$incdir = $self->XPPIncludeDir();
		}
		
		warn "XPPIncludeDir => $incdir" if ($debug);
		
		if (ref($r)) {
			$incdir = ($incdir =~ m#^/#) ? $incdir : $r->server_root_relative($incdir);
			warn "XPPIncludeDir => $incdir" if ($debug);		
		}
		
		$incdir =~ s#/$##;
		$incdir =~ /^(.*)$/;
		$incdir =  $Apache::XPP::_cache::incdir{$self->server_name} = $1;
		warn "XPPIncludeDir => $incdir" if ($debug);		
	}
	
	return $incdir	
} # END method incdir


=item C<docroot> (  )

Returns the document root directory from which all rooted filenames will be retrieved in
C<include>, and C<xinclude>.

=cut
sub docroot {
	my $self	= shift;
	my $docroot	= ref($self->r) ? $self->r->document_root : '';
	$docroot	||= '/';
	
	$docroot	=~ /^([\/.\w-]*)$/;
	return $1;
} # END method docroot


=item C<r> (  )

Returns the Apache request object

=cut
sub r {
	my $proto	= shift;
	my $data	= shift;
	my $r;
	if ($data && ref($proto)) {
		$r = $proto->{ 'r' } = shift;
	} elsif ( ref($proto) && ref($proto->{ 'r' }) ) {
		return $proto->{ 'r' };
	} else {
	 	# calling C<request> if the Apache package hadn't been loaded would cause an error
		if ($INC{ 'Apache.pm' }) {
			$r = ( ref($proto) ? ( $proto->{ 'r' } = Apache->request ) : return Apache->request )
		}
	}
	
	(ref $r) || return undef;
	### This prevents subrequests from using the wrong request object.  Also in new()
	$r->register_cleanup(sub { delete $proto->{'r'}; });
	return $r;
} # END method r

=item C<include> ( $filename )

Static, unbuffered, unparsed content include. It can be used within an xpml
script by simply saying

  include $filename;

See the C<load> method for more information

=cut
sub include ($) {
	my $self		= shift;
	my $filename	= shift;
	return (print $self->load( $self->qualify( $filename )  ));
} # END method include

=item C<xinclude> ( $filename, @options )

Dynamic, parsed, buffered content include. It can be used within an xpml
script by simply saying

  xinclude $filename;

=cut
sub xinclude {
	my $self		= shift;
	my $filename	= shift;
	my @options		= @_;
	my $x			= $self->new( { filename => $self->qualify( $filename ) } );
	$x->run( @options );
} # END method xinclude

sub XPMLHeaders {
	my $self	= shift;
	my $data	= ref($self) ? $self->{ 'XPMLHeaders' } : undef;
	$data		||= ref($self->r) ? $self->r->dir_config( 'XPMLHeaders' ) : undef;
	return $data;
}

sub XPMLFooters {
	my $self	= shift;
	my $data	= ref($self) ? $self->{ 'XPMLFooters' } : undef;
	$data		||= ref($self->r) ? $self->r->dir_config( 'XPMLFooters' ) : undef;
	return $data;
}

sub XPPIncludeDir {
	my $self	= shift;
	my $data	= ref($self) ? $self->{ 'XPPIncludeDir' } : undef;
	$data		||= ref($self->r) ? $self->r->dir_config( 'XPPIncludeDir' ) : undef;
	return $data;
}

sub XPPVHostIncludeDir {
	my $self	= shift;
	my $data	= ref($self) ? $self->{ 'XPPVHostIncludeDir' } : undef;
	$data		||= ref($self->r) ? $self->r->dir_config( 'XPPVHostIncludeDir' ) : undef;
	return $data;
}

sub server_name {
	my $self	= shift;
	my $data	= ref($self) ? $self->{ 'server_name' } : undef;
	$data		||= ref($self->r) ? $self->r->get_server_name : 'localhost';
	return $data;
}

=item C<debug> ( $debuglevel [, $debuglines ] )

Manipulates debug level.  See $debug above.

N.B. -- at present these flags are global, not per object.  Method works
as static or dynamic.

=cut
sub debug {
	(defined $_[2]) && ($debuglines = $_[1]);
	(defined $_[1]) ? $debug = $_[1] : $debug;
} # END method debug


sub AUTOLOAD {
	my $self	= shift;
	my $class	= ref($self) || return undef;
	my $name	= $AUTOLOAD;
	return undef if (substr($name,-9) eq '::DESTROY');
	$name		=~ s/^.*://;
	if (scalar(@_)) {
		return ($self->{ $name } = shift);
	} else {
		return $self->{ $name };
	}
} # END method AUTOLOAD

sub preparseclass { 'Apache::XPP::PreParse' }

package Apache::XPP::Page;

=item include( $inc_location )

Returns the plaintext of the include file $inc_location.

=cut
sub include {
	return Apache::XPP->include( shift );
} # END method include

=item xinclude( $inc_location, @ARGS )

Returns the XPP parsed text of the include file $inc_location, passing @ARGS to the page as arguments.

=cut
sub xinclude {
	return $Apache::XPP::main_class->xinclude( @_ );
} # END method xinclude


package XPP::Tie;

use Carp;
use strict;
use vars qw( $debug $debuglines );

# Debugging uses debug settings of Apache::XPP
$debug		= \$Apache::XPP::debug;
$debuglines	= \$Apache::XPP::debuglines;

sub TIEHANDLE {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $content	= '';
	my $self	= bless(\$content, $class);
}


sub PRINT {
	my $self		= shift;
	warn "tie: caught print" . ($$debuglines ? '' : "\n") if ($$debug);
	warn "tie:\t@_" . ($$debuglines ? '' : "\n") if ($$debug >= 2);
	${ $self }	.= join($,, @_) . (defined($\) ? $\ : '');
}


sub PRINTF {
	my $self		= shift;
	warn "tie: caught printf" . ($$debuglines ? '' : "\n") if ($$debug);
	warn "tie:\t" . sprintf( @_ ) . ($$debuglines ? '' : "\n") if ($$debug >= 2);
	${ $self }	.= sprintf( @_ );
}


sub content {
	my $self		= shift;
	return ${ $self };
}


1;

__END__

=back

=head1 REVISION HISTORY

$Log: XPP.pm,v $
Revision 1.32  2002/02/15 05:00:01  kasei
- fixed bugs introduced by adding Apache::XPP::Inline

Revision 1.31  2002/02/15 02:39:31  kasei
- merged 1.30 and 1.28 conflicts

Revision 1.30  2002/02/15 02:17:06  kasei
- Fixed quoting bug with $r->content_type
- Changed use constant to use subs for Apache constants when in a non m_p environment

Revision 1.29  2002/02/01 08:22:12  kasei
Reduced dependance on Apache (still waiting on testing to confirm nothing broke)

Revision 1.28  2002/01/16 22:06:46  kasei
- Updated README to mention version 2.01
- POD typo fix in XPP.pm

Revision 1.27  2002/01/16 21:06:01  kasei
Updated VERSION variables to 2.01

Revision 1.26  2002/01/16 21:00:02  kasei
- Added PREREQ_PM arguments to Makefile.PL
- XPP.pm now only uses Data::Dumper if $debug >= 3 (not listed as a prereq)

Revision 1.25  2000/09/23 01:22:06  dweimer
Fixed VHostIncludeDir's, thanks david.

Revision 1.24  2000/09/20 00:33:18  zhobson
Fixed a warning in docroot(), misplaced "-" made it look like an invalid range

Revision 1.23  2000/09/08 22:26:44  david
added, changed, revised, and otherwise cleaned up a lot of POD
cleaned up new()
	- removed dependence on MD5 (uses conventional checksum)
	- folded nearly duplicate header and footer code into a loop
incdir()
	- now uses Apache->server_root_relative() instead of $ENV{SERVER_ROOT}
debug()
	- new method to manipulate $debug and $debuglines globals
Apache::XPP::Tie class now uses $debug settings of Apache::XPP class

	"This would go great with gwack-a-mole!" - Z.B.

Revision 1.22  2000/09/08 00:42:45  dougw
Took out rscope stuff.

Revision 1.21  2000/09/07 23:42:23  greg
fixed POD

Revision 1.20  2000/09/07 23:30:40  dougw
Fixed over.

Revision 1.19  2000/09/07 20:15:54  david
new(), r() - makes previous bug fix less agressive, yet more thorough.

Revision 1.18  2000/09/07 19:49:01  david
r() - fixed peculiar (and elusive) bug where DirectoryIndex accessed pages
(and potentially any page using a subrequest) caused a segmentation fault
with cached pages.

Revision 1.17  2000/09/07 18:48:11  dougw
Small update

Revision 1.16  2000/09/07 18:45:14  dougw
Version update

Revision 1.15  2000/09/06 23:42:50  dougw
Modified POD to be consistent with BingoX


=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

None

=head1 TODO

precompile

=head1 COPYRIGHT

 Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free
 software. It may be used, redistributed and/or modified under the terms
 of the GNU Lesser General Public License as published by the Free Software
 Foundation.

 You should have received a copy of the GNU Lesser General Public License
 along with this library; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Greg Williams <greg@cnation.com>
Doug Weimer <dougw@cnation.com>

=head1 THANKS TO

=over 4

=item Chris Nandor <pudge@pobox.com> for his help on the regex core.

=back

=cut
