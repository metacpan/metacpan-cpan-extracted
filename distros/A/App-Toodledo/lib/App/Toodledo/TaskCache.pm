package App::Toodledo::TaskCache;

use Moose;
use MooseX::Method::Signatures;
use MooseX::ClassAttribute;
use App::Toodledo::Util qw(home);
use YAML qw(LoadFile DumpFile);
with 'MooseX::Log::Log4perl';

our $VERSION = '1.00';

has tasks          => ( is => 'rw', isa => 'ArrayRef[App::Toodledo::Task]',
		        auto_deref => 1 );
has last_updated   => ( is => 'rw', isa => 'Int' );  # Timestamp
class_has Filename => ( is => 'rw', default => '.toodledo_task_cache' );


sub _cache_filename
{
  File::Spec->catfile( home(), __PACKAGE__->Filename );
}


method exists () {
  -s _cache_filename() or return;
  $self->log->debug( "Task cache exists\n" );
}


method fetch () {
  $self->log->debug( "Loading from task cache\n" );
  %$self = LoadFile( _cache_filename() );
  $self->log->debug( "Fetched " . @{ $self->tasks } . " tasks from "
          . _cache_filename() . "\n" );
}


method store ( App::Toodledo::Task @tasks ) {
  $self->last_updated( time );
  $self->tasks( [ @tasks ] );
  $self->log->debug( "Storing " . @tasks ." tasks in " . _cache_filename() . "\n" );
  DumpFile( _cache_filename(), %$self );
}


1;

__END__

=head1 NAME

App::Toodledo::TaskCache - Manage a local cache of Toodledo tasks

=head1 SYNOPSIS

=head1 DESCRIPTION

This is neither fast nor space efficient.  It uses YAML to store the tasks.
This has the advantage of producing a human-readable cache but that's about the
only advantage.  Go ahead and send a patch for SQLite if you can.  That'll
facilitate selective updating of the cache.

=head1 METHODS

=head2 $boolean = $cache->exists

Return true if the cache file exists and is nonempty.

=head2 $cache->fetch

Load the cache from the file.

=head2 $cache->store

Store the cache to the file.

=head1 ATTRIBUTES

=head2 tasks

A hashref of L<App::Toodledo::Task> objects.

=head2 last_updated

Unix time the cache was last written.  Use for comparing with time of
the last operation on the Toodledo server.

=head1 NOTES

Override the routine C<_cache_filename> in this package if you want to
change the filename used for the cache.  It returns the concatenation
of the user's home directory with the class attribute C<Filename>
(default: C<.toodledo_task_cache>).  If you just want to change the
name of the file and keep it in the home directory, override the
C<Filename> attribute (declared with C<class_has> via
L<MooseX::ClassAttribute>).

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
