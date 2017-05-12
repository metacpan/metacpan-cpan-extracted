=head1 NAME

Data::Downloader::Linktree -- a tree of symlinks

=head1 DESCRIPTION

A linktree is a tree of symlinks to files in the data store.

A linktree has a condition (a serialized L<SQL::Abstract|SQL::Abstract> clause):
the metadata of a file must satisfy this condition in order for
the file to be in this linktree.  It also has a template and a
root.  The path of a symlink in a linktree is determined by filling
the metadata for the file into the template, and prepending the root.

=head1 EXAMPLE

 my $linktree = Data::Downloader::Linktree->new(
    repository => $mine,
    condition => q[ esdt => "OMTO3" ],
    root => "/download/files/omi",
    path_template => "<archiveset>/<esdt>/<starttime:%Y/%m/%d>", );


=head1 METHODS

=over

=cut

package Data::Downloader::Linktree;
use Log::Log4perl qw/:easy/;
use Params::Validate qw/validate/;
use if $Data::Downloader::useProgressBars, "Smart::Comments";
use strict;
use warnings;

=item rebuild

Rebuild all the links in this tree.

Removes all the files, then iterate over all the files
which meet the condition for this linktree, and adds
symlinks, using the metadata for the file.

=cut

sub rebuild {
    my $self = shift;
    my $args = validate(@_, { progress_bar => 0 });

    TRACE "removing old symlinks";
    # remove all existing symlinks
    my @symlinks = $self->symlinks;
    for (@symlinks) {  ### Removing old symlinks [===%           ]
        TRACE "removing ".$_->linkname;
        -l $_->linkname or do {
            DEBUG "symlink " . $_->linkname . " is gone, flushing";
            $_->delete;
            next;
        };
        unlink $_->linkname or do { WARN "unlink failed : $!"; next; };
        $_->delete;
    }

    # add them back
    TRACE "Adding symlinks";
    my %condition = defined($self->condition) ? %{ eval $self->condition } : ();
    LOGDIE "error parsing condition '@{[ $self->condition ]}' : $@" if $@;
    $condition{on_disk} = 1;
    $condition{repository} = $self->repository;
    my $manager = "Data::Downloader::File::Manager";
    TRACE "getting count";
    # This is memory intensive, but an iterator would lock the db for longer.
    my $files = $manager->get_files( query => [%condition], require_objects => ['file_metadata']);
    for my $file (@$files) { ### Adding new symlinks [===%       ]
        DEBUG "making symlink for ".$file->filename;
        $file->decorate_tree(tree => $self);
    }
}

=back

=head1 SEE ALSO

L<Rose::DB::Object>

L<Data::Downloader/SCHEMA>

=cut


1;

