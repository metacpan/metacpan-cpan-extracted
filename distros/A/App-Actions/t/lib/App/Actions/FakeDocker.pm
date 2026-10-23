package App::Actions::FakeDocker;

use strict;
use warnings;
use Exporter qw(import);
use File::Spec;

our $VERSION = '0.001.0';
our @EXPORT_OK = qw(split_volume mounts to_host);

# Split a Docker "host:container[:mode]" volume specification.  A Windows host
# path has a colon of its own (C:\Users\...), so the container path must be
# taken from the end rather than from the first colon.  Returns an empty list
# when the specification is not a host:container pair.
sub split_volume {
    my ($value) = @_;

    return unless defined $value && length $value;

    my @parts = split /:/, $value, -1;
    pop @parts if @parts > 1
        && $parts[-1] =~ /^(?:ro|rw|z|Z|delegated|cached|consistent)$/;
    return if @parts < 2;

    my $container = pop @parts;
    return unless $container =~ m{^/};
    return unless length $parts[0];

    return (join(':', @parts), $container);
}

# Collect the mounts from a Docker argument list.
sub mounts {
    my ($args) = @_;

    my %mounts;
    for my $index (0 .. $#$args - 1) {
        next unless $args->[$index] eq '-v' || $args->[$index] eq '--volume';
        my ($host, $container) = split_volume($args->[$index + 1]);
        next unless defined $container;
        $mounts{$container} = $host;
    }

    return \%mounts;
}

# Map a path inside the container to the host path it is mounted from.
sub to_host {
    my ($container_path, $mounts) = @_;

    return undef unless defined $container_path;

    for my $container (sort { length $b <=> length $a } keys %$mounts) {
        next unless index($container_path, $container) == 0;

        my $rest = substr($container_path, length $container);
        my @parts = grep { length } split m{/}, $rest;

        # catfile uses the host's separator, so a Windows mount such as
        # C:\project becomes C:\project\scripts\step-1.sh rather than a mix.
        return File::Spec->catfile($mounts->{$container}, @parts);
    }

    return undef;
}

1;

__END__

=head1 NAME

App::Actions::FakeDocker - path helpers shared by the fake Docker test double

=head1 DESCRIPTION

L<App::Actions::FakeDocker> is part of the test suite.  It contains the pure
path handling that L<t/bin/fake-docker> needs, so that Windows-specific volume
specifications can be tested on any platform.

=head1 FUNCTIONS

=head2 split_volume

    my ($host, $container) = split_volume('C:\project:/github/workspace');

Splits a Docker volume specification into its host and container paths,
ignoring an optional mode such as C<:ro>.

=head2 mounts

    my $mounts = mounts(\@docker_arguments);

Returns a hash reference mapping container paths to host paths.

=head2 to_host

    my $host = to_host('/github/workspace/script.sh', $mounts);

Maps a container path to the host path it is mounted from, using the host's
directory separator.

=cut
