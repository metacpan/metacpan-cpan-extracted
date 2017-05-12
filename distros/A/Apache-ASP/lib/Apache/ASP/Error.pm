
package Apache::ASP;

sub ProcessErrors {
    my $self = shift;
    my $r = $self->{r};
    my $status;

    # just to make sure we have everything we need for the errors templates
    $self->InitPackageGlobals;
    
    if($self->{dbg} >= 2) {
	$self->PrettyError();
	$status = 200;
    } else {
	if($self->Response->{header_done}) {
	    $self->{r}->print("<!-- Error -->");
	}
	
	# debug of 2+ and mail_errors_to are mutually exclusive,
	# since debugging 2+ is for development, and you don't need to 
	# be emailed the error, if its right in your browser
	$self->{mail_alert_to}  = &config($self,'MailAlertTo') || 0;
	$self->{mail_errors_to} = &config($self,'MailErrorsTo') || 0;
	$self->{mail_errors_to} && $self->MailErrors();
	$self->{mail_alert_to} && $self->MailAlert();
	
	$status = 500;
    }
}

sub PrettyError {
    my($self) = @_;
    my $response = $self->{Response};

    my $out = $response->{out};
    $response->{ContentType} = 'text/html';
    $$out = $self->PrettyErrorHelper();
    $response->Flush();

    1;
}

sub PrettyErrorHelper {
    my $self = shift;

    my $response_buffer = $self->{Response}{out};
    $self->{Response}->Clear();
    my $errors_out = '';
    my @eval_error_lines = ();
    if($self->{errors_output}[0]) {
	my($url, $file);
	$errors_out = join("\n<li> ", '', map { $self->Escape($_) } @{$self->{errors_output}});
	# link in the line number to the compiled program
	$self->Debug("errors out $errors_out");
	if($errors_out =~
	   s|\s+at\s+(.*?)\s+line\s+(\d+)|
	   {
	    my($file, $line_no) = ($1, $2);
            if($file =~ /\)/) {
              " at $file line $line_no";
            } else {
	      $url = $self->{Server}->URLEncode($file.' '.$line_no);
	      " at $file <a href=#$url>line $line_no</a>";
            }
	   }
	   |exs
	  )
	  {
	      push(@eval_error_lines, $url);	      
	  }
    }

    my $out = <<OUT;
<tt>
<b><u>Errors Output</u></b>
<ol>
$errors_out
</ol>

<b><u>Debug Output</u></b>
<ol>
@{[join("\n<li> ", '', map { $_ } @{$self->{debugs_output}}) ]}
</ol>
</tt>
<pre>
OUT
    ;

    # could be looking at a compilation error, then set the script to what
    # we were compiling (maybe global.asa), else its our real script
    # with probably a runtime error
    my $script;     
    if($self->{compile_error}) {    
	$script = ${$self->{compile_eval}};
    }
    
    if($$response_buffer) {
	my $length = &config($self, 'DebugBufferLength') || 100;
	$out .= "<b><u>Last $length Bytes of Buffered Output</u></b>\n\n";
	$out .= $self->Escape(substr($$response_buffer, -1 * $length));
	$out .= "\n\n";
    }

    my $error_desc;
    if($script) {
	$error_desc = "Compiled Data with Error";
    } else {
	$error_desc = "ASP to Perl Script";
	my $run_perl_script = $self->{run_perl_script};
	$script = $run_perl_script ? $$run_perl_script : '';
    }
    $out .= "<b><u>$error_desc</u></b><a name=1>&nbsp;</a>\n\n";

    my($file_context, $lineno) = ('', 0);
    for(split(/\n/, $script)) {
	my($lineprint, $lineurl,$frag);
	if ($_ =~ /^#\s*line (\d+) (.+)$/){
	    $lineno = $1;
	    $file_context = $2;
	    $lineurl = '  -';
	} elsif (($lineno == 0)) {
	    $lineurl = '  -';
	} else {
	    $frag = $self->{Server}->URLEncode($file_context.' '.$lineno);
	    $lineurl = "<a name=$frag>".sprintf('%3d', $lineno)."</a>";
	    $lineno++;
	}
	$frag ||= '';
	grep($frag eq $_, @eval_error_lines) && 
	  ($lineurl = "<b><font color=red>$lineurl</font></b>");
	unless(&config($self, 'CommandLine')) {
	    $_ = $self->Escape($_);
	}

	$out .= "$lineurl: $_\n";
    }

    $out .= <<OUT;

</pre>
<hr width=30% size=1>\n<font size=-1>
<i> 
An error has occured with the Apache::ASP script just run. 
If you are the developer working on this script, and cannot work 
through this problem, please try researching it at the 
<a href=http://www.apache-asp.org/>Apache::ASP web site</a>,
specifically the <a href=http://www.apache-asp.org/faq.html>FAQ section</a>.
Failing that, check out your 
<a href=http://www.apache-asp.org/support.html>support options</a>, and 
if necessary include this debug output with any query. 

OUT
  ;

    $out;
}

sub MailErrors {
    my $self = shift;
    
    # email during register cleanup so the user doesn't have 
    # to wait, and possible cancel the mail by pressing "STOP"
    $self->Log("registering error mail to $self->{mail_errors_to} for cleanup phase");
    my $body_ref;
    eval {
	# there was a "use strict" + warn error while compiling this template
	local $^W = 0;
	$body_ref = $self->Response->TrapInclude('Share::CORE/MailErrors.inc', 
						 COMPILE_ERROR => $self->PrettyErrorHelper
						);
    };
    if($@) {
	$self->Error("error creating error mail in MailErrors(): $@");
	return;
    }

    my($subject,$body);
    if($$body_ref =~ /^\s+Subject:\s*(.*?)\s*\n\s*(.*)$/is) {
	($subject,$body) = ($1,$2);
    } else {
	($subject,$body) = ('Apache::ASP::Error', $$body_ref);
    }

    $self->{Server}->RegisterCleanup
      ( 
       sub { 
	   for(1..3) {
	       my $success = 
		 $self->SendMail
		   ({
		     To => $self->{mail_errors_to},
		     From => &config($self, 'MailFrom') || $self->{mail_errors_to},
		     Subject => $subject,
		     Body => $body,
		     'Content-Type' => 'text/html',
		    });
	       if($success) {
		   last;
	       } else {
		   $self->Error("can't send errors mail to $self->{mail_errors_to}");
	       }
	   }
       });
}    

sub MailAlert {
    my $self = shift;

    unless($self->{mail_alert_period}) {
	$self->{mail_alert_period} = &config($self, 'MailAlertPeriod', undef, 20);
    }
    
    # if we have the internal database defined, check last time the alert was
    # sent, and if the alert period is up, send again
    if(defined $self->{Internal}) {
	my $time = time;
	if(defined $self->{Internal}{mail_alert_time}) {
	    my $alert_in = $self->{Internal}{mail_alert_time} + $self->{mail_alert_period} * 60 - $time;
	    if($alert_in <= 0) {
		$self->{Internal}{mail_alert_time} = $time;
	    } else {
		# not time to send an alert again
		$self->Debug("will alert again in $alert_in seconds");
		return 1;
	    }
	} else {
	    $self->{Internal}{mail_alert_time} = $time;
	}
    } else {
	$self->Log("mail alerts will be sent every time.  turn NoState off so that ".
		   "alerts can be sent only every $self->{mail_alert_period} minutes");
    }

    my $host = '';
    if($self->LoadModules('MailAlert', 'Net::Domain')) {
	$host = Net::Domain::hostname();	
    }
    
    # email during register cleanup so the user doesn't have 
    # to wait, and possible cancel the mail by pressing "STOP"
    $self->Log("registering alert mail to $self->{mail_alert_to} for cleanup phase");

    $self->{Server}->RegisterCleanup
      ( 
       sub { 
	   for(1..3) {
	       my $success = 
		 $self->SendMail({
				  To => $self->{mail_alert_to},
				  From => &config($self, 'MailFrom', undef, $self->{mail_alert_to}),
				  Subject => join('-', 'ASP-ALERT', $host), 
				  Body => "$self->{global}-$ENV{SCRIPT_NAME}",				 
				 });
	       
	       if($success) {
		   last;
	       } else {
		   $self->Error("can't send alert mail to $self->{mail_alert_to}");
	       }
	   }
       });
}

1;
