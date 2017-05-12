package Data::WeightedRoundRobin;

use strict;
use warnings;
our $VERSION = '0.07';

our $DEFAULT_WEIGHT = 100;
our $BTREE_BORDER = 10;

use Scope::Guard qw(guard);
use Data::Clone qw(clone);

sub new {
    my ($class, $list, $args) = @_;
    $args ||= {};
    my $self = bless {
        rrlist         => [],
        weights        => 0,
        list_num       => 0,
        default_weight => $args->{default_weight} || $DEFAULT_WEIGHT,
        btree_border   => $args->{btree_border} || $BTREE_BORDER,
    }, $class;
    $self->set($list) if $list;
    return $self;
}

sub _normalize {
    my ($self, $data) = @_;
    return unless defined $data;

    my ($key, $value, $weight);

    # { value => 'foo', weight => 1 }
    if (ref $data eq 'HASH') {
        ($key, $value, $weight) = @$data{qw/key value weight/};
        return unless defined $value;
        return if defined $weight && $weight < 0;
        $key = $value unless defined $key; 
        $weight = $self->{default_weight} unless defined $weight;
    }
    # foo
    else {
        # \{ foo => 'bar' }
        if (ref $data eq 'REF' && ref $$data eq 'HASH') {
            $data = $$data;
        }
        $key = $value = $data;
        $weight = $self->{default_weight};
    }

    return { key => $key, value => $value, weight => $weight };
}

sub set {
    my ($self, $list) = @_;
    return unless $list;

    my $normalized = {};
    for my $data (@$list) {
        $data = $self->_normalize($data) || next;
        $normalized->{$data->{key}} = $data;
    }

    my $rrlist = [];
    my $weights = 0;
    for my $key (sort keys %$normalized) {
        unshift @$rrlist, {
            key    => $key,
            value  => $normalized->{$key}{value},
            range  => $weights,
            weight => $normalized->{$key}{weight},
        };
        $weights += $normalized->{$key}{weight};
    }

    $self->{rrlist}   = $rrlist;
    $self->{weights}  = $weights;
    $self->{list_num} = scalar @$rrlist;

    return 1;
}

sub add {
    my ($self, $value) = @_;
    my $rrlist = $self->{rrlist};
    $value = $self->_normalize($value) || return;

    my $added = 1;
    for my $data (@$rrlist) {
        if ($data->{key} eq $value->{key}) {
            $added = 0;
            last;
        }
    }

    if ($added) {
        push @$rrlist, $value;
        $self->set($rrlist);
    }

    return $added;
}

sub replace {
    my ($self, $value) = @_;
    my $rrlist = $self->{rrlist};
    $value = $self->_normalize($value) || return;

    my $replaced = 0;
    for my $data (@$rrlist) {
        if ($data->{key} eq $value->{key}) {
            $data = $value;
            $replaced = 1;
            last;
        }
    }

    if ($replaced) {
        $self->set($rrlist);
    }

    return $replaced;
}

sub remove {
    my ($self, $value) = @_;
    my $rrlist = $self->{rrlist};

    my $removed = 0;
    my $newlist = [];
    for my $data (@$rrlist) {
        unless ($data->{key} eq $value) {
            push @$newlist, $data; 
        }
        else {
            $removed = 1;
        }
    }

    if ($removed) {
        $self->set($newlist);
    }

    return $removed;
}

sub next {
    my ($self, $key) = @_;
    my ($rrlist, $weights, $list_num) = @$self{qw/rrlist weights list_num/};
    return unless $list_num; # empty data
    my ($start, $end) = (0, $list_num - 1);

    # if all weight is 0, choose random
    return $rrlist->[int rand $list_num]->{value} if $weights == 0;

    my $rweight = rand($weights);
    if ($list_num < $self->{btree_border}) {
        # linear
        for my $rr (@$rrlist) {
            return $rr->{value} if $rweight >= $rr->{range};
        }
    }
    else {
        # b-tree
        while ($start < $end) {
            my $mid = int(($start + $end) / 2);
            if ($rrlist->[$mid]{range} <= $rweight) {
                $end = $mid;
            }
            else {
                $start = $mid + 1;
            }
        }
        return $rrlist->[$start]{value};
    }
}

sub save {
    my $self = shift;
    my $orig_rrlist = clone $self->{rrlist};
    guard { $self->set($orig_rrlist) };
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::WeightedRoundRobin - Serve data in a Weighted RoundRobin manner.

=head1 SYNOPSIS

  use Data::WeightedRoundRobin;
  my $dwr = Data::WeightedRoundRobin->new([
      qw/foo bar/,
      { value => 'baz', weight => 50 },
      { key => 'hoge', value => [qw/fuga piyo/], weight => 120 },
  ]);
  $dwr->next; # 'foo' : 'bar' : 'baz' : [qw/fuga piyo/] = 100 : 100 : 50 : 120

=head1 DESCRIPTION

Data::WeightedRoundRobin is a Serve data in a Weighted RoundRobin manner.

=head1 METHODS

=over

=item C<< new([$list:ARRAYREF, $option:HASHREF]) >>

Creates a Data::WeightedRoundRobin instance.

  $dwr = Data::WeightedRoundRobin->new();               # empty rr data
  $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);  # foo : bar = 100 : 100

  # foo : bar : baz : qux = 100 : 100 : 120 : 50 :
  $dwr = Data::WeightedRoundRobin->new([
      'foo',
      { value => 'bar' },
      { value => 'baz', weight => 120 },
      { key => 'qux', value => [qw/q u x/], weight => 50 },
      \{ foo => 'bar' },
  ]);

Sets default_weight option, DEFAULT is B<< $Data::WeightedRoundRobin::DEFAULT_WEIGHT >>.

  # foo : bar : baz = 0.3 : 0.7 : 1
  $dwr = Data::WeightedRoundRobin->new([
      { value => 'foo', weight => 0.3 },
      { value => 'bar', weight => 0.7 },
      { value => 'baz' },
  ], { default_weight => 1 });

=item C<< next() >>

Fetch a data.

  my $dwr = Data::WeightedRoundRobin->new([
      qw/foo bar/],
      { value => 'baz', weight => 50 },
  );
  
  # Infinite loop
  while (my $data = $dwr->next) {
      say $data; # foo : bar : baz = 100 : 100 : 50 
  }
 
=item C<< set($list:ARRAYREF) >>

Sets datum.

  $drw->set([
      { value => 'foo', weight => 100 },
      { value => 'bar', weight => 50  },
  ]);

You can specify the following data.

  [qw/foo/]                           # eq [ { key => 'foo', value => 'foo', weight => 100 } ]
  [{ value => 'foo' }]                # eq [ { key => 'foo', value => 'foo', weight => 100 } ]
  [{ key => 'foo', value => 'foo' }]  # eq [ { key => 'foo', value => 'foo', weight => 100 } ] 

=item C<< add($value:SCALAR || $value:HASHREF) >>

Add a value. You can add NOT already value. Returned value is 1 or 0, but if error is undef.

  use Test::More;
  my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
  is $dwr->add('baz'), 1, 'added baz';
  is $dwr->add('foo'), 0, 'foo is exists';
  is $dwr->add({ value => 'hoge', weight => 80 }), 1, 'added hoge with weight 80';
  is $dwr->add(), undef, 'error';

=item C<< replace($value:SCALAR || $value::HASHREF) >>

Replace a value. Returned value is 1 or 0, but if error is undef.

  use Test::More;
  my $dwr = Data::WeightedRoundRobin->new([qw/foo/, { value => 'bar', weight => 50 }]);
  is $dwr->replace('bar'), 1, 'replaced bar to default weight (50 -> 100)';
  is $dwr->replace('hoge'), 0, 'hoge is not found';
  is $dwr->replace({ value => 'foo', weight => 80 }), 1, 'replaced foo with weight 80';
  is $dwr->replace(), undef, 'error';

=item C<< remove($value:SCALAR) >>

Remove a value. Returned value is 1 or 0, but if error is undef.

  use Test::More;
  my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
  is $dwr->remove('foo'), 1, 'removed foo';
  is $dwr->remove('hoge'), 0, 'hoge is not found';
  is $dwr->remove(), undef, 'error';

=item C<< save() >>

When destroyed C<< $guard >> is gone, will return to the saved state.

  my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
  {
      my $guard = $drw->save;
      $drw->remove('foo');
      is $drw->next, 'bar';
  }

  # return to saved state
  my $data = $dwr->next; # foo or bar

=back

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
