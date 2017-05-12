package Apache::ShowRequest;

use strict;
use vars qw($VERSION);
use Apache::Module ();
use Apache::Constants qw(:satisfy :common :args_how);

$VERSION = '1.02';
sub TRUE  () {1}
sub FALSE () {0}

sub handler {
    my $request = shift;

    my $uri = $request->path_info || "/";
    my %args = $request->args;
    my $headers_in = $request->headers_in;
    while (my($k,$v) = each %args) {
	$headers_in->set($k, $v);
    }
    $request->send_http_header("text/html");

    my $r = $request->lookup_uri($uri);

    my $status = OK;

    print <<EOF;
<html>
<head><title></title></head>
<body>
Running request for $uri
<pre>
EOF

    run_method($r, "post_read_request", TRUE); #1

    run_method($r, "translate_handler", FALSE); #2

    run_method($r, "header_parser", TRUE); #3

    my $satisfy = ($r->satisfies == SATISFY_ANY) ? "Any" : "All";

    print "Access to <b>$uri</b> must Satisfy <b>$satisfy</b> requirements\n";
    print "Authentication/Authorization is ";
    print "not " unless $r->some_auth_required;
    print "required for <b>$uri</b>\n";
   
    if($r->some_auth_required) {
	if(my $requires = $r->requires) {
	    print "Requirements:\n";
	    for my $req (@$requires) {
		print "    require $req->{requirement}\n";
	    }
	}
    }

    run_method($r, "access_checker", TRUE); #4

    run_method($r, "check_user_id", FALSE); #5

    run_method($r, "auth_checker", FALSE);  #6

    run_method($r, "type_checker", FALSE);  #7
    
    run_method($r, "fixer_upper", TRUE);    #8

    invoke_handler($r);                     #9

    run_method($r, "logger", TRUE);         #10

    print "</body></html>";

}

sub run_method {
    my($r, $method, $run_all) = @_;
    my $top_module = Apache::Module->top_module;
    my $say_defined = 0;
    my $format = sub { shift };

    print "\nRequest phase: $method\n";
    for (my $modp = $top_module; $modp; $modp = $modp->next) {
	my $name = $modp->name;
	$name =~ s/\.c$//;
	print_item($name);

	if(my $cv = $modp->$method()) {
	    my $status = $r->$cv();
	    if ($say_defined) {
		print $format->("defined");
	    }
	    else {
		constant_name($status);
	    }
	    print "\n";

	    if ($status != DECLINED && (!$run_all || $status != OK)) {
		$say_defined = 1;
		$format = sub { "<i>@_</i>" };
	    }
	}
	else {
	    print $format->("undef\n");
	}
    } 
    print "\n";

    return $run_all ? OK : DECLINED;
}

sub invoke_handler {
    my $r = shift;
    my $content_type = $r->content_type ? $r->content_type : "text/plain";

    my $handler = $r->handler ? $r->handler : $content_type;

    my $top_module = Apache::Module->top_module;

    print "Request phase: response handler (type: $handler)\n";

    for (my $modp = $top_module; $modp; $modp = $modp->next) {
	next unless $modp->handlers;

	for (my $handp = $modp->handlers; $handp; $handp = $handp->next) {
	    next unless $handp->content_type;

	    my $name = $modp->name;
	    $name =~ s/\.c$//;
	    
	    if ($handler eq $handp->content_type) {
		#direct match
		print_item($name, "defined\n");
                #$handp->handler->($r);
	    }
	    else {
		#wildcard match
		my $type = $handp->content_type;
		next unless $type =~ /\*/;
		my $pat = "\Q$type";
		$pat =~ s/\*/.*/g; 
		if($handler =~ /$pat/) {
		    print_item($name, "defined\n");
		    #$handp->handler->($r);
		}
	    }
	}
    }
}

sub print_item {
    my $name = shift;
    print "   $name ", '.' x (28 - length($name)), @_;
}

sub constant_name { 
    my $status = shift;
    my $bold = ($status != OK) && ($status != DECLINED);
    print "<b>" if $bold;
    print Apache::Constants->name($status);
    print "</b>" if $bold;
}


1;
__END__

=head1 NAME

Apache::ShowRequest - Show phases and module participation

=head1 SYNOPSIS

 <Location /show>
  SetHandler perl-script
  PerlHandler Apache::ShowRequest
 </Location>

=head1 DESCRIPTION

This module will run a request using the given B<PATH_INFO> as the uri.
Each request phase will be run in order, along with each module handler.
The module response code will be printed or B<undef> if the module does not
participate in the given phase.  Apache::ShowRequest stops running module 
handlers for the given phase just as Apache would.  For example, if any 
returns a code other than B<OK> or B<DECLINED>.  Or, phases which only
allow one module to return B<OK>, e.g. URI translate.
The content response phase is not run, but possible modules are listed as
B<defined>.  

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO 

Apache::Module(3), Apache(3), mod_perl(3)

