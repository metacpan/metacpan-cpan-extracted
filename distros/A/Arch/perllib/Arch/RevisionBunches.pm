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

package Arch::RevisionBunches;

use Arch::Util qw(date2daysago);

sub new ($%) {
	my $class = shift;
	my %args = @_;

	my $self = {
		bunched_revision_descs => [],
		new_revision_descs => [],
		bunches => [],
		versions => [],
		filepaths => [],
		bunch_size => 50,
		max_sumlen => undef,
		version => undef,
		final_revision => undef,
		final_filepath => undef,
		cb_remove_all_bunches => undef,
		cb_add_new_bunch => undef,
	};
	bless $self, $class;
	return $self->init(%args);
}

sub init ($%) {
	my $self = shift;
	my %args = @_;

	while (my ($key, $value) = each %args) {
		unless (exists $self->{$key}) {
			warn "Arch::RevisionBunches: unknown key $key, ignoring\n";
			next;
		}
		$self->{$key} = $value;
	}
	$self->{max_sumlen} = undef if $args{max_sumlen} &&
		!($args{max_sumlen} =~ /^\d+$/ && $args{max_sumlen} > 5);
	return $self;
}

sub add_revision_descs ($$%) {
	my $self = shift;
	my $revision_descs = shift;
	my %args = @_;
	my $max_sumlen = $self->{max_sumlen};

	foreach (@$revision_descs) {
		substr($_->{summary}, $max_sumlen - 3) = "..."
			if $max_sumlen && length($_->{summary}) > $max_sumlen;
		foreach my $arg (keys %args) {
			$_->{$arg} = $args{$arg};
		}
	}
	push @{$self->{new_revision_descs}}, @$revision_descs;
	return $self;
}

sub get ($) {
	my $self = shift;
	$self->rebunch if @{$self->{new_revision_descs}};
	return wantarray? @{$self->{bunches}}: $self->{bunches};
}

sub _set_bunch_interval_data ($$;$) {
	my $self = shift;
	my $bunch = shift || die;
	my $start_index = shift || 0;

	my $nr = @{$bunch->{revision_descs}};
	my $i = 1;
	my $idx2 = $nr > 1 ? -1 : undef;
	foreach my $idx (0, $idx2) {
		my $revision_desc = defined $idx && $bunch->{revision_descs}->[$idx];
		$bunch->{"name$i"} = $revision_desc? $revision_desc->{name}: undef;
		my ($daysago, $time, $tz) = $revision_desc?
			date2daysago($revision_desc->{date}): (undef) x 3;
		$bunch->{"daysago$i"} = $daysago;
		$bunch->{"time$i"} = $time;
		$bunch->{"tz$i"} = $tz;
		$i++;
	}
	$bunch->{size} = $nr;

	my %creators = ();
	my $nm = 0;
	foreach my $revision_desc (@{$bunch->{revision_descs}}) {
		my $creator = $revision_desc->{creator} || "";
		my $email = $revision_desc->{email} || "";
		my $entry = $creators{$creator,$email} ||= [ $creator, $email, 0 ];
		$entry->[2]++;
		$nm++ if $revision_desc->{is_merged};
	}
	my $nc = $bunch->{num_creators} = scalar keys %creators;
	$bunch->{num_other_creators} = $nc? $nc - 1: 0;
	($bunch->{main_creator}, $bunch->{main_email}) =
		@{ (sort { $b->[2] <=> $a->[2] } values %creators)[0] || [] };
	$bunch->{creator} = $bunch->{main_creator} . ($nc == 1? "": " among $nc creators");

	$bunch->{name} = $bunch->{name1};
	$bunch->{date} = $bunch->{daysago1};
	if ($bunch->{name2}) {
		$bunch->{name} .= " .. $bunch->{name2}";
		$bunch->{date} .= " .. $bunch->{daysago2}";
	}
	$bunch->{date} .= " days ago";
	$bunch->{summary} = "$nr revision" . ($nr == 1? "": "s");
	$bunch->{summary} .= ' (missing)' if $bunch->{is_missing} && $nm < $nr;
	$bunch->{summary} .= " ($nm merged)" if $nm > 0;

	$self->{cb_add_new_bunch}->($bunch, $start_index) if $self->{cb_add_new_bunch};
}

sub _invalidate_bunches ($) {
	my $self = shift;

	$self->{cb_remove_all_bunches}->() if $self->{cb_remove_all_bunches};

	unshift @{$self->{new_revision_descs}}, @{$self->{bunched_revision_descs}};
	@{$self->{bunched_revision_descs}} = ();
	@{$self->{bunches}} = ();
	@{$self->{versions}} = ();
	@{$self->{filepaths}} = ();
}

sub rebunch ($;$) {
	my $self = shift;
	my $bunch_size = shift;
	my $change_size = !!$bunch_size;
	$bunch_size ||= $self->{bunch_size} || die "No bunch size given";

	if ($change_size) {
		$self->{bunch_size} = $bunch_size;
		$self->_invalidate_bunches;
	}
	goto RETURN unless @{$self->{new_revision_descs}};

	my $last_bunch = $self->{bunches}->[-1];
	my $start_index = $last_bunch? @{$last_bunch->{revision_descs}}: 0;
	my $multi_version = !$self->{version};
	while (my $rd = shift @{$self->{new_revision_descs}}) {
		my $version = $rd->{version};
		my $is_missing = $rd->{is_missing};
		my $has_is_missing = defined $is_missing;
		my $filepath = $rd->{filepath};
		my $has_filepath = defined $filepath;
		my $is_bunch_property_changed = 0;

		if ($last_bunch && $multi_version && $last_bunch->{version} ne $version) {
			push @{$self->{versions}}, $version;
			$is_bunch_property_changed = 1;
		}
		if ($last_bunch && $has_is_missing && $last_bunch->{is_missing} ne $is_missing) {
			$is_bunch_property_changed = 1;
		}
		if (!$last_bunch || $has_filepath && $last_bunch->{filepath} ne $filepath) {
			push @{$self->{filepaths}}, $filepath;
			$is_bunch_property_changed = 1;
		}

		if (
			!$last_bunch || $is_bunch_property_changed ||
			@{$last_bunch->{revision_descs}} >= $bunch_size
		) {
			$self->_set_bunch_interval_data($last_bunch, $start_index) if $last_bunch;
			$start_index = 0;
			$last_bunch = { revision_descs => [] };
			$last_bunch->{version} = $version if $multi_version;
			$last_bunch->{filepath} = $filepath if $has_filepath;
			$last_bunch->{is_missing} = $is_missing if $has_is_missing;
			push @{$self->{bunches}}, $last_bunch;
		}
		push @{$last_bunch->{revision_descs}}, $rd;
		push @{$self->{bunched_revision_descs}}, $rd;
	}
	$self->_set_bunch_interval_data($last_bunch, $start_index) if $last_bunch;

	RETURN:
	return wantarray? @{$self->{bunches}}: $self->{bunches};
}

sub clear ($) {
	my $self = shift;

	$self->_invalidate_bunches;
	@{$self->{new_revision_descs}} = @{$self->{bunched_revision_descs}} = ();
	return $self;
}

sub reverse_revision_descs ($) {
	my $self = shift;

	$self->_invalidate_bunches;
	@{$self->{new_revision_descs}} = reverse(@{$self->{new_revision_descs}});
	return $self;
}

sub versions ($) {
	my $self = shift;
	return $self->{versions};
}

sub filepaths ($) {
	my $self = shift;
	return $self->{filepaths};
}

1;

__END__

=head1 NAME

Arch::RevisionBunches - manage bunches of related revisions

=head1 SYNOPSIS 

    use Arch::RevisionBunches;
    use Arch::Tree;

    my $rb = Arch::RevisionBunches->new;
    my $tree = Arch::Tree->new(".", own_logs => 1);
    $rb->add_revision_descs($tree->get_history_revision_descs);
    $rb->rebunch(25);  # the default is 50
    foreach my $bunch ($rb->get) {
        print "$bunch->{version}\n";
        print "    $_->{name}\t$_->{summary}\n"
            foreach @{$bunch->{revision_descs}};
    }
    foreach my $bunch ($rb->reverse_revision_descs->rebunch(30)) {
        print $bunch->{name1};
        print " .. $bunch->{name2}" if $bunch->{name2};
        print " ($bunch->{daysago1}";
        print " .. $bunch->{daysago2}" if $bunch->{name2};
        print " days ago)\n";
    }

=head1 DESCRIPTION

This class helps front-ends to group revisions. Such grouping is essential
when, for example, the version to be shown contains thousands of revisions.
The front-end may decide to show expandable bunches of 100 revisions each.

There is a support for revision descriptions (summary, date, creator, email,
and in some cases associated the file name and/or the associated version).
There is a constraint by convention, one bunch may only contain revisions of
the same version, and the ones associated with the same file if applicable.
It is possible to define an order of versions. It is possible to recreate
bunches (rebunch) using a different number of revisions. The constraint
defines the actual number of revisions in different bunches, it is not
guaranteed to be the same.

=head1 METHODS

The following methods are available:

B<new>,
B<init>,
B<add_revision_descs>,
B<versions>,
B<rebunch>,
B<get>,
B<clear>,
B<reverse_revision_descs>,
B<versions>,
B<filepaths>.

=over 4

=item B<new> [I<%args>]

Construct Arch::RevisionBunches object.

The I<%args> are passed to B<init> method.

=item B<init> [I<%args>]

The I<%args> keys may be I<bunch_size> (to use as the default bunch size
instead of 50), I<max_sumlen> (maximal summary length to keep including
trailing ellipsis, must be greater than 5), I<version> (if set, then all
revisions are assumed to be of one version, otherwise multiple versions are
assumed), I<final_revision> and I<final_filepath> (the final revision and
filepath for which the revision bunches are constructed). These last two
I<%args> keys are not really used yet.

=item B<add_revision_descs> [I<%constant_fields>]

Add revision descriptions that is arrayref of hashes. See other classes that
return such revision descriptions. If the I<%constant_fields> is given, then
add these to all revision descriptions (rarely needed).

Return the object, this enables chaining of B<get> or B<rebunch> method call.

=item B<rebunch> [I<bunch_size>]

Group newly added revisions if no I<bunch_size> is specified. Otherwise
regroup all revisions using a given I<bunch_size>. The default bunch size
may be specified in the constructor.

Return the same B<get> does.

=item B<get>

Return bunches that is arrayref in scalar context, array in list context.

Each bunch is hashref with keys:

    revision_descs
    name1 daysago1 time1 tz1
    name2 daysago2 time2 tz2
    size
    num_creators
    num_other_creators
    main_creator
    main_email
    creator
    name
    date
    summary

and optionally "version", "is_missing" and "filepath" if applicable.

This method implicitly calls B<rebunch> with no parameter if new revision
descriptions were added that are not bunched yet.

=item B<clear>

Clear all bunches and their revision descriptions.

=item B<reverse_revision_descs>

Effectivelly empty all revision descriptions (both old and new) and readd
them in the reverse order.

Return the object, this enables chaining of B<get> or B<rebunch> method call.

=item B<versions>

Return distinct versions participated in all bunches. Return empty arrayref
if not applicable, i.e. if I<version> is given in the constructor.

=item B<filepaths>

Return distinct filepaths participated in all bunches. Return empty arrayref
if not applicable, i.e. if revision descriptions have no I<filepath>.

=back

=head1 BUGS

Waiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<Arch::Tree>, L<Arch::Log>, L<Arch::Session>,
L<Arch::Library>.

=cut
