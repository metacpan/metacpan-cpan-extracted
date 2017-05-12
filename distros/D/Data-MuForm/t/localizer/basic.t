#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Data::MuForm::Localizer;
use Test::More;

my $localizer = Data::MuForm::Localizer->new(
  language => 'en',
);

ok( $localizer, 'created localizer' );

my $lexicon = $localizer->get_lexicon;

ok( $lexicon, 'got lexicon' );

ok( keys(%$lexicon) > 40, 'we got a lexicon with data' );

# error_occurred
my $tr_str = $localizer->loc_('error occurred');
is( $tr_str, 'error occurred', 'error_occurred' );

# required
$tr_str = $localizer->loc_x("'{field_label}' field is required", field_label => 'Some Field');
is( $tr_str, "'Some Field' field is required", 'required');

# not in messages.po
$tr_str = $localizer->loc_x("{name} is nice", name => 'Joe Blow');
is( $tr_str, "Joe Blow is nice", 'message not in .po' );

# range_incorrect
$tr_str = $localizer->loc_x("Value must be between {low} and {high}", low => 5, high => 10);
is( $tr_str, "Value must be between 5 and 10", 'range_incorrect');

# range_too_high
$tr_str = $localizer->loc_x("Value must be less than or equal to {high}", high => 20 );
is( $tr_str, "Value must be less than or equal to 20", 'range_too_high' );

# loc_nx
$tr_str = $localizer->loc_nx("First message {num_digits}", "Second message {num_digits}", 2, num_digits => 2 );
is( $tr_str, "Second message 2", 'got correct nx string' );
$tr_str = $localizer->loc_nx("First message {num_digits}", "Second message {num_digits}", 1, num_digits => 1 );
is( $tr_str, "First message 1", 'got correct nx string' );
$tr_str = $localizer->loc_nx("First message {num_digits}", "Second message {num_digits}", 3, num_digits => 4 );
is( $tr_str, "Second message 4", 'got correct nx string' );

like( $localizer->module_path, qr{lib/Data/MuForm/Localizer.pm}, 'got path' );
done_testing;
