package App::WRT::Renderer;

use strict;
use warnings;
use 5.10.0;

use Carp;
use File::Basename;
use Time::HiRes;

=pod

=head1 NAME

App::WRT::Renderer - render a wrt repo to publishable HTML

=head1 SYNOPSIS

    use App::WRT;
    use App::WRT::Renderer;

    my $wrt = App::WRT::new_from_file($config_file);
    my $renderer = App::WRT::Renderer->new(
      $wrt,
      sub { say $_[0]; }
    );

    $renderer->render();

=head1 METHODS

=over

=item new($class, $entry_dir, $logger, $io)

Get a new Renderer.  Takes an instance of App::WRT, a logging callback, and a
App::WRT::FileIO or similar object to be used for the actual intake and
mangling of things on the filesystem.

=cut

sub new {
  my $class = shift;
  my ($wrt, $logger, $io) = @_;

  ref($logger) eq 'CODE' or
    croak("Error: Renderer expects an anonymous function for logging");

  my %params = (
    wrt    => $wrt,
    logger => $logger,
    io     => $io,
  );

  my $self = \%params;
  bless $self, $class;
}


=item write($path, $contents)

Write $contents to $path, using the FileIO object passed into the constructor
above.

=cut

sub write {
  my ($self, $file, $contents) = @_;
  $self->{io}->file_put_contents($file, $contents)
}


=item render($class, $entry_dir)

Render entries to F<publish_dir>.

=cut

sub render {
  my $self = shift;

  my $entry_dir = $self->{wrt}->{entry_dir};
  my $publish_dir = $self->{wrt}->{publish_dir};

  # Use this to log elapsed render time:
  my $start_time = [Time::HiRes::gettimeofday()];

  # Ensure that publication path exists and is a directory:
  if (-e $publish_dir) {
    unless (-d $publish_dir) {
      croak("$publish_dir exists but is not a directory");
    }
  } else {
    $self->log("Attempting to create $publish_dir");
    unless ($self->dir_make_logged($publish_dir)) {
      croak("Could not create $publish_dir");
    }
  }

  # Handle the front page and Atom feed:
  $self->write("${publish_dir}/index.html", $self->{wrt}->display('new'));

  my $feed_alias = $self->{wrt}->{feed_alias};
  my $feed_content = $self->{wrt}->display($feed_alias);
  $self->write("${publish_dir}/${feed_alias}", $feed_content);
  $self->write("${publish_dir}/${feed_alias}.xml", $feed_content);

  # Handle any other paths that aren't derived directly from files:
  my @meta_paths = qw(all);

  my $rendered_count = 0;
  my $copied_count   = 0;
  for my $target ($self->{wrt}->{entries}->all(), @meta_paths)
  {
    # Skip index files - these are the text content of an entry, not
    # a sub-entry:
    next if $target =~ m{/index$};

    # Lowercase and alphanumeric + underscores + dashes, no dots - an entry:
    if ($target =~ $self->{wrt}->{entrypath_expr}) {
      $self->dir_make_logged("$publish_dir/$target");

      my $rendered = $self->{wrt}->display($target);

      my $target_file = "$publish_dir/$target/index.html";
      $self->log("[write] $target_file " . length($rendered));
      $self->write($target_file, $rendered);
      $rendered_count++;
      next;
    }

    # A directory - no-op:
    if (-d "$entry_dir/$target") {
      $self->log("[directory] $entry_dir/$target");
      next;
    }

    # Some other file - a static asset of some kind:
    my $dirname = dirname($target);
    $self->log("[copy] archives/$target -> $publish_dir/$target");
    $self->dir_make_logged("$publish_dir/$dirname");
    $self->{io}->file_copy("$entry_dir/$target", "$publish_dir/$target");
    $copied_count++;
  }

  $self->log("rendered $rendered_count entries");
  $self->log("copied $copied_count static files");
  $self->log(
    "  in "
    . Time::HiRes::tv_interval($start_time)
    . " seconds"
  );

  # Presumed success:
  return 1;
}


=item dir_make_logged($path)

Make a directory path or log an error.

=cut

sub dir_make_logged {
  my ($self, $path) = @_;
  my $path_err;
  $self->log("[create] $path");
  $self->{io}->dir_make($path);
  # XXX: surface these somehow
  # $self->log(Dumper($path_err)) if @{ $path_err };
}


=item log(@log_items)

Call logging callback with passed parameters.

=cut

sub log {
  my ($self) = shift;
  $self->{logger}->(@_);
}

=back

=cut

1;
