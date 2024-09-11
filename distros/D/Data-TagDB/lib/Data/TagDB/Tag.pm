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

our $VERSION = v0.01;



sub db {
    my ($self) = @_;
    return $self->{db};
}


sub dbid {
    my ($self) = @_;
    return 0 unless defined $self;
    return $self->{dbid};
}


sub uuid {
    my ($self) = @_;
    return $self->{uuid} //= $self->_get_data(_tag_simple_identifier => uuid => $self->dbid);
}
sub oid {
    my ($self) = @_;
    return $self->{oid} //= $self->_get_data(_tag_simple_identifier => oid => $self->dbid);
}
sub uri {
    my ($self) = @_;
    return $self->{uri} //= URI->new($self->_get_data(_tag_simple_identifier => uri => $self->dbid));
}
sub sid {
    my ($self) = @_;
    return $self->{sid} //= $self->_get_data(_tag_simple_identifier => 'small-identifier' => $self->dbid);
}


sub ise {
    my ($self) = @_;
    return eval {$self->uuid} // eval {$self->oid} // $self->uri->as_string;
}


sub displayname {
    my ($self) = @_;

    if (defined $self->{displayname}) {
        return $self->{displayname};
    } else {
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

        $name = eval {
            _select_string(
                $policies,
                $db->metadata(tag => $self, relation => $asi, no_type => [
                        @identifier_types,
                        $wk->uuid, $wk->oid, $wk->uri,
                    ])->collect('data', skip_died => 1),
            );
        };
        return $self->{displayname} = $name if defined($name) && length($name);

        $name = eval {$self->ise};
        return $self->{displayname} = $name if defined($name) && length($name);

        return $self->{displayname} = 'no name';
    }
}


sub displaycolour {
    my ($self) = @_;
    if (exists $self->{displaycolour}) {
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

        return $self->{displaycolour};
    }
}


sub icontext {
    my ($self) = @_;
    if (exists $self->{icontext}) {
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

        return $self->{icontext};
    }
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

version v0.01

=head1 SYNOPSIS

    use Data::TagDB;

    my $db = Data::TagDB->new(...);

    my Data::TagDB::Tag $tag = $db->tag_by_...(...);

=head1 METHODS

=head2 db

    my Data::TagDB $db = $tag->db;

Returns the current L<Data::TagDB> object.

=head2 dbid

    my $dbid = $db->dbid;

Returns the current tag's database internal identifier. This call should be avoided as those identifiers are not stable nor portable.
It is however the best option when directly interacting with the backend database.

=head2 uuid, oid, uri, sid

    my     $uuid = $tag->uuid;
    my     $oid  = $tag->oid;
    my URI $uri  = $tag->uri;
    my     $sid  = $tag->sid;

Returns the tags UUID, OID, URI, or SID (small-identifier).
It is not yet defined if those functions die or return a calculated identifier if the requested identifier is unavailable.
This will be defined in a later version of this module.
Identifiers may also be unavailable due to being not part of the database.

=head2 ise

    my $ise = $tag->ise;

Returns an identifier (C<uuid>, C<oid>, or C<uri>) for the tag as string.

=head2 displayname

    my $displayname = $tag->displayname;

Returns a name that can be used to display to the user.
This function always returns a plain string (even if no usable name is found).

=head2 displaycolour

    my $displaycolour = $tag->displaycolour;

Returns a colour that can be used to display the tag or undef.
This will return a decoded object, most likely (but not necessarily) an instance of L<Data::URIID::Colour>.
Later versions of this module may allow to force a specific type.

=head2 icontext

    my $icontext = $tag->icontext;

Returns a string or C<undef> that is a single unicode character that represents the tag.
This can be used as a visual aid for the user.
It is not well defined what single character means in this case. A single character may map
to multiple unicode code points (such as a base and modifiers). If the application requies a
specific definition of single character it must validate the value.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
