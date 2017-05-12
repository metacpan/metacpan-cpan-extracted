package DateTime::Format::Natural::Duration::Checks;

use strict;
use warnings;
use boolean qw(true false);

our $VERSION = '0.04';

sub for
{
    my ($duration, $date_strings, $present) = @_;

    if (@$date_strings == 1
      && $date_strings->[0] =~ $duration->{for}{regex}
    ) {
        $$present = $duration->{for}{present};
        return true;
    }
    else {
        return false;
    }
}

sub first_to_last
{
    my ($duration, $date_strings, $extract) = @_;

    my %regexes = %{$duration->{first_to_last}{regexes}};

    if (@$date_strings == 2
      && $date_strings->[0] =~ /^$regexes{first}$/
      && $date_strings->[1] =~ /^$regexes{last}$/
    ) {
        $$extract = $regexes{extract};
        return true;
    }
    else {
        return false;
    }
}

my %anchor_regex = (
    left  => sub { my $regex = shift; qr/(?:^|(?<=\s))$regex/             },
    right => sub { my $regex = shift; qr/$regex(?:(?=\s)|$)/              },
    both  => sub { my $regex = shift; qr/(?:^|(?<=\s))$regex(?:(?=\s)|$)/ },
);

my $extract_chunk = sub
{
    my ($string, $base_index, $start_pos, $match) = @_;

    my $start_index = 0;

    if ($start_pos > 0
     && $string =~ /^(.{0,$start_pos})\s+/
    ) {
        my $substring = $1;
        $start_index++ while $substring =~ /\s+/g;
        $start_index++; # final space
    }
    my @tokens    = split /\s+/, $match;
    my $end_index = $start_index + $#tokens;

    my $expression = join ' ', @tokens;

    return [ [ $base_index + $start_index, $base_index + $end_index ], $expression ];
};

my $has_timespan_sep = sub
{
    my ($tokens, $chunks, $timespan_sep) = @_;

    my ($left_index, $right_index) = ($chunks->[0]->[0][1], $chunks->[1]->[0][0]);

    if ($tokens->[$left_index  + 1] =~ /^$timespan_sep$/i
     && $tokens->[$right_index - 1] =~ /^$timespan_sep$/i
     && $right_index - $left_index == 2
    ) {
        return true;
    }
    else {
        return false;
    }
};

sub _first_to_last_extract
{
    my ($self, $duration, $date_strings, $indexes, $tokens, $chunks) = @_;

    return false unless @$date_strings == 2;

    my %regexes = %{$duration->{first_to_last}{regexes}};

    $regexes{first} = $anchor_regex{left}->($regexes{first});
    $regexes{last}  = $anchor_regex{right}->($regexes{last});

    my $timespan_sep = $self->{data}->__timespan('literal');

    my @chunks;
    if ($date_strings->[0] =~ /(?=($regexes{first})$)/g) {
        my $match = $1;
        push @chunks, $extract_chunk->($date_strings->[0], $indexes->[0][0], pos $date_strings->[0], $match);
    }
    if ($date_strings->[1] =~ /(?=^($regexes{last}))/g) {
        my $match = $1;
        push @chunks, $extract_chunk->($date_strings->[1], $indexes->[1][0], pos $date_strings->[1], $match);
    }
    if (@chunks == 2 && $has_timespan_sep->($tokens, \@chunks, $timespan_sep)) {
        @$chunks = @chunks;
        return true;
    }
    else {
        return false;
    }
}

my $duration_matches = sub
{
    my ($duration, $date_strings, $entry, $target) = @_;

    my $data = $duration->{from_count_to_count};

    my (@matches, %seen);
    foreach my $ident (@{$data->{order}}) {
        my $regex = $anchor_regex{both}->($data->{regexes}{$ident});
        while ($date_strings->[0] =~ /(?=$regex)/g) {
            my $pos = pos $date_strings->[0];
            next if $seen{$pos};
            push @matches, [ $ident, $pos ];
            $seen{$pos} = true;
        }
    }
    my @idents = map $_->[0], sort { $a->[1] <=> $b->[1] } @matches;

    my %categories;
    foreach my $ident (@{$data->{order}}) {
        my $category = $data->{categories}{$ident};
        push @{$categories{$category}}, $ident;
    }

    my $get_target = sub
    {
        my ($category, $target) = @_;
        foreach my $ident (@{$categories{$category}}) {
            my $regex = $anchor_regex{both}->($data->{regexes}{$ident});
            if ($date_strings->[1] =~ $regex) {
                $$target = $ident;
                return true;
            }
        }
        return false;
    };

    if (@idents >= 2
     && $data->{categories}{$idents[-1]} eq 'day'
     && $data->{categories}{$idents[-2]} eq 'time'
     && $get_target->($data->{categories}{$idents[-2]}, $target)
    ) {
        $$entry = $idents[-2];
        return true;
    }
    elsif (@idents
        && $get_target->($data->{categories}{$idents[-1]}, $target)
    ) {
        $$entry = $idents[-1];
        return true;
    }
    else {
        return false;
    }
};

sub from_count_to_count
{
    my ($duration, $date_strings, $extract, $adjust, $indexes) = @_;

    return false unless @$date_strings == 2;

    my ($entry, $target);
    return false unless $duration_matches->($duration, $date_strings, \$entry, \$target);

    my $data = $duration->{from_count_to_count};

    my $get_data = sub
    {
        my ($types, $idents, $type) = @_;

        my $regex = $data->{regexes}{$idents->[0]};
        my %regexes = (
            left   => qr/^.+? \s+ $regex$/x,
            right  => qr/^$regex \s+ .+$/x,
            target => qr/^$data->{regexes}{$idents->[1]}$/,
        );
        my %extract = (
            left  => qr/^(.+?) \s+ $regex$/x,
            right => qr/^$regex \s+ (.+)$/x,
        );
        my %adjust = (
            left => sub
            {
                my ($date_strings, $index, $complete) = @_;
                $date_strings->[$index] = "$complete $date_strings->[$index]";
            },
            right => sub
            {
                my ($date_strings, $index, $complete) = @_;
                $date_strings->[$index] .= " $complete";
            },
        );

        return (@regexes{@$types}, $extract{$type}, $adjust{$type});
    };

    my @sets = (
        [ [ qw( left target) ], [ $entry, $target ], 'left',  [0,1] ],
        [ [ qw(right target) ], [ $entry, $target ], 'right', [0,1] ],
    );

    my @new;
    foreach my $set (@sets) {
        push @new, [ [ reverse @{$set->[0]} ], [ reverse @{$set->[1]} ], $set->[2], [ reverse @{$set->[3]} ] ];
    }
    push @sets, @new;

    foreach my $set (@sets) {
        my ($regex_types, $idents, $type, $string_indexes) = @$set;

        my ($regex_from, $regex_to, $extract_regex, $adjust_code) = $get_data->($regex_types, $idents, $type);

        if ($date_strings->[0] =~ $regex_from
         && $date_strings->[1] =~ $regex_to
        ) {
            $$extract = $extract_regex;
            $$adjust  = $adjust_code;
            @$indexes = @$string_indexes;
            return true;
        }
    }

    return false;
}

sub _from_count_to_count_extract
{
    my ($self, $duration, $date_strings, $indexes, $tokens, $chunks) = @_;

    return false unless @$date_strings == 2;

    my ($entry, $target);
    return false unless $duration_matches->($duration, $date_strings, \$entry, \$target);

    my $data = $duration->{from_count_to_count};

    my $get_data = sub
    {
        my ($types, $idents) = @_;

        my $category = $data->{categories}{$idents->[0]};
        my $regex    = $data->{regexes}{$idents->[0]};

        my %regexes = (
            left   => qr/$data->{extract}{left}{$category}\s+$regex/,
            right  => qr/$regex\s+$data->{extract}{right}{$category}/,
            target => $data->{regexes}{$idents->[1]},
        );

        $regexes{entry} = qr/(?:$regexes{left}|$regexes{right})/;

        return @regexes{@$types};
    };

    my $timespan_sep = $self->{data}->__timespan('literal');

    my @sets = (
        [ [ qw(entry target) ], [ $entry, $target ] ],
    );

    my @new;
    foreach my $set (@sets) {
        push @new, [ [ reverse @{$set->[0]} ], [ reverse @{$set->[1]} ] ];
    }
    push @sets, @new;

    foreach my $set (@sets) {
        my ($regex_types, $idents) = @$set;

        my ($regex_from, $regex_to) = $get_data->($regex_types, $idents);

        $regex_from = $anchor_regex{left}->($regex_from);
        $regex_to   = $anchor_regex{right}->($regex_to);

        my @chunks;
        if ($date_strings->[0] =~ /(?=($regex_from)$)/g) {
            my $match = $1;
            push @chunks, $extract_chunk->($date_strings->[0], $indexes->[0][0], pos $date_strings->[0], $match);
        }
        if ($date_strings->[1] =~ /(?=^($regex_to))/g) {
            my $match = $1;
            push @chunks, $extract_chunk->($date_strings->[1], $indexes->[1][0], pos $date_strings->[1], $match);
        }
        if (@chunks == 2 && $has_timespan_sep->($tokens, \@chunks, $timespan_sep)) {
            @$chunks = @chunks;
            return true;
        }

        pos $date_strings->[0] = 0;
        pos $date_strings->[1] = 0;
    }

    return false;
}

1;
