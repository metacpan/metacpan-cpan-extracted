# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Cloudlet;

use v5.14;
use strict;
use warnings;

use parent qw(Data::Identifier::Interface::Userdata);

use Carp;

use Data::Identifier;

our $VERSION = v0.25;

my %_valid_new_opts = (
    db          => 'Data::TagDB',
    extractor   => 'Data::URIID',
    fii         => 'File::Information',
    store       => 'File::FStore',
);


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {}, $pkg;

    if (defined(my $from = delete($opts{from}))) {
        if (defined(delete($opts{root})) || defined(delete($opts{entry}))) {
            croak 'root and entry given with from';
        }

        if (eval {$from->isa(__PACKAGE__)}) {
            $opts{$_} //= $from->{$_} foreach keys %_valid_new_opts;

            $opts{root} = [$from->roots];
            $opts{entry} = [$from->entries];
        }

        if (!ref($from) || ref($from) eq 'ARRAY' || eval {$from->can('ise')}) {
            $opts{root} = $from;
        }

        croak 'Unknown/Unsupported from' unless defined $opts{root};
    }

    foreach my $key (keys %_valid_new_opts) {
        my $v = delete($opts{$key}) // next;

        croak 'Bad type for key '.$key unless $v->isa($_valid_new_opts{$key});

        $self->{$key} = $v;
    }

    foreach my $key (qw(root entry)) {
        my $v = delete($opts{$key}) // next;

        $v = [$v] unless ref($v) eq 'ARRAY';

        foreach my $s (@{$v}) {
            unless (eval {$s->can('ise')}) {
                $s = Data::Identifier->new(from => $s);
            }
        }

        $v = {map {$_->ise => $_} @{$v}};

        $self->{$key} = $v;
    }

    croak 'Stray options passed' if scalar keys %opts;

    croak 'No root given' unless defined $self->{root};

    $self->{entry} = {%{$self->{entry}//{}}, %{$self->{root}}};

    return $self;
}


sub as {
    my ($self, $as, %opts) = @_;
    my %extra = %opts{qw(db extractor fii store)};

    $as = $opts{rawtype} if $as eq 'raw' && defined($opts{rawtype});

    return $self if ($as =~ /^[A-Z]/ || $as =~ /::/) && eval {$self->isa($as)};

    if (eval {$self->isa(__PACKAGE__)}) {
        $extra{$_} //= $self->{$_} foreach qw(db extractor fii store);
    }

    if (!ref($self) || ref($self) eq 'ARRAY') {
        $self = __PACKAGE__->new(root => $self, %extra);
        return $self if ($as =~ /^[A-Z]/ || $as =~ /::/) && eval {$self->isa($as)};
    }

    return $opts{default} if exists $opts{default};
    croak 'Unknown/Unsupported as: '.$as;
}


sub roots {
    my ($self, %opts) = @_;

    if (defined $opts{as}) {
        my %extra = map {$_ => ($opts{$_} // $self->{$_})} qw(db extractor fii store);
        return map {$_->Data::Identifier::as(
            $opts{as},
            %extra,
            )} values %{$self->{root}};
    }

    return values %{$self->{root}};
}


sub entries {
    my ($self, %opts) = @_;

    if (defined $opts{as}) {
        my %extra = map {$_ => ($opts{$_} // $self->{$_})} qw(db extractor fii store);
        return map {$_->Data::Identifier::as(
            $opts{as},
            %extra,
            )} values %{$self->{root}};
    }

    return values %{$self->{entry}};
}


sub is_root {
    my ($self, $tag) = @_;
    $tag = Data::Identifier->new(from => $tag) unless eval {$tag->can('ise')};
    return exists $self->{root}{$tag->ise};
}


sub is_entry {
    my ($self, $tag) = @_;
    $tag = Data::Identifier->new(from => $tag) unless eval {$tag->can('ise')};
    return exists $self->{entry}{$tag->ise};
}


#@returns Data::TagDB
sub db {
    my ($self, %opts) = @_;
    return $self->{db} if defined $self->{db};
    return $opts{default} if exists $opts{default};
    croak 'No database known';
}

#@returns Data::URIID
sub extractor {
    my ($self, %opts) = @_;
    return $self->{extractor} if defined $self->{extractor};
    return $opts{default} if exists $opts{default};
    croak 'No extractor known';
}

#@returns File::Information
sub fii {
    my ($self, %opts) = @_;
    return $self->{fii} if defined $self->{fii};
    return $opts{default} if exists $opts{default};
    croak 'No fii known';
}

#@returns File::FStore
sub store {
    my ($self, %opts) = @_;
    return $self->{store} if defined $self->{store};
    return $opts{default} if exists $opts{default};
    croak 'No store known';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Cloudlet - format independent identifier object

=head1 VERSION

version v0.25

=head1 SYNOPSIS

    use Data::Identifier::Cloudlet;

    my Data::Identifier::Cloudlet $cl = Data::Identifier::Cloudlet->new(root => [...] [, entry => [...]]);

    my @roots = $cl->entries;
    my @entries = $cl->entries;

    my $bool = $cl->is_root($entry);
    my $bool = $cl->is_entry($entry);

(since v0.10)

This module implements a cloudlet. A cloudlet is a often a collection of tags (represented by identifiers).

In a cloudlet each tag can only be once.
There is no order.
Each tag has a boolean attached that indices if it is a root tag.
This is used to indicate if a tag is a first level member or was added by means of completion.

Cloudlets are often used to implement tag listings for single items.
But they could also be used for example to provide a directory listing.

B<Note:>
Two tags are considered equal if their ISE string equals (C<eq>), see L</new> for details.

This package inherits from L<Data::Identifier::Interface::Userdata> (since v0.14).

=head1 METHODS

=head2 new

    my Data::Identifier::Cloudlet $cl = Data::Identifier::Cloudlet->new(root => ..., entry => ..., [ %opts ]);

Creates a new cloudlet object.

The following options are supported (all of which are optional but for C<root>):

=over

=item C<from>

Creates a new cloudlet from another object. If this option is passed C<root> nor C<entry> must be passed.

Currently the following types are supported:
L<Data::Identifier::Cloudlet>,
L<Data::Identifier>,
and arrayrefs.

If the type corresponds to an object that is not a collection the object is taken as per C<root>.

B<Note:>
This option is experimental.

=item C<root>

The root tag or tags. Must be a single object or a arrayref to such an object.
This module accepts all types as long as they implement a method alike L<Data::Identifier/ise>.

This is true for at least
L<Data::Identifier>,
L<Data::TagDB::Tag>,
L<Data::URIID::Base> (which many L<Data::URIID> related packages inherit from), and
L<File::FStore::Base> (as long as they implement L<File::FStore::Base/contentise>).

The ISE value returned is internally used as the primary key (for deduplication and equality checks).

If the object does not implement a ISE returning method,
it is passed via L<Data::Identifier/new> with the C<from> option to convert it to a L<Data::Identifier>.

=item C<entry>

The list of other (non-root) entries. Accepts the same values as C<root>.

=item C<db>

A L<Data::TagDB> instance.

=item C<extractor>

A L<Data::URIID> instance.

=item C<fii>

A L<File::Information> instance.

=item C<store>

A L<File::FStore> instance.

=back

=head2 as

    my $xxx = $cl->as($as, ...);

This method converts the given cloudlet to another type of object.

C<$as> must be a name of the package (containing C<::> or starting with an uppercase letter),
or one of the special values.

Currently the following packages are supported:
L<Data::Identifier::Cloudlet>.
Other packages might be supported. Packages need to be installed in order to be supported.
Also some packages need special options to be passed to be available.

If C<$cl> is or may not be a L<Data::Identifier::Cloudlet> this method tries to convert it to one first.
If C<$cl> is a collection without the root/entry flag, then all entries are considered root entries.

If C<$cl> is a C<$as> (see also C<rawtype> below) then C<$cl> is returned as-is,
even if C<$as> would not be supported otherwise.

See also:
L<Data::Identifier/as>.

The following options (all optional) are supported:

=over

=item C<autocreate>

If the requested type refers to some permanent storage and the object does not exist for
the given identifier whether to create a new object or not.

Defaults to false.

=item C<db>

An instance of L<Data::TagDB>. This is used to create instances of related packages.

=item C<default>

Same as in L</uuid>.

=item C<extractor>

An instance of L<Data::URIID>. This is used to create instances of related packages
such as L<Data::URIID::Result>.

=item C<fii>

An instance of L<File::Information>. This is used to create instances of related packages.

=item C<no_defaults>

Same as in L</uuid>.

=item C<rawtype>

If C<$as> is given as C<raw> then this value is used for C<$as>.
This can be used to ease implementation of other methods that are required to accept C<raw>.

=item C<store>

An instance of L<File::FStore>. This is used to create instances of related packages
such as L<File::FStore::File>.

=back

=head2 roots

    my @roots = $cl->roots;

Returns the list of root tags.

Takes the following (all optional) options:

=over

=item C<as>

An type to which the returned entries should be converted to.
This is implemented by calling L<Data::Identifier/as>.

=item C<db>

A L<Data::TagDB> object passed to L<Data::Identifier/as>. Defaults to the value given via L</new>.

=item C<extractor>

A L<Data::URIID> object passed to L<Data::Identifier/as>. Defaults to the value given via L</new>.

=item C<fii>

A L<File::Information> object passed to L<Data::Identifier/as>. Defaults to the value given via L</new>.

=item C<store>

A L<File::FStore> object passed to L<Data::Identifier/as>. Defaults to the value given via L</new>.

=back

=head2 entries

    my @entries = $cl->entries;

Returns the list of all entries.

Takes the same options as L</roots>.

=head2 is_root

    my $bool = $cl->is_root($tag);

Returns whether or not a given tag is a root tag.
Accepts the same type of objects as L</new> in C<root>. See there for how the matching is performed.

=head2 is_entry

    my $bool = $cl->is_entry($tag);

Returns whether or not a given tag is part of the cloudlet.
Accepts the same type of objects as L</new> in C<root>. See there for how the matching is performed.

=head2 db, extractor, fii, store

    my Data::TagDB $db        = $cl->db;
    my Data::URIID $extractor = $cl->extractor;
    my File::Information $fii = $cl->fii;
    my File::FStore $store    = $cl->store;

Gets the corresponding object as passed to L</new>.

If no such object is known, those methods C<die>.
This can be changed to return C<undef> by passing C<undef> via C<default>.

The following (all optional) options are supported:

=over

=item C<default>

The default value to return if the value is unknown.

=item C<no_defaults>

This option has currently no effect and is ignored.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
