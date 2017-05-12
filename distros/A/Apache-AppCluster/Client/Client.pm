package Apache::AppCluster::Client;
use strict;

use IO::Socket;
use Time::HiRes;
use POSIX;
use Storable qw( freeze thaw );
use Carp;
use Digest::MD5 qw( md5_hex );

use constant REQ_INCOMPLETE => 0;
use constant REQ_SUCCESS => 1;
use constant REQ_REMOTE_TIMEOUT => 2;
use constant REQ_CONNECT_FAIL => 4;
use constant REQ_RESPONSE_NOT_UNDERSTOOD => 5;

use constant SRV_NO_SUCH_METHOD => 6;
use constant SRV_SUCCESS => 7;
use constant SRV_COULD_NOT_UNDERSTAND_REQ => 8;
use constant SRV_METHOD_RETURNED_ERROR => 9;

use vars qw( $VERBOSE $VERSION );

$VERSION = '0.02';

$VERBOSE = 0;

sub new
{
	my ($caller, %args) = @_;
	my $class = ref($caller) || $caller;
	my $self = bless {}, $class;

	
	return $self;
}

sub get_total_success
{
	my $self = shift @_;
	if(exists $self->{_total_success})
	{
		return $self->{_total_success};
	} else
	{
		return undef;
	}
}

sub get_total_failed
{
	my $self = shift @_;
	if(exists $self->{_total_failed})
	{
		return $self->{_total_failed};
	} else
	{
		return undef;
	}
}


sub translate_error
{
	my $self = shift @_;
	my $err = shift @_;

	if($err == REQ_INCOMPLETE)
	{
		return "Request not completed yet.";
	} elsif($err == REQ_SUCCESS)
	{
		return "Request successful.";
	} elsif($err == REQ_REMOTE_TIMEOUT)
	{
		return "The request timed out while waiting for the remote server.";
	} elsif($err == REQ_CONNECT_FAIL)
	{
		return "The request failed to connect to the server and/or port you specified.";
	} elsif($err == REQ_RESPONSE_NOT_UNDERSTOOD)
	{
		return "The response the remote server sent back was not understood.";
	} elsif($err == SRV_NO_SUCH_METHOD)
	{
		return "The remote server generated an error: No such method.";
	} elsif($err == SRV_SUCCESS)
	{
		return "Remote server completed the operation succesfully.";
	} elsif($err == SRV_COULD_NOT_UNDERSTAND_REQ)
	{
		return "The remote server could not understand the request you sent it.";
	} elsif($err == SRV_METHOD_RETURNED_ERROR)
	{
		return "The method called on the remote server returned an error.";
	} else
	{
		return undef;
	}
}
	

sub request_ok
{
	my $self = shift @_;
	my $key = shift @_;

	if($self->{_requests}->{$key}->{status} == REQ_SUCCESS)
	{
		return 1;
	} else
	{
		return 0;
	}
}

sub add_request
{
	my $self = shift @_;
	my %data = @_;

	$self->{_requests} = {} if(!$self->{_requests});

	croak "A request with key " . $data{key} . " has already been registered! Each request must have a unique key." 
		if(exists $self->{_requests}->{$data{key}});

	my $new_req = {};

	$new_req->{method} = ($data{method}) ? $data{method} : croak "No remote method specified!";
	$new_req->{params} = ($data{params}) ? $data{params} : undef;
	$new_req->{status} = REQ_INCOMPLETE;


	my $msg = "Please use the format url => 'http://www.servername.com:8080/my/first/application' (The colon and port number are optional) and make sure your remote AppCluster server is configured to handle that URL.";
	
	(exists $data{url}) || croak "No server URL specified. $msg";
	
	if($data{url} =~ m/http:\/\/(.*?)(\/.*)$/i)
	{
		my $sdetail = $1;
		my $uri = $2;
		my ($server, $port);
		if($sdetail =~ m/(.*?):(\d+)$/)
		{
			$server = $1;
			$port = $2;
		} else
		{
			$server = $sdetail;
			$port = 80;
		}

		if($server =~ m/[^a-zA-Z\d\-\.]/)
		{
			croak "Could not interpret your server name: $server";
		}

		$new_req->{server} = $server;
		$new_req->{port} = $port;
		$new_req->{uri} = $uri;

	} else
	{
		croak "Could not understand your URL: " . $data{url};
	}

	$self->{_requests}->{$data{key}} = $new_req;
}

sub get_request_keys
{
	my $self = shift @_;
	if(ref($self->{_requests}) eq 'HASH')
	{
		return (keys %{$self->{_requests}});
	} else
	{
		return undef;
	}
}


sub get_request_data
{
	my $self = shift @_;
	my $index = shift @_;

	if(exists $self->{_requests}->{$index})
	{
		if(exists $self->{_requests}->{$index}->{data})
		{
			return $self->{_requests}->{$index}->{data};
		} else
		{
			return 0; #No data
		}
	} else
	{
		return undef; #No such request
	}
}

sub get_request_status
{
	my $self = shift @_;
	my $index = shift @_;

	if(exists $self->{_requests}->{$index})
	{
		return $self->{_requests}->{$index}->{status}; 
	} else
	{
		return undef; #no such request
	}
}

sub send_requests
{
	my $self = shift @_;
	my $timeout = shift @_; #in seconds - can be a float
	
	my $stime = Time::HiRes::time();

	foreach my $index (keys %{$self->{_requests}})
	{
		warn "Connecting to: " . $self->{_requests}->{$index}->{server} . ":" . $self->{_requests}->{$index}->{port} if($VERBOSE);
		if(! ($self->{_requests}->{$index}->{sock} = new IO::Socket::INET (
			PeerAddr => $self->{_requests}->{$index}->{server},
			PeerPort => $self->{_requests}->{$index}->{port},
			Proto => 'tcp',)) 
		  ) 
		{
			$self->{_requests}->{$index}->{status} = REQ_CONNECT_FAIL;
		} else
		{
			fcntl($self->{_requests}->{$index}->{sock}, F_SETFL(), O_NONBLOCK()); #now you're a non-blocker
		}
	}

	my $connected_sockets = 0;
	
	foreach my $index (keys %{$self->{_requests}})
	{
	
		if( $self->{_requests}->{$index}->{status} == REQ_INCOMPLETE ) #those that didn't fail to connect
		{
			$connected_sockets++;
			my $href = {
				method => $self->{_requests}->{$index}->{method},
				params => $self->{_requests}->{$index}->{params},
				};

			my $data = freeze($href);
			my $digest = md5_hex($data);
			my $send_data = '<frozen>' . $digest . $data . '</frozen>';
			my $content_length = length($send_data);
			my $uri = $self->{_requests}->{$index}->{uri};
			my $host = $self->{_requests}->{$index}->{server};

#I'm guessing that octet-stream is the correct mime type for this sort of thing.
			print {$self->{_requests}->{$index}->{sock}} <<"EOF";
POST $uri HTTP/1.0
Accept: application/octet-stream
Accept: */*
Host: $host
Connection: close
User-Agent: Apache::AppCluster::Client v0.1
Content-Length: $content_length
Content-Type: application/octet-stream;

$send_data
EOF

			$self->{_requests}->{$index}->{sock}->flush();
		}
	}





	my $cutoff_time = Time::HiRes::time() + $timeout;

	my $sockets_pending = $connected_sockets;

	while((Time::HiRes::time() < $cutoff_time) && $sockets_pending)
	{
		my $sockets_finished = 0;
		foreach my $index (keys %{$self->{_requests}})
		{
			if($self->{_requests}->{$index}->{status} == REQ_INCOMPLETE) 
			{
				my $buf;
				my $bytes_read = sysread($self->{_requests}->{$index}->{sock}, $buf, 1024);
				if(defined($bytes_read) )
				{
					if($bytes_read == 0)
					{
						close($self->{_requests}->{$index}->{sock});
						$self->{_requests}->{$index}->{status} = REQ_SUCCESS; #finished
						$sockets_pending--;
					} else
					{
						$self->{_requests}->{$index}->{data} .= $buf;
					}
				} else #no data to read yet
				{
					if($! == EAGAIN()) #socket would have blocked
					{
						#keep going until there is more data on the socket
					} else
					{
						$self->{_requests}->{$index}->{status} = REQ_SUCCESS;
						$sockets_pending--;
					}
				}
			} 
		}
		
	}

	foreach my $index (keys %{$self->{_requests}})
	{
		if($self->{_requests}->{$index}->{status} == REQ_SUCCESS)
		{
			if($self->{_requests}->{$index}->{data} =~ m/<frozen>(.*)<\/frozen>/s)
			{
				my $input = $1;
				my $digest = substr($input, 0, 32);
				my $data = substr($input, 32);
				my $response;
				if($digest eq md5_hex($data))
				{
					$response = thaw($data);
					if($response->{status} == SRV_SUCCESS) #remote success
					{
						$self->{_requests}->{$index}->{data} = $response->{data};
						$self->{_total_success}++;
					} else
					{
						$self->{_requests}->{$index}->{data} = undef;
						$self->{_requests}->{$index}->{status} = $response->{status};
						$self->{_requests}->{$index}->{method_error} = $response->{method_error};
						$self->{_total_failed}++;
					}
				} else
				{
					warn "Digest failed." if($VERBOSE);
					$self->{_requests}->{$index}->{data} = undef;
					$self->{_requests}->{$index}->{status} = REQ_RESPONSE_NOT_UNDERSTOOD;
					$self->{_total_failed}++;
				}

			} else
			{
				warn "Regex not matched." if($VERBOSE);
				$self->{_requests}->{$index}->{data} = undef;
				$self->{_requests}->{$index}->{status} = REQ_RESPONSE_NOT_UNDERSTOOD;
				$self->{_total_failed}++;
			}
		} else
		{
			if($self->{_requests}->{$index}->{status} == REQ_INCOMPLETE)
			{
				$self->{_requests}->{$index}->{status} = REQ_REMOTE_TIMEOUT;
			}
			$self->{_total_failed}++;
		}
	}

	$self->{_time_taken} = Time::HiRes::time() - $stime;

	return $self->{_total_success};
}


sub get_total_request_time
{
	my $self = shift @_;
	if(exists $self->{_time_taken})
	{
		return $self->{_time_taken};
	} else
	{
		return undef;
	}
}
1;

=head1 NAME

Apache::AppCluster::Client

=head1 SYNOPSIS

  #To call a single remote method:
  
  use Apache::AppCluster::Client;
  my $client = Apache::AppCluster::Client->new();
  
  $client->add_request(
    key => 'key1',
    method => 'MyLib::search()',
    params => ['val1', 'val2', 'another_val', 'more_stuff'],
    url => 'http://your.servername.com:8080/search',
  );
  
  my $timeout = 5.6; #seconds - can be a float
  my $num_succesful = $client->send_requests($timeout);
  my $num_failed = $client->get_total_failed();
  
  if($client->request_ok('key1')) {
    my $key1_data = $client->get_request_data('key1');
  } else {
    print "Request 'key1' failed with error: " . 
      $client->translate_error($client->get_request_status('key1'));
  }

          -OR-
	  
  #To call many remote methods on distributed servers simultaneously:
  use Apache::AppCluster::Client;
  
  my $client = Apache::AppCluster::Client->new();
  
  my @servers = qw( server1.cluster.com server2.cluster.com 
     server3.cluster.com server4.cluster.com );
  
  for(my $counter = 0; $counter < 4000; $counter += 4) {
    my $server_url = 'http://' . $servers[$counter % 4] . '/server_uri';
    
    $client->add_request(
      key => $counter,
      #Method and params can vary per request
      method => 'MyLib::do_something()', 
      params => { key1 => 'value1', key2 => 'value2' },
      url => $server_url,
    );
  }

  my $num_succesful = $client->send_requests(60);
  my $num_failed = $client->get_total_failed();
  
  my %data;
  for(my $counter = 0; $counter < 4000; $counter++) {
    if($client->request_ok($counter)) {
      $data{$counter} = $client->get_request_data($counter);
    } else {
      $data{$counter} = undef;
    }
  }

  print "Total time for all requests to finish: " . 
    $client->get_total_request_time();
        
=head1 DESCRIPTION

Apache::AppCluster::Client is designed to be a lightweight RPC mechanism 
for mod_perl applications that allows concurrent method calls to
multiple remote mod_perl application servers. If you simply want 
a mod_perl app to do 20 things at once locally, or you have a cluster
of 100 distributed mod_perl web servers acting as back end processors 
for a front end web server, you'll (hopefully) find this useful.

=head1 THE CLIENT OBJECT

The client object is created by calling new with no parameters. 
Then call add_request() to add as many requests as you like specifying
a request key each time. 
Then call send_requests($timeout) to send all requests simultaneously
to their respective remote servers. The return data for each request
can be retreived using get_request_data($request_key). 

=head1 METHODS

The following methods may be called on the client object.

=over 4

=item new()
	
Creates a client object - takes no parameters.

=item add_request()

$client->add_request(
    key => $keyname,
    method => 'MyLib::MainModule::method()',
    params => $scalar_reference,
    url => 'http://server.mydomain.com:8080/svr_uri',
    );

Add request registers a request to be sent to a remote server with
the client object. 'key' may be any key that may be used in a hash. 
'method' is the name of the remote method you wish to invoke including
full package name and brackets. 'params' is any scalar. The scalar may
contain a reference to a HASH, ARRAY, object, or anything that 
Storable::freeze and Storable::thaw can serialize. 'url' is a URL in
standard format. You may optionally specify a remote port. If none 
is specified, it defaults to 80 as per normal. The URI portion of the 
URL (/svr_uri in the example) must point to the URI that is handled
by Apache::AppCluster::Server. Please see the latters documentation
for details.

=item $n = send_requests($timeout)

Send requests must be called with a timeout in seconds. The timeout can be 
a floating point number. The return value is the number of requests succesfully returned.
All requests that have been 
registered with add_request will be sent simultaneously to their respective
servers when send_requests is called. 
send_requests will return when all responses have been received or
the specified timeout has elapsed. If the timeout is 0 or omitted, then
send_requests will wait an infinite time for a response. 

B<NOTE> that when you call send_requests, a socket will be created for each request
to be sent. Please make sure you have enough sockets available i.e. don't 
try to send 100000 requests simultaneously. Also note that the client first
establishes a connection to all remote servers, then sends the requests. 
If you are connecting to a single server, make sure you dont overload it
with connections, or you will find all your requests timing out i.e. B<Don't
exceed your apache server's MaxClient's setting.>

=item get_total_failed()

Returns the number of failed requests.

=item get_total_success()

Returns number of succesful requests.

=item request_ok($key)

Returns true if the request associated with $key was succesful

=item get_request_data($key)

Returns the data that was returned from the request associated with $key. 
Returns undef if there is no such request and false if there is no data 
(which would be the case if the request failed). If you have a function
that returns false, then have it return a reference that points to a false
value.

=item get_total_request_time()

Returns the total time taken to process all requests. You can call this after
you call send_requests.

=item request_status($key)

Returns a numerical status for the request.

=item translate_error(request_status($key))

translate_error() will translate the numerical status returned by request_status().

=item get_request_keys()

Returns an array of all keys for all requests added using add_request().

=back

=head1 BUGS

None yet. Please send to mark@swiftcamel.com

=head1 SEE ALSO

Apache::AppCluster::Server

=head1 AUTHOR

Mark Maunder <mark@swiftcamel.com> - Any problems, bugs, feature requests or questions are welcome.





