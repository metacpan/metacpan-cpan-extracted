package Algorithm::SpatialIndex::Storage;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

require Algorithm::SpatialIndex::Strategy;
use Scalar::Util 'weaken';

use Class::XSAccessor {
  getters => [qw(
    index
    no_of_subnodes
    bucket_class
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;
  my $ext_opt = $opt{opt}||{};

  my $self = bless {
    bucket_class => defined($ext_opt->{bucket_class}) ? $ext_opt->{bucket_class} : 'Algorithm::SpatialIndex::Bucket',
    %opt,
  } => $class;

  weaken($self->{index});

  my $bucket_class = $self->bucket_class;
  if (not $bucket_class =~ /::/) {
    $bucket_class = "Algorithm::SpatialIndex::Bucket::$bucket_class";
    $self->{bucket_class} = $bucket_class;
  }

  eval "require $bucket_class; 1;" or do {
    my $err = $@ || "Zombie error";
    die "Could not load bucket implementation '$bucket_class': $err"
  };

  my $strategy = $self->index->strategy;
  $self->{no_of_subnodes} = $strategy->no_of_subnodes;

  $self->init() if $self->can('init');

  return $self;
}

sub fetch_node {
  croak("Not implemented in base class");
}

sub store_node {
  croak("Not implemented in base class");
}

sub fetch_bucket {
  croak("Not implemented in base class");
}

sub delete_bucket {
  croak("Not implemented in base class");
}

sub store_bucket {
  croak("Not implemented in base class");
}

sub get_option {
  croak("Not implemented in base class");
}

sub set_option {
  croak("Not implemented in base class");
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Storage - Base class for storage backends

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    storage => 'Memory', # or others
  );

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Constructor. Called by the L<Algorithm::SpatialIndex>
constructor. You probably do not need to call or implement this.
Calls your C<init> method if available.

=head2 init

If your subcass implements this, it will be called on the
fresh object in the constructor.

=head2 fetch_node

Fetch a node from storage by node id.

Has to be implemented in a subclass.

=head2 store_node

Store the provided node. Assigns a new ID to it if it has none.
Returns the (potentially new) node id.

Note that general id handling is the task of the storage backend.
Users or strategies should not set node ids.

Has to be implemented in a subclass.

=head2 set_option

Takes a key/value pair for a tree property/option to be
stored.

Has to be implemented in a subclass.

=head2 get_option

Takes a key for a tree property/option to be
fetched from storage.

Has to be implemented in a subclass.

=head2 fetch_bucket

Takes a node id as argument and returns the bucket for this
node (or undef on failure).

Has to be implemented in a subclass.

=head2 store_bucket

Takes a bucket object (with assigned node id)
and stores the bucket
as the bucket for this node id.

Has to be implemented in a subclass.

=head2 delete_bucket

Removes the given bucket (or bucket/node id) from the
storage.

Has to be implemented in a subclass.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
