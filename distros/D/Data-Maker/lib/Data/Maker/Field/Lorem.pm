package Data::Maker::Field::Lorem;
use Moose;
with 'Data::Maker::Field';
use Text::Lorem;

our $VERSION = '0.10';

has words => ( is => 'rw', isa => 'Num' );
has sentences => ( is => 'rw', isa => 'Num' );
has paragraphs => ( is => 'rw', isa => 'Num' );

sub generate_value {
  my $this = shift;
  my $lorem = new Text::Lorem;
  if ($this->words) {
    return $lorem->words($this->words); 
  }
  if ($this->sentences) {
    return $lorem->sentences($this->sentences); 
  }
  if ($this->paragraphs) {
    return $lorem->paragraphs($this->paragraphs); 
  }
}
1;

__END__

=head1 NAME 

Data::Maker::Field::Lorem - A L<Data::Maker> field class that uses L<Text::Lorem> to generate random Latin-looking text, given a number of words, sentences or paragraphs.

=head1 SYNOPSIS 

  use Data::Maker;
  use Data::Maker::Field::Lorem;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'lorem',
        class => 'Data::Maker::Field::Lorem',
        args => {
          words => 4
        }
      }
    ]
  );

=head1 DESCRIPTION 

Data::Maker::Field::Lorem takes any of the following arguments, which are passed directly to Text::Ipsum:

=over 4

=item * B<words>

The number of words to generate

=item * B<sentences>

The number of sentences to generate

=item * B<paragraphs>

The number of paragraphs to generate

=back

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
