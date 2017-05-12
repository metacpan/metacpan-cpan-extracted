package Amazon::MWS::Routines;

use URI;
use DateTime;
use XML::Simple;
use URI::Escape;
use MIME::Base64;
use Digest::SHA;
use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5 qw(md5_base64);
use Amazon::MWS::TypeMap qw(:all);
use Amazon::MWS::Exception;
use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK = qw(define_api_method new sign_request convert force_array);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub slurp_kwargs { ref $_[0] eq 'HASH' ? shift : { @_ } }

sub define_api_method {
    my $method_name = shift;
    my $spec        = slurp_kwargs(@_);
    my $params      = $spec->{parameters};

    my $method = sub {

        my $self = shift;
        my $args = slurp_kwargs(@_);
        my $body = '';

        my %form = (
            Action           		=> $method_name,
            AWSAccessKeyId   		=> $self->{access_key_id},
            Merchant         		=> $self->{merchant_id},
            SellerId         		=> $self->{merchant_id},
            SignatureVersion 		=> 2,
            SignatureMethod  		=> 'HmacSHA256',
            Timestamp        		=> to_amazon('datetime', DateTime->now),
        );

        foreach my $name (keys %$params) {
            my $param = $params->{$name};
            unless (exists $args->{$name}) {
                Amazon::MWS::Exception::MissingArgument->throw(name => $name) if $param->{required};
                next;
            }

            my $type  = $param->{type};
            my $array_names  = $param->{array_names};
            my $value = $args->{$name};

	    if ($type =~ /^List$/) {
	 	my %valuehash;
		@valuehash{@{$param->{values}}}=();
		Amazon::MWS::Exception::Invalid->throw(field => $name, value=>$value) unless (exists ($valuehash{$value}));
		$form{$name} = $value;
		next;
            }

            # Odd 'structured list' notation handled here
            if ($type =~ /(\w+)List/) {
                my $list_type = $1;
		 Amazon::MWS::Exception::Invalid->throw(field => $name, value=>$value, message=>"$name should be of type ARRAY") unless (ref $value eq 'ARRAY');
                my $counter   = 1;

                foreach my $sub_value (@$value) {
                    my $listKey = "$name.$list_type." . $counter++;
                    $form{$listKey} = $sub_value;
                }
                next;
            }

            if ($type =~ /(\w+)Array/) {
		 Amazon::MWS::Exception::Invalid->throw(field => $name, value=>$value, message=>"$name should be of type ARRAY") unless (ref $value eq 'ARRAY');
                my $list_type = $1;
                my $counter   = 0;
                foreach my $sub_value (@$value) {
		    $counter++;
		    my $arr_col=0;
		    foreach my $array_name (@{$array_names}) {
			if ( ! defined $sub_value->[$arr_col] ) { next; }
                    	my $listKey = "$name.$list_type." . $counter;
		     	   $listKey .= ".$array_name";
                    	$form{$listKey} = $sub_value->[$arr_col++];
    		    }
                }
                next;
            }
            if ($type eq 'HTTP-BODY') {
                $body = $value;
            }
            else {
                $form{$name} = to_amazon($type, $value);
            }
        }

	$form{Version} = $spec->{version} || '2010-01-01';

	my $endpoint = ( $spec->{service} ) ? "$self->{endpoint}$spec->{service}" : $self->{endpoint};

        my $uri = URI->new($endpoint);

        my $request = HTTP::Request->new;
	   $request->protocol('HTTP/1.0');

        my ($response, $content);

	$spec->{method} = 'GET' unless $spec->{method};

        if ($spec->{method} eq 'POST') {
            $request->uri($uri);
            $request->method('POST'); 
            $request->content($body);
            $request->content_type($args->{content_type}||'application/x-www-form-urlencoded');
            my $signature = $self->sign_request($request, %form);

            $response = $self->agent->request($request);
            $content  = $response->content;
        } elsif ($body) {
	    $request->uri($uri);
            $request->method('POST');
            $request->content($body);
            $request->header('Content-MD5' => md5_base64($body) . '==');
            $request->content_type($args->{content_type}||'text/plain');

   	    $self->sign_request($request, %form);
            $request->content($body);
            $response = $self->agent->request($request);
            $content = $response->content;
        } else {
            $uri->query_form(\%form);
            $request->uri($uri);
            $request->method('GET');

            $self->sign_request($request);
          
            $response = $self->agent->request($request);
            $content  = $response->content;

        }


	if ($self->{debug}) {
                open LOG, ">>$self->{logfile}";
		print LOG Dumper($response);
            }

        my $xs = XML::Simple->new( KeepRoot => 1 );

        if ($response->code == 400 || $response->code == 403) {
            my $hash = $xs->xml_in($content);
            my $root = $hash->{ErrorResponse};
            force_array($root, 'Error');
            Amazon::MWS::Exception::Response->throw(errors => $root->{Error}, xml => $content);
        }

        if ($response->code == 503) {
            my $hash = $xs->xml_in($content);
            my $root = $hash->{ErrorResponse};
            force_array($root, 'Error');
            Amazon::MWS::Exception::Throttled->throw(errors => $root->{Error}, xml => $content);
        }

        unless ($response->is_success) {
            Amazon::MWS::Exception::Transport->throw(request => $request, response => $response);
        }

        if (my $md5 = $response->header('Content-MD5')) {
            Amazon::MWS::Exception::BedChecksum->throw(response => $response) 
                unless ($md5 eq md5_base64($content) . '==');
        }

        return $content if ($spec->{raw_body} || $args->{raw_body});

        my $hash = $xs->xml_in($content);

        my $root = $hash->{$method_name . 'Response'}
            ->{$method_name . 'Result'};

        return $spec->{respond}->($root);
    };

    my $module_name = $spec->{module_name} || 'Amazon::MWS::Client';
    my $fqn = join '::', "$module_name", $method_name;

    no strict 'refs';
    *$fqn = $method;

}

sub force_array {

    my ($hash, $key) = @_;
    my $val = $hash->{$key};

    if (!defined $val) {
        $val = [];
    }
    elsif (ref $val ne 'ARRAY') {
        $val = [ $val ];
    }

    $hash->{$key} = $val;
}

sub sign_request {
    my ($self, $request, %form) = @_;

    my $uri = $request->uri;
    my %params = ($request->method eq 'GET' ) ? $uri->query_form : %form;

    my $canonical = join '&', map {
        my $param = uri_escape($_);
        my $value = uri_escape($params{$_});
        "$param=$value";
    } sort keys %params;

    my $path = $uri->path || '/';
    my $string = $request->method . "\n"
	. $uri->authority . "\n"
        . $path . "\n"
        . $canonical;

    $params{Signature} = Digest::SHA::hmac_sha256_base64($string, $self->{secret_key});
     while (length($params{Signature}) % 4) {
                $params{Signature} .= '=';
        }

    if ($request->{_method} eq 'GET' || $request->{_content} ) {
    	$uri->query_form(\%params);
    } else {
	$request->{_content} = "$canonical&Signature=$params{Signature}";
    }
	$request->uri($uri);
	return $request;

}

sub convert {
    my ($hash, $key, $type) = @_;
    $hash->{$key} = from_amazon($type, $hash->{$key});
}


sub new {
	
 my($pkg, %opts) = @_;

 $opts{configfile} ||= 'amazon.xml';

  if (-r $opts{configfile} ) {

    my $xmlconfig = XML::Simple::XMLin("$opts{configfile}");

    $opts{access_key_id} ||= $xmlconfig->{access_key_id};
    $opts{secret_key} ||= $xmlconfig->{secret_key};
    $opts{merchant_id} ||= $xmlconfig->{merchant_id};
    $opts{marketplace_id} ||= $xmlconfig->{marketplace_id};
    $opts{endpoint} ||= $xmlconfig->{endpoint};
    $opts{debug} ||= $xmlconfig->{debug};
    $opts{logfile} ||= $xmlconfig->{logfile};
 }

 my $attr = $opts->{agent_attributes};
    $attr->{Language} = 'Perl';

    my $attr_str = join ';', map { "$_=$attr->{$_}" } keys %$attr;
    my $appname  = $opts{Application} || 'Amazon::MWS::Client';
    my $version  = $opts{Version}     || 0.5;

    my $agent_string = "$appname/$version ($attr_str)";

    die 'No access key id' unless  $opts{access_key_id};
    die 'No secret key' unless $opts{secret_key};
    die 'No merchant id' unless $opts{merchant_id};
    die 'No marketplace id' unless $opts{marketplace_id};

    if ($opts{debug}) {
       open LOG, ">$opts{logfile}" or die "Cannot open logfile.";
       print LOG DateTime->now();
       print LOG "\nNew instance created. \n";
       print LOG Dumper(\%opts);
       close LOG; 
    }

 # https://github.com/interchange/Amazon-MWS/issues/9
 $opts{endpoint} ||= 'https://mws.amazonaws.com';
 # strip the trailing slashes
 $opts{endpoint} =~ s/\/+\z//;

  bless {
    package => "$pkg",
    agent => LWP::UserAgent->new(agent => $agent_string),
    endpoint => $opts{endpoint},
    access_key_id => $opts{access_key_id},
    secret_key => $opts{secret_key},
    merchant_id => $opts{merchant_id},
    marketplace_id => $opts{marketplace_id}, 
    debug => $opts{debug}, 
    logfile => $opts{logfile},
	}, $pkg;

}

1;

# Local Variables:
# tab-width: 8
# End:

