# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::SharedIndex;

sub new ($%) {
	my $class = shift;
	my %init = @_;

	my $file = $init{file} or die "No index file given\n";
	my $can_create = exists $init{can_create}? $init{can_create}: 1;
	my $time_renewal = exists $init{time_renewal}? $init{time_renewal}:
		$init{max_size}? 1: 0;

	my $self = {
		file => $file,
		can_create => $can_create,
		max_size => int($init{max_size} || 0),
		expiration => int($init{expiration} || 0),
		time_renewal => $time_renewal,
		perl_data => $init{perl_data} || 0,
		perl_data_indent => $init{perl_data_indent} || 0,
		perl_data_pair   => $init{perl_data_pair} || "=>",
	};

	bless $self, $class;
	return $self;
}

sub encode_value ($$) {
	my $self = shift;
	return unless $self->{perl_data};
	my $value = shift;
	# Data::Dumper is one of the silly-API modules; configure every time.
	# Object oriented API is a bit slower and less backward compatible.
	# Avoid unused variable warnings by separate declaration/assignment.
	require Data::Dumper;
	local $Data::Dumper::Indent;
	local $Data::Dumper::Pair;
	local $Data::Dumper::Quotekeys;
	local $Data::Dumper::Terse;
	$Data::Dumper::Indent = $self->{perl_data_indent};
	$Data::Dumper::Pair   = $self->{perl_data_pair};
	$Data::Dumper::Quotekeys = 0;
	$Data::Dumper::Terse  = 1;
	$$value = Data::Dumper->Dump([$$value]);
}

sub decode_value ($$) {
	my $self = shift;
	return unless $self->{perl_data};
	my $value = shift;
	$$value = eval $$value;
}

sub delete_value ($$$) {
	my $self = shift;
	my ($key, $token) = @_;
	# super class implementation
}

sub fetch_value ($$$) {
	my $self = shift;
	my ($key, $token) = @_;

	# super class implementation
	my $value = $token;
	$self->decode_value(\$value);
	return $value;
}

sub store_value ($$$) {
	my $self = shift;
	my ($key, $token, $value) = @_;

	# super class implementation
	$self->encode_value(\$value);
	$token = $value;
	return $token;
}

sub index_list_to_hash ($$) {
	my $self = shift;
	my $index_list = shift;

	my $index_hash = {};
	foreach my $entry (@$index_list) {
		$index_hash->{$entry->[0]} = $entry;
	}
	return $index_hash;
}

sub _do_delete ($$$) {
	my $self = shift;
	my $index_list = shift;
	my $keys = shift;

	my %keys = map { $_ => 1 } @$keys;
	for (my $num = @$index_list - 1; %keys && $num >= 0; $num--) {
		my $index_entry = $index_list->[$num];
		my ($key, $token) = @$index_entry;
		next unless $keys{$key};
		$self->delete_value($key, $token);
		splice(@$index_list, $num, 1);
		delete $keys{$key};
	}
	return @$keys - keys %keys;
}

sub _do_fetch ($$$) {
	my $self = shift;
	my $index_list = shift;
	my $keys = shift;
	my @values = ();
	my $index_hash = $self->index_list_to_hash($index_list);

	my $time;
	foreach my $key (@$keys) {
		my $index_entry = $index_hash->{$key};
		my $value = $index_entry?
			$self->fetch_value(@$index_entry): undef;
		if (defined $value && $self->{time_renewal}) {
			$time ||= time();
			$index_entry->[2] = $time;
		}
		push @values, $value;
	}
	return \@values;
}

sub _do_store ($$$) {
	my $self = shift;
	my $index_list = shift;
	my @new_key_values = @{shift()};
	my $entries_stored = 0;
	my $index_hash = $self->index_list_to_hash($index_list);

	my $time = time;
	my %seen = ();
	while (my ($key, $value) = splice(@new_key_values, 0, 2)) {
		next if $seen{$key}; $seen{$key} = 1;
		my $old_entry = $index_hash->{$key};
		my $old_token = $old_entry? $old_entry->[1]: undef;
		my $new_token = $self->store_value($key, $old_token, $value);
		next unless defined $new_token;

		my $new_entry = [ $key, $new_token, $time ];
		if (defined $old_entry) {
			@$old_entry = @$new_entry;
		} else {
			push @$index_list, $new_entry;
		}
		$entries_stored++;
	}
	return $entries_stored;
}

sub delete ($@) {
	my $self = shift;
	my $keys = ref($_[0]) eq 'ARRAY'? shift: [ @_ ];
	my $entries_deleted;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		$entries_deleted = $self->_do_delete($index_list, $keys);
	});
	return $entries_deleted;
}

sub fetch ($@) {
	my $self = shift;
	my $single_ref = ref($_[0]) eq 'ARRAY';
	my $keys = $single_ref? shift: [ @_ ];
	my $values = [];

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		$values = $self->_do_fetch($index_list, $keys);
	});
	return $single_ref? $values: wantarray? @$values: $values->[0];
}

sub store ($%) {
	my $self = shift;
	my $new_key_values =
		ref($_[0]) eq 'HASH'? [ %{shift()} ]:  # unordered
		ref($_[0]) eq 'ARRAY'? shift: [ @_ ];  # ordered
	my $entries_stored;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		$entries_stored = $self->_do_store($index_list, $new_key_values);
	});
	return $entries_stored;
}

sub fetch_store ($$@) {
	my $self = shift;
	my $code = shift || die "No code given";
	my $single_ref = ref($_[0]) eq 'ARRAY';
	my $keys = $single_ref? shift: [ @_ ];
	my $values;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		$values = $self->_do_fetch($index_list, $keys);
		my (@new_keys, @missing_idxs);
		my $run_idx = 0;
		@new_keys = grep { (defined $values->[$run_idx]? 0:
			push @missing_idxs, $run_idx) * ++$run_idx } @$keys;

		if ($ENV{DEBUG} && ("$ENV{DEBUG}" & "\2") ne "\0") {
			my $status = @new_keys? @new_keys == @$keys? "miss":
				"partial hit-miss": "hit";
			my $keystr = join(', ', @$keys);
			substr($keystr, 57) = "..." if length($keystr) > 60;
			print STDERR "Shared fetch_store ($keystr): $status\n";
		}
		return unless @new_keys;

		my @new_key_values = map { $_ => ref($code) ne 'CODE'?
			$code: &$code($_) } @new_keys;
		my $num_stored = $self->_do_store($index_list, \@new_key_values);
		warn "fetch_store: not all new values are actually stored\n"
			if $num_stored < @new_keys;
		@$values[@missing_idxs] =
			@new_key_values[map { $_ * 2 + 1 } 0 .. @new_keys - 1];
	});
	return $single_ref? $values: wantarray? @$values: $values->[0];
}

sub keys ($) {
	my $self = shift;
	my @keys;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		@keys = map { $_->[0] } @$index_list;
	});
	return wantarray? @keys: \@keys;
}

sub values ($) {
	my $self = shift;
	my @values;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		@values = map { $self->fetch_value(@$_) } @$index_list;
	});
	return wantarray? @values: \@values;
}

sub hash ($) {
	my $self = shift;
	my %hash;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		%hash = map { $_->[0] => $self->fetch_value(@$_) } @$index_list;
	});
	return wantarray? %hash: \%hash;
}

sub list ($) {
	my $self = shift;
	my @list;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		@list = map { [ $_->[0] => $self->fetch_value(@$_) ] }
			@$index_list;
	});
	return wantarray? @list: \@list;
}

sub grep ($;$) {
	my $self = shift;
	my $code = shift || sub { $_[1] };
	my @keys;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		@keys = map { $_->[0] }
			grep { &$code($_->[0], $self->fetch_value(@$_)) }
			@$index_list;
	});
	return wantarray? @keys: \@keys;
}

sub filter ($;$) {
	my $self = shift;
	my $code = shift || sub { $_[1] };
	my @keys;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		@keys = map { $_->[0] }
			grep { &$code($_->[0], $self->fetch_value(@$_)) }
			@$index_list;
		$self->_do_delete($index_list, \@keys);
	});
	return wantarray? @keys: \@keys;
}

sub update ($$;$) {
	my $self = shift;
	my $code = shift;
	my $grep_code = shift;
	die "No code or value given" unless defined $code;
	my $entries_updated;

	$self->query_index_list(sub ($) {
		my $index_list = shift;
		$entries_updated = $self->_do_store($index_list, [
			map { $_->[0] => ref($code) ne 'CODE'? $code:
				&$code($_->[0], $self->fetch_value(@$_)) }
			grep { $grep_code? &$grep_code(
				$_->[0], $self->fetch_value(@$_)): 1 }
			@$index_list
		]);
	});
	return $entries_updated;
}

sub query_index_list ($$) {
	my $self = shift;
	my $code = shift;

	my $file = $self->{file};
	if (!-f $file && $self->{can_create}) {
		open FH, ">$file" or die "Can't create index file ($file)\n";
		close FH;
	}
	-f $file or die "No index file ($file)\n";

	open FH, "+<$file" or die "Can't open $file for updating: $!\n";
	flock FH, 2;         # wait for exclusive lock
	seek FH, 0, 0;       # rewind to beginning
	my @content = <FH>;  # get current content
	chomp @content;

	my $index_list = [ grep { defined } map {
		/^(\d+)\t(.+?)\t(.*)/? [ $2, $3, $1 ]:
			warn("Corrupt line ($_) in $file; ignored\n"), undef
	} @content ];

	if ($self->{expiration}) {
		my $time = time();
		my $diff = $self->{expiration};
		my @expired_keys = map { $_->[0] }
			grep { $time - $_->[2] > $diff } @$index_list;
		$self->_do_delete($index_list, \@expired_keys) if @expired_keys;
	}

	# apply callback filter
	&$code($index_list);

	if ($self->{max_size} && @$index_list > $self->{max_size}) {
		my @excess_nums = (0 .. @$index_list - $self->{max_size} - 1);
		my @excess_keys = map { $_->[0] } (@$index_list)[@excess_nums];
		$self->_do_delete($index_list, \@excess_keys);
	}

	my @new_content = map { "$_->[2]\t$_->[0]\t$_->[1]" } @$index_list;
	my $is_changed = join('', @content) ne join('', @new_content);

	if ($is_changed) {
		seek FH, 0, 0;       # rewind again
		truncate FH, 0;      # empty the file
		print FH map { "$_$/" } @new_content;
	}
	close FH;            # release file
}

1;

__END__

=head1 NAME

Arch::SharedIndex - a synchronized data structure (map) for IPC

=head1 SYNOPSIS

    use Arch::SharedIndex;

    my $map = Arch::SharedIndex->new(file => "/tmp/logintimes.idx");
    my $time = time;
    $map->store(migo => $time - 75, bob => $time - 5, enno => $time);

    printf "All users: %s, %s, %s\n", $map->keys;
    printf "New users: %s\n", $map->grep(sub { $_[1] == $time });
    printf "Login time of migo: %s\n", $map->fetch('migo');

    $map->update(sub { $_[1] + 10 }, sub { $_[1] == $time });
    $map->store(migo => $time);
    $map->delete('bob');

    printf "Logged users with times: (%s)\n", join(", ", $map->hash);

=head1 DESCRIPTION

Arch::SharedIndex provides a key-value map that can be shared and
accessed safely by multiple processes.

=head1 METHODS

The following methods are available:

B<new>,
B<encode_value>,
B<decode_value>,
B<store_value>,
B<fetch_value>,
B<delete_value>,
B<store>,
B<fetch>,
B<delete>,
B<fetch_store>,
B<keys>,
B<values>,
B<hash>,
B<list>,
B<grep>,
B<filter>,
B<update>,
B<query_index_list>.

=over 4

=item B<new> I<options>

Create a new index object.  I<option> is a hash of parameters.

=over 4

=item B<file>

The path of the index file, used to store data.  Must not be omitted.

=item B<can_create>

Whether the index file is automatically created.  Defaults to 1.

=item B<max_size>

Maximum number of entries in the index.  Defaults to 0 (no limit).

=item B<expiration>

Timeout in seconds after which unused entries are removed.  Defaults
to 0 (don't expire entries)

=item B<time_renewal>

Whether fetching values resets the entry expiration timeout.  Defaults
to 1 if B<max_size> is set, 0 otherwise.

=item B<perl_data>

Whether non-scalar perl data can be stored.  If true, values are
encoded using Data::Dumper.

=item B<perl_data_indent>

Indent value for Data::Dumper when B<perl_data> is set.  Defaults to
0.

=item B<perl_data_pair>

Pair value for Data::Dumper when B<perl_data> is set.  Defaults to
C<=E<gt>>.

=back

=item B<encode_value> I<ref>

Encode the value referenced by I<ref> in a string representation.
The encoding is done in place.

=item B<decode_value> I<ref>

Decode a value encoded with B<encode_value> from its string
representation.  The decoding is done in place.

=item B<store_value> I<key> I<token> I<value>

Store a value for the given I<key> and I<token>.  Create a new token
if none is given.  Returns the (new) token.  Sub-classes should
implement this method.

=item B<fetch_value> I<key> I<token>

Fetch the value stored for the given I<key> and I<token>.  Sub-classes
should implement this method.

=item B<delete_value> I<key> I<token>

Delete a value stored for the given I<key> and I<value>.  Sub-classes
should implement this method.

=item B<store> I<kvp>

Store a set of key-value pairs.  I<kvp> may either be a reference to a
hash or array, or list of keys and values.

=item B<fetch> I<keys>

Fetch values stored for a list of keys. I<keys> may either be an array
reference, or a list of keys.

=item B<delete> I<keys>

Delete values stored for a list of keys.  I<keys> may either be an
array reference, or a list of keys.

=item B<fetch_store> I<mapfunc> I<keys>

This is an optimized (B<fetch> or B<store>) in a single step.  Fetch
values stored for keys, just like B<fetch>, but store values for the
missing keys in the process.  I<keys> may be an array reference or a list
of keys.  I<mapfunc> will be called once for every key in I<keys> that
has no associated value, with the key as its only argument.  Its return
value will be stored for that key.

=item B<keys>

Returns a list of all valid keys.  In scalar context, returns an array
reference.

Keys are returned in no particular order, but B<values> will return
values in matching order if the index has not been changed between
calls.

=item B<values>

Returns a list of all stored values.  In scalar context, returns an
array reference.

Values are returned in no particular order, but B<keys> will return
values in matching order if the index has not been changed between
calls.

=item B<hash>

Returns the stored keys and values as a perl hash.  In scalar context,
returns hash reference.

=item B<list>

Returns the stored keys and values as a list of pairs (array
references with two elements each).  In scalar context, returns an
array reference.

=item B<grep> I<predicate>

Returns a list of keys for which I<predicate> returns a true value.
I<predicate> is called once for every key, with the key and the stored
value as its first and second argument.

=item B<filter> I<predicate>

Deletes every entry for which I<predicate> returns a true value.
I<predicate> is called once for every key, with the key and the stored
value asi its first and second argument.

=item B<update> I<mapfunc> I<predicate>

Updates the value for every key for which I<predicate> returns a true
value with the return value from I<mapfunc>.  Both I<predicate> and
I<mapfunc> are called with the key and the stored values as their
first and second argument.

=item B<update_index_list> I<code>

Synchronize access and call I<code> with a reference to a list of
pairs, each containing the key and token, for every stored value.

Used internally by B<store>, B<fetch>, B<delete>, B<fetch_store>,
B<keys>, B<values>, B<hash>, B<list>, B<grep>, B<filter> and B<update>.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<Arch::SharedCache>.

=cut
