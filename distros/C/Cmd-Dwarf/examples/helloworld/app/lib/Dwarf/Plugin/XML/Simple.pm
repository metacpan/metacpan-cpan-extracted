package Dwarf::Plugin::XML::Simple;
use Dwarf::Pragma;
use Dwarf::Util qw/encode_utf8 add_method/;
use XML::Simple;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	$c->{'dwarf.xml'} = XML::Simple->new(%$conf);

	add_method($c, xml => sub {
		my $self = shift;
		if (@_ == 1) {
			$self->{'dwarf.xml'} = $_[0];
		}
		return $self->{'dwarf.xml'};
	});

	add_method($c, decode_xml => sub {
		my ($self, $data, @opts) = @_;
		return $self->{'dwarf.xml'}->XMLin($data, @opts);
	});

	add_method($c, encode_xml => sub {
		my ($self, $data, @opts) = @_;
		return $self->{'dwarf.xml'}->XMLout($data, @opts);
	});

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		return unless ref $res->body;

		if ($res->content_type =~ /(application|text)\/xml/) {
			$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $res->body);
			my $encoded = $self->encode_xml($res->body);
			$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$encoded);
			$res->body(encode_utf8($encoded));
		}
	});
}

1;
