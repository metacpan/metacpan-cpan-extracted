package Array::FileReader;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
use IO::File;
use Tie::Array;
use Carp;

@ISA = qw(Tie::Array DynaLoader);

$VERSION = '0.03';

# bootstrap Array::FileReader $VERSION;

sub TIEARRAY {
  my ($class, $file) = @_;
  my $fh = new IO::File;
  $fh->open($file) or croak "Can't open $file: $!";
  my $self = {
          fh => $fh,
          offsets => [0]
         };
  bless $self, $class;
}

sub FETCH {
  my ($self, $elem) = @_;
  if ($elem > $#{$self->{offsets}} ) {
    &_getupto;
  }
  goto &_getit;
}

sub FETCHSIZE {
    my $self= shift;
    return $self->{size} if exists $self->{size};
    seek $self->{fh},0,0;
    _getupto($self,-1);
    return $self->{size} = $#{$self->{offsets}};
}

sub _getupto {
  my ($self, $elem) = @_;
  # Go to end
  my $fh= $self->{fh};
  seek($fh,$self->{offsets}->[-1],0);
  my $out;
  until (eof $fh or $#{$self->{offsets}} == $elem) {
    $out = scalar <$fh>;
    push @{$self->{offsets}}, tell($fh);
  }
  return $out;
}

sub _getit {
  my ($self, $elem) = @_;
  die "ASSERTION FAILED" unless defined $self->{offsets}->[$elem];
  seek $self->{fh}, $self->{offsets}->[$elem],0;
  my $fh = $self->{fh};
  my $out = <$fh>;
  push @{$self->{offsets}}, tell($fh);
  return $out;
}
1;
__END__

=head1 NAME

Array::FileReader - Lazily tie files to arrays for reading

=head1 SYNOPSIS

  use Array::FileReader;
  tie @foo, Array::FileReader, "some.file";
  print $foo[30];

=head1 DESCRIPTION

Plenty of times I've wanted to run up and down a file like this:

    @foo = <FILE>;
    for (0..100) {
        print $foo[$_];
    }
    print $foo[10], $foo[20], $foo[30];

Of course, this is hugely inefficient since you have to load the entire
file into an array in memory. Array::FileReader removes the inefficiency
by only storing the line offsets in memory, and only discovering the
line offsets when a line is called for. For instance, C<$foo[4]> will
only load 4 numbers into memory, and then C<$foo[30]> will load another
26.

Because the file offsets are discovered when needed, there's no good way
of getting the size of the file - you just have to pad through them all,
which is slow.

The module was designed to speed up Mark-Jason Dominus'
L<Algorithm::Diff|Algorithm::Diff> module when finding differences
between two very large files. In fact, it makes things less efficient,
since the first thing that module does is find the size of the arrays.
It just goes to show, doesn't it?

=head1 MAINTAINER

Curtis "Ovid" Poe, E<lt>1napc-pmetsuilbup@yahoo.comE<gt>

Reverse the name to email me.

=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

=head1 SEE ALSO

L<Algorithm::Diff>, L<Tie::MmapArray>

=cut
