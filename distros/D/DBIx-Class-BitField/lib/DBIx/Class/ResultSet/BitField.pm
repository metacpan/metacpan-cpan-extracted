package DBIx::Class::ResultSet::BitField;
our $VERSION = '0.13';


use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use Carp;

sub search_bitfield {
  my ($self, $search) = @_;
  
  my $source = $self->result_source;
  my $row = $self->new_result({});
  
  my %search = ref $search eq 'ARRAY' ? @{$search} : ref $search eq 'HASH' ? %{$search} : croak 'search_bitfield takes an arrayref or a hashref';
  
  my $type = ref $search eq 'ARRAY' ? '-or' : '-and';
  
  my $query = [];
  
  while(my($column, $value) = each %search) {
    $column =~ s/^(.*?\.)?(.*)$/$2/;
    my $prefix = $1 || q{};
    next unless(my $bitfield = $row->__is_bitfield_item($column));
    
    my $info = $source->column_info($bitfield);
    
    my $i = 0;
    foreach my $field (@{$info->{bitfield} || []}) {
      my $bit = 2**$i++;
      next unless($field eq $column);
      if($value) {
        push(@{$query}, \qq($prefix$bitfield & $bit > 0));
      } else {
        push(@{$query}, \qq($prefix$bitfield & $bit = 0));
      }
    }
    
    
  }
  
  return $self->search({ $type => $query });
  
}

sub update {
  my ($self, $data, @rest) = @_;
  my $source = $self->result_source;
  my $row = $self->new_result({});
  while(my ($k, $value) = each %{$data || {}}) {
    my $info = $source->column_info($k);
    if($row->__is_bitfield($info) && ($value !~ /^\d+$/ || int($value) ne $value)) {
      if(ref $value eq 'ARRAY') {
        foreach my $bit (@{$value || []}) {
          $row->can($bit) ? $row->$bit(1) : croak qq(bitfield item '$bit' does not exist);
        }
      } else {
        $row->can($value) ? $row->$value(1) : croak qq(bitfield item '$value' does not exist);
      }
      my $accessor = $info->{accessor};
      $data->{$k} = $row->$accessor;
      $row = $self->new_result({});
    }
  }
  
  return $self->next::method($data, @rest);
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ResultSet::BitField

=head1 VERSION

version 0.13

=head1 AUTHOR

  Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut 


