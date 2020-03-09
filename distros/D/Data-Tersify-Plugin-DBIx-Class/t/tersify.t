#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;
use Test::More;

use Data::Tersify qw(tersify);

subtest('We can handle a result source', \&test_result_source);
subtest('We can handle a result set',    \&test_result_set);

done_testing();

sub test_result_source {
    my %table_data = (
        _result_source => bless {
            _columns => {
                map { $_ => { data_type => 'CHAR', is_nullable => 0 } }
                    qw(none of these matter)
            },
            _ordered_columns => [qw(these aren't even the same ones)],
            _relationships   => q{Nothing like what a real object would have},
            name             => 'Dave',
            schema           => 'Mercator? Is that right?',
            source_registrations => {
                CMYK => 'You put like a blotch of each colour side by side',
            }
        } => 'DBIx::Class::ResultSource::Table',
    );
    my $tersified = tersify(\%table_data);
    like(${ $tersified->{_result_source} },
        qr{ DBIx::Class::ResultSource::Table \s \S+ \s Dave }x,
        'We just summarised the name of the table and nothing else');

    my %view_data = (
        _result_source => bless {
            _columns         => 'We established that these are ignored',
            _ordered_columns => [qw(yeah yeah yeah)],
            _relationships   => 'Dickens was paid by the word, you know',
            view_definition =>
                q{OK, that's not true, but then none of this is},
            name => 'Look at Dave!',
        } => 'DBIx::Class::ResultSource::View'
    );
    my $tersified_view = tersify(\%view_data);
    use Data::Dumper;
    like(${ $tersified_view->{_result_source} },
        qr{ DBIx::Class::ResultSource::View \s \S+ \s Look \s at \s Dave! }x,
        'This also works for views');
}

sub test_result_set {
    my %data = (
        result_set => bless {
            _result_class => 'Arbitrary::Class::Name',
            attrs         => {
                Paul    => 'alive',
                Jessica => 'alive',
                Leto    => 'dead',
                Alia    => 'abomination',
            },
            cond          => 'Not even a hashref',
            result_source => 'Ignored',
        } => 'DBIx::Class::ResultSet',
    );
    my $tersified = tersify(\%data);
    like(
        ${ $tersified->{result_set} },
        qr{^ DBIx::Class::ResultSet \s \S+ \s Arbitrary::Class::Name $}x,
        'We just summarised the result class of a result set'
    );
}
