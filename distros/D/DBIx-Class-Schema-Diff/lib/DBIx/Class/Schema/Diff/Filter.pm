package DBIx::Class::Schema::Diff::Filter;
use strict;
use warnings;

# Further filters diff data produced by DBIx::Class::Schema::Diff

use Moo;
with 'DBIx::Class::Schema::Diff::Role::Common';

use Types::Standard qw(:all);

has 'mode',  is => 'ro', isa => Enum[qw(limit ignore)], default => sub{'limit'};
has 'match', is => 'ro', isa => Maybe[InstanceOf['Hash::Layout']], default => sub{undef};

has 'events', is => 'ro', coerce => \&_coerce_list_hash,
  isa => Maybe[Map[Enum[qw(added changed deleted)],Bool]];

has 'source_events', is => 'ro', coerce => \&_coerce_list_hash,
  isa => Maybe[Map[Enum[qw(added changed deleted)],Bool]];

has 'empty_match', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return (scalar(keys %{$self->match->Data}) > 0) ? 0 : 1;
}, init_arg => undef, isa => Bool;

has 'matched_paths', is => 'ro', init_arg => undef, default => sub {[]};

sub filter {
  my ($self, $diff) = @_;
  return undef unless ($diff);
  
  my $newd = {};
  for my $s_name (keys %$diff) {
    my $h = $diff->{$s_name};
    next if (
      $self->skip_source($s_name)
      || $self->_is_skip( source_events => $h->{_event})
    );
    
    $newd->{$s_name} = $self->source_filter( $s_name => $h );
    delete $newd->{$s_name} unless (defined $newd->{$s_name});

    # Strip if the event is 'changed' but the diff data has been stripped
    delete $newd->{$s_name} if (
      $newd->{$s_name} && 
      $newd->{$s_name}{_event} &&
      $newd->{$s_name}{_event} eq 'changed' &&
      scalar(keys %{$newd->{$s_name}}) == 1
    );
  }
  
  return scalar(keys %$newd) > 0 ? $newd : undef;
}


sub source_filter {
  my ($self, $s_name, $diff) = @_;
  return undef unless ($diff);
  
  my $newd = {};
  for my $type (keys %$diff) {
    next if ($type ne '_event' && $self->skip_type($s_name => $type));
    my $val = $diff->{$type};
    if($type eq 'columns' || $type eq 'relationships' || $type eq 'constraints') {
      $newd->{$type} = $self->_info_filter( $type, $s_name => $val );
      delete $newd->{$type} unless (defined $newd->{$type});
    }
    else {
      $newd->{$type} = $val
    }
  }
  
  return (scalar(keys %$newd) > 0) ? $newd : undef;
}

sub _info_filter {
  my ($self, $type, $s_name, $items) = @_;
  return undef unless ($items);

  my $new_items = {};

  for my $name (keys %$items) {
    next if (
      $self->_is_skip( 'events' => $items->{$name}{_event})
      || $self->skip_type_id($s_name, $type => $name )
    );

    if($items->{$name}{_event} eq 'changed') {
    
      my $check = $self->test_path($s_name, $type, $name);
      if($check && ref($check) eq 'HASH') {
        my $new_diff = $self->_deep_value_filter(
          $items->{$name}{diff}, $s_name, $type, $name
        ) or next;
        
        $new_items->{$name} = {
          _event => 'changed',
          diff   => $new_diff
        };
      }
      else {
        # Allow through as-is:
        $new_items->{$name} = $items->{$name};# if ($check);
      }
    }
    else {
      # Allow through as-is:
      $new_items->{$name} = $items->{$name};
        #if($self->match->lookup_leaf_path($s_name, $type, $name));
    }
  }
  
  return scalar(keys %$new_items) > 0 ? $new_items : undef;
}

sub _deep_value_filter {
  my ($self, $hash, @path) = @_;
  
  my $new_hash = {};
  for my $k (keys %$hash) {
    my $val = $hash->{$k};
    my $set = $self->test_path(@path,$k);
    
    if($set) {
      if($val && ref($val) eq 'HASH' && ref($set) eq 'HASH' && scalar(keys %$val) > 0) {
        $new_hash->{$k} = $self->_deep_value_filter($val,@path,$k);
        delete $new_hash->{$k} unless (defined $new_hash->{$k});
      }
      else {
        next if ($self->mode eq 'ignore');
        $new_hash->{$k} = $val;
      }
    }
    else {
      next if ($self->mode eq 'limit');
      $new_hash->{$k} = $val;
    }
  }
  
  return scalar(keys %$new_hash) > 0 ? $new_hash : undef;
}


sub _is_skip {
  my ($self, $meth, $key) = @_;
  my $h = $self->$meth;
  $self->mode eq 'limit' ? $h && ! $h->{$key} : $h && $h->{$key};
}


sub skip_source {
  my ($self, $s_name) = @_;
  my $HL = $self->match or return 0;
  my $set = $self->test_path($s_name) || 0;
  
  if($self->mode eq 'limit') {
    return 0 if ($self->empty_match);
    return $set ? 0 : 1;
  }
  else {
    return $set && ! ref($set) ? 1 : 0;
  }
}

sub skip_type {
  my ($self, $s_name, $type) = @_;
  my $HL = $self->match or return 0;
  my $set = $self->test_path($s_name,$type);
  
  if($self->mode eq 'limit') {
    return 0 if ($self->empty_match);
    # If this source/type is set, OR if the entire source is included:
    return $set || $self->test_leaf_path($s_name) ? 0 : 1;
  }
  else {
    return $set && ! ref($set) ? 1 : 0;
  }
}

sub skip_type_id {
  my ($self, $s_name, $type, $id) = @_;

  my $HL = $self->match or return 0;
  my $set = $self->test_path($s_name,$type,$id);
  
  if($self->mode eq 'limit') {
    return 0 if ($self->empty_match);
    # If this source/type is set, OR if the entire source or source/type is included:
    return $set
      || $self->test_leaf_path($s_name)
      || $self->test_leaf_path($s_name,$type) ? 0 : 1;
  }
  else {
    return $set && ! ref($set) ? 1 : 0;
  }
}

sub test_path {
  my ($self, @path) = @_;
  return $self->test_leaf_path(@path) || $self->match->lookup_path(@path);
}

sub test_leaf_path {
  my ($self, @path) = @_;
  my $ret = $self->match->lookup_leaf_path(@path);
  push @{$self->matched_paths}, \@path if (
    $ret 
    # We don't want to record the path as "matched" for empty HashRef {} leafs 
    && ! ref $ret
  );
  return $ret;
}

1;


__END__

=pod

=head1 NAME

DBIx::Class::Schema::Diff::Filter - internal filtering object class

=head1 DESCRIPTION

This class is used internally by L<DBIx::Class::Schema::Diff> and is not meant to be called directly. 

Please refer to the main L<DBIx::Class::Schema::Diff> documentation for more info.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
