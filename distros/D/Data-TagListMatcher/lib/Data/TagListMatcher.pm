# Copyright (c) 2026 Philipp Schafft
    
# licensed under Artistic License 2.0 (see LICENSE file)
    
# ABSTRACT: A simple rule based tag matcher
        
     
package Data::TagListMatcher;

use v5.10;
use strict;
use warnings;

use Carp;
use Data::Identifier;

use parent qw(Data::Identifier::Interface::Subobjects);

our $VERSION = v0.02;

my %_valid_types = (
    int => {
        add => {
            initial => 0,
            cb => sub { $_[0] + $_[1] },
        },
        mul => {
            initial => 1,
            cb => sub { $_[0] * $_[1] },
        },
    },
    bool => {
        and => {
            initial => 1,
            cb => sub { $_[0] && $_[1] },
        },
        or => {
            initial => 0,
            cb => sub { $_[0] || $_[1] },
        },
    },
    limit => {
        apply => {
            initial => {lower => 0, upper => undef},
            cb => sub {
                my ($x, $y) = @_;
                my $lower = $x->{lower};
                my $upper = $x->{upper};

                if (ref $y) {
                    $lower = $y->{lower} if defined($y->{lower}) && (!defined($lower) || $lower < $y->{lower});
                    $upper = $y->{upper} if defined($y->{upper}) && (!defined($upper) || $upper > $y->{upper});
                } else {
                    if ($y >= 0) {
                        $lower = $y if !defined($lower) || $lower < $y;
                    } else {
                        $y *= -1;
                        $upper = $y if !defined($upper) || $upper > $y;
                    }
                }
                return {lower => $lower, upper => $upper},
            },
            finalise => sub {
                my (undef, $x) = @_;
                return $x->{upper} if defined($x->{upper}) && $x->{upper} < $x->{lower};
                return $x->{lower};
            },
        },
    },
);


sub new {
    my ($pkg, @opts) = @_;
    my $self = bless {
        metrics => {},
        rules => [],
        converter_cache => {},
    }, $pkg;

    croak 'Stray options passed' if scalar @opts;

    return $self;
}


sub default_converter {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->{default_converter} = $n if defined $n;

    return $self->{default_converter};
}


sub default_type {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->{default_type} = Data::Identifier->new(from => $n) if defined $n;

    return $self->{default_type};
}


sub clear_cache {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->{converter_cache} = {};

    return $self;
}


sub register {
    my ($self, @opts) = @_;
    my $converter_cache = $self->{converter_cache};
    my $default_converter = $self->{default_converter};
    my $default_type = $self->{default_type};

    croak 'Stray options passed' if scalar @opts;

    if (defined(my $default_type = $self->{default_type})) {
        $default_type->register;
    }

    foreach my $rule (@{$self->{rules}}) {
        foreach my $entry (@{$rule->{match}}) {
            if (ref $entry) {
                if ($entry->isa('Data::Identifier')) {
                    $entry->register;
                }
            } else {
                # try to auto generate
                eval { $converter_cache->{$entry} //= Data::Identifier->new($default_type => $entry) } if defined $default_type;
                eval { $converter_cache->{$entry} //= $self->$default_converter($entry) } if defined $default_converter;
            }
        }
    }

    foreach my $entry (values %{$converter_cache}) {
        if ($entry->isa('Data::Identifier')) {
            $entry->register;
        }
    }

    return $self;
}


sub add_metric {
    my ($self, $name, $type, $op, @opts) = @_;
    my %metric = (type => $type, op => $op);
    my $ent;

    croak 'Stray options passed' if scalar @opts;

    croak 'No name given' unless defined $name;
    croak 'No type given' unless defined $type;
    croak 'No op given' unless defined $op;

    croak 'Metric already in place' if exists $self->{metrics}{$name};

    $ent = $_valid_types{$type};
    croak 'No valid type given' unless defined $ent;
    $ent = $ent->{$op};
    croak 'No valid op given' unless defined $ent;

    $metric{op_cb} = $ent->{cb};
    $metric{initial} = $ent->{initial};
    $metric{finalise} = $ent->{finalise};
    $self->{metrics}{$name} = \%metric;

    return $self;
}


sub add_rule {
    my ($self, $match, $score, @opts) = @_;
    my $metrics = $self->{metrics};

    croak 'Stray options passed' if scalar @opts;

    $match = [$match] unless ref($match) eq 'ARRAY';

    if (ref($score) ne 'HASH' && scalar(keys %{$metrics}) == 1) {
        $score = {(keys %{$metrics})[0] => $score};
    }

    foreach my $metric (keys %{$score}) {
        croak 'No such metric: '.$metric unless defined $metrics->{$metric};
    }

    push(@{$self->{rules}}, {match => $match, score => $score});

    return $self;
}


sub match {
    my ($self, $list, @opts) = @_;
    my $metrics = $self->{metrics};
    my %result = map {$_ => $metrics->{$_}{initial}} keys %{$metrics};

    foreach my $rule (@{$self->{rules}}) {
        my $match = 1;

        foreach my $req (@{$rule->{match}}) {
            my $found;

            foreach my $have (@{$list}) {
                if ($self->_eq($have, $req)) {
                    $found = 1;
                    last;
                }
            }

            unless ($found) {
                $match = undef;
                last;
            }
        }

        next unless $match;

        foreach my $key (keys %{$rule->{score}}) {
            my $v = $rule->{score}{$key};

            $result{$key} = $metrics->{$key}{op_cb}($result{$key}, $v);
        }
    }

    foreach my $key (keys %{$metrics}) {
        my $metric = $metrics->{$key};
        my $finalise = $metric->{finalise};

        $result{$key} = $self->$finalise($result{$key}) if defined $finalise;
    }

    return \%result;
}

sub _eq {
    my ($self, $x, $y) = @_;

    return 1 if !defined($x) && !defined($y);
    return 0 if !defined($x) || !defined($y);
    return Data::Identifier::eq($x, $y) if ref($x) && ref($y);

    if (ref($x) || ref($y)) {
        if (defined(my $default_converter = $self->{default_converter}) || defined(my $default_type = $self->{default_type})) {
            my $converter_cache = $self->{converter_cache};

            foreach my $z ($x, $y) {
                next if ref $z;
                $z = eval { $converter_cache->{$z} //= Data::Identifier->new($default_type => $z) } if defined $default_type;
                next if ref $z;
                $z = eval { $converter_cache->{$z} //= $self->$default_converter($z) } if defined $default_converter;
                return undef unless defined $z;
            }

            # Both are identifiers of some sort now, if they aren't the above code should have failed.
            # And Data::Identifier::eq() will do the last bit of error checking for us.
            return Data::Identifier::eq($x, $y);
        }
    }
    return $x eq $y;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagListMatcher - A simple rule based tag matcher

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Data::TagListMatcher;

    my Data::TagListMatcher $matcher = Data::TagListMatcher->new;

    $matcher->add_metric(score => int => 'add');
    $matcher->add_rule(good => 5);

    my $res = $matcher->match(['ok', 'good', 'funny']);

This package provides a simple rule based tag matcher.

This package inherits from L<Data::Identifier::Interface::Subobjects>.

=head1 METHODS

=head2 new

    my Data::TagListMatcher $matcher = Data::TagListMatcher->new;

(since v0.01)

Creates a new matcher object.
Takes no options.

=head2 default_converter

    $matcher->default_converter($converter);
    my $converter = $matcher->default_converter;

(since v0.02)

A function that is called to convert tags from strings into objects as needed.

The function is passed the matcher as first argument and the string to convert as second argument.
The function must return any object that L<Data::Identifier/eq> can compare.

If the function dies the tag is handled the same way as if the converter was not set.
However it might be called again for the same tag or other tags later.

The result might be cached.

It is undefined in which order the converter is tried related to other ways to convert from a string to an object.

See also:
L</default_type>.

=head2 default_type

    $matcher->default_type($type);
    my Data::Identifier $type = $matcher->default_type;

(since v0.02)

The type to use when a tag needs to be converted from a string to an object.
When set this will be used to call L<Data::Identifier/new> with the given type and the string as identifier.

The type passed here is converted to a L<Data::Identifier> as needed by L<Data::Identifier/new> using C<from>.

If converting to an identifier fails the tag is handled the same way as if the type was not set.
However it might be tried again for the same tag or other tags later.

The result might be cached.

It is undefined in which order the type is tried related to other ways to convert from a string to an object.

See also:
L</default_converter>.

=head2 clear_cache

    $matcher->clear_cache;

(since v0.02)

Clears all caches.

=head2 register

    $matcher->register;

(since v0.02)

Registers identifiers currently known to the matcher.
This may improve performance when calling L</match> multiple times.

However registered identifiers are kept globally and this operation cannot be undone.

This operation may interact with the cache (both prefil it, but also register any already cached entries).

See also:
L<Data::Identifier/register>.

=head2 add_metric

    $matcher->add_metric($name, $type, $operation);

(since v0.01)

Adds a metric to the matcher.

Each metric has a name by which it is known, a type of it's value, and an operation that defines how scores from rules are applied.

=head2 add_rule

    $matcher->add_rule($match, $score);

(since v0.01)

Adds a rule to the matcher.

C<$match> must be a tag or an arrayref of tags to check. The rule matches if I<all> tags are present.

C<$score> is the score the rule applies to the metrics. It must be an hashref.
Each element in the hashref uses the key of the metric it applies to and the value that is applied to the metric based on the selected operator.

There is a shortcut that if C<$score> is a single non-ref and there is only one metric it is then applied to the single metric present.

B<Note:>
Rules need to be added after the metrics they apply to.

=head2 match

    my $score = $matcher->match($list);

(since v0.01)

Runs the matcher agains the given list (arrayref).
The return will be a hashref with one element for each metric added via L</add_metric>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
