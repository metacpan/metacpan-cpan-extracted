package Data::Password::zxcvbn::AuthorTools::BuildRankedDictionaries;
use v5.26;
use Types::Path::Tiny qw(Dir);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Standard qw(HashRef);
use Moo;
use namespace::clean;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: class to generate C<Data::Password::zxcvbn::*::RankedDictionaries>

with 'Data::Password::zxcvbn::AuthorTools::PackageWriter';


has dictionaries_word_count => (
    is => 'ro',
    required => 1,
    isa => HashRef[PositiveOrZeroInt],
);


has data_dir => (
    is => 'ro',
    default => 'data/',
    isa => Dir,
    coerce => 1,
);


has '+package_abstract' => (
    default => 'ranked dictionaries for common words',
);

sub _parse_frequency_lists {
    my ($self) = @_;

    my %freq_lists;

    for my $file ($self->data_dir->children(qr{\.txt\z})) {
        my $basename = $file->basename('.txt');
        unless (exists $self->dictionaries_word_count->{$basename}) {
            next;
        }

        my %token_to_rank;
        my $fh = $file->openr_utf8;
        while (my $line = <$fh>) {
            my ($token) = $line =~ m{^\s*(\S+)};
            $token_to_rank{$token} //= $.;
        }

        $freq_lists{$basename} = \%token_to_rank;
    }

    warn "The $_ dictionary was not found, ignoring\n"
        for grep { !exists $freq_lists{$_} } sort keys %{$self->dictionaries_word_count};

    return \%freq_lists;
}

sub _is_rare_and_short {
    my ($token, $rank) = @_;
    return $rank >= 10**length($token);
}

# filters frequency data according to:
# - filter out short tokens if they are too rare.
# - filter out tokens if they already appear in another dict
#   at lower rank.
# - cut off final freq_list at limits set in
#   `dictionaries_word_count`, if any.
#
# The result of this function is a bit different from the JS and
# Python ones: those produce a hash $list_name => [ $token, ...]
# sorted by ascending rank, and then build a $list_name => { $token =>
# $rank, ... } on load; here we produce the latter data structure
# directly
sub _filter_frequency_lists {
    my ($self, $freq_lists) = @_;
    # $freq_lists = { $list_name => { $token => $rank, ... } }

    # $token => $min_rank_across_all_lists
    my %minimum_rank;
    # $token => $list_name_with_lowest_rank_for_this_token
    my %minimum_name;

    # find out in which list each token appears nearest the top of the
    # ranking
    for my $list_name (sort keys %{$freq_lists}) {
        my $token_to_rank = $freq_lists->{$list_name};
        for my $token (keys %{$token_to_rank}) {
            my $rank = $token_to_rank->{$token};
            if ( !$minimum_rank{$token} || $minimum_rank{$token} >= $rank ) {
                $minimum_rank{$token} = $rank;
                $minimum_name{$token} = $list_name;
            }
            #warn "$list_name $token $rank $minimum_rank{$token} $minimum_name{$token}\n";
        }
    }

    # $list_name => [ [ $token, $rank ], ... ]
    my %filtered_token_and_rank;

    for my $list_name (sort keys %{$freq_lists}) {
        my $token_to_rank = $freq_lists->{$list_name};
        for my $token (keys %{$token_to_rank}) {
            # only consider a token if this is the list where it
            # appears nearest the top of the ranking
            next unless $minimum_name{$token} eq $list_name;

            my $rank = $token_to_rank->{$token};
            next if _is_rare_and_short($token,$rank);

            push @{$filtered_token_and_rank{$list_name}},
                [ $token, $rank ];
        }
    }

    # $list_name => { $token => $rank } # filtered & compacted rank
    my %result;
    for my $list_name (sort keys %filtered_token_and_rank) {
        my @sorted_tokens = sort { $a->[1] <=> $b->[1] }
            @{ $filtered_token_and_rank{$list_name} };
        if (my $cutoff = $self->dictionaries_word_count->{$list_name}) {
            splice @sorted_tokens,$cutoff;
        }
        my $idx = 1;
        $result{$list_name} = {
            map { $_->[0] => $idx++ } @sorted_tokens
        };
    }

    return \%result;
}


sub generate {
    my ($self) = @_;

    $self->write_out(
        $self->_filter_frequency_lists(
            $self->_parse_frequency_lists()
        )
    );
}


sub hash_variable_name { 'ranked_dictionaries' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::AuthorTools::BuildRankedDictionaries - class to generate C<Data::Password::zxcvbn::*::RankedDictionaries>

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

In your distribution's F<maint/build-ranked-dictionaries>:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Data::Password::zxcvbn::AuthorTools::BuildRankedDictionaries;

    Data::Password::zxcvbn::AuthorTools::BuildRankedDictionaries->new({
        dictionaries_word_count => {
            mything_wikipedia => 30000,
            mything_names     => 10000,
        },
        package_name => 'Data::Password::zxcvbn::RankedDictionaries::MyThing',
        package_abstract => 'adjacency graphs for my language',
        package_description => <<'EOF',
    This is a data file used by L<<
    C<Data::Password::zxcvbn::Match::Dictionary> >>, and is generated by
    the L<< C<build-ranked-dictionaries>|...>> program when
    building the distribution.
    EOF
    })->generate;

(a skeleton of such a file is generated when running C<dzil new -P
zxcvbn Data::Password::zxcvbn::MyThing>)

=head1 ATTRIBUTES

=head2 C<dictionaries_word_count>

A hashref mapping dictionary names to number of words to use (a 0
value means "include all words"). The code in the L</synopsis> would
look for files F<data/mything_wikipedia.txt> and
F<data/mything_names.txt>.

=head2 C<data_dir>

Where to look for data files, defaults to F<data/>.

=head2 C<output_dir>

Where to write the generated package. Defaults to C<$ARGV[1]> or
F<lib/>; this supports running the F<main/build-ranked-dictionaries>
script manually and via the F<dist.ini> file.

=head2 C<package_name>

Name of the package to generate, required. Should start with
C<Data::Password::zxcvbn::RankedDictionaries::>

=head2 C<package_version>

Version of the package. Defaults to C<$ARGV[0]> or C<undef>; this
supports running the F<main/build-ranked-dictionaries> script manually
and via the F<dist.ini> file.

=head2 C<package_abstract>

Abstract of the package, defaults to "ranked dictionaries for common
words".

=head2 C<package_description>

Description of the package, required.

=head1 METHODS

=head2 C<generate>

Writes out the package.

=for Pod::Coverage hash_variable_name

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
