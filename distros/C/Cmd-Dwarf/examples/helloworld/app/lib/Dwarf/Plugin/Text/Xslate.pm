package Dwarf::Plugin::Text::Xslate;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method encode_utf8/;
use Dwarf::Util::Xslate qw/reproduce_line_feed/;
use Text::Xslate;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};
	$conf->{path}      ||= [$c->base_dir.'/tmpl'];
	$conf->{cache_dir} ||= $c->base_dir.'/.xslate_cache';
	$conf->{function}  ||=  {
		lf => reproduce_line_feed,
	};

	add_method($c, render => sub {
		my ($self, $template, $vars, $options) = @_;
		$vars    ||= {};
		$options ||= {};

		$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $vars);

		my $tx = Text::Xslate->new(%$conf, %$options);
		my $out = $tx->render($template, $vars);

		$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$out);

		return encode_utf8($out);
	});
}

1;
