#!perl -w
use strict;
use Test::More;
use Data::Dumper;
use Dancer::SearchApp::HTMLSnippet;

#plan tests => 'no_plan';

for my $test (
    ['t/htmlsnippet.html',8],
    ['t/htmlsnippet-ical.html',1],
) {
    my($fn,$entries) = @$test;
    diag $fn;
    # Sluurp
    my $html = do { local(@ARGV,$/) = ($fn); <> };

    my @snippets = Dancer::SearchApp::HTMLSnippet->extract_highlights(
        html => $html,
        max_length => 150,
    );

    is 0+@snippets, $entries, "We get the expected number of snippets back";

    # All snippets should contain a matching number of em / /em tags
    my @unmatched;
    for my $s (@snippets) {
        my $text = substr($html, $s->{start}, $s->{length});
        my $opening = () =  ($text =~ m!<em>!g);
        my $closing = () =  ($text =~ m!</em>!g);
        push @unmatched, [$s,$text]
            if( $opening != $closing );
    };
    if( ! is 0+@unmatched, 0, "All matched phrases are balanced") {
        diag Dumper \@unmatched;
    };

    # All snippets should contain at least one matched phrases
    my @phrase;
    for my $s (@snippets) {
        my $text = substr($html, $s->{start}, $s->{length});
        my $opening = () = ($text =~ m!<em>!g);
        push @phrase, [$s,$text]
            if( ! $opening );
    };
    if( ! is 0+@phrase, 0, "All snippets contain a phrase") {
        diag Dumper \@phrase;
    };

    # All snippets should be within the HTML string
    my @outside = grep { $_->{start} <= 0 or $_->{end} >= length $html } @snippets;
    if( ! is 0+@outside, 0, "No snippet reaches outside the HTML string") {
        diag Dumper \@outside;
    };

    # Collext all overlapping snippets (there shouldn't be any)
    # relax this - there should not be overlaps in the matched keywords
    my @overlaps;

    # Unaccidentially quadratic
    for my $curr (@snippets) {
        for my $other (@snippets) {
            next if $curr == $other;
            
            # $curr:       |------------|
            # $other:   |-----------|

            # Only repeat each combination once
            # by only looking at things that start within others
            my($start,$end,$ostart);
            substr( $html, $curr->{start} ) =~ /^(.*?)<em>/
                or die "No highlight found?!";
            $start += length $1;
            substr( $html, $curr->{start}, $curr->{length} ) =~ m!.*</em>(.*?)$!
                or die "No highlight end found?!";
            $end -= length $1;
            substr( $html, $other->{start} ) =~ m!^(.*?)<em>!
                or die "No highlight found?!";
            $ostart += length $1;
            push @overlaps, [$curr,$other]
                if(     $start <= $ostart
                    and $end   >= $ostart
                  );
        };
    };

    if(! is 0+@overlaps, 0, "The snippets don't overlap") {
        for( @overlaps ) {
            my ($l,$r) = @$_;
            diag sprintf <<'OVERLAP', $l->{start},$l->{end},$r->{start},$r->{end};
    |-----------|     %d - %d
        |-----------| %d - %d
OVERLAP
            diag Dumper $_;
        };
    };

    # Maybe count text outside of tags?!
    my @too_long = grep { $_->{length} >= 150 } @snippets;
    if( ! is 0+@too_long, 0, "No snippet is too long (150 chars)") {
        diag Dumper \@too_long;
    };
};

done_testing;