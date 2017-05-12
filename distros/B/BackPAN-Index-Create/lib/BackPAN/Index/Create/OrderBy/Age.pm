package BackPAN::Index::Create::OrderBy::Age;
$BackPAN::Index::Create::OrderBy::Age::VERSION = '0.13';
use Moo;
use CPAN::DistnameInfo;

has filehandle => (is => 'ro');
has entries    => (is => 'ro', default => sub { return [] });

sub add_file
{
    my $self     = shift;
    my ($path, $time, $size) = @_;
    my $entries  = $self->entries;

    push(@{ $entries }, [$path,$time,$size] );
}

sub finish
{
    my $self    = shift;
    my $entries = $self->entries;
    my $fh      = $self->filehandle;

    foreach my $entry (sort { $a->[1] <=> $b->[1] || $a->[0] cmp $b->[0] }
                            @{ $entries })
    {
        printf $fh "%s %d %d\n", @$entry;
    }
}

1;
