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

our $VERSION = v0.01;

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
    }, $pkg;

    croak 'Stray options passed' if scalar @opts;

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
                if (_eq($have, $req)) {
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
    my ($x, $y) = @_;

    return 1 if !defined($x) && !defined($y);
    return 0 if !defined($x) || !defined($y);
    return Data::Identifier::eq($x, $y) if ref($x) && ref($y);
    return $x eq $y;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagListMatcher - A simple rule based tag matcher

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Data::TagListMatcher;

    my Data::TagListMatcher $matcher = Data::TagListMatcher->new;

This package provides a simple rule based tag matcher.

This package inherits from L<Data::Identifier::Interface::Subobjects>.

=head1 METHODS

=head2 new

    my Data::TagListMatcher $matcher = Data::TagListMatcher->new;

(since v0.01)

Creates a new matcher object.
Takes no options.

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

=head2 add_metric

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
