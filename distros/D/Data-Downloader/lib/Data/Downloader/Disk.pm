=head1 NAME

Data::Downloader::Disk

=head1 DESCRIPTION

Represents a disk for storing files.

=cut

package Data::Downloader::Disk;
use Log::Log4perl qw/:easy/;
use Filesys::Df qw/df/;
use Params::Validate qw/validate/;
use Data::Downloader::Utils qw/human_size/;
use strict;
use warnings;

=head1 METHODS

=over

=item abs_path

Returns the absolute path of this disk.

=cut

sub abs_path {
    my $self = shift;
    my $path = join '/', $self->repository_obj->storage_root, $self->root;
    $path =~ s[/+][/]g;
    return $path;
}

=item blocks_available

Find the # of blocks available using df.

Parameters : block_size (default 1024)

=cut

sub blocks_available {
    my $self = shift;
    my $args = validate(@_, { block_size => {default => '1024'} });
    my $path = $self->abs_path;
    my $r = df($path, $args->{blocksize});
    while (!defined($r) && $path =~ s|/[^/]*$||) {
        # look up the tree if necessary, dirs may not yet exist
        $r = df($path, $args->{blocksize});
    }
    LOGDIE "couldn't df $path : $!" unless defined($r);
    TRACE "$r->{bavail} blocks available in $path";
    return $r->{bavail};
}

=item bytes_taken

Find the number of bytes taken by data downloader (i.e.
the sum of the sizes of the files on disk.

=cut

sub bytes_taken {
    my $self = shift;

    my ($taken) = $self->db->simple->select( 'file', 'sum(size)',
         { on_disk => 1, disk => $self->id } )->list;
    $taken ||= 0;
    TRACE "disk ".$self->root." has taken $taken bytes";
    return $taken;
}


=item usage

When called as a class method, prints the usage across all
disks.  When called as an instance method, prints the usage
for this particular disk.

Note that this is not the _actual_ usage (as reported by "du")
but rather the sum of the sizes of the files.

=cut

sub usage {
    my $self = shift;
    my $args = validate(@_, { summary => 0, human => 0 } );

    if (ref $self) {
        print $self->bytes_taken, "\n";
        return;
    }

    my $class = $self; # (since ref $obj is false)

    if ( $args->{summary} ) {
        my ($sum) =
          Data::Downloader::DB->new()
          ->simple->select( 'file', ['sum(size)'], { on_disk => 1 } )
          ->list;
        print( $args->{human} ? human_size($sum) : ($sum || 0) );
        print "\n";
        return;
    }

    my $manager = $class."::Manager";
    my $iterator = $manager->get_disks_iterator;
    while ( my $disk = $iterator->next ) {
        printf( "%-15s %s\n",
           ($args->{human} ? human_size( $disk->bytes_taken ) : $disk->bytes_taken),
            $disk->root );
    }
    my ($no_disk) =
        Data::Downloader::DB->new()
        ->simple->select( 'file', ['sum(size)'], { on_disk => 1, disk => undef } )
        ->list;
    return unless $no_disk;
    printf( "%-15s %s\n", ($args->{human} ? human_size( $no_disk ) : $no_disk), "(no disk)");

}


=back

=head1 SEE ALSO

L<Data::Downloader/SCHEMA>

=cut

1;
