package BackPAN::Index::Create::OrderBy::Dist;
$BackPAN::Index::Create::OrderBy::Dist::VERSION = '0.13';
use Moo;
use CPAN::DistnameInfo;

has filehandle => (is => 'ro');
has entries    => (is => 'ro', default => sub { return {} });

sub add_file
{
    my $self     = shift;
    my ($path, $time, $size) = @_;
    my $distinfo = CPAN::DistnameInfo->new($path);
    my $entries  = $self->entries;
    my $distname;

    if (!defined($distinfo) || !defined($distname = $distinfo->dist)) {
        $distname = '';
    }
    push(@{ $entries->{$distname} }, [$path,$time,$size] );
}

sub finish
{
    my $self    = shift;
    my $entries = $self->entries;
    my $fh      = $self->filehandle;

    foreach my $distname (sort { lc($a) cmp lc($b) } keys %$entries) {
        foreach my $entry (sort { $a->[1] <=> $b->[1] }
                                @{ $entries->{$distname} }) {
            printf $fh "%s %d %d\n", @$entry;
        }
    }
}

1;
