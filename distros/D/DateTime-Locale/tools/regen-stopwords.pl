#!/usr/bin/env perl

use v5.22;

use strict;
use warnings;
use autodie qw( :all );

## no critic (TestingAndDebugging::ProhibitNoWarnings )
no warnings qw( experimental::regex_sets );

use Pod::Simple::Search;

{
    package My::Parser;

    use parent 'Pod::Simple::Methody';

    sub handle_text {
        my $self = shift;

        for my $word ( split / +/, shift ) {
            $word             =~ s/^\s+|\s+$//g;
            $word             =~ s/^['(,.]+|['),.]+\z//g;
            next unless $word =~ /\p{L}/;

            $self->{words}{$word} = 1;
        }
    }

    sub words {
        my $self = shift;
        return grep { length $_ } ( sort keys %{ $self->{words} } );
    }
}

# Words from the non-generated files.
my @additional = qw(
    CLDR
    Eg
    Hant
    Starman
    yyyyMM
);

sub main {
    binmode STDOUT, ':encoding(UTF-8)';

    say $_ or die for @additional;

    for my $path ( files() ) {
        my $parser = My::Parser->new;
        $parser->parse_file($path);
        for my $word ( $parser->words ) {
            say $word or die;
        }
    }
}

sub files() {
    if (@ARGV) {
        return @ARGV;
    }
    my ($name2path) = Pod::Simple::Search->new->inc(0)->survey('lib');
    return grep {/\.pod$/} sort values %{$name2path};
}

main();
