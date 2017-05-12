package Archive::Peek::External::Tar;
use Moose;
use IPC::Run3;
extends 'Archive::Peek::External';

sub files {
    my $self = shift;

    my $filename = $self->filename;
    run3 [ 'tar', 'ft', $filename ], \undef, \my $out, \undef;
    my @files = sort grep { $_ !~ m{/$} } split $/, $out;
    return @files;
}

sub file {
    my ( $self, $filename ) = @_;

    my $archive = $self->filename;
    run3 [ 'tar', 'fxO', $archive, $filename ], \undef, \my $out, \undef;
    return $out;
}

__PACKAGE__->meta->make_immutable;
