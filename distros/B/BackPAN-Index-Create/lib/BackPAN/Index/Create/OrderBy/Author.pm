package BackPAN::Index::Create::OrderBy::Author;
$BackPAN::Index::Create::OrderBy::Author::VERSION = '0.13';
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
    my $author;

    if (!defined($distinfo) || !defined($author = $distinfo->cpanid)) {
        $author = '';
    }
    push(@{ $entries->{$author} }, [$path,$time,$size] );
}

sub finish
{
    my $self    = shift;
    my $entries = $self->entries;
    my $fh      = $self->filehandle;

    foreach my $author (sort { lc($a) cmp lc($b) } keys %$entries) {
        foreach my $entry (sort { $a->[1] <=> $b->[1] }
                                @{ $entries->{$author} }) {
            printf $fh "%s %d %d\n", @$entry;
        }
    }
}

1;
