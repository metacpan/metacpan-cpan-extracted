use Data::AMF::Remoting;
use Plack::Request;
use UNIVERSAL::require;

sub
{
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $res = $req->new_response(200);
	
	if ($req->path =~ /\/amf\/gateway$/)
	{
		my $remoting = Data::AMF::Remoting->new(
			source => $req->raw_body,
			message_did_process => sub
			{
				my $message = shift;

				my ($controller_name, $method) = split '\.', $message->target_uri;
				
				$controller_name->require;
				my $controller = $controller_name->new;
				
				return $controller->$method($message->value);
			}
		);
		$remoting->run;
		
		$res->content_type('application/x-amf');
		$res->body($remoting->data);
	}
	
	return $res->finalize;
};
