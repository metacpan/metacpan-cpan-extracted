package Bio::Gonzales::Util::Role::FileIO;

use warnings;
use strict;

use Mouse::Role;
use Data::Dumper;
use Bio::Gonzales::Util::File qw/open_on_demand/;
use Carp;
use IO::Handle;
use IO::Zlib;

our $VERSION = '0.0546'; # VERSION

has fh              => ( is => 'rw' );
has mode            => ( is => 'rw', default => '<' );
has _fhi            => ( is => 'rw', lazy_build => 1 );
has _cached_records => ( is => 'rw', default => sub { [] } );
has record_separator => ( is => 'rw', default => $/ );
has record_filter    => ( is => 'rw' );
has _fh_was_open     => ( is => 'rw', default => 1 );

requires 'BUILDARGS';

# file handle iterator
sub _build__fhi {
  my ($self) = @_;

  my $fh = $self->fh;

  my $rs     = $self->record_separator;
  my $filter = $self->record_filter;

  return sub {
    # make use of cached records if we have
    return shift @{ $self->_cached_records }
      if ( @{ $self->_cached_records } > 0 );

    local $/ = $rs;

    while (1) {
      my $l = <$fh>;
      if ( defined($l) ) {
        $l =~ s/\r\n/\n/;
        chomp $l;
      } else {
        return;
      }

      return $l
        if ( !$filter || ( $filter && $filter->($l) ) );
    }
  };
}

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig( file => $_[0] );
  } else {
    return $class->$orig(@_);
  }
};

sub BUILD { }

before BUILD => sub {
  my ( $self, $args ) = @_;

  confess "use either file, fh or file_or_fh" . Dumper $args
    if ( $self->fh && $args->{file} );

  # open file
  if ( $args->{file} ) {
    $self->fh( scalar open_on_demand( $args->{file}, $self->mode ) );
    $self->_fh_was_open(0);
  } elsif ( $args->{file_or_fh} ) {
    my ( $fh, $was_open ) = open_on_demand( $args->{file_or_fh}, $self->mode );
    $self->fh($fh);
    $self->_fh_was_open($was_open);
  } else {
    confess "You did not supply a file handle for fh: " . ref $self->fh
      unless ( Bio::Gonzales::Util::File::is_fh( $self->fh ) );
  }
};

sub close {
  my ($self) = @_;

  my $fh = $self->fh;
  $fh->close unless ( $self->_fh_was_open );

  return;
}

1;

__END__

=head1 NAME

BaMo::Role::FileIO - File input & ouput interface for parser classes

=head1 SYNOPSIS

    use Mouse;

    with 'BaMo::Role::FileIO';

    sub parse {
        my ($self) = @_;
        $fhi = $self->_fhi;

        while(my $line = $fhi->()) {
            #parse a bit
            if($line =~ /break/) {
                # oh no, we parsed too much...
                push @{$self->_cached_records}, $line;
                #but we can reverse it
            }
        }
    }

=head1 DESCRIPTION

Enhances the class that uses this role with a file handle iterator that is
capable of caching records (lines in most cases), in case you read too much.

=head1 METHODS

=over 4

=item B<< $self->fh() >>

Get or set the filehandle.

=item B<< $self->_cached_records() >>

You can push lines on @{$self->_cached_records} (they need to be chomped
already). The file handle iterator will use them first if you call it. The
file handle will not be touched until all cached lines are shifted.

=item B<< $class->new(file => 'filename.xyz', mode => '<') >>

Opens the file in the specified mode. Sets the C<fh> and C<_fhi> attribute (indirectly).

=item B<< $self->_fhi() >>

Get the file handle iterator.

=item B<< $class->new(fh => $fh) >>

=item B<< $self->close() >>

Close the filehandle.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
