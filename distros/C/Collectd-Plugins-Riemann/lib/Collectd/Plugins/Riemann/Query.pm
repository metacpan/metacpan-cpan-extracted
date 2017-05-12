package Collectd::Plugins::Riemann::Query;

use strict;
use warnings;

use Collectd qw( :all );
use Collectd::Plugins::Common qw(recurse_config);
use Riemann::Client;
use Try::Tiny;
#use DDP {
#	deparse => 1,
#	class => {
#		expand => 'all'
#	}
#};

my %opt = (
	Server => "127.0.0.1",
	Port => 5555,
	Protocol => 'TCP',
	Type => 'gauge',
	PluginInstance => '',
	TypeInstance => '',
	PluginFrom => 'plugin',
	PluginInstanceFrom => 'plugin_instance',
	TypeFrom => 'ds_type',
	TypeInstanceFrom => 'type_instance',
);

=head1 NAME

Collectd::Plugins::Riemann::Query - Collectd plugin for querying Riemann Events

=head1 SYNOPSIS

To be used with L<Collectd>.

=over 8

=item From the collectd configfile

 <LoadPlugin "perl">
   Globals true
 </LoadPlugin>

 <Plugin "perl">
   BaseName "Collectd::Plugins"
   LoadPlugin "Riemann::Query"
   <Plugin "Riemann::Query">
     Host     myriemann
     Port     5555
     Protocol TCP
     # Static plugin metadata
     <Plugin foo>
       Query          "tagged \"foo\" and service =~ \"bar%\""
       Plugin         foo
       PluginInstance bar
       Type           gauge
     </Plugin>
     # plugin metadata from riemann attributes
     <Plugin>
       Query              "tagged \"aggregation\""
       PluginFrom         plugin
       PluginInstanceFrom plugin_instance
       TypeFrom           ds_type
       TypeInstanceFrom   type_instance
     </Plugin>
   </Plugin>
 </Plugin>

=back
 
=head1 Root block configuration options

=over 8

=item Host STRING

riemann host to query. defaults to localhost

=item Port STRING

riemann port to query. defaults to 5555

=item Protocol STRING

defaults to TCP

=back

=head1 Plugin block configuration options

=over 8

=item Query STRING

Riemann Query. Mandatory

=item Host STRING

Static host part of collectd plugin. If unset, the host part of the riemann event will be used instead.

=item PluginFrom/TypeFrom/PluginInstanceFrom/TypeInstanceFrom STRING

Dynamic plugin metadata: riemann attribute to be used to set corresponding collectd metadata. service and host are also possible. Defaults to plugin, type, plugin_instance and type_instance respectively.

=item Plugin/Type/PluginInstance/TypeInstance STRING

Will be used instead if no *From counterpart is used or found in riemann event. Can be used as a fallback. Default for Type is gauge and for Plugin is riemann service of the event.

=back

=head1 SUBROUTINES

Please refer to the L<Collectd> documentation.
Or C<man collectd-perl>

=head1 FILES

/etc/collectd.conf
/etc/collectd.d/

=head1 SEE ALSO

Collectd, collectd-perl, collectd

=cut

my $plugin_name = "Riemann::Query";
my $r;

plugin_register(TYPE_CONFIG, $plugin_name, 'my_config');
plugin_register(TYPE_READ, $plugin_name, 'my_get');
plugin_register(TYPE_INIT, $plugin_name, 'my_init');

sub my_init {
	1;
}

sub my_log {
	plugin_log shift @_, join " ", "plugin=".$plugin_name, @_;
}

sub my_config {
	my (undef,$o) = recurse_config($_[0]);
	_validate_config($o) or return;
	%opt = (%opt,%$o);
}

sub my_get {
	unless (ref $r eq "Riemann::Client") {
		my_log(LOG_DEBUG, "get: initializing riemann client");
		$r = Riemann::Client->new(
			host => $opt{Host},
			port => $opt{Port},
			proto => $opt{Protocol},
		)
	}
	my_log(LOG_DEBUG, "get: fetching data");


#$VAR8 = [
#          {
#            'PluginInstance' => 'bar',
#            'Type' => 'gauge',
#            'Query' => 'tagged "foo" and service =~ "bar%"'
#          },
#          {
#            'TypeFrom' => 'ds_type',
#            'PluginInstanceFrom' => 'plugin_instance',
#            'Query' => 'tagged "aggregation"',
#            'TypeInstanceFrom' => 'type_instance',
#            'PluginFrom' => 'plugin'
#          }
#        ];

	my @Plugins;
	if (ref $opt{Plugin} eq "ARRAY") {
		@Plugins = @{$opt{Plugin}}
	} elsif ( ref $opt{Plugin} eq "HASH") {
		@Plugins = ($opt{Plugin})
	} else {
		my_log(LOG_ERR, "get: internal configuration problem: 'Plugin' must be hash or array");
		return
	}
my $pi = -1;
PLUGIN: for my $Plugin (@Plugins) {
	$pi++;
	my $res;
	my $query = $Plugin -> {Query};
	unless (defined $query) {
		my_log(LOG_ERR, "get: no query defined for plugin[$pi]. ignoring");
		next PLUGIN
	}
	try {
		$res = $r -> query($Plugin -> {Query});
	} catch {
		my_log(LOG_ERR, "get: problem fetching data for query `$query`", $_);
		return;
	};
	unless ($res) {
		my_log(LOG_ERR, "get: empty message for query `$query`");
		next PLUGIN
	}
	my $events = $res -> {events};
	unless ($events) {
		my_log(LOG_INFO, "get: query `$query` returned no events");
		next PLUGIN
	}
	unless (ref $events eq "ARRAY") {
		my_log(LOG_ERR, "get: events not array for query `$query`");
		return;
	}
	for my $event (@$events) {
		my $host = $Plugin->{Host} || $event -> {host} || "nil";
		_sanitize($host);
		my %plugin;
		for my $k (qw(Type TypeInstance Plugin PluginInstance)) {
			if (exists($Plugin->{"${k}From"})) { # metadata from riemann
				my $ik = "${k}From";
				my $attr = _get_riemann_attribute($event,$Plugin->{$ik});
				if (defined($attr)) {
					my_log(LOG_DEBUG, "Inferring `$k` using `$ik=$attr` option value for query `$query`.");
					$plugin{_plug2cb($k)} = $attr
				} else {
					my_log(LOG_DEBUG, "Not inferring `$k` using `$ik` option value for query `$query`.");
				}
		  } elsif (exists($Plugin->{$k})) { # static metadata
				my $ik = $k;
				my $v = $Plugin->{$ik};
				my_log(LOG_DEBUG, "Inferring `$k` using `$ik=$v` option value for query `$query`.");
				$plugin{_plug2cb($k)} = $v;
			} elsif (defined($opt{"${k}From"})) {
				my $ik = "${k}From";
				my $attr = _get_riemann_attribute($event,$opt{$ik});
				if (defined($attr)) {
					my_log(LOG_DEBUG, "Inferring `$k` using default `$ik=$attr` option value for query `$query`.");
					$plugin{_plug2cb($k)} = $attr if defined($attr);
				} else {
					my_log(LOG_DEBUG, "Not inferring `$k` using default `$ik` option value for query `$query`.");
				}
			} elsif (defined($opt{$k})) {
				my $ik = $k;
				my $v = $opt{$ik};
				my_log(LOG_DEBUG, "Inferring `$k` using default `$ik=$v` option value for query `$query`.");
				$plugin{_plug2cb($k)} = $v;
			} else {
				my_log(LOG_INFO, "failed to infer `${k}` for query `$query`. Will ignore query results");
				next PLUGIN
			}
		}
		for my $k (qw/Plugin Type/) {
			unless (defined $plugin{_plug2cb($k)}) {
				my_log(LOG_INFO, "Key `$k` is empty for query `$query`. Will ignore query results");
				next PLUGIN
			}
		}
		my $ttl = $event -> {ttl};
		my $interval = plugin_get_interval();
		if ($ttl && $interval gt $ttl) {
			my_log(LOG_INFO, "TTL ($ttl) for event returned by query `$query` is smaller than collectd interval ($interval)");
		}
		my $metric;
		if (exists $event -> {metric_d}) {
			$metric = $event -> {metric_d}
		} elsif (exists $event -> {metric_f}) {
			$metric = $event -> {metric_f}
		} elsif (exists $event -> {metric_sint64}) {
			$metric = $event -> {metric_sint64}
		} else {
			my $p_s = join(',',%plugin);
			my_log(LOG_INFO, "get: event `$p_s` for query `$query` has no metric: ignoring");
			next PLUGIN
		}
		_dispatch($host,\%plugin,$metric);
	}
}
	1;
}

sub _validate_config {
	my $o = shift;
	unless (exists($o->{Plugin})) {
		my_log(LOG_ERR, "missing 'Plugin' block in configuration");
		return
	}
	
}

sub _sanitize ($) {
	map { s/ /_/g } @_;
}

sub _get_riemann_attribute ($$) {
	my ($evt, $key) = @_;
	unless ($evt -> isa('Event')) {
		my_log(LOG_ERR, "_get_riemann_attribute event is garbled");
		return
	}
	unless ($key) {
		my_log(LOG_ERR, "_get_riemann_attribute arg2 empty");
		return
	}
	if ($key eq 'service' or $key eq 'host') {
		return $evt -> {$key};
	} else {
		my $attributes = $evt -> {attributes};
		if ($attributes && ref $attributes eq "ARRAY") {
			for my $attr (@$attributes) {
				if ($attr -> {key} eq $key) {
					return $attr -> {value}
				}
			}
		} else {
			my_log(LOG_DEBUG, "_get_riemann_attribute no attributes for event");
		}
		my_log(LOG_DEBUG, "_get_riemann_attribute attribute `$key` not found for event");
	}
	return
}

sub _dispatch ($$$) {
	my $host = shift;
	my $p = shift;
	my %plugin = %$p;
	my $metric = shift;
	$plugin{host} = $host;
	$plugin{values} = [ $metric ];
	my $ret = plugin_dispatch_values(\%plugin);
	unless ($ret) {
		my $p_s = join(',',%plugin);
		my_log(LOG_INFO, "dispatch error: `$p_s`") unless ($ret);
	}
	return $ret;
}

sub _plug2cb {
	my $p = shift;
	my %plugin_cb_mapping = (
		Plugin => 'plugin',
		PluginInstance => 'plugin_instance',
		Type => 'type',
		TypeInstance => 'type_instance'
	);
	if (exists($plugin_cb_mapping{$p})) {
		$plugin_cb_mapping{$p};
	} else {
		undef
	}
}

1;

