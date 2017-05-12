package App::CSE::Command::Update;
$App::CSE::Command::Update::VERSION = '0.012';
use Moose;
extends qw/App::CSE::Command/;

use App::CSE::Command::Check;
use App::CSE::Command::Index;
use App::CSE::File;

use File::MimeInfo::Magic;


use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub execute{
  my ($self) = @_;

  my $colorizer = $self->cse()->colorizer();

  my $colored = sub{ $colorizer->colored(@_);};

  # Check the index.
  # Re-index if nothing is there.
  my $check = App::CSE::Command::Check->new({ cse => $self->cse() });
  if( $check->execute() ){
    $LOGGER->info(&$colored("Rebuilding the index..", 'green bold'));
    my $index_cmd = App::CSE::Command::Index->new( { cse => $self->cse() });
    if( $index_cmd->execute() ){
      $LOGGER->error(&$colored("Building index failed", 'red'));
      return 1;
    }
    # Nothing else to do.
    return 0;
  }

  # Right time to reindex dirty files.
  my @dirty_files = sort keys %{$self->cse->dirty_files()};
  unless( @dirty_files ){
    $LOGGER->info(&$colored("No dirty files", 'green bold'));
    return 0;
  }

  # Build an indexer.
  my $searcher = Lucy::Search::IndexSearcher->new( index => $self->cse()->index_dir().'' );
  my $indexer =  Lucy::Index::Indexer->new( schema => $searcher->get_schema(),
                                            index => $self->cse()->index_dir().'' );

  my $NFILES = 0;
  foreach my $dirty_file ( @dirty_files ){
    $indexer->delete_by_term( field => 'path.raw',
                              term => $dirty_file );
    my $mime_type = File::MimeInfo::Magic::mimetype($dirty_file.'') || 'application/octet-stream';
    my $file_class = App::CSE::File->class_for_mime($mime_type, $dirty_file.'');
    unless( $file_class ){
      next;
    }

    ## Build a file instance.
    my $file = $file_class->new({cse => $self->cse(),
                                 mime_type => $mime_type,
                                 file_path => $dirty_file.'' })->effective_object();

    $LOGGER->info("Reindexing file $dirty_file as ".$file->mime_type());
    # And index it
    my $content = $file->content();
    $indexer->add_doc({
                       path => $file->file_path(),
                       'path.raw' => $file->file_path(),
                       dir => $file->dir(),
                       mime => $file->mime_type(),
                       mtime => $file->mtime->iso8601(),
                       $content ? ( content => $content ) : ()
                      });
    # Remove from the dirty files hash
    delete $self->cse()->dirty_files()->{$dirty_file};
    $NFILES++;
  }

  # Commit and save that.
  $indexer->commit();
  $self->cse()->save_dirty_files();
  $LOGGER->info(&$colored('Re-indexed '.$NFILES.' files' ,'green bold'));
  return 0;
}

__PACKAGE__->meta->make_immutable();
