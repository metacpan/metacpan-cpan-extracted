package Data::Maker::Field::MultiSet;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.16';

has sets => ( is => 'rw', isa => 'ArrayRef[ArrayRef]' );
has delimiter => ( is => 'rw', isa => 'Str', default => ' ' );

sub generate_value {
  my $this = shift;
  if ($this->sets) {
    my @out;
    for my $set(@{$this->sets}) {
      push(@out, $set->[ rand @{$set} ]);
    }
    return join($this->delimiter, @out);
  }
}
1;

__END__

=head1 NAME 

Data::Maker::Field::MultiSet - A L<Data::Maker> field class that generates its data based on a set of lists of potential values.

=head1 SYNOPSIS 

  use Data::Maker;
  use Data::Maker::Field::MultiSet;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'character',
        class => 'Data::Maker::Field::MultiSet',
        args => {
          sets => [
            [ 'Dasher', 'Dancer', 'Prancer', 'Vixen', 'Comet', 'Cupid', 'Donner', 'Blitzen' ]
            [ 'Dopey', 'Sleepy', 'Grumpy', 'Doc', 'Happy', 'Bashful', 'Sneezy' ]
          ]
        }
      }
    ]
  );

=head1 DESCRIPTION 

Data::Maker::Field::MultiSet takes a single argument, C<sets>, whose value must be an array reference consisting of array references of potential values.

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
