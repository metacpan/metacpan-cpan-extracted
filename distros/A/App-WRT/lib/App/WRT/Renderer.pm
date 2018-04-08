package App::WRT::Renderer;

use strict;
use warnings;
use 5.10.0;

use base qw(Exporter);
our @EXPORT_OK = qw(render);

use App::WRT::Util qw(file_put_contents);
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Time::HiRes;

sub render {
  # This is invoked off of an App::WRT object, so it's passing in $self:
  my ($wrt) = shift;

  # Expects a callback to be used to log (or print) rendering diagnostics:
  my ($logger) = @_;
  ref($logger) eq 'CODE' or
    die "Error: render() expects an anonymous function $!";

  my $entry_dir = $wrt->entry_dir;
  my $publish_dir = $wrt->publish_dir;

  # Use this to log elapsed render time:
  my $start_time = [Time::HiRes::gettimeofday()];

  # Insure that publication path exists and is a directory:
  if (-e $publish_dir) {
    unless (-d $publish_dir) {
      die("$publish_dir exists but is not a directory");
    }
  } else {
    my $path_err;
    make_path($publish_dir, { error => \$path_err });
    $logger->("Attempting to create $publish_dir");
    if (@{ $path_err }) {
      $logger->(Dumper($path_err));
      die("Could not create $publish_dir: " . Dumper($path_err));
    }
  }

  # Handle the front page and Atom feed:
  file_put_contents("${publish_dir}/index.html", $wrt->display('new'));

  my $feed_alias = $wrt->feed_alias;
  my $feed_content = $wrt->display($feed_alias);
  file_put_contents("${publish_dir}/${feed_alias}", $feed_content);
  file_put_contents("${publish_dir}/${feed_alias}.xml", $feed_content);

  # Handle any other paths that aren't derived direct from files:
  my @meta_paths = qw(all);

  my $rendered_count = 0;
  my $copied_count   = 0;
  for my $target ($wrt->get_all_source_files(), @meta_paths)
  {
    my $path_err;

    # Lowercase and alpanumeric + underscores + dashes, no dots - an entry:
    if ($target =~ $wrt->entrypath_expr) {
      make_path("${publish_dir}/$target", { error => \$path_err });
      $logger->(Dumper($path_err)) if @{ $path_err };

      my $rendered = $wrt->display($target);

      my $target_file = "${publish_dir}/$target/index.html";
      $logger->("[write] $target_file " . length($rendered));
      file_put_contents($target_file, $rendered);
      $rendered_count++;
      next;
    }

    # A directory - no-op:
    if (-d "$entry_dir/$target") {
      $logger->("[directory] $entry_dir/$target");
      next;
    }

    # Some other file - a static asset of some kind:
    my $dirname = dirname($target);
    $logger->("[copy] archives/$target -> ${publish_dir}/$target");
    make_path("public/$dirname", { error => \$path_err });
    $logger->(Dumper($path_err)) if @{ $path_err };
    copy("$entry_dir/$target", "${publish_dir}/$target");
    $copied_count++;
  }

  $logger->("rendered $rendered_count entries");
  $logger->("copied $copied_count static files");
  $logger->(
    "  in "
    . Time::HiRes::tv_interval($start_time)
    . " seconds"
  );

  # Presumed success:
  return 1;
}
