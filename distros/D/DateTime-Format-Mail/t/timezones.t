use strict;
use Test::More tests => 13;
use vars qw( $class );
BEGIN {
    $class = 'DateTime::Format::Mail';
    use_ok $class;
}

my $fn = sub {
    DateTime::Format::Mail::_determine_timezone( @_ );
};

my %testsuite = (
    'EDT translates' => { 'EDT' => '-0400' },
    '+0400 remains the same' => { '+0400' => '+0400' },
    'leading GMTs on valids stripped' => {
	'GMT+0300' => '+0300',
	'GMT-0300' => '-0300',
    },
    'slightly off forms' => {
	'400'	=> '+0400',
	'-400'	=> '-0400',
	'+400'	=> '+0400',
    },
    'GMT normals' => {
	'GMT'	=> '+0000',
	'UTC'	=> '+0000',
    },
    'multiple signs' => {
	'+-700'	=> '-0700',
	'--700'	=> '-0700',
    },
    'invalids to -0000' => {
	'fnar'	=> '-0000',
    },
);

for my $label (sort keys %testsuite)
{
    my $tests = $testsuite{$label};
    for my $input (sort keys %$tests)
    {
	my $expected = $tests->{$input};
	is $fn->( $input ) => $expected => "$label ($input)";
    }
}
