package DataStruct::Flat;
  use Moo;
  our $VERSION = '0.01';

  sub flatten {
    my ($self, $struct) = @_;

    my $result = {};
    _flatten($struct, undef, $result);
    return $result;
  }

  sub _flatten {
    my ($struct, $prefix, $result) = @_;

    if (ref($struct) eq 'HASH') {
      foreach my $key (keys %$struct) {
        my $local_prefix = (defined $prefix) ? "$prefix." : "";
        my $key_in_result = $key;
        $key_in_result =~ s/\./\\./g;
        _flatten($struct->{ $key }, "$local_prefix$key_in_result", $result);
      }
    } elsif (ref($struct) eq 'ARRAY') {
      my $i = 0;
      foreach my $element (@$struct) {
        my $local_prefix = (defined $prefix) ? "$prefix." : ""; 
        _flatten($element, "$local_prefix$i", $result);
        $i++;
      }
    } else {
      my $local_prefix = (defined $prefix) ? $prefix : '';
      $result->{ $prefix } = $struct;
    }
  }
1;

#################### main pod documentation begin ###################

=head1 NAME

DataStruct::Flat - Convert a data structure into a one level list of keys and values

=head1 SYNOPSIS

  use DataStruct::Flat;

  my $flattener = DataStruct::Flat->new;

  my $flat = $flattener->flatten({
    a => [ 7, 8, 9, 10 ],
    b => { c => d },
  });

  # $flat = {
  #   'a.0' => 7,
  #   'a.1' => 8,
  #   'a.2' => 9,
  #   'a.3' => 10,
  #   'b.c' => 'd'
  # };

=head1 DESCRIPTION

This module converts a nested Perl data structure into a one level hash of keys and values
apt for human consumption.

=head1 METHODS

=head2 new

Constructor. Initializes the flattener object

=head2 flatten($struct)

Returns a hashref for $struct which contains keys with dotted "paths" to the respective
values in the datastructure.

=head1 CONTRIBUTE

The source code is located here: https://github.com/pplu/datastruct-flat

=head2 SEE ALSO

L<Hash::Flatten>

=head1 AUTHOR
    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

Copyright (c) 2019 by CAPSiDE

=head1 LICENSE

Apache 2.0

=cut
