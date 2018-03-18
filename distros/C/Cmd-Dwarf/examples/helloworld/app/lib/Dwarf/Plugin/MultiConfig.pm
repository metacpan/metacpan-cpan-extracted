package Dwarf::Plugin::MultiConfig;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method load_class/;
use Sys::Hostname;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $production   = $conf->{production}  || 'production';
	my $developments = $conf->{development} || {};

	add_method($c, hostname => sub {
		Sys::Hostname::hostname();
	});

	add_method($c, config_name => sub {
		my $self = shift;

		$self->{'dwarf.config'} ||= do {
			my $name = $production;
			my @def = @$developments;

			for (my $i = 0; $i < @def; $i = $i + 2) {
				my $key = $def[$i];
				my $value = $def[$i + 1];

				my ($host, $dir);
				if (ref $value eq 'HASH') {
					$host = $value->{host};
					$dir  = $value->{dir};
				} else {
					$host = $value;
				}

				if ($self->hostname =~ /$host/) {
					if ($dir) {
						if ($self->base_dir =~ /$dir/) {
							$name = $key;
							last;
						}
					} else {
						$name = $key;
						last;
					}
				}
			}

			$name;
		};
	});

	add_method($c, is_production => sub {
		shift->config_name eq $production;
	});
}

1;
