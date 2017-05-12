use strict;
use warnings;
package Dancer::Plugin::StatsD;
{
  $Dancer::Plugin::StatsD::VERSION = '0.0001';
}
use Dancer;
use Dancer::Plugin;
use Etsy::StatsD;

# ABSTRACT: Dancer Plugin for StatsD support

my $statsd;

# Create statsd object, or return existing one
sub statsd_obj {
    # Return it if we got it
    return $statsd if $statsd;

    my $config = plugin_setting;
    my $host = $config->{host};
    my $port = $config->{port};
    my $sample_rate = $config->{sample_rate} // 1;

    die "No StatsD Host/Port found!" unless $host && $port;

    return $statsd = Etsy::StatsD->new( $host, $port, $sample_rate );
}

register statsd    => sub { statsd_obj };

register_plugin;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::StatsD - Dancer Plugin for StatsD support

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

L<Dancer::Plugin::StatsD> is a L<Dancer> plugin that lets you log events and
track times using C<StatsD>.

    use Dancer;
    use Dancer::Plugin::StatsD qw( statsd increment decrement update timing );
    use Time::HiRes qw( time );

    hook before_error_renden => sub {
        my ($err) = @_;
        statsd->increment( 'errors.' . $err->code );
    };

    get '/' => sub {
        # Increment the homepage hits counter
        statsd->increment( 'hits.homepage' );

        my $t1 = time;

        # Do something that takes a while

        # Log the time taken in ms
        statsd->timing( 'something.slow', (time - $t1) / 1000 );
    };

    dance;

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
