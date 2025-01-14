# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Tag;

use v5.16;
use strict;
use warnings;

use Carp;
use URI;

our $VERSION = v0.08;

my $HAVE_DATA_IDENTIFIER = eval {require Data::Identifier; 1;};

my %_key_to_data_identifier = (
    'small-identifier' => 'sid',
    (map {$_ => $_} qw(uuid oid uri)),
);



sub db {
    my ($self) = @_;
    return $self->{db};
}


sub dbid {
    my ($self) = @_;
    return 0 unless defined $self;
    return $self->{dbid};
}


sub _get_id {
    my ($self, %opts) = @_;
    my $key = $opts{_key};
    my $value = $self->{$key} //= eval { $self->_get_data(_tag_simple_identifier => $key => $self->dbid) };
    my $curtype;

    if (!defined($value) && !$opts{no_defaults}) {
        if (defined $self->{$key.'_defaults'}) {
            $value = $self->{$key.'_defaults'};
        } else {
            my $id;
            my $backup_key;
            foreach my $backup_key_try (qw(uuid oid uri small-identifier)) {
                $id = eval { $self->_get_data(_tag_simple_identifier => $backup_key_try => $self->dbid) };
                if (defined $id) {
                    $backup_key = $backup_key_try;
                    last;
                }
            }
            if (defined($id) && defined($backup_key)) {
                if ($HAVE_DATA_IDENTIFIER && defined(my $type = $_key_to_data_identifier{$backup_key})) {
                    my $did = Data::Identifier->new($type => $id);
                    my $func = $did->can($_key_to_data_identifier{$key} // '');
                    if (defined $func) {
                        $value = eval {$did->$func()};
                        $curtype = $key;
                    }
                } elsif ($backup_key eq 'uuid' && $key eq 'uri') {
                    $value = sprintf('urn:uuid:%s', $id);
                } elsif ($backup_key eq 'oid' && $key eq 'uri') {
                    $value = sprintf('urn:oid:%s', $id);
                } elsif ($backup_key eq 'small-identifier' && $key eq 'uri') {
                    my $u = URI->new("https://uriid.org/");
                    $u->path_segments('', 'sid', $id);
                    $value = $u->as_string;
                }
            }

            $self->{$key.'_defaults'} = $value if defined $value;
        }
    }

    if (defined $value) {
        my $as = $opts{as} // $key;
        $curtype //= $key;

        if ($as eq $key || $as eq 'raw') {
            return $value;
        } elsif ($as eq 'URI' && $curtype eq 'uri') {
            return $self->{$key.'_URI'} //= URI->new($value); # convert and cache.
        } elsif ($as eq 'Data::Identifier' && $HAVE_DATA_IDENTIFIER && defined(my $type = $_key_to_data_identifier{$curtype})) {
            return Data::Identifier->new($type => $value, displayname => sub { $self->displayname(default => undef) });
        } else {
            croak 'Unsupported as option: '.$as;
        }
    }

    return $opts{default} if exists $opts{default};
    croak 'No identifier of requested type';
}

sub uuid {
    my ($self, %opts) = @_;
    return $self->_get_id(%opts, _key => 'uuid');
}
sub oid {
    my ($self, %opts) = @_;
    return $self->_get_id(%opts, _key => 'oid');
}
sub uri {
    my ($self, %opts) = @_;
    return $self->_get_id(%opts, _key => 'uri', as => $opts{as} // 'URI');
}
sub sid {
    my ($self, %opts) = @_;
    return $self->_get_id(%opts, _key => 'small-identifier');
}


sub ise {
    my ($self, %opts) = @_;
    my $has_default     = exists $opts{default};
    my $val_default     = delete $opts{default};
    my $val_no_defaults = delete $opts{no_defaults};
    my @keys = qw(uuid oid uri);
    my $value;

    $opts{default}      = undef;
    $opts{no_defaults}  = 1;

    foreach my $key (@keys) {
        $value = $self->_get_id(%opts, _key => $key);
        last if defined $value;
    }
    return $value if defined $value;

    unless ($val_no_defaults) {
        # retry with defaults
        delete $opts{default};
        delete $opts{no_defaults};
        foreach my $key (@keys) {
            my $func = $self->can($key);
            $value = eval {$self->$func(%opts)};
            last if defined $value;
        }
        return $value if defined $value;
    }

    return $val_default if $has_default;

    croak 'No ISE found or unsupported as-option';
}


sub displayname {
    my ($self, %opts) = @_;

    unless (defined $self->{displayname}) {
        my $policies = [qw(british dash nospace lower noupper long)];
        my $db = $self->db;
        my $wk = $db->wk;
        my $asi = $wk->also_shares_identifier;
        my $name;
        my @identifier_types = (
            $wk->tagname,
        );

        foreach my $relation (
            [qw(also_has_title)],
            [qw(tagpool_title gamebook_has_title)],
        ) {
            $relation = [grep {defined} map {eval{$wk->_call($_)}} @{$relation}];
            next unless scalar @{$relation};
            $name = eval {
                _select_string(
                    $policies,
                    $db->metadata(tag => $self, relation => $relation)->collect('data', skip_died => 1),
                );
            };
            return $self->{displayname} = $name if defined($name) && length($name);
        }

        foreach my $type (@identifier_types) {
            $name = eval {
                _select_string(
                    $policies,
                    $db->metadata(tag => $self, relation => $asi, type => $type)->collect('data', skip_died => 1),
                );
            };
            return $self->{displayname} = $name if defined($name) && length($name);
        }

        unless ($opts{no_defaults} || defined($self->{displayname_defaults})) {
            $name = eval {
                _select_string(
                    $policies,
                    $db->metadata(tag => $self, relation => $asi, no_type => [
                            @identifier_types,
                            $wk->uuid, $wk->oid, $wk->uri,
                        ])->collect('data', skip_died => 1),
                );
            };
            return $self->{displayname_defaults} = $name if defined($name) && length($name);

            $name = eval {$self->ise};
            return $self->{displayname_defaults} = $name if defined($name) && length($name);
        }
    }

    return $self->{displayname} if defined $self->{displayname};
    return $opts{default} if exists $opts{default};
    unless ($opts{no_defaults}) {
        return $self->{displayname_defaults} if defined $self->{displayname_defaults};
        return 'no name';
    }

    croak 'No displayname found';
}


sub displaycolour {
    my ($self, %opts) = @_;
    if (exists $self->{displaycolour}) {
        return $opts{default} if !defined($self->{displaycolour}) && exists $opts{default};
        return $self->{displaycolour};
    } else {
        my $db = $self->db;
        my $wk = $db->wk;

        $self->{displaycolour} = undef; # set to undef early so we can safely recurse.

        foreach my $relation (
            [qw(displaycolour)],
            [qw(has_colour_value)],
            [qw(wd_sRGB_colour_hex_triplet)]
        ) {
            $relation = [grep {defined} map {eval{$wk->_call($_)}} @{$relation}];
            next unless scalar @{$relation};
            my $colour = eval {
                ($db->metadata(tag => $self, relation => $relation)->collect('data', skip_died => 1))[0],
            };
            return $self->{displaycolour} = $colour if defined($colour);
        }

        foreach my $relation (
            [qw(displaycolour)],
            [qw(primary_colour)],
            [qw(also_shares_colour)],
        ) {
            $relation = [grep {defined} map {eval{$wk->_call($_)}} @{$relation}];
            next unless scalar @{$relation};
            my $colour = eval {
                ($db->relation(tag => $self, relation => $relation)->collect(sub {$_[0]->related->displaycolour}, skip_died => 1))[0],
            };
            return $self->{displaycolour} = $colour if defined($colour);
        }

        return $opts{default} if !defined($self->{displaycolour}) && exists $opts{default};
        return $self->{displaycolour};
    }
}


sub icontext {
    my ($self, %opts) = @_;
    if (exists $self->{icontext}) {
        return $opts{default} if !defined($self->{icontext}) && exists $opts{default};
        return $self->{icontext};
    } else {
        my $db = $self->db;
        my $wk = $db->wk;

        $self->{icontext} = undef; # set to undef as a default.

        foreach my $relation (
            [qw(tagpool_tag_icontext)],
            [qw(wd_unicode_character)],
        ) {
            $relation = [grep {defined} map {eval{$wk->_call($_)}} @{$relation}];
            next unless scalar @{$relation};
            my $icontext = eval {
                ($db->metadata(tag => $self, relation => $relation)->collect('data', skip_died => 1))[0],
            };
            return $self->{icontext} = $icontext if defined($icontext) && length($icontext);
        }

        # TODO: This should be extended to all roles:
        {
            if ((defined(my $tagpool_type_icontext = eval {$wk->tagpool_type_icontext}))) {
                my $relation = [grep {defined} map {eval{$wk->_call($_)}} qw(has_type)];
                if (scalar @{$relation}) {
                    my $icontext = ($db->metadata(
                            tag => $db->relation(tag => $self, relation => $relation)->collect('related', return_ref => 1),
                            relation => $tagpool_type_icontext
                        )->collect('data', skip_died => 1))[0];
                    return $self->{icontext} = $icontext if defined($icontext) && length($icontext);
                }
            }
        }

        return $opts{default} if !defined($self->{icontext}) && exists $opts{default};
        return $self->{icontext};
    }
}


sub description {
    my ($self, %opts) = @_;
    if (exists $self->{description}) {
        return $opts{default} if !defined($self->{description}) && exists $opts{default};
        return $self->{description};
    } else {
        my $db = $self->db;
        my $wk = $db->wk;

        $self->{description} = undef; # set to undef as a default.

        foreach my $relation (
            [qw(also_has_description)],
            [qw(tagpool_description)],
        ) {
            $relation = [grep {defined} map {eval{$wk->_call($_)}} @{$relation}];
            ($self->{description}) = $db->metadata(tag => $self, relation => $relation)->collect('data', skip_died => 1);
            last if defined $self->{description};
        }

        return $opts{default} if !defined($self->{description}) && exists $opts{default};
        return $self->{description};
    }
}


sub cloudlet {
    my ($self, $which) = @_;
    my $wk = $self->db->wk;
    my %opts = (
        tag => $self,
        indirect => [
            $wk->specialises,
        ],
    );

    if ($which eq 'roles') {
        $opts{direct} = [
            $wk->has_type,
            $wk->also_has_role,
        ];
    } elsif ($which eq 'flags') {
        $opts{direct} = [
            $wk->flagged_as,
        ];
    } else {
        croak 'Unknown cloudlet';
    }

    return $self->db->_load_cloudlet(%opts);
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    return bless \%opts, $pkg;
}

sub _query {
    my ($self, $name) = @_;
    return $self->db->_query($name);
}

sub _get_data {
    my ($self, $name, @args) = @_;
    return $self->db->_get_data($name, @args);
}

sub _select_string {
    my ($policies, @strings) = @_;
    my %res = map {$_ => 0} @strings;

    return undef unless scalar @strings;

    foreach my $policy (@{$policies}) {
        foreach my $first (@strings) {
            if ($policy eq 'upper') {
                $res{$first} +=  $first =~ /\p{upper}/ ? 1 : -1;
            } elsif ($policy eq 'lower') {
                $res{$first} +=  $first !~ /\p{upper}/ ? 1 : -1;
            } elsif ($policy eq 'space') {
                if ($first =~ /\s/) {
                    $res{$first}++;
                } elsif ($first =~ /[-_]/) {
                    $res{$first}--;
                }
            } elsif ($policy eq 'dash') {
                if ($first =~ /[-_]/) {
                    $res{$first}++;
                } elsif ($first =~ /\s/) {
                    $res{$first}--;
                }
            } elsif ($policy eq 'nospace') {
                if ($first =~ /\s/) {
                    $res{$first} -= 64;
                }
            } elsif ($policy eq 'noupper') {
                if ($first =~ /\p{upper}/) {
                    $res{$first} -= 64;
                }
            } elsif ($policy eq 'long' || $policy eq 'short') {
                foreach my $second (@strings) {
                    next if $first eq $second;
                    my $lf = length($first);
                    my $ls = length($second);
                    ($lf, $ls) = ($ls, $lf) if $policy eq 'short'; # swap.
                    if ($lf > $ls) {
                        $res{$first}++;
                        $res{$second}--;
                    }
                }
            } elsif ($policy eq 'british') {
                foreach my $second (@strings) {
                    next if $first eq $second;
                    if (fc($first =~ tr/z/s/r) eq fc($second =~ tr/z/s/r)) {
                        my $fx = scalar($first  =~ /(z)/g) || 0;
                        my $sx = scalar($second =~ /(z)/g) || 0;
                        if ($fx < $sx) {
                            $res{$first}++;
                            $res{$second}--;
                        }
                    }
                    if (fc(($first.' ') =~ s/er\b/re/gr) eq fc(($second.' ') =~ s/er\b/re/gr)) {
                        my $fx = scalar(($first.' ')  =~ /(er)\b/g) || 0;
                        my $sx = scalar(($second.' ') =~ /(er)\b/g) || 0;
                        if ($fx < $sx) {
                            $res{$first}++;
                            $res{$second}--;
                        }
                    }
                    if (fc($first =~ s/ou/o/gr) eq fc($second =~ s/ou/o/gr)) {
                        my $fx = scalar($first  =~ /(ou)/g) || 0;
                        my $sx = scalar($second =~ /(ou)/g) || 0;
                        if ($fx > $sx) {
                            $res{$first}++;
                            $res{$second}--;
                        } elsif ($fx < $sx) { # this one is not symetric, so we need it the other way around as well
                            $res{$first}--;
                            $res{$second}++;
                        }
                    }
                    if (fc($first =~ s/gray/grey/gir) eq fc($second)) {
                        $res{$first}--;
                        $res{$second}++;
                    }
                }
            } else {
                die 'Bad policy';
            }
        }
    }

    #say '#++ Dump: [', join(' ', @{$policies}), ']', map {sprintf(' "%s" => %d', $_, $res{$_})} sort {$res{$b} <=> $res{$a} || $a cmp $b} @strings;
    return (sort {$res{$b} <=> $res{$a} || $a cmp $b} @strings)[0];
}

sub attribute {
    my ($self, $attribute, %opts) = @_;

    if ($attribute =~ /^display/ || $attribute eq 'icontext') {
        my $func = $self->can($attribute);

        return $self->$func(%opts) if defined $func;
    }

    $self->{attribute} //= {};

    if (exists $opts{set}) {
        $self->{attribute}{$attribute} = $opts{set};
    }

    unless (exists $self->{attribute}{$attribute}) {
        # TODO: try to calculate here.
    }

    return $self->{attribute}{$attribute};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Tag - Work with Tag databases

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use Data::TagDB;

    my $db = Data::TagDB->new(...);

    my Data::TagDB::Tag $tag = $db->tag_by_...(...);

=head1 UNIVERSAL OPTIONS

The following universe options are supported by many methods of this module. Each method lists which universal options it supports.

=head2 default

The default value to be returned if no value could be found.
Can be C<undef> to switch the method from C<die>ing to returning C<undef> in case no value is found.

=head2 no_defaults

Prevents the calculation of any fallback values.

=head1 METHODS

=head2 db

    my Data::TagDB $db = $tag->db;

Returns the current L<Data::TagDB> object.

=head2 dbid

    my $dbid = $db->dbid;

Returns the current tag's database internal identifier. This call should be avoided as those identifiers are not stable nor portable.
It is however the best option when directly interacting with the backend database.

=head2 uuid, oid, uri, sid

    my     $uuid = $tag->uuid( [ %opts ] );
    my     $oid  = $tag->oid( [ %opts ] );
    my URI $uri  = $tag->uri( [ %opts ] );
    my     $sid  = $tag->sid( [ %opts ] );

Returns the tags UUID, OID, URI, or SID (small-identifier).
Identifiers may also be unavailable due to being not part of the database.

The following universal options are supported: L</default>, L</no_defaults>.

=head2 ise

    my $ise = $tag->ise( [ %opts ] );

Returns an identifier (C<uuid>, C<oid>, or C<uri>) for the tag as string.

Supports the same options as supported by L</uuid>, L</oid>, and L</uri>.

=head2 displayname

    my $displayname = $tag->displayname( [ %opts ] );

Returns a name that can be used to display to the user or C<die>s.
This function always returns a plain string (even if no usable name is found) unless L</no_defaults> is given.

The following universal options are supported: L</default>, L</no_defaults>.

=head2 displaycolour

    my $displaycolour = $tag->displaycolour( [ %opts ] );

Returns a colour that can be used to display the tag or C<undef>.
This will return a decoded object, most likely (but not necessarily) an instance of L<Data::URIID::Colour>.
Later versions of this module may allow to force a specific type.

B<Note:> Future versions of this method will C<die> if no value can be found.

The following universal options are supported: L</default>.
The following universal options are ignored (without warning or error): L</no_defaults>.

=head2 icontext

    my $icontext = $tag->icontext( [ %opts ] );

Returns a string or C<undef> that is a single unicode character that represents the tag.
This can be used as a visual aid for the user.
It is not well defined what single character means in this case. A single character may map
to multiple unicode code points (such as a base and modifiers). If the application requies a
specific definition of single character it must validate the value.

B<Note:> Future versions of this method will C<die> if no value can be found.

The following universal options are supported: L</default>.
The following universal options are ignored (without warning or error): L</no_defaults>.

=head2 description

    my $description = $tag->description( [ %opts ] );

Returns a description that can be used to display to the user or C<undef>.

B<Note:> Future versions of this method will C<die> if no value can be found.

The following universal options are supported: L</default>.
The following universal options are ignored (without warning or error): L</no_defaults>.

=head2 cloudlet

    my Data::TagDB::Cloudlet $cl = $tag->cloudlet($which);

B<Experimental:>
Gets the given cloudlet.

B<Note:>
This method is experimental. It may change prototype, and behaviour or may be removed in future versions without warning.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
