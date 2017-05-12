package Adapter::Async::OrderedList::Array;
$Adapter::Async::OrderedList::Array::VERSION = '0.019';
use strict;
use warnings;

use parent qw(Adapter::Async::OrderedList);

=head1 NAME

Adapter::Async::OrderedList::Array - arrayref adapter

=head1 VERSION

version 0.018

=head1 DESCRIPTION

See L<Adapter::Async::OrderedList> for the API.

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{data} ||= [];
	$self
}

sub clear {
	my $self = shift;
	@{$self->{data}} = ();
	$self->bus->invoke_event('clear');
	Future->wrap
}

sub splice:method {
	my ($self, $idx, $len, $data) = @_;
	$idx ||= 0;
	$data ||= [];
	my @rslt = splice @{$self->{data}}, $idx, $len, @$data;
	$self->bus->invoke_event(splice => $idx, $len, $data => \@rslt);
	Future->wrap($idx, $len, $data, \@rslt);
}

# XXX weakrefs
sub move {
	my ($self, $idx, $len, $offset) = @_;
	my @data = splice @{$self->{data}}, $idx, $len;
	splice @{$self->{data}}, $idx + $offset, 0, @data;
	$self->bus->invoke_event(move => $idx, $len, $offset);
	Future->wrap($idx, $len, $offset);
}

# XXX needs updating
sub modify {
	my ($self, $idx, $data) = @_;
	die "row out of bounds" unless @{$self->{data}} >= $idx;
	$self->{data}[$idx] = $data;
	$self->bus->invoke_event(modify => $idx, $data);
	Future->wrap
}

sub delete {
	my ($self, $idx) = @_;
	$self->splice($idx, 1, [])
}

# Locate matching element (via eq), starting at the given index
# and iterating either side until we hit it. For cases where splice
# activity may have moved the element but we're not expecting it to
# have gone far.
sub find_from {
	my ($self, $idx, $data) = @_;
	my $delta = 0;
	my $end = $#{$self->{data}};
	$idx = $end if $idx > $end;
	$idx = 0 if $idx < 0;
	ITEM:
	while(1) {
		if($idx + $delta <= $end) {
			return Future->wrap(
				$idx + $delta
			) if $self->{data}[$idx + $delta] eq $data;
		}
		if($idx - $delta >= 0) {
			return Future->wrap(
				$idx - $delta
			) if $self->{data}[$idx - $delta] eq $data;
		}
		last ITEM if $idx + $delta > $end && $idx - $delta < 0;
		++$delta;
	}
	Future->fail('not found');
}

=head1 count

=cut

sub count {
	my $self = shift;
	Future->wrap(scalar @{$self->{data}});
}

=head1 get

=cut

sub get {
	my ($self, %args) = @_;
	return Future->fail('unknown item') if grep $_ > @{$self->{data}}, @{$args{items}};
	my @items = @{$self->{data}}[@{$args{items}}];
	if(my $code = $args{on_item}) {
		my @idx = @{$args{items}};
		$code->(shift(@idx), $_) for @items;
	}
	Future->wrap(\@items)
}

=head2 range

Retrieves all items in a range.

=over 4

=item * start

=item * end

=item * count

=item * on_item

=back

=cut

sub range {
	my ($self, %args) = @_;
	my $idx = delete $args{start} || 0;
	my $code = delete $args{on_item};
	my $max = $#{$self->{data}};
	$args{end} //= $idx + $args{count} if exists $args{count};
	$args{end} //= $max;
	while($idx < $args{end}) {
		last if $idx > $max;
		$code->($idx, $self->{data}[$idx]);
		++$idx;
	}
	Future->done
}

sub find_idx {
	my ($self, $item, $code) = @_;
	require List::BinarySearch;
	$code ||= sub { ($a // '') cmp ($b // '') };
	my $idx = List::BinarySearch::binsearch($code, $item, $self->{data});
	return defined($idx) ? Future->done($idx) : Future->fail('not found');
}

sub find_insert_pos {
	my ($self, $item, $code) = @_;
	require List::BinarySearch;
	$code ||= sub { ($a // '') cmp ($b // '') };
	my $idx = List::BinarySearch::binsearch_pos($code, $item, $self->{data});
	return defined($idx) ? Future->done($idx) : Future->fail('not found');
}

sub extract_first_by {
	my ($self, $code, $start_idx) = @_;
	$start_idx //= 0;
	for my $idx ($start_idx..$#{$self->{data}}) {
		if(grep $code->($_), $self->{data}[$idx]) {
			return Future->done(CORE::splice @{$self->{data}}, $idx, 1);
		}
	}
	return Future->done;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
