package App::WRT::Util;

use strict;
use warnings;

use Carp;
use Encode;

use base qw(Exporter);
our @EXPORT_OK = qw(dir_list file_put_contents file_get_contents);

=over

=item dir_list($dir, $sort_order, $pattern)

Return a $sort_order sorted list of files matching regex $pattern in a
directory.

Calls $sort_order, which can be one of:

         alpha - alphabetical
 reverse_alpha - alphabetical, reversed
   high_to_low - numeric, high to low
   low_to_high - numeric, low to high

=cut

sub dir_list {
  my ($dir, $sort_order, $pattern) = @_;

  $pattern    ||= qr/^[0-9]{1,2}$/;
  $sort_order ||= 'high_to_low';

  opendir my $list_dir, $dir
    or die "Couldn't open $dir: $!";

  my @files = sort $sort_order
              grep { m/$pattern/ }
              readdir $list_dir;

  closedir $list_dir;

  return @files;
}

# Various named sorts for dir_list:
sub alpha         { $a cmp $b; } # alphabetical
sub high_to_low   { $b <=> $a; } # numeric, high to low
sub low_to_high   { $a <=> $b; } # numberic, low to high
sub reverse_alpha { $b cmp $a; } # alphabetical, reversed

=item file_put_contents($file, $contents)

Write $contents string to $file path.  Because:

L<https://secure.php.net/manual/en/function.file-put-contents.php>

=cut

sub file_put_contents {
  my ($file, $contents) = @_;
  open(my $fh, '>', $file)
    or die "Unable to open $file for writing: $!";
  print $fh $contents;
  close $fh;
}

=item file_get_contents($file)

Get contents string of $file path.  Because:

L<https://secure.php.net/manual/en/function.file-get-contents.php>

=cut

sub file_get_contents {
  my ($file) = @_;

  open my $fh, '<', $file
    or croak "Couldn't open $file: $!\n";

  my $contents;
  {
    # line separator:
    local $/ = undef;
    $contents = <$fh>;
  }

  close $fh or croak "Couldn't close $file: $!";

  # TODO: _May_ want to assume here that any file is UTF-8 text.
  # http://perldoc.perl.org/perlunitut.html
  # return decode('UTF-8', $contents);
  return $contents;
}

=back

1;
