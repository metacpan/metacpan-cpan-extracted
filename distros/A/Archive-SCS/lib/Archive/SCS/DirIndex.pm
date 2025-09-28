use v5.28;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::DirIndex 1.09;

field $dirs  :param = [];
field $files :param = [];

method dirs () { $dirs->@* }
method files () { $files->@* }


my $dirname_basename = qr{
  \A((?:    # dirname components, starting from beginning of string
    /?        # beginning with a path separator, if any
    .+?       # minimal match
    (?=/)     # ending before the next separator
  )*+)      # stingy match of zero or more dirname components
  /?        # drop the last path separator, if any
  (.*)      # basename
}xx;

# Create DirIndex objects for the entire directory hierarchy described by
# the given list of file paths (and optional dir paths, for empty subdirs).
# Takes array refs, returns hash ref.
method auto_index :common ($files, $dirs = []) {
  my %index;
  my %dirs;

  for my $file ($files->@*) {
    my ($parent, $name) = $file =~ $dirname_basename;

    $index{$parent}{files}{$name} = 1;
    length $parent and $dirs{$parent} = 1;
  }

  # Performance optimization: Gather parent dirs above in hash instead of array
  # because there is a very large amount of duplicates
  my @dirs = ($dirs->@*, keys %dirs);

  while (defined (my $dir = shift @dirs)) {
    my ($parent, $name) = $dir =~ $dirname_basename;

    # Performance optimization: Don't add dir to queue if we've got it already
    exists $index{$dir} && exists $index{$parent}{dirs}{$name} and next;

    # Add index for empty dirs
    $index{$dir} //= {};

    $index{$parent}{dirs}{$name} = 1;
    length $parent and push @dirs, $parent;
  }

  $index{$_} = Archive::SCS::DirIndex->new(
    dirs  => [ sort keys $index{$_}{dirs }->%* ],
    files => [ sort keys $index{$_}{files}->%* ],
  ) for keys %index;

  return \%index;
}

1;
