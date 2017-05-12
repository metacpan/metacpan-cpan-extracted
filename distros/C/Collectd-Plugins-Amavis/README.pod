package Collectd::Plugins::Amavis;

use strict;
use warnings;
use Collectd qw( :all );

use BerkeleyDB;

# ABSTRACT: collectd plugin for reading amavisd-new performance counters
# VERSION

=head1 SYNOPSIS

This is a collectd plugin for reading counters from a amavisd-new server.

In your collectd config:

  <LoadPlugin "perl">
    Globals true
  </LoadPlugin>

  <Plugin "perl">
    BaseName "Collectd::Plugins"
    LoadPlugin "Amavis"

    <Plugin "Amavis">
      # set this if you use an different path
      # db_env "/var/lib/amavis/db"
      # db_file "snmp.db"
    </Plugin>
  </Plugin>

=cut

our $db_env = '/var/lib/amavis/db';
our $db_file = 'snmp.db';

sub amavis_stats_config {
    my ($ci) = @_;
    foreach my $item (@{$ci->{'children'}}) {
        my $key = lc($item->{'key'});
        my $val = $item->{'values'};

        if ($key eq 'db_env' ) {
            $db_env = $val->[0];
        } elsif ($key eq 'db_file' ) {
            $db_file = $val->[0];
        }
    }
    return 1;
}

sub read_amavis_snmp_db {
  my $stats = {};

  my $env = BerkeleyDB::Env->new(
    -Home => $db_env,
    -Flags => DB_INIT_CDB | DB_INIT_MPOOL,
    -ErrFile => \*STDOUT,
    -Verbose => 1
  ) or die "could not open db_env: $!";

  my $db = BerkeleyDB::Hash->new(
    -Filename => $db_file,
    -Env => $env
  ) or die "could not open db: $!";

  my $cursor = $db->db_cursor;

  my ( $key, $val ) = ('','');
  while ( $cursor->c_get($key,$val,DB_NEXT) == 0 ) {
    if( $val !~ s/^(?:C32|C64|INT) //) {
      next;
    }
    $val = int( $val );
    $key =~ s/([a-z])([A-Z])/$1_$2/g;
    $key =~ s/[\.\/\-]/_/g;
    $key = lc( $key );

    if( $key =~ /^(sys|log)/) {
      next;
    }

    $stats->{$key} = $val;
  }
  return $stats;
}

sub amavis_stats_read {
  my $stats = read_amavis_snmp_db();
    
  foreach my $metric (sort keys %$stats) {
    my $vl = {
      plugin => 'amavis',
      plugin_instance => 'snmp',
      type => 'counter',
      type_instance => $metric,
      values => [ $stats->{$metric} ],
    };
    plugin_dispatch_values($vl);
  }
  return 1;
}

plugin_register(TYPE_CONFIG, "Amavis", "amavis_stats_config");
plugin_register(TYPE_READ, "Amavis", "amavis_stats_read");

1;

