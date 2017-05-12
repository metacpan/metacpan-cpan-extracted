my (undef, $dir) = app->presentation_file;

my $conf = {
  slides => ['hello', 'goodbye'],
  bootstrap_theme => 1,
  templates => $dir,
};
