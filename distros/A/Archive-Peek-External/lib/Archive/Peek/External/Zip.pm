package Archive::Peek::External::Zip;
use Moose;
use IPC::Run3;
extends 'Archive::Peek::External';

sub files {
    my $self = shift;

    my $filename = $self->filename;
    run3 [ 'unzip', '-lqq', $filename ], \undef, \my @out, \undef;
    my @files
        = sort grep { $_ !~ m{/$} } map { ( split '\s+', $_ )[-1] } @out;
    return @files;
}

sub file {
    my ( $self, $filename ) = @_;

    my $archive = $self->filename;
    run3 [ 'unzip', '-pqq', $archive, $filename ], \undef, \my $out, \undef;
    return $out;
}

__PACKAGE__->meta->make_immutable;
