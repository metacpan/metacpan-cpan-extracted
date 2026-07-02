package Data::SortedSet::Shared::Strings;
use strict;
use warnings;
use Carp ();
use Data::Intern::Shared ();
use Data::SortedSet::Shared ();

our $VERSION = '0.02';

# ---- construction ----

sub new {
    my ($class, %opt) = @_;
    my $max = $opt{max};
    Carp::croak("new: 'max' is required") unless defined $max;
    my $set  = Data::SortedSet::Shared->new($opt{set}, $max);
    my $keys = Data::Intern::Shared->new($opt{keys}, $opt{max_keys} // $max, $opt{arena} // 0);
    return bless { set => $set, keys => $keys }, $class;
}

# wrap two already-constructed shared objects (e.g. memfd-backed)
sub wrap {
    my ($class, $set, $keys) = @_;
    Carp::croak("wrap: expected a Data::SortedSet::Shared")
        unless ref $set && $set->isa('Data::SortedSet::Shared');
    Carp::croak("wrap: expected a Data::Intern::Shared")
        unless ref $keys && $keys->isa('Data::Intern::Shared');
    return bless { set => $set, keys => $keys }, $class;
}

sub set        { $_[0]{set} }     # the underlying Data::SortedSet::Shared
sub key_table  { $_[0]{keys} }    # the underlying Data::Intern::Shared

# ---- mutators (intern the key -> id) ----

sub add {
    my ($self, $str, $score) = @_;
    my $id = $self->{keys}->intern($str);
    return undef unless defined $id;          # key table full
    return $self->{set}->add($id, $score);
}

sub incr {
    my ($self, $str, $delta) = @_;
    my $id = $self->{keys}->intern($str);
    Carp::croak("incr: key table full") unless defined $id;
    return $self->{set}->incr($id, $delta);
}

sub remove {
    my ($self, $str) = @_;
    my $id = $self->{keys}->id_of($str);
    return defined $id ? $self->{set}->remove($id) : 0;
}

sub add_many {
    my ($self, $rows) = @_;
    Carp::croak("add_many: expected an arrayref") unless ref $rows eq 'ARRAY';
    my @id_rows;
    for my $r (@$rows) {
        next unless ref $r eq 'ARRAY' && @$r >= 2;
        next if $r->[1] != $r->[1];           # skip a NaN score before interning (no ghost key slot)
        my $id = $self->{keys}->intern($r->[0]);
        last unless defined $id;              # key table full -> stop
        push @id_rows, [ $id, $r->[1] ];
    }
    return $self->{set}->add_many(\@id_rows);
}

sub clear { $_[0]{set}->clear; $_[0]{keys}->clear; return }

# ---- lookup (id_of the key; undef short-circuits) ----

sub score    { my $id = $_[0]{keys}->id_of($_[1]); defined $id ? $_[0]{set}->score($id)    : undef }
sub rank     { my $id = $_[0]{keys}->id_of($_[1]); defined $id ? $_[0]{set}->rank($id)     : undef }
sub rev_rank { my $id = $_[0]{keys}->id_of($_[1]); defined $id ? $_[0]{set}->rev_rank($id) : undef }
sub exists   { my $id = $_[0]{keys}->id_of($_[1]); defined $id ? $_[0]{set}->exists($id)   : 0 }
sub count          { $_[0]{set}->count }
sub count_in_score { shift->{set}->count_in_score(@_) }

# ---- rank / range (decode ids back to strings) ----

sub _decode {
    my ($self, $ws, @list) = @_;
    my $k = $self->{keys};
    return map { $k->string($_) } @list unless $ws;
    my @out;
    for (my $i = 0; $i < @list; $i += 2) { push @out, $k->string($list[$i]), $list[$i + 1] }
    return @out;
}

sub at_rank {
    my $id = $_[0]{set}->at_rank($_[1]);
    return defined $id ? $_[0]{keys}->string($id) : undef;
}

sub range_by_rank {
    my ($self, $start, $stop, %opt) = @_;
    $self->_decode($opt{withscores}, $self->{set}->range_by_rank($start, $stop, %opt));
}
sub rev_range_by_rank {
    my ($self, $start, $stop, %opt) = @_;
    $self->_decode($opt{withscores}, $self->{set}->rev_range_by_rank($start, $stop, %opt));
}
sub range_by_score {
    my ($self, $min, $max, %opt) = @_;
    $self->_decode($opt{withscores}, $self->{set}->range_by_score($min, $max, %opt));
}
sub rev_range_by_score {
    my ($self, $max, $min, %opt) = @_;
    $self->_decode($opt{withscores}, $self->{set}->rev_range_by_score($max, $min, %opt));
}

# ---- pop / peek (id -> string) ----

for my $m (qw(pop_min pop_max peek_min peek_max)) {
    no strict 'refs';
    *$m = sub {
        my ($id, $score) = $_[0]{set}->$m;
        return defined $id ? ($_[0]{keys}->string($id), $score) : ();
    };
}

# ---- iteration ----

sub each {
    my ($self, $cb) = @_;
    my $k = $self->{keys};
    $self->{set}->each(sub { $cb->($k->string($_[0]), $_[1]) });
    return;
}

# ---- lifecycle ----

sub sync  { $_[0]{set}->sync; $_[0]{keys}->sync; return }
sub unlink { $_[0]{set}->unlink; $_[0]{keys}->unlink; return }
sub stats { { set => $_[0]{set}->stats, keys => $_[0]{keys}->stats } }

1;
__END__

=encoding utf-8

=head1 NAME

Data::SortedSet::Shared::Strings - string-keyed shared-memory sorted set (ZSET)

=head1 SYNOPSIS

    use Data::SortedSet::Shared::Strings;

    # anonymous (fork-shared); or pass set => $path, keys => $path for file-backed
    my $z = Data::SortedSet::Shared::Strings->new(max => 1_000_000);

    $z->add("alice", 1500);
    $z->incr("alice", 50);                       # 1550
    my @top   = $z->rev_range_by_rank(0, 9);     # ("alice", "bob", ...)
    my $score = $z->score("alice");
    my ($who, $sc) = $z->pop_min;                # remove + return the lowest

=head1 DESCRIPTION

A string-keyed sorted set in shared memory: the same API as
L<Data::SortedSet::Shared> but with B<string members> instead of int64 ids. It is
a thin layer composing two shared structures -- a L<Data::SortedSet::Shared> for
the (id, score) ordering and a L<Data::Intern::Shared> mapping each string key to
a dense id. Keys are interned on the way in and decoded back to strings on the way
out.

Because both backing stores live in shared memory, the set works B<across
processes>: every process resolves a key to the same id, so a string-keyed
leaderboard, priority queue, or rate limiter can be shared by many workers.

Ties among equal scores break by interning id (roughly insertion order of
first-seen keys), B<not> lexicographically. Keys are interned by byte content and
stay interned until C<clear> (see L<Data::Intern::Shared/LIMITS>). B<Linux-only>, 64-bit Perl.

=head1 METHODS

=head2 Construction

    my $z = Data::SortedSet::Shared::Strings->new(
        max      => $max_members,     # required
        set      => $path_or_undef,   # SortedSet backing (undef = anonymous)
        keys     => $path_or_undef,   # Intern backing    (undef = anonymous)
        max_keys => $max_members,     # distinct-key capacity (default: max)
        arena    => $bytes,           # key-arena bytes (default: max_keys * 32)
    );

    my $z = Data::SortedSet::Shared::Strings->wrap($set, $intern);

C<new> creates (or reopens) both backing stores; for cross-process file-backed use,
every process passes the same C<set>/C<keys> paths. C<wrap> wraps two
already-constructed objects (e.g. memfd-backed ones shared by fd). C<set> and
C<key_table> return the underlying L<Data::SortedSet::Shared> and
L<Data::Intern::Shared> objects.

=head2 API

Every method takes/returns B<string> members; otherwise the semantics are exactly
those of L<Data::SortedSet::Shared>:

    $z->add($str, $score);     # 1 new / 0 updated / undef if a pool is full
    $z->incr($str, $delta);    # add to the score (creates the key if absent); returns the new score
    $z->remove($str);          # true if removed, false if absent
    $z->add_many([ [$s1,$sc1], ... ]);
    $z->clear;

    $z->score($str); $z->rank($str); $z->rev_rank($str); $z->exists($str);
    $z->count; $z->count_in_score($min, $max);

    $z->at_rank($r);
    $z->range_by_rank($start, $stop, %opts);     # ($str, ...) or ($str,$score,...) with withscores
    $z->rev_range_by_rank($start, $stop, %opts);
    $z->range_by_score($min, $max, %opts);       # limit / offset / withscores
    $z->rev_range_by_score($max, $min, %opts);

    my ($str, $score) = $z->pop_min;  # pop_max / peek_min / peek_max
    $z->each(sub { my ($str, $score) = @_; ... });

    $z->sync; $z->unlink; $z->stats;   # stats: { set => {...}, keys => {...} }

C<remove> leaves the key interned (ids are stable); the key universe (C<max_keys>)
must therefore accommodate every distinct key ever added, not just those currently
present. C<clear> is the one exception -- it resets B<both> the set and the key
table, so ids minted before a C<clear> no longer resolve. C<add> returns C<undef>
(and C<incr> croaks) if the key table or the member pool is full. C<add_many>
interns each row's key in order, stopping only if the key table fills, then
bulk-adds; it returns the number of members B<newly inserted> (fewer than the rows
given if either pool fills -- keys interned past the member pool's capacity stay
interned but unadded). Malformed rows and NaN-scored rows are skipped without
interning their key.

=head1 SEE ALSO

L<Data::SortedSet::Shared>, L<Data::Intern::Shared>.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
