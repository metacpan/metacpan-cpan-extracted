package Dwarf::Plugin::Runtime;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Carp;
use Time::HiRes;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	# コマンドラインプログラムの時の振る舞い
	if (defined $conf->{cli} and $conf->{cli} == 0) {
		if ($c->is_cli) {
			return;
		}
	}

	# ランタイム出力を回避（Plugin::MultiConfig と連動）
	if (my $ignore = $conf->{ignore}) {
		if ($c->can('config_name')) {
			if ($c->config_name =~ /$ignore/) {
				return;
			}
		}
	}

	$c->{'dwarf.runtime'} = 1;
	add_method($c, runtime => sub {
		my $self = shift;
		if (@_ == 1) {
			$self->{'dwarf.runtime'} = $_[0];
		}
		return $self->{'dwarf.runtime'};
	});

	my $start;

	$c->add_trigger('BEFORE_DISPATCH' => sub {
		my $self = shift;
		$start = [Time::HiRes::gettimeofday];
	});

	$c->add_trigger('AFTER_DISPATCH' => sub {
		my $self = shift;
		return unless defined $self->handler;
		return unless $self->runtime;

		my $run_time = Time::HiRes::tv_interval($start);
		my $message = "[RUN TIME] " . $self->handler_class . ": " . $run_time;

		if ($self->can('log')) {
			if ($self->can('now')) {
				$message .= sprintf " (%s %s)", $self->now->ymd('/'), $self->now->hms;
			}
			
			$self->log->log(level => 'info', message => $message);
		} else {
			print STDERR $message . "\n";
		}
	});
}

1;
