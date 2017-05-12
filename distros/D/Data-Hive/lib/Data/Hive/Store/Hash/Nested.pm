use strict;
use warnings;
package Data::Hive::Store::Hash::Nested;
# ABSTRACT: store a hive in nested hashrefs
$Data::Hive::Store::Hash::Nested::VERSION = '1.013';
use parent 'Data::Hive::Store';

#pod =head1 DESCRIPTION
#pod
#pod This is a simple store, primarily for testing, that will store hives in nested
#pod hashrefs.  All hives are represented as hashrefs, and their values are stored
#pod in the entry for the empty string.
#pod
#pod So, we could do this:
#pod
#pod   my $href = {};
#pod
#pod   my $hive = Data::Hive->NEW({
#pod     store_class => 'Hash',
#pod     store_args  => [ $href ],
#pod   });
#pod
#pod   $hive->foo->SET(1);
#pod   $hive->foo->bar->baz->SET(2);
#pod
#pod We would end up with C<$href> containing:
#pod
#pod   {
#pod     foo => {
#pod       ''  => 1,
#pod       bar => {
#pod         baz => {
#pod           '' => 2,
#pod         },
#pod       },
#pod     },
#pod   }
#pod
#pod Using empty keys results in a bigger, uglier dump, but allows a given hive to
#pod contain both a value and subhives.  B<Please note> that this is different
#pod behavior compared with earlier releases, in which empty keys were not used and
#pod it was not legal to have a value and a hive at a given path.  It is possible,
#pod although fairly unlikely, that this format will change again.  The Hash store
#pod should generally be used for testing things that use a hive, as opposed for
#pod building hashes that will be used for anything else.
#pod
#pod =method new
#pod
#pod   my $store = Data::Hive::Store::Hash->new(\%hash);
#pod
#pod The only argument expected for C<new> is a hashref, which is the hashref in
#pod which hive entries are stored.
#pod
#pod If no hashref is provided, a new, empty hashref will be used.
#pod
#pod =cut

sub new {
  my ($class, $href) = @_;
  $href = {} unless defined $href;

  return bless { store => $href } => $class;
}

#pod =method hash_store
#pod
#pod This method returns the hashref in which things are being used.  You should not
#pod alter its contents!
#pod
#pod =cut

sub hash_store {
  $_[0]->{store}
}

my $BREAK = "BREAK\n";

# Wow, this is quite a little machine!  Here's a slightly simplified overview
# of what it does:  -- rjbs, 2010-08-27
#
# As long as cond->(\@remaining_path) is true, execute step->($next,
# $current_hashref, \@remaining_path)
#
# If it dies with $BREAK, stop looping and return.  Once the cond returns
# false, return end->($current_hashref, \@remaining_path)
sub _descend {
  my ($self, $orig_path, $arg) = @_;
  my @path = @$orig_path;

  $arg ||= {};
  $arg->{step} or die "step is required";
  $arg->{cond} ||= sub { @{ shift() } };
  $arg->{end}  ||= sub { $_[0] };

  my $node = $self->hash_store;

  while ($arg->{cond}->(\@path)) {
    my $seg = shift @path;

    {
      local $SIG{__DIE__};
      eval { $arg->{step}->($seg, $node, \@path) };
    }

    return if $@ and $@ eq $BREAK;
    die $@ if $@;
    $node = $node->{$seg} ||= {};
  }

  return $arg->{end}->($node, \@path);
}

sub get {
  my ($self, $path) = @_;
  return $self->_descend(
    $path, {
      end  => sub { $_[0]->{''} },
      step => sub {
        my ($seg, $node) = @_;

        die $BREAK unless exists $node->{$seg};

        $node->{$seg} = { '' => $node->{$seg} } if ! ref $node->{$seg};
      }
    }
  );
}

sub set {
  my ($self, $path, $value) = @_;
  return $self->_descend(
    $path, {
      step => sub {
        my ($seg, $node, $path) = @_;
        if (exists $node->{$seg} and not ref $node->{$seg}) {
          _die("can't overwrite existing non-ref value: '$node->{$seg}'");
        }
      },
      cond => sub { @{ shift() } > 1 },
      end  => sub {
        my ($node, $path) = @_;
        $node->{$path->[0]}{''} = $value;
      },
    },
  );
}

#pod =method name
#pod
#pod The name returned by the Hash store is a string, potentially suitable for
#pod eval-ing, describing a hash dereference of a variable called C<< $STORE >>.
#pod
#pod   "$STORE->{foo}->{bar}"
#pod
#pod This is probably not very useful.  It might be replaced with something else in
#pod the future.
#pod
#pod =cut

sub name {
  my ($self, $path) = @_;
  return join '->', '$STORE', map { "{'$_'}" } @$path;
}

sub exists {
  my ($self, $path) = @_;
  return $self->_descend(
    $path, { 
      step => sub {
        my ($seg, $node) = @_;
        die $BREAK unless exists $node->{$seg};

        $node->{$seg} = { '' => $node->{$seg} } if ! ref $node->{$seg};
      },
      end  => sub { return exists $_[0]->{''}; },
    },
  );
}  

sub delete {
  my ($self, $path) = @_;

  my @to_check;

  return $self->_descend(
    $path, {
      step => sub {
        my ($seg, $node) = @_;
        die $BREAK unless exists $node->{$seg};
        $node->{$seg} = { '' => $node->{$seg} } if ! ref $node->{$seg};
        push @to_check, [ $node, $seg ];
      },
      cond => sub { @{ shift() } > 1 },
      end  => sub {
        my ($node, $final_path) = @_;

        $node->{ $final_path->[0] } = { '' => $node->{ $final_path->[0] } }
          unless ref $node->{ $final_path->[0] };

        my $this = $node->{ $final_path->[0] };
        my $rv = delete $this->{''};

        # Cleanup empty trees after deletion!  It would be convenient to have
        # ->_ascend, but I'm not likely to bother with writing it just yet.
        # -- rjbs, 2010-08-27
        for my $to_check (
          [ $node, $final_path->[0] ],
          reverse @to_check
        ) {
          my ($node, $seg) = @$to_check;
          last if keys %{ $node->{$seg} };
          delete $node->{ $seg };
        }

        return $rv;
      },
    },
  );
}

sub keys {
  my ($self, $path) = @_;

  return $self->_descend($path, {
    step => sub {
      my ($seg, $node) = @_;
      die $BREAK unless exists $node->{$seg};
      $node->{$seg} = { '' => $node->{$seg} } if ! ref $node->{$seg};
    },
    end  => sub {
      return grep { length } keys %{ $_[0] };
    },
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Hive::Store::Hash::Nested - store a hive in nested hashrefs

=head1 VERSION

version 1.013

=head1 DESCRIPTION

This is a simple store, primarily for testing, that will store hives in nested
hashrefs.  All hives are represented as hashrefs, and their values are stored
in the entry for the empty string.

So, we could do this:

  my $href = {};

  my $hive = Data::Hive->NEW({
    store_class => 'Hash',
    store_args  => [ $href ],
  });

  $hive->foo->SET(1);
  $hive->foo->bar->baz->SET(2);

We would end up with C<$href> containing:

  {
    foo => {
      ''  => 1,
      bar => {
        baz => {
          '' => 2,
        },
      },
    },
  }

Using empty keys results in a bigger, uglier dump, but allows a given hive to
contain both a value and subhives.  B<Please note> that this is different
behavior compared with earlier releases, in which empty keys were not used and
it was not legal to have a value and a hive at a given path.  It is possible,
although fairly unlikely, that this format will change again.  The Hash store
should generally be used for testing things that use a hive, as opposed for
building hashes that will be used for anything else.

=head1 METHODS

=head2 new

  my $store = Data::Hive::Store::Hash->new(\%hash);

The only argument expected for C<new> is a hashref, which is the hashref in
which hive entries are stored.

If no hashref is provided, a new, empty hashref will be used.

=head2 hash_store

This method returns the hashref in which things are being used.  You should not
alter its contents!

=head2 name

The name returned by the Hash store is a string, potentially suitable for
eval-ing, describing a hash dereference of a variable called C<< $STORE >>.

  "$STORE->{foo}->{bar}"

This is probably not very useful.  It might be replaced with something else in
the future.

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
