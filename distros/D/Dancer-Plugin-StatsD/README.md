# NAME

Dancer::Plugin::StatsD - Dancer Plugin for StatsD support

# VERSION

version 0.0001

# SYNOPSIS

[Dancer::Plugin::StatsD](https://metacpan.org/pod/Dancer::Plugin::StatsD) is a [Dancer](https://metacpan.org/pod/Dancer) plugin that lets you log events and
track times using `StatsD`.

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

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
