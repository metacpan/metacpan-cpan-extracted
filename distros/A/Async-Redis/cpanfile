# Runtime dependencies
requires 'perl', '5.018';
requires 'Future', '0.49';
requires 'Future::AsyncAwait', '0.66';
requires 'Future::IO', '0.23';
requires 'Protocol::Redis';
requires 'IO::Socket::INET';
requires 'Socket';
requires 'Time::HiRes';
requires 'Digest::SHA';

# Optional dependencies (for performance/features)
recommends 'Protocol::Redis::XS';  # Faster RESP parsing
recommends 'IO::Socket::SSL';      # TLS support
suggests 'OpenTelemetry::SDK';     # Observability integration

# Test dependencies
on 'test' => sub {
    requires 'Test2::V0';
    requires 'Test::Lib';
};

# Development dependencies
on 'develop' => sub {
    requires 'Dist::Zilla';
};
