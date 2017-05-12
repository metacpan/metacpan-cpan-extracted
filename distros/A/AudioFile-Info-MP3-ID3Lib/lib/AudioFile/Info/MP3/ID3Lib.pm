package AudioFile::Info::MP3::ID3Lib;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '1.7.3';

use MP3::ID3Lib;

my %data = (artist => 'TPE1',
            title  => 'TIT2',
            album  => 'TALB',
            track  => 'TRCK',
            year   => 'TYER',
            genre  => 'TCON');

sub new {
  my $class = shift;
  my $file = shift;
  my $obj = MP3::ID3Lib->new($file);

  bless { obj => $obj }, $class;
}

sub DESTROY {}

sub AUTOLOAD {
  our $AUTOLOAD;

  my ($pkg, $sub) = $AUTOLOAD =~ /(.+)::(\w+)/;

  die "Invalid attribute $sub" unless exists $data{$sub};

  if ($_[1]) {
    my $attr = $_[1];
    my $found;
    for (@{$_[0]->{obj}->frames}) {
      if($_->code eq $data{$sub}) {
	$found = 1;
	$_->set($attr);
        last;
      }
    }

    $_[0]->{obj}->add_frame($data{$sub}, $attr) unless $found;
    $_[0]->{obj}->commit;
  }

  for (@{$_[0]->{obj}->frames}) {
    return $_->value if $_->code eq $data{$sub};
  }
}


1;
__END__

=head1 NAME

AudioFile::Info::MP3::ID3Lib - Perl extension to get info from MP3 files.

=head1 DESCRIPTION

This is a plugin for AudioFile::Info which uses MP3::ID3Lib to get
data about MP3 files.

See L<AudioFile::Info> for more details.

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::MP3::ID3Lib. Usually called
by AudioFile::Info::new.

=head1 AUTHOR

Dave Cross, E<lt>dave@dave.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
