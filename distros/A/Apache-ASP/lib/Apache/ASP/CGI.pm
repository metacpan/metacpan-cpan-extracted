
package Apache::ASP::CGI;

# this package emulates an Apache request object with a CGI backend

use Apache::ASP;
use Apache::ASP::Request;
use Class::Struct;
use Apache::ASP::CGI::Table;

use strict;
no strict qw(refs);
use vars qw($StructsDefined @END);
$StructsDefined = 0;

sub do_self {
    my $class = shift;

    if(defined($class)) {
	if(ref $class or $class =~ /Apache::ASP::CGI/) {
	    # we called this OO style
	} else {
	    unshift(@_, $class);
	    $class = undef;
	}
    }

    my %config = @_;
    $class ||= 'Apache::ASP::CGI';

    my $r = $class->init($0, @ARGV);
    $r->dir_config->set('CgiDoSelf', 1);
    $r->dir_config->set('NoState', 0);

    # init passed in config
    for(keys %config) {
	$r->dir_config->set($_, $config{$_});
    }

    &Apache::ASP::handler($r);

    $r;
}

sub init {
    my($class, $filename, @args) = @_;
    $filename ||= $0;
    
#    for('Class/Struct.pm') {
#	next if require $_;
#	die("can't load the $_ library.  please make sure you installed it");
#    }
    
    # we define structs here so modperl users don't incur a runtime / memory
    unless($StructsDefined) {
	$StructsDefined = 1;
	&Class::Struct::struct( 'Apache::ASP::CGI::connection' => 
				{
				   'remote_ip' => "\$",
				   'auth_type' => "\$",
				   'user' => "\$",
				   'aborted' => "\$",
				   'fileno' => "\$",
			       }
			       );    

	&Class::Struct::struct( 'Apache::ASP::CGI' => 
				{
				   'connection'=> 'Apache::ASP::CGI::connection',
				   'content_type' => "\$",
				   'current_callback' => "\$",
				   'dir_config'=>    "Apache::ASP::CGI::Table",
				   'env'       =>    "\%",
				   'filename'  =>    "\$",
				   'get_basic_auth_pw' => "\$",
				   'headers_in' =>    "Apache::ASP::CGI::Table",
				   'headers_out'=>    "Apache::ASP::CGI::Table",
				   'err_headers_out' => "Apache::ASP::CGI::Table",
				   'subprocess_env'  => "Apache::ASP::CGI::Table",
				   'method'    =>    "\$",
				   'sent_header' =>  "\$",
				   'OUT'    =>    "\$",
			       }
			       );
    }

    # create struct
    my $self = new();
    if(defined $ENV{GATEWAY_INTERFACE} and $ENV{GATEWAY_INTERFACE} =~ /^CGI/) {
	# nothing, don't need CGI object anymore
    } else {
	# command line
	my %args = @args;
	$ENV{QUERY_STRING} = join('&', map { "$_=$args{$_}" } keys %args);
    }
    
    $self->connection(Apache::ASP::CGI::connection->new);
    $self->dir_config(Apache::ASP::CGI::Table->new);
    $self->err_headers_out(Apache::ASP::CGI::Table->new);
    $self->headers_out(Apache::ASP::CGI::Table->new);
    $self->headers_in(Apache::ASP::CGI::Table->new);
    $self->subprocess_env(Apache::ASP::CGI::Table->new);

    my $env = $self->subprocess_env;
    %$env = %ENV;

    $self->filename($filename);
    $self->connection->remote_ip($ENV{REMOTE_HOST} || $ENV{REMOTE_ADDR} || '0.0.0.0');
    $self->connection->aborted(0);
    $self->current_callback('PerlHandler');

    # $self->headers_in->set('Cookie', $ENV{HTTP_COOKIE});
    for my $env_key ( sort keys %ENV ) {
	if($env_key =~ /^HTTP_(.+)$/ or $env_key =~ /^(CONTENT_TYPE|CONTENT_LENGTH)$/) {
	    my $env_header_in = $1;
	    my $header_key = join('-', map { ucfirst(lc($_)) } split(/\_/, $env_header_in));
	    $self->headers_in->set($header_key, $ENV{$env_key});
	}
    }

    # we kill the state for now stuff for now, as it's just leaving .state
    # directories everywhere you run this stuff
    defined($self->dir_config->get('NoState')) || $self->dir_config->set('NoState', 1);

    $self->method($ENV{REQUEST_METHOD} || 'GET');

    for my $env_key ( keys %ENV ) {
	$self->env($env_key, $ENV{$env_key});
    }
    $self->env('SCRIPT_NAME') || $self->env('SCRIPT_NAME', $filename);

    # fix truncated output in standalone CGI mode under Win32
    binmode(STDOUT);

    bless $self, $class;
}

sub init_dir_config {
    my($self, %config) = @_;
    my $dir_config = $self->dir_config;
    %$dir_config = %config;
    $dir_config;
}

sub status { 
    my($self, $status) = @_;
    if(defined($status)) {
	$self->headers_out->set('status', $status);
    } else {
	$self->headers_out->get('status');
    }
}

sub cgi_env { %{$_[0]->env} ; }

sub send_http_header {
    my($self) = @_;
    my($k, $v, $header);
    
    $self->sent_header(1);
    $header = "Content-Type: " .$self->content_type()."\n";
    
    for my $headers ($self->headers_out, $self->err_headers_out) {
        while(($k, $v) = each %$headers) {
	    next if ($k =~ /^content\-type$/i);
	    if(ref $v) {
		# if ref, then we have an array for cgi_header_out for cookies
		for my $value (@$v) {
		    $value ||= '';
		    $header .= "$k: $value\n";
		}
	    } else {
		$v ||= '';
		$header .= "$k: $v\n";	    
	    }
	}
    }

    $header .= "\n";
 	
    $self->print($header);
}

sub send_cgi_header {
    my($self, $header) = @_;

    $self->sent_header(1);
    my(@left);
    for(split(/\n/, $header)) {
	my($name, $value) = split(/\:\s*/, $_, 2);
	if($name =~ /content-type/i) {
	    $self->content_type($value);
	} else {
	    push(@left, $_);
	}
    }

    $self->print(join("\n", @left, ''));
    $self->send_http_header();
}

sub print { 
    shift; 
    local $| = 1;
    print STDOUT map { ref($_) =~ /SCALAR/ ? $$_ : $_; } @_; 
}

sub args {
    my $self = shift;

    if(wantarray) {
	my $params = Apache::ASP::Request->ParseParams($ENV{QUERY_STRING});
	%$params;
    } else {
	$ENV{QUERY_STRING};
    }
}
*content = *args;

sub log_error {
    my($self, @args) = @_;
    print STDERR @args, "\n";
}

sub register_cleanup { push(@END, $_[1]); }

# gets called when the $r get's garbage collected
sub END { 
    for ( @END ) {
	next unless $_;
	if(ref($_) && /CODE/) {
	    my $rv = eval { &$_ };
	    if($@) {
		Apache::ASP::CGI->log_error("[ERROR] error executing register_cleanup code $_: $@");
	    }
	}
    }
}

sub soft_timeout { 1; };

sub lookup_uri {
    die('cannot call $Server->MapPath in CGI mode');
}

sub custom_response {
    die('$Response->ErrorDocument not implemented for CGI mode');
}

1;
