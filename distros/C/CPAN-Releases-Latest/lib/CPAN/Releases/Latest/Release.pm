package CPAN::Releases::Latest::Release;
$CPAN::Releases::Latest::Release::VERSION = '0.08';
use 5.006;
use Moo;
use CPAN::DistnameInfo;

has 'distname'  => (is => 'ro');
has 'path'      => (is => 'ro');
has 'timestamp' => (is => 'ro');
has 'size'      => (is => 'ro');
has 'distinfo'  => (is => 'lazy');

sub _build_distinfo
{
    my $self = shift;

    return CPAN::DistnameInfo->new($self->path);
}

1;
