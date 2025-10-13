package Data::Password::zxcvbn::Combinatorics;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK=qw(nCk factorial enumerate_substitution_maps);
our $VERSION = '1.1.3'; # VERSION
# ABSTRACT: some combinatorial functions


sub nCk {
    my ($n, $k) = @_;
    # from http://blog.plover.com/math/choose.html

    return 0 if $k > $n;
    return 1 if $k == 0;

    my $ret = 1;
    for my $d (1..$k) {
        $ret *= $n;
        $ret /= $d;
        --$n;
    }

    return $ret;
}

# given as array of simple str-str hashrefs, returns a list without
# duplicates
sub _dedupe {
    my ($subs) = @_;
    my %keyed = map {
        my $this_sub=$_;
        # build a string representing the substitution, use it as a
        # hash key, so duplicates get eliminated
        join(
            '-',
            map { "${_},$this_sub->{$_}" } sort keys %{$this_sub},
        ) => $this_sub
    } @{$subs};
    return [values %keyed];
}

sub _recursive_enumeration {
    my ($table,$keys,$subs) = @_;
    return $subs unless @{$keys};
    my ($first_key,@rest_keys) = @{$keys};
    my @next_subs;
    for my $value (@{$table->{$first_key}}) {
        for my $sub (@{$subs}) {
            # if we already have a reverse mapping for this, keep it
            push @next_subs, $sub
                if exists $sub->{$value};
            # and add this new one
            push @next_subs, { %{$sub}, $value => $first_key };
        }
    }

    my $deduped_next_subs = _dedupe(\@next_subs);
    return _recursive_enumeration($table,\@rest_keys,\@next_subs);
}


sub enumerate_substitution_maps {
    my ($table) = @_;

    return _recursive_enumeration(
        $table,
        [keys %{$table}],
        [{}], # it needs an accumulator with an initial empty element
    );
}


sub factorial {
    my $ret=1;
    $ret*=$_ for 1..$_[0];
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords combinatorial

=head1 NAME

Data::Password::zxcvbn::Combinatorics - some combinatorial functions

=head1 VERSION

version 1.1.3

=head1 DESCRIPTION

This module provides a few combinatorial functions that are used
throughout the library.

=head1 FUNCTIONS

=head2 C<nCk>

  my $combinations = nCk($available,$taken);

Returns the binomial coefficient:

 / $available \
 |            |
 \   $taken   /

=head2 C<enumerate_substitution_maps>

 my $enumeration = enumerate_substitution_maps(\%substitutions);

Given a hashref of arrayrefs, interprets it as a map of
substitutions. Returns an arrayref of hashrefs, containing all
reverse-substitutions.

For example, given:

 {'a' => ['@', '4']}

("'a' can be replaced with either '@' or '4'")

it returns:

  [{'@' => 'a'}, {'4' => 'a'}] ],

("in one case, '@' could have been substituted for 'a'; in the other,
'4' could have been substituted for 'a'")

=head2 C<factorial>

  my $fact = factorial($number);

Returns the factorial of the given number.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
