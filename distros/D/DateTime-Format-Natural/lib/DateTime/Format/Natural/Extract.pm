package DateTime::Format::Natural::Extract;

use strict;
use warnings;
use base qw(
    DateTime::Format::Natural::Duration::Checks
    DateTime::Format::Natural::Formatted
);
use boolean qw(true false);

use constant DATE_TYPE     => 0x01;
use constant GRAMMAR_TYPE  => 0x02;
use constant DURATION_TYPE => 0x04;

our $VERSION = '0.11';

my %grammar_durations = map { $_ => true } qw(for_count_unit);

my $get_range = sub
{
    my ($aref, $index) = @_;
    return [ grep defined, @$aref[$index, $index + 1] ];
};

my $extract_duration = sub
{
    my ($skip, $indexes, $index) = @_;

    return false unless defined $indexes->[$index] && defined $indexes->[$index + 1];
    my ($left_index, $right_index) = ($indexes->[$index][1], $indexes->[$index + 1][0]);

    return ($skip->{$left_index} || $skip->{$right_index}) ? false : true;
};

sub _extract_expressions
{
    my $self = shift;
    my ($extract_string) = @_;

    $extract_string =~ s/^\s*[,;.]?//;
    $extract_string =~ s/[,;.]?\s*$//;

    while ($extract_string =~ /([,;.])/g) {
        my $mark = $1;
        my %patterns = (
            ',' => qr/(?!\d{4})/,
            ';' => qr/(?=\w)/,
            '.' => qr/(?=\w)/,
        );
        my $pattern = $patterns{$mark};
        $extract_string =~ s/\Q$mark\E \s+? $pattern/ [token] /x; # pretend punctuation marks are tokens
    }

    $self->_rewrite(\$extract_string);

    my @tokens = split /\s+/, $extract_string;
    my %entries = %{$self->{data}->__grammar('')};

    my (@expressions, %skip);

    my $timespan_sep = $self->{data}->__timespan('literal');

    if ($extract_string =~ /\s+ $timespan_sep \s+/ix) {
        my $trim = sub { local $_ = shift; s/^\s+//; s/\s+$//; $_ };

        my @strings = grep /\S/, map $trim->($_), split /\b$timespan_sep\b/i, do {
            local $_ = $extract_string;
            1 while s/^$timespan_sep\s+//i;
            1 while s/\s+$timespan_sep$//i;
            $_
        };
        if (@strings) {
            my $index = 0;
            $index++ while $extract_string =~ /\G$timespan_sep\s+/gi;
            my @indexes;
            for (my $i = 0; $i < @strings; $i++) {
                my @string_tokens = split /\s+/, $strings[$i];
                push @indexes, [ $index, $index + $#string_tokens ];
                $index += $#string_tokens + 1;
                $index++ while defined $tokens[$index] && $tokens[$index] =~ /^$timespan_sep$/i;
            }

            my $duration = $self->{data}->{duration};

            DURATION: {
                for (my $i = 0; $i < @strings - 1; $i++) {
                    next unless $extract_duration->(\%skip, \@indexes, $i);
                    my $save_expression = false;
                    my @chunks;
                    foreach my $extract (qw(_first_to_last_extract _from_count_to_count_extract)) {
                        if ($self->$extract($duration, $get_range->(\@strings, $i), $get_range->(\@indexes, $i), \@tokens, \@chunks)) {
                            $save_expression = true;
                            last;
                        }
                    }
                    if ($save_expression) {
                        my $timespan_sep_index = $chunks[0]->[0][1] + 1;
                        my $expression = join ' ', ($chunks[0]->[1], $tokens[$timespan_sep_index], $chunks[1]->[1]);
                        my @indexes = ($chunks[0]->[0][0], $chunks[1]->[0][1]);
                        push @expressions, [ [ @indexes ], $expression, { flags => DURATION_TYPE } ];
                        $skip{$_} = true foreach ($indexes[0] .. $indexes[1]);
                        redo DURATION;
                    }
                }
            }
        }
    }

    my (%expand, %lengths);
    foreach my $keyword (keys %entries) {
        $expand{$keyword}  = $self->_expand_for($keyword);
        $lengths{$keyword} = @{$entries{$keyword}->[0]};
    }

    my $seen_expression;
    do {
        $seen_expression = false;
        my $date_index;
        for (my $i = 0; $i < @tokens; $i++) {
            next if $skip{$i};
            if ($self->_check_for_date($tokens[$i], $i, \$date_index)) {
                last;
            }
        }
        GRAMMAR:
        foreach my $keyword (sort { $lengths{$b} <=> $lengths{$a} } grep { $lengths{$_} <= @tokens } keys %entries) {
            my @grammar = @{$entries{$keyword}};
            my $types_entry = shift @grammar;
            my @grammars = [ [ @grammar ], false ];
            if ($expand{$keyword} && @$types_entry + 1 <= @tokens) {
                @grammar = $self->_expand($keyword, $types_entry, \@grammar);
                unshift @grammars, [ [ @grammar ], true ];
            }
            foreach my $grammar (@grammars) {
                my $expanded = $grammar->[1];
                my $length = $lengths{$keyword};
                   $length++ if $expanded;
                foreach my $entry (@{$grammar->[0]}) {
                    my ($types, $expression) = $expanded ? @$entry : ($types_entry, $entry);
                    my $definition = $expression->[0];
                    my $matched = false;
                    my $pos = 0;
                    my @indexes;
                    my $date_index;
                    for (my $i = 0; $i < @tokens; $i++) {
                        next if $skip{$i};
                        last unless defined $types->[$pos];
                        if ($self->_check_for_date($tokens[$i], $i, \$date_index)) {
                            next;
                        }
                        if ($types->[$pos] eq 'SCALAR' && defined $definition->{$pos} && $tokens[$i] =~ /^$definition->{$pos}$/i
                         or $types->[$pos] eq 'REGEXP'                                && $tokens[$i] =~   $definition->{$pos}
                        && (@indexes ? ($i - $indexes[-1] == 1) : true)
                        ) {
                            $matched = true;
                            push @indexes, $i;
                            $pos++;
                        }
                        elsif ($matched) {
                            last;
                        }
                    }
                    if ($matched
                     && @indexes == $length
                     && (defined $date_index ? ($indexes[0] - $date_index == 1) : true)
                    ) {
                        my $expression = join ' ', (defined $date_index ? $tokens[$date_index] : (), @tokens[@indexes]);
                        my $start_index = defined $date_index ? $indexes[0] - 1 : $indexes[0];
                        my $type = $grammar_durations{$keyword} ? DURATION_TYPE : GRAMMAR_TYPE;
                        push @expressions, [ [ $start_index, $indexes[-1] ], $expression, { flags => $type } ];
                        $skip{$_} = true foreach (defined $date_index ? $date_index : (), @indexes);
                        $seen_expression = true;
                        last GRAMMAR;
                    }
                }
            }
        }
        if (defined $date_index && !$seen_expression) {
            push @expressions, [ [ ($date_index) x 2 ], $tokens[$date_index], { flags => DATE_TYPE } ];
            $skip{$date_index} = true;
            $seen_expression = true;
        }
    } while ($seen_expression);

    return $self->_finalize_expressions(\@expressions, \@tokens);
}

sub _finalize_expressions
{
    my $self = shift;
    my ($expressions, $tokens) = @_;

    my $timespan_sep = $self->{data}->__timespan('literal');
    my (@duration_indexes, @final_expressions);

    my $seen_duration = false;

    my @expressions = sort { $a->[0][0] <=> $b->[0][0] } @$expressions;

    for (my $i = 0; $i < @expressions; $i++) {
        my $expression = $expressions[$i];

        my $prev = $expression->[0][0] - 1;
        my $next = $expression->[0][1] + 1;

        if ($expression->[2]->{flags} & DATE_TYPE
         || $expression->[2]->{flags} & GRAMMAR_TYPE
        ) {
            if (!$seen_duration
             && defined $tokens->[$next]
             &&         $tokens->[$next] =~ /^$timespan_sep$/i
             && defined $expressions[$i + 1]
             &&        ($expressions[$i + 1]->[2]->{flags} & DATE_TYPE
                     || $expressions[$i + 1]->[2]->{flags} & GRAMMAR_TYPE)
             &&         $expressions[$i + 1]->[0][0] - $next == 1
            ) {
                push @duration_indexes, ($expression->[0][0] .. $expression->[0][1]);
                $seen_duration = true;
            }
            elsif ($seen_duration) {
                push @duration_indexes, ($prev, $expression->[0][0] .. $expression->[0][1]);
                push @final_expressions, join ' ', @$tokens[@duration_indexes];
                @duration_indexes = ();
                $seen_duration = false;
            }
            else {
                push @final_expressions, $expression->[1];
            }
        }
        elsif ($expression->[2]->{flags} & DURATION_TYPE) {
            push @final_expressions, $expression->[1];
        }
    }

    my $exclude = sub { $_[0] =~ /^\d{1,2}$/ };

    return grep !$exclude->($_), @final_expressions;
}

sub _check_for_date
{
    my $self = shift;
    my ($token, $index, $date_index) = @_;

    my ($formatted) = $token =~ $self->{data}->__regexes('format');
    my %count = $self->_count_separators($formatted);
    if ($self->_check_formatted('ymd', \%count)) {
        $$date_index = $index;
        return true;
    }
    else {
        return false;
    }
}

1;
__END__

=head1 NAME

DateTime::Format::Natural::Extract - Extract parsable expressions from strings

=head1 SYNOPSIS

 Please see the DateTime::Format::Natural documentation.

=head1 DESCRIPTION

C<DateTime::Format::Natural::Extract> extracts expressions from strings to be
processed by the parse methods.

=head1 SEE ALSO

L<DateTime::Format::Natural>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
