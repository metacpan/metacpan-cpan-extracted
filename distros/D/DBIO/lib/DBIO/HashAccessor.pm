package DBIO::HashAccessor;
# ABSTRACT: Accessor methods for serialized hash columns

use strict;
use warnings;

use parent 'DBIO::Row';

sub _install {
  my ($class, $name, $code) = @_;
  no strict 'refs';
  *{"${class}::${name}"} = $code;
}

sub add_hash_accessor {
  my ( $class, $accessor, $hash ) = @_;
  die 'require accessor and hash name' unless defined $accessor and defined $hash;
  die 'accessor can\'t be named like hash' if $accessor eq $hash;

  $class->_install($accessor, sub {
    my ( $self, @args ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    my %h = %{$self->$hash || {}};
    if (scalar @args == 1) {
      return $h{$args[0]};
    } elsif (scalar @args == 2) {
      $h{$args[0]} = $args[1];
      $self->$hash({ %h });
      return $args[1];
    } else {
      die $accessor.' function must get 1 or 2 args';
    }
  });

  $class->_install($accessor.'_hash', sub {
    my ( $self, $key, @args ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    my %h = %{$self->$hash || {}};
    if (scalar @args == 1) {
      return ref $h{$key} eq 'HASH' ? $h{$key}->{$args[0]} : undef;
    } elsif (scalar @args == 2) {
      $h{$key} = {} unless exists $h{$key};
      return undef unless ref $h{$key} eq 'HASH';
      $h{$key}->{$args[0]} = $args[1];
      $self->$hash({ %h });
      return $args[1];
    } else {
      die $accessor.'_hash function must get 2 or 3 args';
    }
  });

  $class->_install($accessor.'_hash_delete', sub {
    my ( $self, $key, $hash_key ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    my %h = %{$self->$hash || {}};
    if ($key && $hash_key) {
      return undef unless ref $h{$key} eq 'HASH';
      my $old_value = delete $h{$key}->{$hash_key};
      $self->$hash({ %h });
      return $old_value;
    } else {
      die $accessor.'_hash_delete function must get 2 args';
    }
  });

  $class->_install($accessor.'_push', sub {
    my ( $self, $key, @elements ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_push function requires 1 arg' unless defined $key;
    my %h = %{$self->$hash || {}};
    my @array = defined $h{$key} ? ( @{$h{$key}} ) : ();
    push @array, @elements;
    $h{$key} = [ @array ];
    $self->$hash({ %h });
    return @elements;
  });

  $class->_install($accessor.'_shift', sub {
    my ( $self, $key ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_shift function requires 1 arg' unless defined $key;
    my %h = %{$self->$hash || {}};
    my @array = defined $h{$key} ? ( @{$h{$key}} ) : ();
    return unless scalar @array;
    my $return = shift @array;
    $h{$key} = [ @array ];
    $self->$hash({ %h });
    return $return;
  });

  $class->_install($accessor.'_in', sub {
    my ( $self, $key, $val ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_in function requires 2 args' unless defined $val && defined $key;
    my %h = %{$self->$hash || {}};
    my @array = defined $h{$key} ? ( @{$h{$key}} ) : ();
    for (@array) {
      return 1 if $val eq $_;
    }
    return 0;
  });

  $class->_install($accessor.'_in_delete', sub {
    my ( $self, $key, $val ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_in_delete function requires 2 args' unless defined $val && defined $key;
    my %h = %{$self->$hash || {}};
    my @array = defined $h{$key} ? ( @{$h{$key}} ) : ();
    my @new_array;
    for my $old_val (@array) {
      push @new_array, $old_val unless $val eq $old_val;
    }
    $h{$key} = [ @new_array ];
    $self->$hash({ %h });
    return;
  });

  $class->_install($accessor.'_delete', sub {
    my ( $self, $key ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_delete function requires 1 arg' unless defined $key;
    my %h = %{$self->$hash || {}};
    my $return = delete $h{$key};
    $self->$hash({ %h });
    return $return;
  });

  $class->_install($accessor.'_exists', sub {
    my ( $self, $key ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_exists function requires 1 arg' unless defined $key;
    my %h = %{$self->$hash || {}};
    return exists $h{$key};
  });

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::HashAccessor - Accessor methods for serialized hash columns

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  __PACKAGE__->load_components(
    'HashAccessor',
    'InflateColumn::Serializer',
  );

  __PACKAGE__->table('data');

  __PACKAGE__->add_columns(
    'data' => {
      'data_type' => 'VARCHAR',
      'size' => 255,
      'serializer_class' => 'JSON',
    }
  );

  __PACKAGE__->add_hash_accessor( da => 'data' );

In code:

  print $result->da_exists('key') ? 1 : 0; # exists
  $result->da('key',$new_value); # set
  print $result->da('key'); # get
  $result->da_delete('key'); # delete
  $result->da_hash('hash','key',22); # set inside hash
  print $result->da_hash('hash','key'); # get inside hash
  $result->da_hash_delete('hash','key'); # delete inside hash
  $result->da_push('array',@elements); # add to array
  $result->da_shift('array'); # shift from array
  $result->da_in('array',$value); # value is in array
  $result->da_in_delete('array',$value); # find and delete value in array

See F<t/hash_accessor.t> for a runnable example.

=head1 DESCRIPTION

Generates convenience accessor methods for serialized hash columns. Designed
to be used alongside L<DBIO::InflateColumn::Serializer>. Call
C<add_hash_accessor> with a prefix and column name, and it installs get/set,
exists, delete, nested hash, and array manipulation methods.

Based on L<DBIx::Class::HashAccessor> by GETTY.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
