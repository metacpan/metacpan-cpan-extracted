package Collectd::Plugins::RsyslogStats;

use strict;
use warnings;
use Collectd qw( :all );

use File::ReadBackwards;

# ABSTRACT: collectd plugin for reading queue metrics from rsyslog/imstats logfile
our $VERSION = '1.001'; # VERSION


my $types = {
        'enqueued' => 'counter',
        'size' => 'gauge',
        'full' => 'counter',
        'discarded_full' => 'counter',
        'discarded_nf' => 'counter',
        'maxqsize' => 'gauge',
};

our $metrics = [ 'enqueued', 'size' ];
our $prefix = 'rsyslog';
our $path = '/var/log/rsyslog-stats.log';

sub rsyslog_stats_config {
    my ($ci) = @_;
    foreach my $item (@{$ci->{'children'}}) {
        my $key = lc($item->{'key'});
        my $val = $item->{'values'}->[0];

        if ($key eq 'path' ) {
            $path = $val;
        } elsif ($key eq 'prefix' ) {
            $prefix = $val;
        } elsif ($key eq 'metrics') {
            $metrics = [ split(/\s*,\s*/, $val) ];
        }
    }
    return 1;
}

sub read_stats_from_log {
	my $file = File::ReadBackwards->new( $path )
		or die("cant open $path: $!");

	my $stats = {};
	my $max_lines = 200;
	my $count = 0;

	while ( my $line = $file->readline ) {
		chomp($line);
		if( $count >= $max_lines ) {
			return;
		}
		$count++;

		my ($timestamp_str) = $line =~ s/^\S+\s+(\S+\s+\d+\s+\d+:\d+:\d+\s+\d+): //;
		if( ! defined $timestamp_str ) {
			next;
		}
		if( $line !~ s/^(main Q|action \d+ queue[^:]*): // ) {
			next;
		}
		my $queue = $1;
		$queue =~ s/[\s\.]+/-/g;
		if( defined $stats->{$queue} ) {
			last;
		}
		$stats->{$queue} = { map { my $v = $_ ; $v =~ s/[\s\.]+/_/g ; $v } split(/[ =]/, $line) };
	}
	return( $stats );
}

sub rsyslog_stats_read {
	my $stats = read_stats_from_log();

	foreach my $queue_name (keys %$stats) {
		my $queue = $stats->{$queue_name};
		foreach my $metric_name ( keys %$queue ) {
			if( ! grep { $_ eq $metric_name } @$metrics ) {
				next;
			}
			my $vl = {
				plugin => 'rsyslog',
				plugin_instance => $queue_name,
				type => 'counter',
				type_instance => $metric_name,
			};
			if( defined $types->{$metric_name} ) {
				$vl->{'type'} = $types->{$metric_name};
			}
			$vl->{'values'} = [ $queue->{$metric_name} ];
			plugin_dispatch_values($vl);
		}
	}
	return 1;
}

plugin_register(TYPE_CONFIG, "RsyslogStats", "rsyslog_stats_config");
plugin_register(TYPE_READ, "RsyslogStats", "rsyslog_stats_read");

1;


__END__
=pod

=head1 NAME

Collectd::Plugins::RsyslogStats - collectd plugin for reading queue metrics from rsyslog/imstats logfile

=head1 VERSION

version 1.001

=head1 SYNOPSIS

This is a collectd plugin for reading queue metrics from rsyslog/imstats logfile.

In your collectd config:

    <LoadPlugin "perl">
    	Globals true
    </LoadPlugin>

    <Plugin "perl">
      BaseName "Collectd::Plugins"
      LoadPlugin "RsyslogStats"

    	<Plugin "RsyslogStats">
    	  path "/var/log/rsyslog-stats.log"
    	  prefix "rsyslog"
	  metrics "enqueued,size"
    	</Plugin>
    </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

