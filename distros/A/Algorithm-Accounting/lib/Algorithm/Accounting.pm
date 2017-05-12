package Algorithm::Accounting;
use Spiffy -Base;
use Array::Compare;
use FreezeThaw qw(freeze thaw);
our $VERSION = '0.08';

field fields           => [];
field occurrence_array => [];
field occurrence_hash  => {};

# arrayref of arrayref
field field_groups     => [];

# array of hashref, but the key of hashref is
# in serialized(freezed) form.
field group_occurrence => [];

field 'report_class' => 'Algorithm::Accounting::Report::Text';

sub reset {
  $self->fields([]);
  $self->field_groups([]);
  $self->occurrence_array([]);
  $self->occurrence_hash({});
}

sub result {
  my $field = shift;
  if($field && grep /^$field$/,@{$self->fields}) {
    return $self->occurrence_hash->{$field};
  }
  return $self->occurrence_array;
}

sub group_result {
  my ($group,@fv) = @_;
  my $occ   = $self->group_occurrence;
  return unless($group =~ /\d+/ && defined($occ->[$group]));
  # Exact match;
  my $cmp = Array::Compare->new;
  if(@fv == @{$self->field_groups->[$group]}) {
    for(keys %{$occ->[$group]}) {
      my @fv_ = thaw($_);
      next unless($cmp->compare(\@fv, \@fv_));
      return $occ->[$group]{$_};
    }
  }
  # Slurp whole thing, convert to multi-level hash.
  my $rv = {};
  for(keys %{$occ->[$group]}) {
    # would this be dangerous ?
    eval "\$rv->".join('',map {"{'$_'}"} thaw($_))."= $occ->[$group]{$_}";
  }
  return $rv;
}

sub append_data {
  my $data = shift;
  $self->update_single_field($data);
  $self->update_group_field($data);
}

sub report {
    my $class = $self->report_class;
    my $obj;
    eval qq{
        require $class;
        \$obj = $class->new;
    };
    die"report() error\n" if $@;
    $obj->process(
        $self->occurrence_hash,
        $self->field_groups,
        $self->group_occurrence
       );
}

sub update_group_field {
  my $data = shift;
  my $groups = $self->field_groups || return;
  my $gocc = $self->group_occurrence;
  for my $i (0..@$groups-1) {
    my @index = $self->position_of($self->fields,$groups->[$i]);
    for my $row (@$data) {
      my $permutor = Algorithm::Accounting::Array::Iterator::LOL->new([@$row[@index]]);
      my %exclude;
      while(my $permutation = $permutor->getNext) {
 	my @_row = map {(ref($_) ? $_->[0] : $_)||''} @$permutation;
 	my $__row = freeze(@_row);
 	# One value-tuple would shows only one time,
 	# So it's excluded upon extra permutations.
 	unless($exclude{$__row}) {
 	  $gocc->[$i]->{freeze(@_row)}++;
 	  $exclude{$__row}++;
 	}
      }
    }
  }
  $self->group_occurrence($gocc);
}

sub update_single_field {
  my $data = shift;
  my $aocc = $self->occurrence_array;
  my $hocc = $self->occurrence_hash;
  my $fields = $self->fields;
  for my $i (0..@$fields-1) {
    my $occ = $aocc->[$i] || {};
    for(@$data) {
      last unless exists $_->[$i];
      if('ARRAY' eq ref($_->[$i])) {
	for my $v (@{$_->[$i]}) {$occ->{$v}++}
      } else {
        $occ->{$_->[$i]}++;
      }
    }
    $aocc->[$i] = $occ;
    $hocc->{$fields->[$i]} = $occ;
  }
  $self->occurrence_array($aocc);
  $self->occurrence_hash($hocc);
}

# Find the position of wanted values in an array
sub position_of {
  my ($arr,$wanted) = @_;
  my @index;
  for my $w (@$wanted) {
    for my $i (0..@$arr-1) {
      push @index,$i if($arr->[$i] eq $w);
    }
  }
  return @index;
}

package Algorithm::Accounting::Array::Iterator::LOL;
use Array::Iterator::Reusable;
use Clone qw(clone);

sub new {
  my $class = $self;
  $self = {};
  bless $self,$class;
  my $lol = shift;
  my @lolp; # list of Array::Iterator::Reusable
  for (@$lol) {
     if(ref($_)) {
       push @lolp, Array::Iterator::Reusable->new($_);
     } else {
       push @lolp, Array::Iterator::Reusable->new([$_]);
     }
  }
  $self->{lol}  = $lol;
  $self->{lolp} = \@lolp ;
  $self->reset();
  return $self;
}

sub reset {
  $_->reset for @{$self->{lolp}};
  my @lov;
  push @lov, $self->{lolp}->[0]->peek;
  for my $i (1..@{$self->{lolp}}-1) {
    push @lov,$self->{lolp}->[$i]->getNext;
  }
  $self->{lov} = \@lov;
  return $self;
}

sub get_next {
  my $method = shift;
  my $reset = 0;
  my $nlov  = clone($self->{lov});
  for my $i (0..@{$self->{lolp}}-1) {
    if($self->{lolp}->[$i]->hasNext) {
      $nlov->[$i] = $self->{lolp}->[$i]->$method;
      last;
    } else {
      my $_index;
      $_index= $self->{lol}->[$i]->{_current_index}
	if($method eq 'peek');

      $reset++;
      $self->{lolp}->[$i]->reset;
      $nlov->[$i] = $self->{lolp}->[$i]->getNext || '(DUMMY)';

      $self->{lol}->[$i]->{_current_index} = $_index
	if($method eq 'peek');
    }
  }
  return if($reset == @{$self->{lolp}});
  $self->{lov} = $nlov if($method eq 'getNext');
  return $nlov;
}

sub peek { $self->get_next('peek') }
sub next { $self->get_next('getNext') }
sub getNext { $self->get_next('getNext') }

__END__

=head1 NAME

  Algorithm::Accounting - Generate accounting statistic for general logs

=head1 SYNOPSIS

  my $fields = [qw/id author file date/];
  my $groups = [[qw(author file)], [qw(author date)]];
  my $data = [
	[1, 'alice', '/foo.txt', '2004-05-01' ],
	[2, 'bob',   '/foo.txt', '2004-05-03' ],
	[3, 'alice', '/foo.txt', '2004-05-04' ],
	[4, 'john ', '/foo.txt', '2004-05-04' ],
	[5, 'john ', [qw(/foo.txt /bar.txt], '2004-05-04' ],
  ];


  # give the object information
  my $acc = Algorithm::Accounting->new(fields => $fields,
                                       field_groups => $groups );

  $acc->append_data($data);

  # Generate report to STDOUT
  $acc->report;

  # Get result
  my $result = $acc->result;

  # Get result of a specific field.
  my $author_accounting = $acc->result('author');

  # Reset current result so we can restart
  $acc->reset;

=head1 DESCRIPTION

C<Algorithm::Accounting> provide simple aggregation method to make log
accounting easier. It accepts data in rows, each rows can have many
fields, and each field is a scalar or a list(arrayref).

The basic usage is you walk through all your logs, and use append_data()
to insert each rows, (you'll have to split the line into fields),
and then call result() to retrieve the result, or report() to
immediatly see simple result.

You may specify a filed_groups parameter (arrayref of arrayref),
and C<Algorithm::Accounting> will account these fields in groups.

Notice you'll have to give a list fileds first, the append_data()
depends on the number of fields to work properly.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

