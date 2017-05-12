
package Apache::ASP::Response;

use Apache::ASP::Collection;

use strict;
no strict qw(refs);
use vars qw(@ISA @Members %LinkTags $TextHTMLRegexp);
@ISA = qw(Apache::ASP::Collection);
use Carp qw(confess);
use Data::Dumper qw(DumperX);
use bytes;

@Members = qw( Buffer Clean ContentType Expires ExpiresAbsolute Status );

# used for session id auto parsing
%LinkTags = (
	     'a' => 'href',
	     'area' => 'href',
	     'form' => 'action',
	     'frame' => 'src',
	     'iframe' => 'src',
	     'img' => 'src',
	     'input' => 'src',
	     'link' => 'href',
	    );

$TextHTMLRegexp = '^text/html(;|$)';

sub new {
    my $asp = shift;

    my $r = $asp->{'r'};
    my $out = '';

    my $self = bless 
      {
       asp => $asp,
       out => \$out,
       # internal extension allowing various scripts like Session_OnStart
       # to end the same response
       #       Ended => 0, 
       CacheControl => 'private',
       CH => &config($asp, 'CgiHeaders') || 0,
       #       Charset => undef,
       Clean => &config($asp, 'Clean') || 0,
       Cookies => bless({}, 'Apache::ASP::Collection'),
       ContentType => 'text/html',
       'Debug' => $asp->{dbg},
       FormFill => &config($asp, 'FormFill'),
       IsClientConnected => 1,
       #       PICS => undef,
       #       Status => 200,
       #       header_buffer => '',
       #       header_done => 0,
       Buffer => &config($asp, 'BufferingOn', undef, 1),
       BinaryRef => \$out,
       CompressGzip => ($asp->{compressgzip} and ($asp->{headers_in}->get('Accept-Encoding') =~ /gzip/io)) ? 1 : 0,
       r => $r,
       headers_out => scalar($r->headers_out()),
      };

    &IsClientConnected($self); # update now

    $self;
}

sub DeprecatedMemberAccess {
    my($self, $member, $value) = @_;
    $self->{asp}->Out(
		      "\$Response->$member() deprecated.  Please access member ".
		      "directly with \$Response->{$member} notation"
		     );
    $self->{$member} = $value;
}

# defined the deprecated subs now, so we can loose the AUTOLOAD method
# the AUTOLOAD was forcing us to keep the DESTROY around
for my $member ( @Members ) {
    my $subdef = "sub $member { shift->DeprecatedMemberAccess('$member', shift); }";
    eval $subdef;
    if($@) {
	die("error defining Apache::ASP::Response sub -- $subdef -- $@");
    }
}

sub AddHeader { 
    my($self, $name, $value) = @_;   

    my $lc_name = lc($name);

    if($lc_name eq 'set-cookie') {
	$self->{r}->err_headers_out->add($name, $value);
    } else {
	# if we have a member API for this header, set that value instead 
	# to avoid duplicate headers from being sent out
	if($lc_name eq 'content-type') {
	    $self->{ContentType} = $value;
	} elsif($lc_name eq 'cache-control') {
	    $self->{CacheControl} = $value;
	} elsif($lc_name eq 'expires') {
	    $self->{ExpiresAbsolute} = $value;
	} else {
	    $self->{headers_out}->set($name, $value);
	}
    }
}   

sub AppendToLog { shift->{asp}->Log(@_); }
sub Debug { 
    my $self = shift;
    $self->{Debug} && $self->{asp}->Out("[$self->{asp}{basename}]", @_);
};

sub BinaryWrite {
    $_[0]->Flush();
    $_[0]->{asp}{dbg} && $_[0]->{asp}->Debug("binary write of ".length($_[1])." bytes");
    &Write;
}

sub Clear { my $out = shift->{out}; $$out = ''; }

sub Cookies {
    my($self, $name, $key, $value) = @_;
    if(defined($name) && defined($key) && defined($value)) {
	$self->{Cookies}{$name}{$key} = $value;
    } elsif(defined($name) && defined($key)) {
	# we are assigning cookie with name the value of key
	if(ref $key) {
	    # if a hash, set the values in it to the keys values
	    # we don't just assign the ref directly since for PerlScript 
	    # compatibility
	    while(my($k, $v) = each %{$key}) {
		$self->{Cookies}{$name}{$k} = $v;
	    }
	} else {
	    $self->{Cookies}{$name}{Value} = $key;	    
	}
    } elsif(defined($name)) {
	# if the cookie was just stored as the name value, then we will
	# will convert it into its hash form now, so we can store other
	# things.  We will probably be storing other things now, since
	# we are referencing the cookie directly
	my $cookie = $self->{Cookies}{$name} || {};
	$cookie = ref($cookie) ? $cookie : { Value => $cookie };
	$self->{Cookies}{$name} = bless $cookie, 'Apache::ASP::Collection';	
    } else {
	$self->{Cookies};
    }
}

sub End {
    my $self = shift;
    # by not calling EndSoft(), but letting it be called naturally after
    # Execute() in hander(), we allow more natural Buffer flushing to occur
    # even if we are in a situation where Flush() has been made null like
    # in an XMLSubs or cached or trapped include
#    &EndSoft($self);
    eval { goto APACHE_ASP_EXECUTE_END; };
}

sub EndSoft {
    my $self = shift;
    return if $self->{Ended}++;
    &Flush($self);
}

sub Flush {
    my $self = shift;
    my $asp = $self->{asp};
    my $out = $self->{out};
    local $| = 1;

    # Script_OnFlush event handler
    $asp->{GlobalASA}{'exists'} &&
      $asp->{GlobalASA}->ScriptOnFlush();

    # XSLT Processing, check for errors so PrettyError() can call Flush()
    if($asp->{xslt} && ! $asp->{errs}) {
	$asp->{dbg} && $asp->Debug("pre xslt $out length: ".length($$out));
	$self->FlushXSLT;
	$asp->{dbg} && $asp->Debug("post xslt $out length: ".length($$out));
	return if $asp->{errs};
    }

    # FormFill
    if ($self->{FormFill} && ! $asp->{errs}) {
	$self->FormFill;
	return if $asp->{errs};
    }

    if($self->{Clean} and $self->{ContentType} =~ /$TextHTMLRegexp/o) {
	# by checking defined, we just check once
	unless(defined $Apache::ASP::CleanSupport) {
	    eval 'use HTML::Clean';
	    if($@) {
		$self->{asp}->Log("Error loading module HTML::Clean with Clean set to $self->{Clean}. ".
				  "Make user you have HTML::Clean installed properly. Error: $@");
		$Apache::ASP::CleanSupport = 0;
	    } else {
		$Apache::ASP::CleanSupport = 1;
	    }
	}

	# if we can't clean, we simply ignore	
	if($Apache::ASP::CleanSupport) {
	    my $h = HTML::Clean->new($out, $self->{Clean});
	    if($h) {
		$h->strip();
	    } else {
		$self->{asp}->Error("clean error: $! $@");
	    }
	}
    }

    ## Session query auto parsing for cookieless sessions
    if(
       $asp->{Session} 
       and ! $asp->{session_cookie} 
       and $asp->{session_url_parse} 
       and ($self->{ContentType} =~ /^text/i)
      ) 
      {
	  $self->SessionQueryParse();
      }

    if($self->{Ended}) {
	# log total request time just once at the end
	# and append to html like Cocoon, per user request
	my $total_time = sprintf('%7.5f', ( eval { &Time::HiRes::time() } || time() ) - $asp->{start_time});
	$asp->{dbg} && $asp->Debug("page executed in $total_time seconds");
	$asp->{total_time} = $total_time;

	if(&config($asp, 'TimeHiRes')) {
	    if($self->{ContentType} =~ /$TextHTMLRegexp/o) {
		if(&config($asp, 'Debug')) {
		    $$out .= "\n<!-- Apache::ASP v".$Apache::ASP::VERSION." served page in $total_time seconds -->";
		}
	    }
	}
    }

    # HEADERS AFTER CLEAN, so content-length would be calculated correctly
    # if this is the first writing from the page, flush a newline, to 
    # get the headers out properly
    if(! $self->{header_done}) {
	# if no headers and the script has ended, we know that the 
	# the script has not been flushed yet, which would at least
	# occur with buffering on
	if($self->{Ended}) {
	    # compression & content-length settings will kill filters
	    # after Apache::ASP
	    if(! $asp->{filter}) {
		# gzip the buffer if CompressGzip && browser accepts it &&
		# the script is flushed once
		if($self->{CompressGzip} && $asp->LoadModule('Gzip','Compress::Zlib')) {
		    $self->{headers_out}->set('Content-Encoding','gzip');
		    $$out = Compress::Zlib::memGzip($out);
		}

		$self->{headers_out}->set('Content-Length', length($$out));
	    }
	}
	
	&SendHeaders($self);
    }

    if($asp->{filter}) {
	print STDOUT $$out;
    } else {
	# just in case IsClientConnected is set incorrectly, still try to print
	# the worst thing is some extra error messages in the error_log ...
	# there have been spurious error reported with the IsClientConnected
	# code since it was introduced, and this will limit the errors ( if any are left )
	# to the users explicitly using this functionality, --jc 11/29/2001
	#
#	if($self->{IsClientConnected}) {
	    if(! defined $self->{Status} or ($self->{Status} >= 200 and $self->{Status} < 400)) {
		$self->{r}->print($$out);
	    }
#	}
    }

    # update after flushes only, expensive call
    $self->{Ended} || &IsClientConnected($self);

    # supposedly this is more efficient than undeffing, since
    # the string does not let go of its allocated memory buffer
    $$out = ''; 

    1;
}

sub FormFill {
    my $self = shift;
    my $asp = $self->{asp};

    $asp->{dbg} && $asp->Debug("form fill begin");
    $asp->LoadModule('FormFill', 'HTML::FillInForm') || return;
    my $ref = $self->{BinaryRef};

    $$ref =~ s/(\<form[^\>]*\>.*?\<\/form\>)/
	     {
		 my $form = $1;
		 my $start_length = $asp->{dbg} ? length($form) : undef;
		 eval {
		     my $fif = HTML::FillInForm->new();
		     $form = $fif->fill(
					scalarref => \$form,
					fdat =>	$asp->{Request}{Form},
					);
		 };
		 if($@) {
		     $asp->CompileErrorThrow($form, "form fill failed: $@");
		 } else {
		     $asp->{dbg} && 
			 $asp->Debug("form fill for form of start length $start_length ".
				     "end length ".length($form));
		 }
		 $form;
	     }		
	     /iexsg;

    1;
}

sub FlushXSLT {
    my $self = shift;
    my $asp = $self->{asp};
    my $xml_out = $self->{BinaryRef};
    return unless length($$xml_out); # could happen after a redirect

    $asp->{xslt_match} = &config($asp, 'XSLTMatch') || '^.';
    return unless ($asp->{filename} =~ /$asp->{xslt_match}/);

    ## XSLT FETCH & CACHE
    $asp->{dbg} && $asp->Debug("xslt processing with $asp->{xslt}");
    my $xsl_dataref = $self->TrapInclude($asp->{xslt});
    $asp->{dbg} && $asp->Debug(length($$xsl_dataref)." bytes in XSL $xsl_dataref");
    return if($asp->{errs});

    ## XSLT XML RENDER
    eval {
	my $xslt_data = $asp->XSLT($xsl_dataref, $xml_out);
	$asp->{dbg} && $asp->Debug("xml_out $xml_out length ".length($$xml_out)." set to $xslt_data length ".
				   length($$xslt_data));
	${$self->{BinaryRef}} = $$xslt_data;
    };
    if($@) {
	$@ =~ s/^\s*//s;
	$asp->Error("XSLT/XML processing error: $@");
	return;
    }

    1;
}

sub IsClientConnected {
    my $self = shift;
    return(0) if ! $self->{IsClientConnected};

    # must init Request first for the aborted test to be meaningful.
    # it seems that under mod_perl 1.25, apache 1.20 on a fast local network,
    # if $r->connection->aborted is checked on a file upload before $Request 
    # is initialized, then aborted will return true, even under normal use.  
    # This causes a file upload script to not render any output.  It may be that this
    # check was done too fast for apache, where it might have still been setting
    # up the upload, so not to check the outbound client connection yet
    # 
    unless($self->{asp}{Request}) {
	$self->{asp}->Out("need to init Request object before running Response->IsClientConnected");
	return 1;
    }

    # IsClientConnected ?  Might already be disconnected for busy site, if
    # a user hits stop/reload
    my $conn = $self->{r}->connection;
    my $is_connected = $conn->aborted ? 0 : 1;

    if($is_connected) {
	my $fileno = eval { $conn->fileno };
	if(defined $fileno) {
	    #    sleep 3;
	    #	    my $s = IO::Select->new($fileno);
	    #	    $is_connected = $s->can_read(0) ? 0 : 1;

	    # much faster than IO::Select interface() which calls
	    # a few perl OO methods to construct & then can_read()
	    my $bits = '';
	    vec($bits, $fileno, 1) = 1;
	    $is_connected = select($bits, undef, undef, 0) > 0 ? 0 : 1;
	    if(! $is_connected) {
		$self->{asp}{dbg} && $self->{asp}->Debug("client is no longer connected, detected via Apache->request->connetion->fileno");
	    }
	}
    }

    $self->{IsClientConnected} = $is_connected;
    if(! $is_connected) {
	$self->{asp}{dbg} && $self->{asp}->Debug("client is no longer connected");
    }

    $is_connected;
}

# use the apache internal redirect?  Thought that would be counter
# to portability, but is still something to consider
sub Redirect {
    my($self, $location) = @_;
    my $asp = $self->{asp};
    my $r = $self->{r};

    $asp->{dbg} && $asp->Debug('redirect called', {location=>$location});
    
    # X: maybe this instead, so no session-id on normal redirects?
    #    if($asp->{Session}) {
    #	$location = $asp->{Server}->URL($location);

    if($asp->{Session} and $asp->{session_url_parse}) {
	$location = &SessionQueryParseURL($self, $location);
	$asp->{dbg} && $asp->Debug("new location after session query parsing $location");
    }

    $r->headers_out->set('Location', $location);
    $self->{Status} = 302;
    $r->status(302);

    # Always SendHeaders() immediately for a Redirect() ... only in a SoftRedirect
    # will execution continue.  Since we call SendHeaders here, instead of 
    # Flush() a Redirect() will still work even in a XMLSubs call where Flush is
    # trapped to Null()
    &SendHeaders($self);

    # if we have soft redirects, keep processing page after redirect
    if(&config($asp, 'SoftRedirect')) {
	$asp->Debug("redirect is soft, headers already sent");
    } else {
	# do we called End() or EndSoft() here?  As of v 2.33, End() will
	# just jump to the end of Execute(), so if we were in a XMLSubs
	# and called End() after doing a Clear() there would still be 
	# output the gets flushed out from before the XMLSubs, to prevent
	# this we clear the buffer now, and called EndSoft() in this case.
	# Finally we also call End() so we will jump out of the executing code.
	#
	&Clear($self);
	$self->{Ended} = 1; # just marked Ended so future EndSoft() cannot be called
#	&EndSoft($self);
	&End($self);
    }

    1;
}

sub SendHeaders {
    my $self = shift;
    my $r = $self->{r};
    my $asp = $self->{asp};
    my $dbg = $asp->{dbg};
    my $status = $self->{Status};

    return if $self->{header_done};
    $self->{header_done} = 1;

    $dbg && $asp->Debug('building headers');
    $r->status($status) if defined($status);

    # for command line script
    return if &config($asp, 'NoHeaders');

    if(defined $status and $status == 401) {
	$dbg && $asp->Debug("status 401, note basic auth failure realm ".$r->auth_name);

	# we can't send out headers, and let Apache use the 401 error doc
	# But this is fine, once authorization is OK, then the headers
	# will go out correctly, so things like sessions will work fine.
	$r->note_basic_auth_failure;
	return;
    } else {
	$dbg && defined $status && $self->{asp}->Debug("status $status");
    }

    if(defined $self->{Charset}) {
	$r->content_type($self->{ContentType}.'; charset='.$self->{Charset});
    } else {
	$r->content_type($self->{ContentType}); # add content-type
    }

    if(%{$self->{'Cookies'}}) {
	&AddCookieHeaders($self);     # do cookies
    }

    # do the expiration time
    if(defined $self->{Expires}) {
	my $ttl = $self->{Expires};
	$r->headers_out->set('Expires', &Apache::ASP::Date::time2str(time()+$ttl));
	$dbg && $self->{asp}->Debug("expires in $self->{Expires}");
    } elsif(defined $self->{ExpiresAbsolute}) {
	my $date = $self->{ExpiresAbsolute};
	my $time = &Apache::ASP::Date::str2time($date);
	if(defined $time) {
	    $r->headers_out->set('Expires', &Apache::ASP::Date::time2str($time));
	} else {
	    confess("Response->ExpiresAbsolute(): date format $date not accepted");
	}
    }

    # do the Cache-Control header
    $r->headers_out->set('Cache-Control', $self->{CacheControl});
    
    # do PICS header
    defined($self->{PICS}) && $r->headers_out->set('PICS-Label', $self->{PICS});
    
    # don't send headers with filtering, since filter will do this for
    # all the modules once
    # doug sanctioned this one
    unless($r->headers_out->get("Content-type")) {
	# if filtering, we don't send out a header from ASP
	# this means that Filtered scripts can use CGI headers
	# we order the test this way in case Ken comes on
	# board with setting header_out, in which case the test 
	# will fail early       
	if(! $asp->{filter} && (! defined $status or $status >= 200 && $status < 400)) {
	    $dbg && $asp->Debug("sending cgi headers");
	    if(defined $self->{header_buffer}) {
		# we have taken in cgi headers
		$r->send_cgi_header($self->{header_buffer} . "\n");
		$self->{header_buffer} = undef;
	    } else {
		unless($Apache::ASP::ModPerl2) {
		    # don't need this for mod_perl2 it seems from Apache::compat
		    $r->send_http_header();
		}
	    }
	}
    }

    1;
}

# do cookies, try our best to emulate cookie collections
sub AddCookieHeaders {
    my $self = shift;
    my $cookies = $self->{'Cookies'};
    my $dbg = $self->{asp}{dbg};

#    print STDERR Data::Dumper::DumperX($cookies);

    my($cookie_name, $cookie);
    for $cookie_name (sort keys %{$cookies}) {
	# skip key used for session id
	if($Apache::ASP::SessionCookieName eq $cookie_name) {
	    confess("You can't use $cookie_name for a cookie name ".
		    "since it is reserved for session management"
		    );
	}
	
	my($k, $v, @data, $header, %dict, $is_ref, $cookie, $old_k);
	
	$cookie = $cookies->{$cookie_name};
	unless(ref $cookie) {
	    $cookie->{Value} = $cookie;
	} 
	$cookie->{Path} ||= '/';
	
	for $k (sort keys %$cookie) {
	    $v = $cookie->{$k};
	    $old_k = $k;
	    $k = lc $k;
	    
#	    print STDERR "$k ---> $v\n\n";

	    if($k eq 'secure' and $v) {
		$data[4] = 'secure';
	    } elsif($k eq 'domain') {
		$data[3] = "$k=$v";
	    } elsif($k eq 'value') {
		# we set the value later, nothing for now
	    } elsif($k eq 'expires') {
		my $time;
		# only the date form of expires is portable, the 
		# time vals are nice features of this implementation
		if($v =~ /^\-?\d+$/) { 
		    # if expires is a perl time val
		    if($v > time()) { 
			# if greater than time now, it is absolute
			$time = $v;
		    } else {
			# small, relative time, add to time now
			$time = $v + time();
		    }
		} else {
		    # it is a string format, PORTABLE use
		    $time = &Apache::ASP::Date::str2time($v);
		}
		
		my $date = &Apache::ASP::Date::time2str($time);
		$dbg && $self->{asp}->Debug("setting cookie expires", 
					    {from => $v, to=> $date}
					   );
		$v = $date;
		$data[1] = "$k=$v";
	    } elsif($k eq 'path') {
		$data[2] = "$k=$v";
	    } else {
		if(defined($cookie->{Value}) && ! (ref $cookie->{Value})) {
		    # if the cookie value is just a string, its not a dict
		} else {
		    # cookie value is a dict, add to it
		    $cookie->{Value}{$old_k} = $v;
		}			
	    } 
	}
	
	my $server = $self->{asp}{Server}; # for the URLEncode routine
	if(defined($cookie->{Value}) && (! ref $cookie->{Value})) {
	    $cookie->{Value} = $server->URLEncode($cookie->{Value});
	} else {
	    my @dict;
	    for my $k ( sort keys %{$cookie->{Value}} ) {
		my $v = $cookie->{Value}{$k};
		push(@dict, $server->URLEncode($k) . '=' . $server->URLEncode($v));
	    }
	    $cookie->{Value} = join('&', @dict);
	}
	$data[0] = $server->URLEncode($cookie_name) . "=$cookie->{Value}";
	
	# have to clean the data now of undefined values, but
	# keeping the position is important to stick to the Cookie-Spec
	my @cookie;
	for(0..4) {	
	    next unless $data[$_];
	    push(@cookie, $data[$_]);
	}		
	my $cookie_header = join('; ', @cookie);

	$self->{r}->err_headers_out->add('Set-Cookie', $cookie_header);
	$dbg && $self->{asp}->Debug({cookie_header=>$cookie_header});
    }
}

# with the WriteRef vs. Write abstration, direct calls 
# to write might slow a little, but more common static 
# html calls to WriteRef will be saved the HTML copy
sub Write {
    my $self = shift;
    
    my $dataref;
    if(@_ > 1) {
	$, ||= ''; # non-standard use, so init here
	my $data = join($,, @_);
	$dataref = \$data;
    } else {
#	$_[0] ||= '';
	$dataref = defined($_[0]) ? \$_[0] : \'';
    }

    &WriteRef($self, $dataref);

    1;
}

# \'';

*Apache::ASP::WriteRef = *WriteRef;
sub WriteRef {
    my($self, $dataref) = @_;

    # allows us to end a response, but still execute code in event
    # handlers which might have output like Script_OnStart / Script_OnEnd
    return if $self->{Ended};
#    my $content_out = $self->{out};

    if($self->{CH}) {
	# CgiHeaders may change the reference to the dataref, because
	# dataref is a read-only scalar ref of static data, and CgiHeaders
	# may need to change it
	$dataref = $self->CgiHeaders($dataref);
    }

    # add dataref to buffer
    ${$self->{out}} .= $$dataref;
    
    # do we flush now?  not if we are buffering
    if(! $self->{'Buffer'} && ! $self->{'FormFill'}) {
	# we test for whether anything is in the buffer since
	# this way we can keep reading headers before flushing
	# them out
	&Flush($self);
    }

    1;
}
*write = *Write;

# alias printing to the response object
sub TIEHANDLE { $_[1]; }
*PRINT = *Write;
sub PRINTF {
    my($self, $format, @list) = @_;   
    my $output = sprintf($format, @list);
    $self->WriteRef(\$output);
}

sub CgiHeaders {
    my($self, $dataref) = @_;
    my $content_out = $self->{out};

    # work on the headers while the header hasn't been done
    # and while we don't have anything in the buffer yet
    #
    # also added a test for the content type being text/html or
    # 
    if($self->{CH} && ! $self->{header_done} && ! $$content_out 
       && ($self->{ContentType} =~ /$TextHTMLRegexp/o)) 
      {
	  # -1 to catch the null at the end maybe
	  my @headers = split(/\n/, $$dataref, -1); 
	  
	  # first do status line
	  my $status = $headers[0];
	  if($status =~ m|HTTP/\d\.\d\s*(\d*)|o) {
	      $self->{Status} = $1; 
	      shift @headers;
	  }
	  
	  while(@headers) {
	      my $out = shift @headers;
	      next unless $out; # skip the blank that comes after the last newline
	      
	      if($out =~ /^[^\s]+\: /) { # we are a header
		  unless(defined $self->{header_buffer}) {
		      $self->{header_buffer} .= '';
		  }
		  $self->{header_buffer} .= "$out\n";
	      } else {
		  unshift(@headers, $out);
		  last;
	      }
	  }
	  
	  # take remaining non-headers & set the data to them joined back up
	  my $data_left = join("\n", @headers);
	  $dataref = \$data_left;
      }

    $dataref;
}

sub Null {};
sub TrapInclude {
    my($self, $file) = (shift, shift);
    
    my $out = "";
    local $self->{out} = local $self->{BinaryRef} = \$out;
    local $self->{Ended} = 0;
    local *Apache::ASP::Response::Flush = *Null;
    $self->Include($file, @_);

    \$out;
}

sub Include {    
    my $self = shift;
    my $file = shift;
    my $asp = $self->{asp};

    my($cache, $cache_key, $cache_expires, $cache_clear);
    if(ref($file) && ref($file) eq 'HASH') {
	my $data = $file;
	$file = $data->{File} 
	  || $asp->Error("no File key passed to Include(), keys ".join(',', keys %$file));
	$asp->{dbg} && $asp->Debug("file $file from HASH ref in Include()");
	
	if($data->{Cache}) {
	    $cache = 1;
	    $cache_expires = $data->{'Expires'};
	    $cache_clear = $data->{'Clear'};
	    my $file_data = '';
	    if(ref($file)) {
		$file_data = 'INCLUDE SCALAR REF '.$$file;
	    } else {
		my $real_file = $asp->SearchDirs($file);
		$file_data = 'INCLUDE FILE '.(stat($real_file))[9].' //\\ :: '.$real_file.' //\\ :: '.$file;
	    }
	    if($data->{Key}) {
		$cache_key = $file_data .' //\\ :: '.DumperX($data->{Key});
		$asp->{dbg} && $asp->Debug("include cache key length ".length($cache_key)." with extra Key data");
	    } else {
		$asp->{dbg} && $asp->Debug("include cache key length ".length($file_data));
		$cache_key = $file_data;
	    }
	    $cache_key .= ' //\\ COMPILE CHECKSUM :: '.$asp->{compile_checksum};
	    $cache_key .= ' //\\ ARGS :: '.DumperX(@_);
	    if(! $cache_clear) {
		my $rv = $asp->Cache('Response', \$cache_key, undef, $data->{Expires}, $data->{LastModified});
		if($rv) {
		    if(! eval { ($rv->{RV} && $rv->{OUT}) }) {
			$asp->{dbg} && $self->Debug("cache item invalid: $@");
		    } else {
			$asp->{dbg} && $asp->Debug("found include $file output in cache");
			$self->WriteRef($rv->{OUT});
			my $rv_data = $rv->{RV};
			return wantarray ? @$rv_data : $rv_data->[0];
		    }
		}
	    }
	}
    }

    my $_CODE = $asp->CompileInclude($file);
    unless(defined $_CODE) {
	die("error including $file, not compiled: $@");
    }

    $asp->{last_compile_include_data} = $_CODE;
    my $eval = $_CODE->{code};

    # exit early for cached static file
    if(ref $eval eq 'SCALAR') {
       $asp->{dbg} && $asp->Debug("static file data cached, not compiled, length: ".length($$eval));
       $self->WriteRef($eval);
       return;
    }

    $asp->{dbg} && $asp->Debug("executing $eval");    

    my @rc;
    if($cache) {
	my $out = "";
	{
	    local $self->{out} = local $self->{BinaryRef} = \$out;
	    local $self->{Ended} = 0;
	    local *Apache::ASP::Response::Flush = *Null;
	    @rc = eval { &$eval(@_) };
	    $asp->{dbg} && $asp->Debug("caching $file output expires: ".($cache_expires || ''));
	    $asp->Cache('Response', \$cache_key, { RV => [ @rc ], OUT => \$out }, $cache_expires);
	}
	$self->WriteRef(\$out);
    } else {
	@rc = eval { &$eval(@_) };
    }
    if($@) {
	my $code = $_CODE;
	die "error executing code for include $code->{file}: $@; compiled to $code->{perl}";
    }
    $asp->{dbg} && $asp->Debug("done executing include code $eval");

    wantarray ? @rc : $rc[0];
}

sub ErrorDocument {
    my($self, $error_code, $uri) = @_;
    $self->{'r'}->custom_response($error_code, $uri); 
}

sub SessionQueryParse {
    my $self = shift;

    # OPTIMIZE MATCH: a is first in the sort, so this is fairly well optimized, 
    # putting img up at the front doesn't seem to make a different in the speed
    my $tags_grep = join('|', sort keys %LinkTags); 
    my $new_content = ''; # we are going to rebuild this content
    my $content_ref = $self->{out};
    my $asp = $self->{asp};    
    $asp->{dbg} && $asp->Debug("parsing session id into url query strings");

    # update quoted links in script location.href settings too
    # if not quoted, then maybe script expressions
    $$content_ref =~ 
      s/(\<script.*?\>[^\<]*location\.href\s*\=[\"\'])([^\"\']+?)([\"\'])
	/$1.&SessionQueryParseURL($self, $2).$3
	  /isgex;
    
    while(1) {
	# my emacs perl mode doesn't like ${$doc->{content}}
	last unless ($$content_ref =~ s/
		     ^(.*?)               # html head 
		     \<                   # start
		     \s*($tags_grep)\s+  # tag itself
		     ([^>]+)              # descriptors    
		     \>                   # end
		     //isxo
		     );
	
	my($head, $tag, $temp_attribs) = ($1, lc($2), $3);
	my $element = "<$2 $temp_attribs>";	
	my %attribs;
	
	while($temp_attribs =~ s/^\s*([^\s=]+)\s*\=?//so) {
	    my $key = lc $1;
	    my $value;
	    if($temp_attribs =~ s/^\s*\"([^\"]*)\"\s*//so) {
		$value = $1;
	    } elsif ($temp_attribs =~ s/^\s*\'([^\']*)\'\s*//so) {
		# apparently browsers support single quoting values
		$value = $1;
	    } elsif($temp_attribs =~ s/^\s*([^\s]*)\s*//so) {
		# sometimes there are mal-formed URL's
		$value = $1;
		$value =~ s/\"//sgo;
	    }
	    $attribs{$key} = $value;
	}
	
	# GET URL from tag attribs finally
	my $rel_url = $attribs{$LinkTags{$tag}};
#	$asp->Debug($rel_url, $element, \%attribs);
	if(defined $rel_url) {
	    my $new_url = &SessionQueryParseURL($self, $rel_url);
	    # escape all special characters so they are not interpreted
	    if($new_url ne $rel_url) {
		$rel_url =~ s/([\W])/\\$1/sg;
		$element =~ s|($LinkTags{$tag}\s*\=\s*[\"\']?)$rel_url|$1$new_url|isg;
#		$asp->Debug("parsed new element $element");
	    }
	}
	
	$new_content .= $head . $element;
    }
    
#    $asp->Debug($$content_ref);
    $new_content .= $$content_ref;
    $$content_ref = $new_content;
    1;
}

sub SessionQueryParseURL {
    my($self, $rel_url) = @_;
    my $asp = $self->{asp};    
    my $match = $asp->{session_url_parse_match};

    if(
       # if we have match expression, try it
       ($match && $rel_url =~ /$match/)
       # then if server path, check matches cookie space 
       || ($rel_url =~ m|^/| and $rel_url =~ m|^$asp->{cookie_path}|)
       # then do all local paths, matching NOT some URI PROTO
       || ($rel_url !~ m|^[^\?\/]+?:|)
      )
      {
	  my($query, $new_url, $frag);
	  if($rel_url =~ /^([^\?]+)(\?([^\#]*))?(\#.*)?$/) {
              $new_url = $1;
              $query = defined $3 ? $3 : '';
	      $frag = $4;
	  } else {
	      $new_url = $rel_url;
	      $query = '';
	  }

	  # for the split, we do not need to handle other entity references besides &amp;
	  # because &, =, and ; should be the only special characters in the query string
	  # and the only of these characters that are represented by an entity reference
	  # is & as &amp; ... the rest of the special characters that might be encoded 
	  # in a URL should be URI escaped
	  # --jc 2/10/2003
	  my @new_query_parts;
	  map {
	      (! /^$Apache::ASP::SessionCookieName\=/) && push(@new_query_parts, $_);
	  }
	    split(/&amp;|&/, $query);

	  my $new_query = join('&amp;', 
			       @new_query_parts,
			       $Apache::ASP::SessionCookieName.'='.$asp->{session_id}
			      );
	  $new_url .= '?'.$new_query;
	  if($frag) {
	      $new_url .= $frag;
	  }
	  $asp->{dbg} && $asp->Debug("parsed session into $new_url");
	  $new_url;
      } else {
	  $rel_url;
      }
}

*config = *Apache::ASP::config;

1;
