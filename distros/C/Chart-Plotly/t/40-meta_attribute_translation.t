#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Trace::Funnel;

my $trace_without_meta = Chart::Plotly::Trace::Scatter->new( x => [ 1, 2, 3 ],
                                                             y => [ 1, 2, 3 ],
)->TO_JSON();

ok( not( exists( $trace_without_meta->{'meta'} ) ), 'Serialized traces should not have meta attribute by default' );

my $meta_content = [ 'arbitray value1', 'arbitray value2', 'arbitrary value3' ];

my $trace_with_meta = Chart::Plotly::Trace::Funnel->new( x     => [ 1, 2, 3 ],
                                                         y     => [ 1, 2, 3 ],
                                                         pmeta => $meta_content,
)->TO_JSON();

ok( defined $trace_with_meta->{meta}, 'Serialized traces should have meta attribute instead of pmeta' );

is_deeply( $trace_with_meta->{meta}, $meta_content, 'Meta content is not meta object protocol details' );

