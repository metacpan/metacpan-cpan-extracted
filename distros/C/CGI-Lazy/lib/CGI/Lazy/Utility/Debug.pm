package CGI::Lazy::Utility::Debug;

use strict;

use Data::Dumper;
use File::Basename;

#-------------------------------------------------------------------------------------------------------------------------------
sub cookie {
	my $self = shift;
	my $q = $self->q;

	print $q->header,
	      $q->start_html({-title => 'CGI Test Page'}),
	      $q->h1('Cookies'),
	      $q->table($q->th('Param'), $q->th('Value'),
			      map {
			      	$q->TR($q->th({-style => "text-align:center"}, $_), $q->td({-style => "text-align:center"}, $q->cookie($_)))
				} $q->cookie()
		       );

}

#-------------------------------------------------------------------------------------------------------------------------------
sub config {
	my $self = shift;
	
	return $self->q->config;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub defaultFile {
	my $self = shift;

	return $self->{_defaultFile};
}

#-------------------------------------------------------------------------------------------------------------------------------
sub dump {
	my $self = shift;

	my $fulloutput = "<div id='debug'>\n";

	foreach my $thing (@_) {
		if (ref $thing) {
			my $output = Dumper($thing);

			$output =~ s/\n/<br>/g;
			$output =~ s/ /&nbsp;/g;
			$output =~ s/\t/&nbsp;&nbsp&nbsp;&nbsp;&nbsp;/g;

			$fulloutput .= $output;
		} else {
			$fulloutput .= $thing;
		}
	}

	$fulloutput .= "\n</div>";

	return $fulloutput;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub edump {
	my $self = shift;

	my $filename = $self->config->debugfile;
	$filename = $self->defaultFile unless $filename;

	open OF, ">> /tmp/$filename" or $self->q->errorHandler->couldntOpenDebugFile($filename, $!);
	local $\=$/;

	print OF '-'x20 . $self->timestamp() . '-'x20;

	foreach my $thing (@_) {
		if (ref $thing) {
			print OF Dumper($thing);
		} else {
			print OF $thing;
		}
	}

	print OF '-'x40;
	print OF "\n\n";

	close OF;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub edumpreplace {
	my $self = shift;

	my $filename = $self->config->debugfile;
	$filename = $self->defaultFile unless $filename;

	open OF, ">> /tmp/$filename" or $self->q->errorHandler->couldntOpenDebugFile($filename, $!);
	local $\=$/;

	print OF '-'x20 . $self->timestamp() . '-'x20;

	foreach my $thing (@_) {
		if (ref $thing) {
			print OF Dumper($thing);
		} else {
			print OF $thing;
		}
	}

	print OF '-'x40;
	print OF "\n\n";

	close OF;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub eparam {
	my $self = shift;

	my $q = $self->q;

	my @list = $q->param();
	my %param;

	foreach (@list) {
		my @values = $q->param($_);
		$param{$_} = \@values;
	}

	my $filename = $self->config->debugfile;
	$filename = $self->defaultFile unless $filename;

	open OF, ">> /tmp/$filename" or $self->q->errorHandler->couldntOpenDebugFile($filename, $!);

	local $\=$/;

	print OF '-'x20 . $self->timestamp() . '-'x20;
	foreach my $key (keys %param) {
		 foreach (@{$param{$key}}) {
			print OF "$key \t => \t $_";
		 }

	}

	foreach my $thing (@_) {
		if (ref $thing) {
			print OF Dumper($thing);
		} else {
			print OF $thing;
		}
	}

	print OF '-'x40;
	print OF "\n\n";

	close OF;

}

#-------------------------------------------------------------------------------------------------------------------------------
sub param {
	my $self = shift;

	my $q = $self->q;

	my @list = $q->param();
	my %param;

	foreach (@list) {
		my @values = $q->param($_);
		$param{$_} = \@values;
	}

	my $fulloutput;

	$fulloutput .= $q->div({-id => 'debug'}, 
			$q->start_html({-title => 'CGI Test Page'}),
		       	$q->h1('CGI Parameters'),
		       	$q->table({-border => 1}, $q->th('Param'), $q->th('Value'),
			      map { 	my $name = $_; 
			      		map { $q->TR($q->th({-style => "text-align:center"}, $name), $q->td({-style => "text-align:center"}, $_))} @{$param{$name}};
					
					} keys %param
		       		)
			);

	foreach my $thing (@_) {
		if (ref $thing) {
			my $output = Dumper($thing);

			$output =~ s/\n/<br>/g;
			$output =~ s/ /&nbsp;/g;
			$output =~ s/\t/&nbsp;&nbsp&nbsp;&nbsp;&nbsp;/g;

			$fulloutput .= $output;
		} else {
			$fulloutput .= $thing;
		}
	}

	return $fulloutput;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub env {
	my $self = shift;

	my $q = $self->q;

	my %env_info = (
		SERVER_SOFTWARE		=> "the server software",
		SERVER_NAME		=> "the server hostname or IP address",
		GATEWAY_INTERFACE	=> "the CGI specification revision",
		SERVER_PROTOCOL		=> "the server protocol name",
		SERVER_PORT		=> "the port number for the server",
		REQUEST_METHOD		=> "the HTTP request method",
		PATH_INFO		=> "the extra path info",
		PATH_TRANSLATED		=> "the extra path info translated",
		DOCUMENT_ROOT		=> "the server document root directory",
		SCRIPT_NAME		=> "the script name",
		QUERY_STRING		=> "the query string",
		REMOTE_HOST		=> "the hostname of the client",
		REMOTE_ADDR		=> "the IP address of the client", 
		AUTH_TYPE		=> "the authentication method",
		REMOTE_USER		=> "the authenticated username",
		REMOTE_IDENT		=> "the remote user is (RFC 931): ",
		CONTENT_TYPE		=> "the media type of the data",
		CONTENT_LENGTH		=> "the length of the request body",
		HTTP_ACCEPT		=> "the media types the client acccepts",
		HTTP_USER_AGENT		=> "the browser the client is using",
		HTTP_REFERER		=> "the URL of the feferring page",
		HTTP_COOKIE		=> "The cookie(s) the client sent"
	);

	# Add additional variables defined by web server or browser
	foreach my $name (keys %ENV) {
		$env_info{$name} = "an extra variable provided by this server"
		unless exists $env_info{$name};
	}

	my $fulloutput;

	$fulloutput .= $q->div({-id => 'debug'}, $q->start_html({-title => 'A List of Envirornment Variables'}), 
			$q->h1('CGI Enviornment Variables'),
		       	$q->table({-border => 1},
			       	$q->Tr($q->th('Variable Name'), $q->th('Description'), $q->th('Value')),
			       		map { $q->Tr($q->td($q->b($_)),$q->td($env_info{$_}), $q->i($q->td(($ENV{$_} || 'Not Defined')))) } 
						sort keys %env_info,
		       		)
			);

	return $fulloutput;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#-------------------------------------------------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my ($file, $path, $suffix) = fileparse($0);
	$file .= ".log";

	my $self = {_q => $q, _defaultFile => $file};

	return bless $self, $class;
}

#-------------------------------------------------------------------------------------------------------------------------------
sub timestamp {
 	my ($sec, $min, $hour, $mday, $mon, $year) = (localtime(time))[0..5];
        $year += 1900;

        my $seconds = sprintf("%02d", $sec);
        my $minutes = sprintf("%02d", $min);
        my $hours = sprintf("%02d", $hour);
        my $day = sprintf("%02d", $mday);

        my %monthname = (
                        0=>'Jan',
                        1=>'Feb',
                        2=>'Mar',
                        3=>'Apr',
                        4=>'May',
                        5=>'Jun',
                        6=>'Jul',
                        7=>'Aug',
                        8=>'Sep',
                        9=>'Oct',
                        10=>'Nov',
                        11=>'Dec',
                        );

        my $monthname = $monthname{$mon};

        return "$year-$monthname-$day-$hours:$minutes:$seconds";


}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Utility::Debug

=head1 DESCRIPTION

CGI::Lazy::Utility::Debug is a bunch of useful CGI debugging functions that I got tired of writing by hand when I needed to figure out what wierdness is happening in a script

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/file');

	my $t = $q->utility->debug;

	$t->param(); 				#dumps html formatted CGI parameters to browser.

	$t->env();				#dumps html formatted %ENV to browser.

	$t->dump($ref, "some string");		#dumps html formatted output from Data::Dumper (if ref) or string (if scalar) to browser. 

	$t->cookie();				#dumps info regarding cookies to browser.

	$t->edump($ref, "some string");		#dumps to external file, appending at each subsequent call.

	$t->edumpreplace($ref);			#dumps to external file, overwriting at each call

=head1 METHODS

=head2 cookie

prints an html formatted page listing all cookies. 

=head2 dump ( output )

Outputs either a value, or a dump of a reference to the browser. 

=head3 ref

String consisiting of message to dump, or reference

=head2 edump ( ref, message, filename )

Outputs either a value, or a dump of a reference to file specified by the 'debugfile' key in the CGI::Lazy config file.  If that file isn't specified, dumps to /tmp/CGILazy.log.  Appends to dump file.

=head3 output

string or reference to dump into external log file

=head3 message 

a message to dump with the dump, if you like

=head2 edumpreplace ( output, message )

Outputs either a value, or a dump of a reference to file specified by the 'debugfile' key in the CGI::Lazy config file.  If that file isn't specified, dumps to /tmp/CGILazy.log.  Replaces dump file

=head3 output

string or reference to dump into external log file

=head3 message 

a message to dump with the dump, if you like

=head2 eparam ( args ) 

Dumps cgi parameters to filename.  Will also print any arguments passed, or dumps of args, if the args are references.

=head3 args

list of additional stuff to be printed out

=head2 param (args)

Writes cgi parameters to browser

=head3 args

list of addional stuff to be printed.  If references are passed, prints html formatted dumps of ref contents.

=head2 env

writes ENV variables to browser

=head2 new

constructor

=head2 timestamp

creates a formatted timestamp string for the log

=cut

