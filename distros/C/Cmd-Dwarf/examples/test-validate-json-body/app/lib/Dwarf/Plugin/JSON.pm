package Dwarf::Plugin::JSON;
use Dwarf::Pragma;
use Dwarf::Util qw/encode_utf8 add_method/;
use JSON;

my %_ESCAPE = (
	'+' => '\\u002b', # do not eval as UTF-7
	'<' => '\\u003c', # do not eval as HTML
	'>' => '\\u003e', # ditto.
);

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	$conf->{pretty}          //= 0;
	$conf->{convert_blessed} //= 0;
	$conf->{ascii}           //= 1;

	$c->{'dwarf.json'} = JSON->new();
	$c->{'dwarf.json'}->pretty($conf->{pretty});
	$c->{'dwarf.json'}->convert_blessed($conf->{convert_blessed});
	$c->{'dwarf.json'}->ascii($conf->{ascii});

	add_method($c, json => sub {
		my $self = shift;
		if (@_ == 1) {
			$self->{'dwarf.json'} = $_[0];
		}
		return $self->{'dwarf.json'};
	});

	add_method($c, decode_json => sub {
		my ($self, $data) = @_;
		my $decoded = eval { $self->{'dwarf.json'}->decode($data) };

		if ($@) {
			$@ = undef;
			return $data;
		}

		return $decoded;
	});

	add_method($c, encode_json => sub {
		my ($self, $data) = @_;
		my $encoded = eval { $self->{'dwarf.json'}->encode($data) };

		if ($@) {
			$@ = undef;
			return $data;
		}

		# for IE7 JSON venularity.
		# see http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html
		$encoded =~ s!([+<>])!$_ESCAPE{$1}!g;

		return $encoded;
	});

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		return unless ref $res->body;

		if ($res->content_type =~ /(application|text)\/json/) {
			$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $res->body);
			my $encoded = $self->encode_json($res->body);

			my $callback = $self->param('callback');
			if (defined $callback and $callback =~ /^[0-9a-zA-Z_]+$/) {
				$encoded = $callback . "(" . $encoded . ")";
				$res->content_type('text/javascript');
			}
			
			$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$encoded);
			$res->body(encode_utf8($encoded));
		}
	});
}

1;
