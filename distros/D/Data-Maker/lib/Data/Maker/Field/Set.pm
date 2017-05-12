package Data::Maker::Field::Set;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.10';

has set => ( is => 'rw', isa => 'ArrayRef' );

sub generate_value {
  my $this = shift;
  if ($this->set) {
    return $this->set->[ rand @{$this->set} ];
  }
}
1;

__END__

=head1 NAME 

Data::Maker::Field::Set - A L<Data::Maker> field class that generates its data based on a list of potential values.

=head1 SYNOPSIS 

  use Data::Maker;
  use Data::Maker::Field::Set;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'reindeer',
        class => 'Data::Maker::Field::Set',
        args => {
          set => [ 'Dasher', 'Dancer', 'Prancer', 'Vixen', 'Comet', 'Cupid', 'Donner', 'Blitzen' ]
        }
      }
    ]
  );

=head1 DESCRIPTION 

Data::Maker::Field::Set takes a single argument, C<set>, whose value must be an array reference of potential values.

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
