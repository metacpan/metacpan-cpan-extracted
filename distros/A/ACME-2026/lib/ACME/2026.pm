package ACME::2026;

use 5.008003;
use strict;
use warnings;

use Carp qw(croak);
use Exporter 'import';
use File::Temp qw(tempfile);
use JSON::PP ();
use POSIX qw(strftime);

=head1 NAME

ACME::2026 - Checklists for glorious 2026 goals

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @EXPORT_OK = qw(
  plan_new plan_load plan_save
  add_item update_item delete_item get_item
  add_note complete_item skip_item reopen_item
  items stats
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=head1 SYNOPSIS

  use ACME::2026 qw(:all);

  my $plan = plan_new(
    title => '2026',
    storage => '2026.json',
    autosave => 1,
  );

  my $id = add_item($plan, 'Run a marathon',
    list => 'Health',
    due => '2026-10-01',
    tags => [qw/fitness endurance/],
    priority => 2,
  );

  complete_item($plan, $id, note => 'Signed up for NYC');
  my @open = items($plan, status => 'todo', list => 'Health', sort => 'due');

  plan_save($plan);

=head1 DESCRIPTION

ACME::2026 is a tiny functional API for keeping 2026 checklists. It stores
plans as plain Perl hashrefs and can persist them to JSON.

=head1 DATA MODEL

Plan hashref:

  {
    title       => '2026',
    items       => [ ... ],
    next_id     => 1,
    created_at  => '2026-01-01T12:00:00Z',
    updated_at  => '2026-01-01T12:00:00Z',
    storage     => '2026.json',
    autosave    => 1,
  }

Item hashref:

  {
    id         => 1,
    title      => 'Run a marathon',
    status     => 'todo',
    list       => 'Health',
    tags       => ['fitness'],
    priority   => 2,
    due        => '2026-10-01',
    notes      => [ { note => 'Signed up', at => '2026-02-10T09:00:00Z' } ],
    created_at => '2026-01-01T12:00:00Z',
    updated_at => '2026-02-10T09:00:00Z',
  }

Status values are C<todo>, C<done>, or C<skipped>. Dates are ISO 8601 strings
(C<YYYY-MM-DD> or C<YYYY-MM-DDTHH:MM:SSZ>).

=head1 FUNCTIONS

=head2 plan_new

  my $plan = plan_new(%opts);

Creates a new plan hashref. Supported options:

  title    - plan title (default: 2026)
  storage  - JSON path used by plan_save and autosave
  autosave - boolean, save after mutating operations

=head2 plan_load

  my $plan = plan_load($path, %opts);

Loads a JSON file from C<$path>. The plan is normalized to ensure required
fields exist. You can override C<title> or C<autosave> with C<%opts>.

=head2 plan_save

  plan_save($plan);
  plan_save($plan, $path);

Writes the plan as JSON. Uses C<$plan-E<gt>{storage}> if no path is provided.

=head2 add_item

  my $id = add_item($plan, $title, %opts);

Adds an item and returns its id. Supported options:

  list, tags (arrayref or string), priority, due, note

=head2 update_item

  my $item = update_item($plan, $id, %attrs);

Updates a few fields in place: C<title>, C<list>, C<tags>, C<priority>, C<due>.
Use C<add_note> or the status helpers for notes and status changes.

=head2 delete_item

  my $item = delete_item($plan, $id);

Removes an item and returns it.

=head2 get_item

  my $item = get_item($plan, $id);

Returns the item or C<undef> if it does not exist.

=head2 add_note

  add_note($plan, $id, $note);

Appends a note with a timestamp.

=head2 complete_item

  complete_item($plan, $id, %opts);

Sets the status to C<done>. If C<note> is supplied, it is added.

=head2 skip_item

  skip_item($plan, $id, %opts);

Sets the status to C<skipped>. If C<note> is supplied, it is added.

=head2 reopen_item

  reopen_item($plan, $id, %opts);

Sets the status back to C<todo>. If C<note> is supplied, it is added.

=head2 items

  my @items = items($plan, %filters);

Filters items with any of:

  status, list, tag, tags, priority, min_priority, max_priority,
  due_before, due_after, sort

For C<tag> or C<tags>, any matching tag is enough. C<sort> supports:
C<due>, C<priority>, C<created>, C<updated>, or C<title>. Prefix with C<->
for descending order.

=head2 stats

  my $stats = stats($plan, %filters);

Returns a hashref with C<total>, C<todo>, C<done>, C<skipped>, and
C<complete_pct>.

=cut

sub plan_new {
    my %opts = _normalize_opts(@_);

    my $now = _now();
    my $plan = {
        title      => defined $opts{title} ? $opts{title} : '2026',
        items      => [],
        next_id    => 1,
        created_at => $now,
        updated_at => $now,
        storage    => $opts{storage},
        autosave   => $opts{autosave} ? 1 : 0,
    };

    return $plan;
}

sub plan_load {
    my ($path, %opts) = @_;
    croak 'plan_load requires a path' unless defined $path && length $path;

    my $json = _read_file($path);
    my $data = eval { JSON::PP->new->decode($json) };
    croak "Failed to decode JSON from $path: $@" if $@;

    _normalize_plan($data);

    $data->{storage} = $path;
    $data->{title} = $opts{title} if exists $opts{title};
    $data->{autosave} = $opts{autosave} ? 1 : 0 if exists $opts{autosave};

    return $data;
}

sub plan_save {
    my ($plan, $path) = @_;
    _ensure_plan($plan);

    $path ||= $plan->{storage};
    croak 'plan_save requires a path or plan storage' unless defined $path && length $path;

    _normalize_plan($plan);

    my $encoder = JSON::PP->new->canonical(1)->pretty(1);
    my $json = $encoder->encode($plan);
    _write_file_atomic($path, $json);

    return 1;
}

sub add_item {
    my ($plan, @args) = @_;
    _ensure_plan($plan);

    my ($title, %opts);
    if (@args % 2 == 1) {
        $title = shift @args;
        %opts = @args;
    } else {
        %opts = @args;
        $title = $opts{title};
    }

    croak 'add_item requires a title' unless defined $title && length $title;
    _reject_unknown('add_item', \%opts, qw(title list tags tag priority due note));

    my $now = _now();
    my $item = {
        id         => $plan->{next_id}++,
        title      => $title,
        status     => 'todo',
        list       => defined $opts{list} ? $opts{list} : 'General',
        tags       => _normalize_tags($opts{tags}, $opts{tag}),
        priority   => defined $opts{priority} ? $opts{priority} : 3,
        due        => $opts{due},
        notes      => [],
        created_at => $now,
        updated_at => $now,
    };

    push @{ $plan->{items} }, $item;
    if (defined $opts{note}) {
        _add_note($plan, $item, $opts{note});
    } else {
        _touch($plan);
    }
    _maybe_autosave($plan);

    return $item->{id};
}

sub update_item {
    my ($plan, $id, %attrs) = @_;
    _ensure_plan($plan);

    my $item = _find_item($plan, $id);
    croak "No item with id $id" unless $item;

    _reject_unknown('update_item', \%attrs, qw(title list tags tag priority due));

    my $changed = 0;
    for my $key (qw(title list priority due)) {
        next unless exists $attrs{$key};
        $item->{$key} = $attrs{$key};
        $changed = 1;
    }

    if (exists $attrs{tags} || exists $attrs{tag}) {
        $item->{tags} = _normalize_tags($attrs{tags}, $attrs{tag});
        $changed = 1;
    }

    return $item unless $changed;

    $item->{updated_at} = _now();
    _touch($plan);
    _maybe_autosave($plan);

    return $item;
}

sub delete_item {
    my ($plan, $id) = @_;
    _ensure_plan($plan);

    my $items = $plan->{items};
    for my $idx (0 .. $#$items) {
        next unless defined $items->[$idx]{id} && $items->[$idx]{id} == $id;
        my $item = splice(@$items, $idx, 1);
        _touch($plan);
        _maybe_autosave($plan);
        return $item;
    }

    return;
}

sub get_item {
    my ($plan, $id) = @_;
    _ensure_plan($plan);
    return _find_item($plan, $id);
}

sub add_note {
    my ($plan, $id, $note) = @_;
    _ensure_plan($plan);
    croak 'add_note requires a note' unless defined $note && length $note;

    my $item = _find_item($plan, $id);
    croak "No item with id $id" unless $item;

    _add_note($plan, $item, $note);
    _maybe_autosave($plan);

    return $item;
}

sub complete_item {
    my ($plan, $id, %opts) = @_;
    return _set_status($plan, $id, 'done', %opts);
}

sub skip_item {
    my ($plan, $id, %opts) = @_;
    return _set_status($plan, $id, 'skipped', %opts);
}

sub reopen_item {
    my ($plan, $id, %opts) = @_;
    return _set_status($plan, $id, 'todo', %opts);
}

sub items {
    my ($plan, %filters) = @_;
    _ensure_plan($plan);

    my @items = @{ $plan->{items} || [] };

    if (defined $filters{status}) {
        my $status = _normalize_status($filters{status});
        @items = grep { $_->{status} eq $status } @items;
    }

    if (defined $filters{list}) {
        @items = grep { defined $_->{list} && $_->{list} eq $filters{list} } @items;
    }

    my @tags;
    push @tags, $filters{tag} if defined $filters{tag};
    if (defined $filters{tags}) {
        if (ref $filters{tags} eq 'ARRAY') {
            push @tags, @{ $filters{tags} };
        } else {
            push @tags, $filters{tags};
        }
    }

    if (@tags) {
        @items = grep {
            my %item_tags = map { $_ => 1 } @{ $_->{tags} || [] };
            my $match = 0;
            for my $tag (@tags) {
                next unless defined $tag && length $tag;
                if ($item_tags{$tag}) {
                    $match = 1;
                    last;
                }
            }
            $match;
        } @items;
    }

    if (defined $filters{priority}) {
        @items = grep { defined $_->{priority} && $_->{priority} == $filters{priority} } @items;
    }

    if (defined $filters{min_priority}) {
        @items = grep { defined $_->{priority} && $_->{priority} >= $filters{min_priority} } @items;
    }

    if (defined $filters{max_priority}) {
        @items = grep { defined $_->{priority} && $_->{priority} <= $filters{max_priority} } @items;
    }

    if (defined $filters{due_before}) {
        @items = grep { defined $_->{due} && $_->{due} le $filters{due_before} } @items;
    }

    if (defined $filters{due_after}) {
        @items = grep { defined $_->{due} && $_->{due} ge $filters{due_after} } @items;
    }

    if (defined $filters{sort}) {
        @items = _sort_items(\@items, $filters{sort});
    }

    return @items;
}

sub stats {
    my ($plan, %filters) = @_;
    _ensure_plan($plan);

    my @items = items($plan, %filters);
    my %stats = (
        total => scalar @items,
        todo => 0,
        done => 0,
        skipped => 0,
    );

    for my $item (@items) {
        $stats{ $item->{status} }++ if exists $stats{ $item->{status} };
    }

    $stats{complete_pct} = $stats{total}
        ? int(($stats{done} / $stats{total}) * 100 + 0.5)
        : 0;

    return \%stats;
}

sub _set_status {
    my ($plan, $id, $status, %opts) = @_;
    _ensure_plan($plan);

    _reject_unknown('_set_status', \%opts, qw(note));
    my $item = _find_item($plan, $id);
    croak "No item with id $id" unless $item;

    $item->{status} = _normalize_status($status);
    $item->{updated_at} = _now();
    if (defined $opts{note}) {
        _add_note($plan, $item, $opts{note});
    } else {
        _touch($plan);
    }
    _maybe_autosave($plan);

    return $item;
}

sub _normalize_opts {
    return %{ $_[0] } if @_ == 1 && ref $_[0] eq 'HASH';
    return @_;
}

sub _normalize_plan {
    my ($plan) = @_;
    _ensure_plan($plan);

    $plan->{title} = '2026' unless defined $plan->{title} && length $plan->{title};
    $plan->{items} = [] unless ref $plan->{items} eq 'ARRAY';
    $plan->{autosave} = $plan->{autosave} ? 1 : 0;

    my $max_id = 0;
    for my $item (@{ $plan->{items} }) {
        next unless ref $item eq 'HASH';
        $max_id = $item->{id} if defined $item->{id} && $item->{id} > $max_id;
    }

    $plan->{next_id} = $plan->{next_id} || ($max_id + 1);
    my $next_id = $plan->{next_id};

    for my $item (@{ $plan->{items} }) {
        next unless ref $item eq 'HASH';
        if (!defined $item->{id}) {
            $item->{id} = $next_id++;
        }
        $item->{status} = _normalize_status($item->{status});
        $item->{tags} = _normalize_tags($item->{tags});
        $item->{notes} = _normalize_notes($item->{notes});
        $item->{priority} = defined $item->{priority} ? $item->{priority} : 3;
        $item->{list} = defined $item->{list} ? $item->{list} : 'General';
        $item->{created_at} = _now() unless defined $item->{created_at};
        $item->{updated_at} = $item->{created_at} unless defined $item->{updated_at};
    }

    $plan->{next_id} = $next_id if $next_id > $plan->{next_id};
    $plan->{created_at} = _now() unless defined $plan->{created_at};
    $plan->{updated_at} = $plan->{created_at} unless defined $plan->{updated_at};

    return $plan;
}

sub _normalize_status {
    my ($status) = @_;
    $status = 'todo' if !defined $status || $status eq '';
    return $status if $status eq 'todo' || $status eq 'done' || $status eq 'skipped';
    croak "Unknown status '$status'";
}

sub _normalize_tags {
    my ($tags, $tag) = @_;
    my @tags;

    if (defined $tags) {
        if (ref $tags eq 'ARRAY') {
            @tags = @$tags;
        } else {
            @tags = ($tags);
        }
    }

    push @tags, $tag if defined $tag;

    @tags = grep { defined $_ && length $_ } @tags;
    return \@tags;
}

sub _normalize_notes {
    my ($notes) = @_;
    return [] unless defined $notes;
    if (ref $notes eq 'ARRAY') {
        my @out;
        for my $note (@$notes) {
            if (ref $note eq 'HASH') {
                push @out, $note;
            } else {
                push @out, { note => $note };
            }
        }
        return \@out;
    }
    return [ { note => $notes } ];
}

sub _ensure_plan {
    my ($plan) = @_;
    croak 'Plan must be a hashref' unless ref $plan eq 'HASH';
}

sub _find_item {
    my ($plan, $id) = @_;
    return unless defined $id;
    for my $item (@{ $plan->{items} || [] }) {
        next unless defined $item->{id};
        return $item if $item->{id} == $id;
    }
    return;
}

sub _add_note {
    my ($plan, $item, $note) = @_;
    return unless defined $note && length $note;

    push @{ $item->{notes} }, { note => $note, at => _now() };
    $item->{updated_at} = _now();
    _touch($plan);
}

sub _touch {
    my ($plan) = @_;
    $plan->{updated_at} = _now();
}

sub _maybe_autosave {
    my ($plan) = @_;
    return unless $plan->{autosave};
    plan_save($plan);
}

sub _sort_items {
    my ($items, $sort) = @_;
    return @$items unless defined $sort && length $sort;

    my $desc = ($sort =~ s/^-//);

    if ($sort eq 'due') {
        return sort {
            my $ad = defined $a->{due} ? $a->{due} : ($desc ? '0000-00-00' : '9999-12-31');
            my $bd = defined $b->{due} ? $b->{due} : ($desc ? '0000-00-00' : '9999-12-31');
            my $cmp = $ad cmp $bd;
            $desc ? -$cmp : $cmp;
        } @$items;
    }

    if ($sort eq 'priority') {
        return sort {
            my $ad = defined $a->{priority} ? $a->{priority} : 0;
            my $bd = defined $b->{priority} ? $b->{priority} : 0;
            my $cmp = $ad <=> $bd;
            $desc ? -$cmp : $cmp;
        } @$items;
    }

    if ($sort eq 'created') {
        return sort {
            my $cmp = ($a->{created_at} || '') cmp ($b->{created_at} || '');
            $desc ? -$cmp : $cmp;
        } @$items;
    }

    if ($sort eq 'updated') {
        return sort {
            my $cmp = ($a->{updated_at} || '') cmp ($b->{updated_at} || '');
            $desc ? -$cmp : $cmp;
        } @$items;
    }

    if ($sort eq 'title') {
        return sort {
            my $cmp = lc($a->{title} || '') cmp lc($b->{title} || '');
            $desc ? -$cmp : $cmp;
        } @$items;
    }

    return @$items;
}

sub _reject_unknown {
    my ($context, $attrs, @known) = @_;
    my %known = map { $_ => 1 } @known;
    my @unknown = grep { !$known{$_} } keys %$attrs;
    return unless @unknown;
    croak "$context does not accept: " . join(', ', sort @unknown);
}

sub _now {
    return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}

sub _read_file {
    my ($path) = @_;
    open my $fh, '<', $path or croak "Unable to read $path: $!";
    local $/;
    return <$fh>;
}

sub _write_file_atomic {
    my ($path, $content) = @_;
    my ($fh, $tmp) = tempfile('acme2026-XXXXXX', DIR => _temp_dir($path));
    print {$fh} $content or croak "Unable to write $tmp: $!";
    close $fh or croak "Unable to close $tmp: $!";
    rename $tmp, $path or croak "Unable to move $tmp to $path: $!";
}

sub _temp_dir {
    my ($path) = @_;
    return '.' unless defined $path && length $path;
    if ($path =~ /[\/\\]/) {
        $path =~ s/[\/\\][^\/\\]+$//;
        return length $path ? $path : '.';
    }
    return '.';
}

=head1 AUTHOR

Will Willis <wwillis@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-2026 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=ACME-2026>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc ACME::2026

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=ACME-2026>

=item * Search CPAN

L<https://metacpan.org/release/ACME-2026>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Will Willis <wwillis@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of ACME::2026
