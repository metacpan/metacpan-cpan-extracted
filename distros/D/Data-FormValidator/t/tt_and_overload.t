#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;

eval { require Template; require Template::Stash; };
plan skip_all => 'Template Toolkit required' if $@;
plan tests => 1;

my $results = Data::FormValidator->check( {}, { required => 1 } );

my $tt = Template->new( STASH => Template::Stash->new );

$tt->process( \'[% form.missing %]', { form => $results }, \my $out );

ok( not $tt->error );
