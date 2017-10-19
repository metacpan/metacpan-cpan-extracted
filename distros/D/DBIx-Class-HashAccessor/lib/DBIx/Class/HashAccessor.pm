package DBIx::Class::HashAccessor;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Helper functions to install accessors for serialized hash columns
$DBIx::Class::HashAccessor::VERSION = '0.001';
use strict;
use warnings;
use Package::Stash;

use parent 'DBIx::Class::Row';

sub add_hash_accessor {
  my ( $class, $accessor, $hash ) = @_;
  die 'require accessor and hash name' unless defined $accessor and defined $hash;
  die 'accessor can\'t be named like hash' if $accessor eq $hash;
  my $st = Package::Stash->new($class);

  $st->add_symbol('&'.$accessor,sub {
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

  $st->add_symbol('&'.$accessor.'_hash',sub {
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

  $st->add_symbol('&'.$accessor.'_hash_delete',sub {
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

  $st->add_symbol('&'.$accessor.'_push',sub {
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

  $st->add_symbol('&'.$accessor.'_shift',sub {
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

  $st->add_symbol('&'.$accessor.'_in',sub {
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

  $st->add_symbol('&'.$accessor.'_in_delete',sub {
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

  $st->add_symbol('&'.$accessor.'_delete',sub {
    my ( $self, $key ) = @_;
    die((ref $self).' does not support '.$hash) unless $self->can($hash);
    die $accessor.'_delete function requires 1 arg' unless defined $key;
    my %h = %{$self->$hash || {}};
    my $return = delete $h{$key};
    $self->$hash({ %h });
    return $return;
  });

  $st->add_symbol('&'.$accessor.'_exists',sub {
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

=head1 NAME

DBIx::Class::HashAccessor - Helper functions to install accessors for serialized hash columns

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Your result class

  __PACKAGE__->load_components(
    'HashAccessor',
    'InflateColumn::Serializer',
    'Core'
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

In code

  # Access key in hash (no default hash needed)

  print $result->da_exists('key') ? 1 : 0; # exists
  $result->da('key',$new_value); # set
  print $result->da('key'); # get
  $result->da_delete('key'); # delete
  $result->da_hash('hash','key',22); # set inside hash
  print $result->da_hash('hash','key'); # get inside hash
  $result->da_hash_delete('hash','key'); # delete inside hash
  $result->da_push('array',@elements); # add to array (and create array if key isn't array)
  $result->da_shift('array'); # shift from array
  $result->da_in('array',$value); # value is in array
  $result->da_in_delete('array',$value); # find value in array and delete

=head1 DESCRIPTION

=head1 SUPPORT

IRC

  Join #dbix-class on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-dbix-class-hashaccessor
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-dbix-class-hashaccessor/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
