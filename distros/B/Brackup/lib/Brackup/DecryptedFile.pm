package Brackup::DecryptedFile;

use strict;
use warnings;
use Carp qw(croak);
use Brackup::Decrypt;

sub new {
  my ($class, %opts) = @_;
  my $self = bless {}, $class;

  $self->{original_file} = delete $opts{filename};    # filename we're restoring from

  die "File $self->{original_file} does not exist"
        unless $self->{original_file} && -f $self->{original_file};
  croak("Unknown options: " . join(', ', keys %opts)) if %opts;

  # decrypted_file might be undef if no decryption was needed.
  $self->{decrypted_file} = Brackup::Decrypt::decrypt_file_if_needed($self->{original_file});

  return $self;
}

sub name {
    my $self = shift;
    return $self->{decrypted_file} || $self->{original_file};
}

sub DESTROY {
    my $self = shift;
    unlink(grep { $_ } ($self->{decrypted_file}));
}

1;
