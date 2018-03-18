package Dwarf::Plugin::CORS;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};
	die "conf must be HASH" unless ref $conf eq 'HASH';

	$conf->{origin}      ||= '*';
	$conf->{methods}     ||= [qw/GET PUT POST DELETE HEAD OPTIONS PATCH/];
	$conf->{headers}     ||= [qw/X-Requested-With/];
	$conf->{credentials} ||= 0;
	$conf->{maxage}      ||= 7200;

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		
		$self->header('Access-Control-Allow-Origin' => $conf->{origin});
		$self->header('Access-Control-Allow-Methods' => join ',', @{ $conf->{methods} });
		$self->header('Access-Control-Allow-Headers' => join ',', @{ $conf->{headers} });

		if ($conf->{credentials}) {
			$self->header('Access-Control-Allow-Credentials' => 'true');
		}

		if ($self->method eq 'OPTIONS' and $conf->{maxage}) {
			# preflight なリクエストには 200 を返してしまう
			$self->response->status(200);
			$self->response->body("");
			$self->header('Access-Control-Max-Age' => $conf->{maxage});
		}
	});
}

1;
