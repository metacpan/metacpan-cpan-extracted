package CGI::SSI;
use strict;

use HTML::SimpleParse;
use File::Spec::Functions; # catfile()
use FindBin;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Cookies;
use URI;
use Date::Format;

our $VERSION = '0.92';

our $DEBUG = 0;

sub import {
    my($class,%args) = @_;
    return unless exists $args{'autotie'};
    $args{'filehandle'} = $args{'autotie'} =~ /::/ ? $args{'autotie'} : caller().'::'.$args{'autotie'};
    no strict 'refs';
    my $self = tie(*{$args{'filehandle'}},$class,%args);
    return $self;
}

my($gmt,$loc,$lmod);

sub new {
    my($class,%args) = @_;
    my $self = bless {}, $class;

    $self->{'_handle'}        = undef;

    my $script_name = '';
    if(exists $ENV{'SCRIPT_NAME'}) {
		($script_name) = $ENV{'SCRIPT_NAME'} =~ /([^\/]+)$/;
    }

    tie $gmt, 'CGI::SSI::Gmt', $self;
    tie $loc, 'CGI::SSI::Local', $self;
    tie $lmod, 'CGI::SSI::LMOD', $self;

    $ENV{'DOCUMENT_ROOT'} ||= '';
    $self->{'_variables'}     = {
        DOCUMENT_URI    =>  ($args{'DOCUMENT_URI'} || $ENV{'SCRIPT_NAME'}),
        DATE_GMT        =>  $gmt,
        DATE_LOCAL      =>  $loc,
        LAST_MODIFIED   =>  $lmod,
        DOCUMENT_NAME   =>  ($args{'DOCUMENT_NAME'} || $script_name),
        DOCUMENT_ROOT   =>  ($args{'DOCUMENT_ROOT'} || $ENV{DOCUMENT_ROOT}),
                                };

    $self->{'_config'}        = {
        errmsg  =>  ($args{'errmsg'}  || '[an error occurred while processing this directive]'),
        sizefmt =>  ($args{'sizefmt'} || 'abbrev'),
        timefmt =>  ($args{'timefmt'} ||  undef),
                                };

	$self->{_max_recursions} = $args{MAX_RECURSIONS} || 100; # no "infinite" loops
	$self->{_recursions} = {};

	$self->{_cookie_jar}  = $args{COOKIE_JAR} || HTTP::Cookies->new();

    $self->{'_in_if'}     = 0;
    $self->{'_suspend'}   = [0];
    $self->{'_seen_true'} = [1];

    return $self;
}

sub TIEHANDLE {
    my($class,%args) = @_;
    my $self = $class->new(%args);
    $self->{'_handle'} = do { local *STDOUT };
    my $handle_to_tie = '';
    if($args{'filehandle'} !~ /::/) {
		$handle_to_tie = caller().'::'.$args{'filehandle'};
    } else {
		$handle_to_tie = $args{'filehandle'};
    }
    open($self->{'_handle'},'>&'.$handle_to_tie) or die "Failed to copy the filehandle ($handle_to_tie): $!";
    return $self;
}

sub PRINT {
    my $self = shift;
    print {$self->{'_handle'}} map { $self->process($_) } @_;
}

sub PRINTF {
    my $self = shift;
    my $fmt  = shift;
    printf {$self->{'_handle'}} $fmt, map { $self->process($_) } @_;
}

sub CLOSE {
	my($self) = @_;
	close $self->{'_handle'};
}

sub process {
    my($self,@shtml) = @_;
    my $processed = '';
    @shtml = split(/(<!--#.+?-->)/s,join '',@shtml);
    local($HTML::SimpleParse::FIX_CASE) = 0; # prevent var => value from becoming VAR => value
    for my $token (@shtml) {
#	next unless(defined $token and length $token);
        if($token =~ /^<!--#(.+?)\s*-->$/s) {
            $processed .= $self->_process_ssi_text($self->_interp_vars($1));
		} else {
	        next if $self->_suspended;
		    $processed .= $token;
		}
    }
    return $processed;
}

sub _process_ssi_text {
    my($self,$text) = @_;

	# are we suspended?
    return '' if($self->_suspended and $text !~ /^(?:if|else|elif|endif)\b/);

	# what's the first \S+?
	if($text !~ s/^(\S+)\s*//) {
		warn ref($self)." error: failed to find method name at beginning of string: '$text'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}
    my $method = $1;
    return $self->$method( HTML::SimpleParse->parse_args($text) );
}

# many thanks to Apache::SSI
sub _interp_vars {
    local $^W = 0;
    my($self,$text) = @_;
    my($a,$b,$c) = ('','','');
    $text =~ s{ (^|[^\\]) (\\\\)* \$(?:\{)?(\w+)(?:\})? }
              {($a,$b,$c)=($1,$2,$3); $a . substr($b,length($b)/2) . $self->_echo($c) }exg;
    return $text;
}

# for internal use only - returns the thing passed in if it's not defined. echo() returns '' in that case.
sub _echo {
    my($self,$key,$var) = @_;
    $var = $key if @_ == 2;

    if($var eq 'DATE_LOCAL') {
		return $loc;
    } elsif($var eq 'DATE_GMT') {
		return $gmt;
    } elsif($var eq 'LAST_MODIFIED') {
		return $lmod;
    }

    return $self->{'_variables'}->{$var} if exists $self->{'_variables'}->{$var};
    return $ENV{$var} if exists $ENV{$var};
    return $var;
}

#
# ssi directive methods
#

sub config {
    my($self,$type,$value) = @_;
    if($type =~ /^timefmt$/i) {
		$self->{'_config'}->{'timefmt'} = $value;
    } elsif($type =~ /^sizefmt$/i) {
		if(lc $value eq 'abbrev') {
		    $self->{'_config'}->{'sizefmt'} = 'abbrev';
		} elsif(lc $value eq 'bytes') {
		    $self->{'_config'}->{'sizefmt'} = 'bytes';
		} else {
			warn ref($self)." error: value for sizefmt is '$value'. It must be 'abbrev' or 'bytes'.\n";
		    return $self->{'_config'}->{'errmsg'};
		}
    } elsif($type =~ /^errmsg$/i) {
		$self->{'_config'}->{'errmsg'} = $value;
    } else {
		warn ref($self)." error: arg to config is '$type'. It must be one of: 'timefmt', 'sizefmt', or 'errmsg'.\n";
		return $self->{'_config'}->{'errmsg'};
    }
    return '';
}

sub set {
    my($self,%args) = @_;
    if(scalar keys %args > 1) {
		$self->{'_variables'}->{$args{'var'}} = $args{'value'};
    } else { # var => value notation
		my($var,$value) = %args;
		$self->{'_variables'}->{$var} = $value;
    }
    return '';
}

sub echo {
    my($self,$key,$var) = @_;
    $var = $key if @_ == 2;

    if($var eq 'DATE_LOCAL') {
		return $loc;
    } elsif($var eq 'DATE_GMT') {
		return $gmt;
    } elsif($var eq 'LAST_MODIFIED') {
		return $lmod;
    }

    return $self->{'_variables'}->{$var} if exists $self->{'_variables'}->{$var};
    return $ENV{$var} if exists $ENV{$var};
    return '';
}

sub printenv {
    #my $self = shift;
    return join "\n",map {"$_=$ENV{$_}"} keys %ENV;
}

sub include {
	$DEBUG and do { local $" = "','"; warn "DEBUG: include('@_')\n" };
    my($self,$type,$filename) = @_;
    if(lc $type eq 'file') {
		return $self->_include_file($filename);
    } elsif(lc $type eq 'virtual') {
		return $self->_include_virtual($filename);
    } else {
		warn ref($self)." error: arg to include is '$type'. It must be one of: 'file' or 'virtual'.\n";
		return $self->{'_config'}->{'errmsg'};
    }
}

sub _include_file {
	$DEBUG and do { local $" = "','"; warn "DEBUG: _include_file('@_')\n" };
    my($self,$filename) = @_;

	# get the filename to open
    $filename = catfile($FindBin::Bin,$filename) unless -e $filename;

	# if we've reached MAX_RECURSIONS for this filename, warn and return the error
	if(++$self->{_recursions}->{$filename} >= $self->{_max_recursions}) {
		warn ref($self)." error: the maximum number of 'include file' recursions has been exceeded for '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}

	# open the file, or warn and return an error
    my $fh = do { local *STDIN };
    open($fh,$filename) or do {
		warn ref($self)." error: failed to open file ($filename): $!\n";
		return $self->{'_config'}->{'errmsg'};
    };

	# process the included file and return the result
    return $self->process(join '',<$fh>);
}

sub _include_virtual {
	$DEBUG and do { local $" = "','"; warn "DEBUG: _include_virtual('@_')\n" };
    my($self,$filename) = @_;

    # if this is a local file that we can just read, let's do that instead of getting it virtually
    if($filename =~ m|^/(.+)|) { # could be on the local server: absolute filename, relative to ., relative to $ENV{DOCUMENT_ROOT}
		my $file = $1;
		if(-e '/'.$file) { # back to the original
			$file = '/'.$file;
		} elsif(-e catfile($self->{'_variables'}->{'DOCUMENT_ROOT'},$file)) {
			$file = catfile($self->{'_variables'}->{'DOCUMENT_ROOT'},$file);
		} elsif(-e catfile($FindBin::Bin,$file)) {
			$file = atfile($FindBin::Bin,$file);
		}
		return $self->_include_file($file) if -e $file;
    }

	# create the URI to get(), or warn and return the error
    my $uri = eval {
		my $uri = URI->new($filename);
		$uri->scheme($uri->scheme || ($ENV{HTTPS} ? 'https' : 'http')); # ??
		$uri->host($uri->host || $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'} || 'localhost');
		$uri;
    } or do {
    	warn ref($self)." error: failed to create a URI based on '$filename'.\n";
    	return $self->{'_config'}->{'errmsg'};
    };
	if($@) {
    	warn ref($self)." error: failed to create a URI based on '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'} if $@;
	}

	# get the content of the request
	$self->{_ua} ||= $self->_get_ua();
	my $url = $uri->canonical;

	# have we reached MAX_RECURSIONS?
	if(++$self->{_recursions}->{$url} >= $self->{_max_recursions}) {
		warn ref($self)." error: the maximum number of 'include virtual' recursions has been exceeded for '$url'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}

	my $response = $self->{_ua}->get($url);

	# is it a success?
	unless($response->is_success) {
    	warn ref($self)." error: failed to get('$url'): ".$response->status_line.".\n";
		return $self->{_config}->{errmsg};
	}

	# process the included content and return the result
    return $self->process($response->content);
}

sub _get_ua {
	my $self = shift;
	my %conf = ();
	$conf{agent} = $ENV{HTTP_USER_AGENT} if $ENV{HTTP_USER_AGENT};
	my $ua = LWP::UserAgent->new(%conf);
	$ua->cookie_jar($self->{_cookie_jar});
	return $ua;
}

sub cookie_jar {
	my $self = shift;
	if(my $jar = shift) {
		$self->{_cookie_jar} = $jar;
	}
	return $self->{_cookie_jar};
}

sub exec {
    my($self,$type,$filename) = @_;
    if(lc $type eq 'cmd') {
		return $self->_exec_cmd($filename);
    } elsif(lc $type eq 'cgi') {
		return $self->_exec_cgi($filename);
    } else {
    	warn ref($self)." error: arg to exec() is '$type'. It must be one of: 'cmd' or 'cgi'.\n";
		return $self->{'_config'}->{'errmsg'};
    }
}

sub _exec_cmd {
    my($self,$filename) = @_;

	# have we reached MAX_RECURSIONS?
	if(++$self->{_recursions}->{$filename} >= $self->{_max_recursions}) {
		warn ref($self)." error: the maximum number of 'exec cmd' recursions has been exceeded for '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}

    my $output = `$filename`; # security here is mighty bad.

	# was the command a success?
	if($?) {
    	warn ref($self)." error: `$filename` was not successful.\n";
	    return $self->{'_config'}->{'errmsg'};
	}

	# process the output, and return the result
    return $self->process($output);
}

sub _exec_cgi { # no relative $filename allowed.
    my($self,$filename) = @_;

	# have we reached MAX_RECURSIONS?
	if(++$self->{_recursions}->{$filename} >= $self->{_max_recursions}) {
		warn ref($self)." error: the maximum number of 'exec cgi' recursions has been exceeded for '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}

	# create the URI from the filename
	my $uri = eval {
		my $uri = URI->new($filename);
		$uri->scheme($uri->scheme || ($ENV{HTTPS} ? 'https' : 'http')); # ??
		$uri->host($uri->host || $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'});
		$uri->query($uri->query || $ENV{'QUERY_STRING'});
		$uri;
	} or do {
    	warn ref($self)." error: failed to create a URI from '$filename'.\n";
		return $self->{'_config'}->{'errmsg'};
	};
	if($@) {
    	warn ref($self)." error: failed to create a URI from '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'} if $@;
	}
    
	# get the content
	$self->{_ua} ||= $self->_get_ua();
	my $url = $uri->canonical;
	my $response = $self->{_ua}->get($url);

	# success?
	unless($response->is_success) {
    	warn ref($self)." error: failed to get('$filename').\n";
		return $self->{_config}->{errmsg};
	}

	# process the content and return the result
    return $self->process($response->content);
}

sub flastmod {
    my($self,$type,$filename) = @_;

    if(lc $type eq 'file') {
		$filename = catfile($FindBin::Bin,$filename) unless -e $filename;
    } elsif(lc $type eq 'virtual') {
		$filename = catfile($self->{'_variables'}->{'DOCUMENT_ROOT'},$filename)
	    unless $filename =~ /$self->{'_variables'}->{'DOCUMENT_ROOT'}/;
    } else {
    	warn ref($self)." error: the first argument to flastmod is '$type'. It must be one of: 'file' or 'virtual'.\n";
		return $self->{'_config'}->{'errmsg'};
    }
	unless(-e $filename) {
    	warn ref($self)." error: flastmod failed to find '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}

    my $flastmod = (stat $filename)[9];

    if($self->{'_config'}->{'timefmt'}) {
		my @localtime = localtime($flastmod); # need this??
		return Date::Format::strftime($self->{'_config'}->{'timefmt'},@localtime);
    } else {
		return scalar localtime($flastmod);
    }
}

sub fsize {
    my($self,$type,$filename) = @_;

	if(lc $type eq 'file') {
		$filename = catfile($FindBin::Bin,$filename) unless -e $filename;
    } elsif(lc $type eq 'virtual') {
		$filename = catfile($ENV{'DOCUMENT_ROOT'},$filename) unless $filename =~ /$ENV{'DOCUMENT_ROOT'}/;
    } else {
    	warn ref($self)." error: the first argument to fsize is '$type'. It must be one of: 'file' or 'virtual'.\n";
		return $self->{'_config'}->{'errmsg'};
    }
	unless(-e $filename) {
    	warn ref($self)." error: fsize failed to find '$filename'.\n";
	    return $self->{'_config'}->{'errmsg'};
	}
	
    my $fsize = (stat $filename)[7];
    
    if(lc $self->{'_config'}->{'sizefmt'} eq 'bytes') {
		1 while $fsize =~ s/^(\d+)(\d{3})/$1,$2/g;
		return $fsize;
    } else { # abbrev
		# gratefully lifted from Apache::SSI
		return "   0k" unless $fsize;
		return "   1k" if $fsize < 1024;
		return sprintf("%4dk", ($fsize + 512)/1024) if $fsize < 1048576;
		return sprintf("%4.1fM", $fsize/1048576.0) if $fsize < 103809024;
		return sprintf("%4dM", ($fsize + 524288)/1048576) if $fsize < 1048576;
    }
}

#
# if/elsif/else/endif and related methods
#

sub _test {
    my($self,$test) = @_;
    my $retval = eval($test);
    return undef if $@;
    return defined $retval ? $retval : 0;
}

sub _entering_if {
    my $self = shift;
    $self->{'_in_if'}++;
    $self->{'_suspend'}->[$self->{'_in_if'}] = $self->{'_suspend'}->[$self->{'_in_if'} - 1];
    $self->{'_seen_true'}->[$self->{'_in_if'}] = 0;
}

sub _seen_true {
    my $self = shift;
    return $self->{'_seen_true'}->[$self->{'_in_if'}];
}

sub _suspended {
    my $self = shift;
    return $self->{'_suspend'}->[$self->{'_in_if'}];
}

sub _leaving_if {
    my $self = shift;
    $self->{'_in_if'}-- if $self->{'_in_if'};
}

sub _true {
    my $self = shift;
    return $self->{'_seen_true'}->[$self->{'_in_if'}]++;
}

sub _suspend {
    my $self = shift;
    $self->{'_suspend'}->[$self->{'_in_if'}]++;
}

sub _resume {
    my $self = shift;
    $self->{'_suspend'}->[$self->{'_in_if'}]--
		if $self->{'_suspend'}->[$self->{'_in_if'}];
}

sub _in_if {
    my $self = shift;
    return $self->{'_in_if'};
}

sub if {
    my($self,$expr,$test) = @_;
    $expr = $test if @_ == 3;
    $self->_entering_if();
    if($self->_test($expr)) {
		$self->_true();
    } else {
		$self->_suspend();
    }
    return '';
}

sub elif {
    my($self,$expr,$test) = @_;
    die "Incorrect use of elif ssi directive: no preceeding 'if'." unless $self->_in_if();
    $expr = $test if @_ == 3;
    if(! $self->_seen_true() and $self->_test($expr)) {
		$self->_true();
		$self->_resume();
    } else {
		$self->_suspend() unless $self->_suspended();
    }
    return '';
}

sub else {
    my $self = shift;
    die "Incorrect use of else ssi directive: no preceeding 'if'." unless $self->_in_if();
    unless($self->_seen_true()) {
		$self->_resume();
    } else {
		$self->_suspend();
    }
    return '';
}

sub endif {
    my $self = shift;
    die "Incorrect use of endif ssi directive: no preceeding 'if'." unless $self->_in_if();
    $self->_leaving_if();
#    $self->_resume() if $self->_suspended();
    return '';
}

#
# if we're called like this, it means that we're to handle a CGI request ourselves.
# that means that we're to open the file and process the content, sending it to STDOUT
# along with a standard HTTP content header
#
unless(caller) {
	goto &handler;
}

sub handler {
	eval "use CGI qw(:standard);";
	print header();

	unless(UNIVERSAL::isa(tied(*STDOUT),'CGI::SSI')) {
		tie *STDOUT, 'CGI::SSI', filehandle => 'main::STDOUT';
	}

	my $filename = "$ENV{DOCUMENT_ROOT}$ENV{REQUEST_URI}";
	if(-f $filename) {
		open my $fh, '<', $filename or die "Failed to open file ($filename): $!";
		print <$fh>;
	} else {
		print "Failed to find file ($filename).";
	}

	exit;
}

#
# packages for tie()
#

package CGI::SSI::Gmt;

sub TIESCALAR { bless [@_], shift() }
sub FETCH {
    my $self = shift;
    if($self->[-1]->{'_config'}->{'timefmt'}) {
		my @gt = gmtime;
		return Date::Format::strftime($self->[-1]->{'_config'}->{'timefmt'},@gt);
    } else {
		return scalar gmtime;
    }
}

package CGI::SSI::Local;

sub TIESCALAR { bless [@_], shift() }
sub FETCH {
    my $self = shift;
    if($self->[-1]->{'_config'}->{'timefmt'}) {
		my @lt = localtime;
		return Date::Format::strftime($self->[-1]->{'_config'}->{'timefmt'},@lt);
    } else {
		return scalar localtime;
    }
}

package CGI::SSI::LMOD;

sub TIESCALAR { bless [@_], shift() }
sub FETCH {
    my $self = shift;
	return $self->[-1]->flastmod('file', $ENV{'SCRIPT_FILENAME'} || $ENV{'PATH_TRANSLATED'} || '');
}

1;
__END__


=head1 NAME

 CGI::SSI - Use SSI from CGI scripts

=head1 SYNOPSIS

 # autotie STDOUT or any other open filehandle

   use CGI::SSI (autotie => 'STDOUT');

   print $shtml; # browser sees resulting HTML

 # or tie it yourself to any open filehandle

   use CGI::SSI;

   open(FILE,'+>'.$html_file) or die $!;
   $ssi = tie(*FILE, 'CGI::SSI', filehandle => 'FILE');
   print FILE $shtml; # HTML arrives in the file

 # or use the object-oriented interface

   use CGI::SSI;

   $ssi = CGI::SSI->new();

   $ssi->if('"$varname" =~ /^foo/');
      $html .= $ssi->process($shtml);
   $ssi->else();
      $html .= $ssi->include(file => $filename);
   $ssi->endif();

   print $ssi->exec(cgi => $url);
   print $ssi->flastmod(file => $filename);

 #
 # or roll your own favorite flavor of SSI
 #

   package CGI::SSI::MySSI;
   use CGI::SSI;
   @CGI::SSI::MySSI::ISA = qw(CGI::SSI);

   sub include {
      my($self,$type,$file_or_url) = @_; 
      # my idea of include goes something like this...
      return $html;
   }
   1;
   __END__

 #
 # or use .htaccess to include all files in a dir
 #

   # in .htaccess
   Action cgi-ssi /cgi-bin/ssi/process.cgi
   <FilesMatch "\.shtml">
      SetHandler cgi-ssi
   </FilesMatch>
   
   # in /cgi-bin/ssi/process.cgi
   #!/usr/local/bin/perl 
   use CGI::SSI;
   CGI::SSI->handler();
   __END__

=head1 DESCRIPTION

CGI::SSI is meant to be used as an easy way to filter shtml 
through CGI scripts in a loose imitation of Apache's mod_include. 
If you're using Apache, you may want to use either mod_include or 
the Apache::SSI module instead of CGI::SSI. Limitations in a CGI 
script's knowledge of how the server behaves make some SSI
directives impossible to imitate from a CGI script.

Most of the time, you'll simply want to filter shtml through STDOUT 
or some other open filehandle. C<autotie> is available for STDOUT, 
but in general, you'll want to tie other filehandles yourself:

    $ssi = tie(*FH, 'CGI::SSI', filehandle => 'FH');
    print FH $shtml;

Note that you'll need to pass the name of the filehandle to C<tie()> as 
a named parameter. Other named parameters are possible, as detailed 
below. These parameters are the same as those passed to the C<new()> 
method. However, C<new()> will not tie a filehandle for you.

CGI::SSI has it's own flavor of SSI. Test expressions are Perlish. 
You may create and use multiple CGI::SSI objects; they will not 
step on each others' variables.

Object-Oriented methods use the same general format so as to imitate 
SSI directives:

    <!--#include virtual="/foo/bar.footer" -->

  would be

    $ssi->include(virtual => '/foo/bar.footer');

likewise,

    <!--#exec cgi="/cgi-bin/foo.cgi" -->

  would be

    $ssi->exec(cgi => '/cgi-bin/foo.cgi');

Usually, if there's no chance for ambiguity, the first argument may 
be left out:

    <!--#echo var="var_name" -->

  could be either

    $ssi->echo(var => 'var_name');

  or

    $ssi->echo('var_name');

Likewise,

    $ssi->set(var => $varname, value => $value)

  is the same as 

    $ssi->set($varname => $value)

=over 4

=item $ssi->new([%args])

Creates a new CGI::SSI object. The following are valid (optional) arguments: 

 DOCUMENT_URI    => $doc_uri,
 DOCUMENT_NAME   => $doc_name,
 DOCUMENT_ROOT   => $doc_root,
 errmsg          => $oops,
 sizefmt         => ('bytes' || 'abbrev'),
 timefmt         => $time_fmt,
 MAX_RECURSIONS  => $default_100, # when to stop infinite loops w/ error msg
 COOKIE_JAR      => HTTP::Cookies->new,

=item $ssi->config($type, $arg)

$type is either 'sizefmt', 'timefmt', or 'errmsg'. $arg is similar to 
those of the SSI C<spec>, referenced below.

=item $ssi->set($varname => $value)

Sets variables internal to the CGI::SSI object. (Not to be confused 
with the normal variables your script uses!) These variables may be used 
in test expressions, and retreived using $ssi->echo($varname). These
variables also will not be available in external, included resources.

=item $ssi->echo($varname)

Returns the value of the variable named $varname. Such variables may 
be set manually using the C<set()> method. There are also several built-in 
variables:

 DOCUMENT_URI  - the URI of this document
 DOCUMENT_NAME - the name of the current document
 DATE_GMT      - the same as 'gmtime'
 DATE_LOCAL    - the same as 'localtime'
 LAST_MODIFIED - the last time this script was modified

=item $ssi->exec($type, $arg)

$type is either 'cmd' or 'cgi'. $arg is similar to the SSI C<spec> 
(see below).

=item $ssi->include($type, $arg)

Similar to C<exec>, but C<virtual> and C<file> are the two valid types.
SSI variables will not be available outside of your CGI::SSI object, 
regardless of whether the virtual resource is on the local system or
a remote system.

=item $ssi->flastmod($type, $filename)

Similar to C<include>.

=item $ssi->fsize($type, $filename)

Same as C<flastmod>.

=item $ssi->printenv

Returns the environment similar to Apache's mod_include.

=item $ssi->cookie_jar([$jar])

Returns the currently-used HTTP::Cookies object. You may optionally
pass in a new HTTP::Cookies object. The jar is used for web requests
in exec cgi and include virtual directives.

=back

=head2 FLOW-CONTROL METHODS

The following methods may be used to test expressions. During a C<block> 
where the test $expr is false, nothing will be returned (or printed, 
if tied).

=over 4

=item $ssi->if($expr)

The expr can be anything Perl, but care should be taken. This causes 
problems:

 $ssi->set(varname => "foo");
 <!--#if expr="'\$varname' =~ /^foo$/" -->ok<!--#endif -->

The $varname is expanded as you would expect. (We escape it so as to use 
the C<$varname> within the CGI::SSI object, instead of that within our 
progam.) But the C<$/> inside the regex is also expanded. This is fixed 
by escaping the C<$>:

 <!--#if expr="'\$varname' =~ /^value\$/" -->ok<!--#endif -->

The expressions used in if and elif tags/calls are tricky due to
the number of escapes required. In some cases, you'll need to 
write C<\\\\> to mean C<\>. 

=item $ssi->elif($expr)

=item $ssi->else

=item $ssi->endif


=back

=head1 SEE ALSO

C<Apache::SSI> and the SSI C<spec> at
http://www.apache.org/docs/mod/mod_include.html

=head1 AUTHOR

(c) 2000-2005 James Tolley <james@bitperfect.com> All Rights Reserved.

This is free software. You may copy and/or modify it under
the same terms as perl itself.

=head1 CREDITS

Many Thanks to Corey Wilson and Fitz Elliot for bug reports and fixes.
