package App::WRT::FileIO;

use strict;
use warnings;

use Carp;
use Encode;
use File::Copy;
use File::Path qw(make_path);
use Data::Dumper;
use App::WRT::Util;

=pod

=head1 NAME

App::WRT::FileIO - read and write directories and files

=head1 SYNOPSIS

    use App::WRT::FileIO;
    my $io = App::WRT::FileIO->new();

=head1 METHODS

=over

=item new($class)

Get a new FileIO object.

=cut

sub new {
  my $class = shift;

  my %params = (
    last_error => '',
  );

  my $self = \%params;
  bless $self, $class;
}

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
  my $self = shift;
  return App::WRT::Util::dir_list(@_);
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
  my $self = shift;
  App::WRT::Util::file_put_contents(@_);
}


=item file_get_contents($file)

Get contents string of $file path.  Because:

L<https://secure.php.net/manual/en/function.file-get-contents.php>

=cut

sub file_get_contents {
  my $self = shift;
  return App::WRT::Util::file_get_contents(@_);
}


=item file_copy($source, $dest)

=cut

sub file_copy {
  my ($self, $source, $dest) = @_;
  copy($source, $dest);
}


=item dir_make($source, $dest)

=cut

sub dir_make {
  my ($self, $path) = @_;
  my $path_err;
  make_path($path, { error => \$path_err });
  if (@{ $path_err }) {
    $self->{last_error} = Dumper($path_err);
    return 0;
  }
  return 1;
}

=back

=cut

1;
