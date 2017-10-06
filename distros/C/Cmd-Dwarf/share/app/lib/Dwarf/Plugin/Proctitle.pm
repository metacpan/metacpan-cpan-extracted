package Dwarf::Plugin::Proctitle;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method load_class/;
use Config;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	$c->add_trigger('BEFORE_DISPATCH' => sub {
		my $self = shift;
		my $controller = $self->route->{controller};
		_proctitle(sprintf "[Dwarf] %s::%s() (%s)", $controller, lc $self->method, $self->base_dir);
	});

	$c->add_trigger('AFTER_DISPATCH' => sub {
		my $self = shift;
		_proctitle(sprintf "[Dwarf] idle (%s)", $self->base_dir);
	});
}

sub _proctitle {
	my ($title) = @_;
	$title ||= $0;
	$0 = $title;
}

1;
