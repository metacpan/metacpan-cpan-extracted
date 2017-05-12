package CPAN::Releases::Latest::DistributionIterator;
$CPAN::Releases::Latest::DistributionIterator::VERSION = '0.08';
use 5.006;
use Moo;
use CPAN::Releases::Latest;
use CPAN::Releases::Latest::Distribution;
use CPAN::Releases::Latest::Release;

has 'latest' =>
    (
        is      => 'ro',
        default => sub { CPAN::Releases::Latest->new() },
    );

has _fh               => (is => 'rw');
has _previous_release => (is => 'rw', clearer => 1);

sub next_distribution
{
    my $self = shift;
    my $previous_release;

    $previous_release = $self->_previous_release();
    if (   defined($previous_release)
        && $previous_release->distinfo->maturity eq 'developer') {
        $self->_clear_previous_release();
        return _single_release_distribution($previous_release);
    }

    my $release = $self->_next_release();
    if (defined($release)) {
        if (defined($previous_release)) {
            return $self->_dist_from_two_releases($previous_release, $release);
        }
        elsif ($release->distinfo->maturity eq 'developer') {
            return _single_release_distribution($release);
        } else {
            my $next_release = $self->_next_release();
            return $self->_dist_from_two_releases($release, $next_release);
        }
    }
    elsif (defined($previous_release)) {
        $self->_clear_previous_release();
        return _single_release_distribution($previous_release);
    }
    else {
        return undef;
    }

}

sub _dist_from_two_releases
{
    my $self           = shift;
    my $first_release  = shift;
    my $second_release = shift;

    if ($first_release->distname eq $second_release->distname) {
        $self->_clear_previous_release();
        return CPAN::Releases::Latest::Distribution->new(
                   distname          => $first_release->distname,
                   release           => $first_release,
                   developer_release => $second_release,
               );
    }
    else {
        $self->_previous_release($second_release);
        return _single_release_distribution($first_release);
    }
}

sub _next_release
{
    my $self = shift;
    my $fh;

    if (not defined($fh = $self->_fh)) {
        $fh = $self->latest->_open_file();
        $self->_fh($fh);
    }

    my $line = <$fh>;

    if (defined($line)) {
        chomp($line);
        my ($distname, $path, $time, $size) = split(/\s+/, $line);
        return CPAN::Releases::Latest::Release->new(
                       distname  => $distname,
                       path      => $path,
                       timestamp => $time,
                       size      => $size,
                   );
    }
    else {
        return undef;
    }

}

sub _single_release_distribution
{
    my $release = shift;
    my @args    = (distname => $release->distinfo->dist);

    if ($release->distinfo->maturity eq 'developer') {
        push(@args, developer_release => $release);
    }
    else {
        push(@args, release => $release);
    }
    return CPAN::Releases::Latest::Distribution->new(@args);
}

1;
