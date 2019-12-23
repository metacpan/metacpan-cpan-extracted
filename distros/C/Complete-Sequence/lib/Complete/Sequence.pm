package Complete::Sequence;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-17'; # DATE
our $DIST = 'Complete-Sequence'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::Common qw(:all);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       complete_sequence
               );

our %SPEC;

our $COMPLETE_SEQUENCE_TRACE = $ENV{COMPLETE_SEQUENCE_TRACE} // 0;

sub _get_strings_from_item {
    my ($item, $stash) = @_;

    my @array;
    my $ref = ref $item;
    if (!$ref) {
        push @array, $item;
    } elsif ($ref eq 'ARRAY') {
        push @array, @$item;
    } elsif ($ref eq 'CODE') {
        push @array, _get_strings_from_item($item->($stash), $stash);
    } elsif ($ref eq 'HASH') {
        if (defined $item->{alternative}) {
            push @array, map { _get_strings_from_item($_, $stash) }
                @{ $item->{alternative} };
        } elsif (defined $item->{sequence} && @{ $item->{sequence} }) {
            my @set = map { [_get_strings_from_item($_, $stash)] }
                @{ $item->{sequence} };
            #use DD; dd \@set;
            # sigh, this module is quite fussy. it won't accept
            if (@set > 1) {
                require Set::CrossProduct;
                my $scp = Set::CrossProduct->new(\@set);
                while (my $tuple = $scp->get) {
                    push @array, join("", @$tuple);
                }
            } elsif (@set == 1) {
                push @array, @{ $set[0] };
            }
        } else {
            die "Need alternative or sequence";
        }
    } else {
        die "Invalid item: $item";
    }
    @array;
}

$SPEC{complete_sequence} = {
    v => 1.1,
    summary => 'Complete string from a sequence of choices',
    description => <<'_',

Sometime you want to complete a string where its parts (sequence items) are
formed from various pieces. For example, suppose your program "delete-user-data"
accepts an argument that is in the form of:

    USERNAME
    UID "(" "current" ")"
    UID "(" "historical" ")"

    "EVERYONE"

Supposed existing users include `budi`, `ujang`, and `wati` with UID 101, 102,
103.

This can be written as:

    [
        {
            alternative => [
                [qw/budi ujang wati/],
                {sequence => [
                    [qw/101 102 103/],
                    ["(current)", "(historical)"],
                ]},
                "EVERYONE",
            ],
        }
    ]

When word is empty (`''`), the offered completion is:

    budi
    ujang
    wati

    101
    102
    103

    EVERYONE

When word is `101`, the offered completion is:

    101
    101(current)
    101(historical)

When word is `101(h`, the offered completion is:

    101(historical)

_
    args => {
        %arg_word,
        sequence => {
            schema => 'array*',
            req => 1,
            description => <<'_',

A sequence structure is an array of items. An item can be:

* a scalar/string (a single string to choose from)

* an array of strings (multiple strings to choose from)

* a coderef (will be called to extract an item)

  Coderef will be called with `$stash` argument which contains various
  information, e.g. the index of the sequence item (`item_index`), the completed
  parts (`completed_item_words`), the current word (`cur_word`), etc.

* a hash (another sequence or alternative of items)

If you want to specify another sub-sequence of items:

    {sequence => [ ... ]}   # put items in here

If you want to specify an alternative of sub-sequences or sub-alternative:

    {alternative => [ ... ]}    # put items in here

_
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_sequence {
    require Complete::Util;

    my %args = @_;

    my $word = $args{word} // "";
    my $sequence = $args{sequence};

    my $orig_word = $word;
    my @prefixes_from_completed_items;

    my $stash = {
        completed_item_words => \@prefixes_from_completed_items,
        cur_word => $word,
        orig_word => $orig_word,
    };

    my $itemidx = -1;
    for my $item (@$sequence) {
        $itemidx++; $stash->{item_index} = $itemidx;
        log_trace("[compseq] Looking at sequence item[$itemidx] : %s", $item) if $COMPLETE_SEQUENCE_TRACE;
        my @array = _get_strings_from_item($item, $stash);
        log_trace("[compseq] Result from sequence item[$itemidx]: %s", \@array) if $COMPLETE_SEQUENCE_TRACE;
        my $res = Complete::Util::complete_array_elem(
            word => $word,
            array => \@array,
        );
        if ($res && @$res == 1) {
            # the word can be completed directly (unambiguously) with this item.
            # move on to get more words from the next item.
            log_trace("[compseq] Word ($word) can be completed unambiguously with this sequence item[$itemidx], moving on to the next sequence item") if $COMPLETE_SEQUENCE_TRACE;
            substr($word, 0, length $res->[0]) = "";
            $stash->{cur_word} = $word;
            push @prefixes_from_completed_items, $res->[0];
            next;
        } elsif ($res && @$res > 1) {
            # the word can be completed with several choices from this item.
            # present the choices as the final answer.
            my $compres = [map { join("", @prefixes_from_completed_items, $_) } @$res];
            log_trace("[compseq] Word ($word) can be completed with several choices from this sequence item[$itemidx], returning final result: %s", $compres) if $COMPLETE_SEQUENCE_TRACE;
            return $compres;
        } else {
            # the word cannot be completed with this item. it can be that the
            # word already contains this item and the next.
            my $num_matches = 0;
            my $matching_str;
            for my $str (@array) {
                # XXX perhaps we want to be case-insensitive?
                if (index($word, $str) == 0) {
                    $num_matches++;
                    $matching_str = $str;
                }
            }
            if ($num_matches == 1) {
                substr($word, 0, length($matching_str)) = "";
                $stash->{cur_word} = $word;
                push @prefixes_from_completed_items, $matching_str;
                log_trace("[compseq] Word ($word) cannot be completed by this sequence item[$itemidx] because part of the word matches previous sequence item(s); completed_parts=%s, word=%s", \@prefixes_from_completed_items, $word) if $COMPLETE_SEQUENCE_TRACE;
                next;
            }

            # nope, this word simply doesn't match
            log_trace("[compseq] Word ($word) cannot be completed by this sequence item[$itemidx], giving up the rest of the sequence items") if $COMPLETE_SEQUENCE_TRACE;
            goto RETURN;
        }
    }

  RETURN:
    my $compres;
    if (@prefixes_from_completed_items) {
        $compres = [join("", @prefixes_from_completed_items)];
    } else {
        $compres = [];
    }
    log_trace("[compseq] Returning final result: %s", $compres) if $COMPLETE_SEQUENCE_TRACE;
    $compres;
}

1;
# ABSTRACT: Complete string from a sequence of choices

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Sequence - Complete string from a sequence of choices

=head1 VERSION

This document describes version 0.002 of Complete::Sequence (from Perl distribution Complete-Sequence), released on 2019-12-17.

=head1 FUNCTIONS


=head2 complete_sequence

Usage:

 complete_sequence(%args) -> array

Complete string from a sequence of choices.

Sometime you want to complete a string where its parts (sequence items) are
formed from various pieces. For example, suppose your program "delete-user-data"
accepts an argument that is in the form of:

 USERNAME
 UID "(" "current" ")"
 UID "(" "historical" ")"
 
 "EVERYONE"

Supposed existing users include C<budi>, C<ujang>, and C<wati> with UID 101, 102,
103.

This can be written as:

 [
     {
         alternative => [
             [qw/budi ujang wati/],
             {sequence => [
                 [qw/101 102 103/],
                 ["(current)", "(historical)"],
             ]},
             "EVERYONE",
         ],
     }
 ]

When word is empty (C<''>), the offered completion is:

 budi
 ujang
 wati
 
 101
 102
 103
 
 EVERYONE

When word is C<101>, the offered completion is:

 101
 101(current)
 101(historical)

When word is C<101(h>, the offered completion is:

 101(historical)

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<sequence>* => I<array>

A sequence structure is an array of items. An item can be:

=over

=item * a scalar/string (a single string to choose from)

=item * an array of strings (multiple strings to choose from)

=item * a coderef (will be called to extract an item)

Coderef will be called with C<$stash> argument which contains various
information, e.g. the index of the sequence item (C<item_index>), the completed
parts (C<completed_item_words>), the current word (C<cur_word>), etc.

=item * a hash (another sequence or alternative of items)

=back

If you want to specify another sub-sequence of items:

 {sequence => [ ... ]}   # put items in here

If you want to specify an alternative of sub-sequences or sub-alternative:

 {alternative => [ ... ]}    # put items in here

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)

=head1 ENVIRONMENT

=head2 COMPLETE_SEQUENCE_TRACE

Bool. If set to true, will display more log statements for debugging.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Sequence>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Sequence>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Sequence>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete::Path>. Conceptually, L</complete_sequence> is similar to
C<complete_path> from L<Complete::Path>. Except unlike a path, a sequence does
not (necessarily) have path separator.

L<Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
