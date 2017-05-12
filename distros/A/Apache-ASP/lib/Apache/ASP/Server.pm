
package Apache::ASP::Server;
use strict;
use vars qw($OLESupport);

sub new {
    bless {asp => $_[0]};
}

sub CreateObject {
    my($self, $name) = @_;
    my $asp = $self->{asp};

    # dynamically load OLE at request time, especially since
    # at server startup, this seems to fail with "start_mutex" error
    #
    # no reason to preload this unix style when module loads
    # because in win32, threaded model does not need this prefork 
    # parent httpd compilation
    #
    unless(defined $OLESupport) {
	eval 'use Win32::OLE';
	if($@) {
	    $OLESupport = 0;
	} else {
	    $OLESupport = 1;
	}
    }

    unless($OLESupport) {
	die "OLE-active objects not supported for this platform, ".
	    "try installing Win32::OLE";
    }

    unless($name) {
	die "no object to create";
    }

    Win32::OLE->new($name);
}

sub Execute {
    my $self = shift;
    $self->{asp}{Response}->Include(@_);
}

sub File {
    shift->{asp}{filename};
}

sub Transfer {
    my $self = shift;

    my $file = shift;
    
    # find the file we are about to execute, and alias $0 to it
    my $file_found;
    if(ref($file)) {
	if($file->{File}) {
	    $file_found = $self->{asp}->SearchDirs($file->{File});
	}
    } else {
	$file_found = $self->{asp}->SearchDirs($file);
    }
    my $file_final = defined($file_found) ? $file_found : $0;
    
    local *0 = \$file_final;
    $self->{asp}{Response}->Include($file, @_);
    $self->{asp}{Response}->End;
}

# shamelessly ripped off from CGI.pm, by Lincoln D. Stein.
sub URLEncode {
    my $toencode = $_[1];
    $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
    $toencode;
}

sub HTMLDecode {
    my($self, $decode) = @_;
    
    $decode=~s/&gt;/>/sg;
    $decode=~s/&lt;/</sg;
    $decode=~s/&#39;/'/sg;
    $decode=~s/&quot;/\"/sg;
    $decode=~s/&amp;/\&/sg;
    
    $decode;
}

sub HTMLEncode {
    my($self, $toencode) = @_;
    return '' unless defined $toencode;

    my $data_ref;
    if(ref $toencode) {
	$data_ref = $toencode;
    } else {
	$data_ref = \$toencode;
    }

    $$data_ref =~ s/&/&amp;/sg;
    $$data_ref =~ s/\"/&quot;/sg;
    $$data_ref =~ s/\'/&#39;/sg;
    $$data_ref =~ s/>/&gt;/sg;
    $$data_ref =~ s/</&lt;/sg;

    ref($toencode) ? $data_ref : $$data_ref;
}

sub RegisterCleanup {
    my($self, $code) = @_;
    if(ref($code) =~ /^CODE/) {
	$self->{asp}{dbg} && $self->{asp}->Debug("RegisterCleanup() called", caller());
	push(@{$self->{asp}{cleanup}}, $code);
    } else {
	$self->{asp}->Error("$code need to be a perl sub reference, see README");
    }
}

sub MapInclude {
    my($self, $file) = @_;
    $self->{asp}->SearchDirs($file);
}

sub MapPath {
    my($self, $path) = @_;
    my $subr = $self->{asp}{r}->lookup_uri($path);
    $subr ? $subr->filename : undef;
}

*SendMail = *Mail;
sub Mail {
    shift->{asp}->SendMail(@_);
}

sub URL {
    my($self, $url, $params) = @_;
    $params ||= {};
    
    if($url =~ s/\?(.*)$//is) {
        my $old_params = $self->{asp}{Request}->ParseParams($1);
	$old_params ||= {};
        $params = { %$old_params, %$params };
    }

    my $asp = $self->{asp};
    if($asp->{session_url} && $asp->{session_id} && ! $asp->{session_cookie}) {
	my $match = $asp->{session_url_match};
	if(
	   # if we have match expression, try it
	   ($match && $url =~ /$match/)
	   # then if server path, check matches cookie space 
	   || ($url =~ m|^/| and $url =~ m|^$asp->{cookie_path}|)
	   # then do all local paths, matching NOT some URI PROTO
	   || ($url !~ m|^[^\?\/]+?:|)
	  ) 
	  {
	      # this should overwrite an incorrectly passed in data
	      $params->{$Apache::ASP::SessionCookieName} = $asp->{session_id};
	  }
    }

    my($k,$v, @query);

    # changed to use sort so this function outputs the same URL every time
    for my $k ( sort keys %$params ) {
	my $v = $params->{$k};
	# inline the URLEncode function for speed
	$k =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/egs;
	my @values = (ref($v) and ref($v) eq 'ARRAY') ? @$v : ($v);
	for my $value ( @values ) {
	    $value =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/egs;
	    push(@query, $k.'='.$value);
	}
    }
    if(@query) {
	$url .= '?'.join('&', @query);
    }

    $url;
}

sub XSLT {
    my($self, $xsl_data, $xml_data) = @_;
    $self->{asp}->XSLT($xsl_data, $xml_data);
}

sub Config {
    shift->{asp}->config(@_);
}

1;
