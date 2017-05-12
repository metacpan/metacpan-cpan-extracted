use strict;
use Test::More tests => 27;
use vars qw( $class );
BEGIN {
    $class = 'DateTime::Format::Mail';
    use_ok $class;
}

sub run_our_tests
{
    my ($fn, $testsuite) = @_;
    for my $label (sort keys %$testsuite)
    {
	my $tests = $testsuite->{$label};
	for my $input (sort keys %$tests)
	{
	    my $expected = $tests->{$input};
	    is $fn->( $input ) => $expected => "$label ($input)";
	}
    }
}

# Test defaults

{
    my $fn = sub {
	$class->fix_year( @_ );
    };

    my %testsuite = (
	'valid' => {
	    '1900' => '1900',
	    '2000' => '2000',
	    '2900' => '2900',
	},
	'low' => {
	    '10' => '2010',
	    '40' => '2040',
	},
	'high' => {
	    '70' => '1970',
	    '90' => '1990',
	},
        default => {
            '49' => '2049',
            '50' => '1950',
        },
    );
    run_our_tests( $fn => \%testsuite );
}

# Test customs

{
    my $parser = $class->new();
    isa_ok( $parser => $class );
    is( $parser->year_cutoff => 49, "Default is default." );
    $parser->set_year_cutoff( 20 );
    is( $parser->year_cutoff => 20, "Default overriden." );
}

{
    my $parser = $class->new( year_cutoff => 20 );
    my $fn = sub {
	$parser->fix_year( @_ );
    };

    my %testsuite = (
	'valid' => {
	    '1900' => '1900',
	    '2000' => '2000',
	    '2900' => '2900',
	},
	'low' => {
	    '10' => '2010',
	},
	'high' => {
	    '40' => '1940',
	    '70' => '1970',
	    '90' => '1990',
	},
    );
    run_our_tests( $fn => \%testsuite );
}

# Test bad arguments
{
    my $parser = $class->new();
    isa_ok( $parser => $class );
    is( $parser->year_cutoff => 49, "Default is default." );
    eval { $parser->set_year_cutoff( ) };
    ok( $@, "Error with no args" );
    eval { $parser->set_year_cutoff( 20, 40) };
    ok( $@, "Error with two args" );
    eval { $parser->set_year_cutoff( undef ) };
    ok( $@, "Error with undef arg" );
    eval { $parser->set_year_cutoff( 100 ) };
    ok( $@, "Error with arg too big" );
    eval { $parser->set_year_cutoff( -1 ) };
    ok( $@, "Error with arg negative" );
}
