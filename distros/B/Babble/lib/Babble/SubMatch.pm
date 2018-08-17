package Babble::SubMatch;

use Mu;

extends 'Babble::Match';

ro 'parent';
ro 'start';

sub replace_text {
  my ($self, $new_text) = @_;
  $self->replace_substring(0, length($self->text), $new_text);
}

sub transform_text {
  my ($self, $code) = @_;
  local $_ = my $text = $self->text;
  $code->($_);
  if ($_ ne $text) { $self->replace_text($_) }
  return $self;
}

before replace_substring => sub {
  my ($self, $start, $length, $new_text) = @_;
  $self->parent
       ->replace_substring($self->start + $start, $length, $new_text);
};

1;
