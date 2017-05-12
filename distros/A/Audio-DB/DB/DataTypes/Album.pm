package Audio::DB::DataTypes::Album;

use strict 'vars';
use Audio::DB::Util::Rearrange;
use Audio::DB::DataTypes::Song;  # Needs access to fetch album-wide data contained in songs


# Data accessors for Album objects

sub album    { return shift->{album};    }
sub album_id { return shift->{album_id}; }

sub artists {
  my $self = shift;
  my %seen;
  my @artists = @{$self->{artists}};
  @artists = map {$_->artist} $self->songs unless @artists;
  my @unique = grep {!$seen{$_}++} @artists;
  wantarray ? @unique : (@unique > 1) ? 'various' : $unique[0];
}

sub songs {
  my $self = shift;
  return @{$self->{songs}};
}

# Call in array context to retrievve all unique bitrates
# call in scalar context to retrive predominant bitrate or "various"
# if multiple bitrates exist
sub bitrates {
  my $self = shift;
  my %seen;
  my @bitrates = @{$self->{bitrates}};
  @bitrates = map {$_->bitrate} $self->songs unless @bitrates;
  my @unique = grep {!$seen{$_}++} @bitrates;
  wantarray ? @unique : (@unique > 1) ? 'various' : $unique[0];
}

sub years {
  my $self = shift;
  my %seen;
  my @years = @{$self->{years}};
  @years = map {$_->year} $self->songs unless @years;
  my @unique = grep {!$seen{$_}++} @years;
  wantarray ? @unique : (@unique > 1) ? 'various' : $unique[0];
}

sub songs {
  my $self = shift;
  my @songs = @{$self->{songs}};
  wantarray ? @songs : scalar @songs;
}

# Add a song to the object
sub add_song {
  my ($self,$song) = @_;
  push (@{$self->{songs}},$song);
}

# Add a group of songs to the object
sub add_songs {
  my ($self,$songs) = @_;
  @{$self->{songs}} = @$songs;
}


1;
