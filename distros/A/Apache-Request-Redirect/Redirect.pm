package Apache::Request::Redirect;

use 5.006;
use strict;
use warnings;
use Carp;
use Exporter;

use vars qw(@ISA @EXPORT $LOG_REQUEST $LOG_QUERYSTRING $LOG_RESPONSE);

@ISA 					= qw(Exporter);
@EXPORT 				= qw($LOG_REQUEST $LOG_QUERYSTRING $LOG_RESPONSE);

use HTTP::Response;
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use URI;

$Apache::Request::Redirect::VERSION = '0.05';

$Apache::Request::Redirect::LOG = 0;

$LOG_REQUEST			= 0b0001;
$LOG_QUERYSTRING		= 0b0010;
$LOG_RESPONSE			= 0b0100;


my $MOD_PERL = 0;
# Turn on special checking for Doug MacEachern's modperl
if (exists $ENV{MOD_PERL}) {
  eval "require mod_perl";
  # mod_perl handlers may run system() on scripts using CGI.pm;
  # Make sure so we don't get fooled by inherited $ENV{MOD_PERL}
  if (defined $mod_perl::VERSION) {
    if ($mod_perl::VERSION >= 1.99) {
      $MOD_PERL = 2;
      require Apache::RequestRec;
      require Apache::RequestUtil;
      require APR::Pool;
    } else {
      $MOD_PERL = 1;
      require Apache;
    }
  }
}


my %fields = (
				apachereq		=> '',
				host			=> 'localhost',
				url				=> '/',			
				args			=> {},
				use_http10		=> 0,
);

sub new {
	my ($proto,%options) = @_;
	my $class = ref($proto) || $proto;
	my $self = { };
	while (my ($key,$value) = each(%options)) {
      if (exists($fields{$key})) {
          $self->{$key} = $value;
      } else {
          die $class . "::new: invalid option '$key'\n";
      }
	}
	#foreach (keys %fields) {
	#	die $class . "::new: omitted required option '$_'\n"
	#		if (!defined $self->{$_});
	#}
		
	bless $self, $class;
	
	# attivo apachereq direttamente da Apache
	if ($MOD_PERL) {
		$self->apachereq(Apache->request) unless $self->apachereq;
		my $apachereq = $self->apachereq;
		if ($MOD_PERL == 1) {
			#$apacheref->register_cleanup(\&CGI::_reset_globals);
		} else {
      		# XXX: once we have the new API
      		# will do a real PerlOptions -SetupEnv check
      		#$apacheref->subprocess_env unless exists $ENV{REQUEST_METHOD};
      		#$apacheref->pool->cleanup_register(\&CGI::_reset_globals);
		}
	}

	if ($Apache::Request::Redirect::LOG != 0) {
		eval {
			require "Log/FileSimple.pm";
		};
		if ($@) {
			warn "Warning: Logging disabled...cannot find Log::FileSimple module";
			$Apache::Request::Redirect::LOG = 0;
		} else {
			$self->{log} 	= new Log::FileSimple(
													name=> "Apache::Request::Redirect",
													file=> '/tmp/Apache-Request-Redirect.log',
													mask=> $Apache::Request::Redirect::LOG,
											);
		}
	}
	return $self;
}

sub redirect() {
	# passare un riferimento ad hash con 
	# i parametri della query in quanto la query string (GET)
	# o il content (POST) deve essere ricostruito
	# (Mason si mangia il content)
	my $self			= shift;
	my $request 		= $self->_prepare_request();
	$self->_log(message => "Request:\n" . $request->as_string , id => $LOG_REQUEST);
	my $response		= $self->_send_request($request);
	my $response_text 	= $response->as_string;
	$self->_log(id => $LOG_RESPONSE, message => "Response:\n" . 
							$response_text);
	return $response;
}

sub _prepare_request() {
	my $self			= shift;
	my $request_args	= $self->{args};

	# Costruisco l'header della richiesta da quello originale
	my $headers			= new HTTP::Headers(%{$self->{apachereq}->headers_in});
	# modifico l'host per impostarlo a quello che andro' realmente a 
	# chiamare
	$headers->header('Host',$self->{host});
	# dato che questo modulo e' fatto per post processare 
	# l'html ottenuto...non posso permettere che mi ritorni 
	# html compresso
	$headers->remove_header('Accept-Encoding');
	#$self->_log(id => $LOG_REQUEST, message => 'HTTP::Headers',objects=>[$headers]);
	# costruisco l'url ed il content
	my $uri				= URI->new();
	$uri->scheme('http');
	$uri->host($self->{host});
	$uri->path($self->{url});
	$uri->query_form(%$request_args);
	my $content;
	if ($self->{apachereq}->method eq 'POST') {
		# costruisco il content
		$content		= $self->_built_content();
		# nel post la query string totale la metto nel
		# content e non nell'url
		$content		.= $uri->query;
		# nell'url ci lasciamo la sola query_string originale (00.04)
		$uri->query(scalar($self->{apachereq}->args));
		# imposto la lunghezza del content nell'header
		$headers->header('Content-Length' => length($content));
	} else {
		# nel get il content non c'e' (sara' vero ? :-)
		$headers->remove_header('Content-Length');
	}
	# costruisco la nuova richiesta per il recupero dell'url
	my $request			= new HTTP::Request($self->{apachereq}->method,
											$uri,
											$headers,
											$content
						);
	return $request;
}

sub _send_request() {
	my $self			= shift;
	my $request			= shift;

	if ($self->{use_http10}) {
		require LWP::Protocol::http10;
		LWP::Protocol::implementor('http', 'LWP::Protocol::http10');
	}
	my $ua 				= new LWP::UserAgent;
	my $response		= $ua->send_request($request);
	return $response;
}

sub _log() {
	my $self 			= shift;
	$self->{log} && $self->{log}->log(@_);
}

sub _built_content() {
	my $self			= shift;
	my $request_args	= $self->{args};

	my $request			= $self->{apachereq};
	my $content;
	my $boundary;
	if ($request->header_in("Content-type") =~ 
							qr|^multipart/form-data; boundary=(.+?)$|i) {
		$boundary   = "--$1";	
		for my $upload ($self->{apachereq}->upload) {
			$self->_log(message => 'Upload object',
						objects=>[$upload], id => $LOG_REQUEST);
			$content .= "$boundary\r\n";
			my $info = $upload->info;
			while (my($key, $val) = each %$info) {
				if ($key ne 'Content-Type') {
					$content .= "$key: $val; ";
				}
				# rimuovo l'ultimo ;
				chop($content);
			}
			$content .= "\r\nContent-Type: " .
			$upload->info("Content-Type") . "\r\n\r\n";
			my $fh = $upload->fh;
			while (<$fh>) {
				$content .= $_;
			}
			# lo rimuovo da args
			delete $request_args->{$upload->name};
		}
		# aggiungo gli args
		while (my ($key,$val) = each(%$request_args)) {
			$content .= qq|\r\n$boundary\r\nContent-Disposition: | .
				qq|form-data; name="$key"\r\n\r\n$val|;
		}
		$content .= "\r\n$boundary--\r\n";
	}
	
	return $content;
}

# read-write property

sub apachereq { 
	my $s = shift; 
	if (@_) { 
		die "apachereq must be a reference to Apache or Apache::Request object" 
			if (ref($_[0]) ne "Apache" && ref($_[0]) ne "Apache::Request");
		$s->{apachereq} = shift; 
	} 
	return $s->{apachereq}; 
}

sub host { my $s = shift; if (@_) { $s->{host} = shift; } return $s->{host}; }
sub url { my $s = shift; if (@_) { $s->{url} = shift; } return $s->{url}; }
sub use_http10 { my $s = shift; if (@_) { $s->{use_http10} = shift; } return $s->{use_http10}; }

sub args { 
	my $s = shift; 
	if (@_) { 
		die "args must be a reference to a hash insteed of " . ref($_[0])
			 if (ref($_[0]) ne "HASH");
		$s->{args} = shift; 
	} 
	return $s->{args}; 
}

1;
__END__
