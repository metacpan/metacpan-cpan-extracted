use Test::More;


# skip all tests if CSV requirements aren't met
my $has_requirements = 0;

eval {
    require IO::Handle;
    require IO::File;
    require Text::CSV;
    $has_requirements = 1;
};

if($has_requirements) {
  plan tests => 5;
} 
else {
    plan skip_all => "Prerequisites for CSV Adapter not installed";
}

my $file = './t/data/csv';

use Data::Pipeline qw( Pipeline Count CSV );

my $s;
my $i = Count -> transform( $s = CSV(
        file => $file,
        file_has_header => 1
    ) );

is( $i -> next -> {count}, 3 );

$s = Pipeline -> transform($s -> duplicate);

is( $s -> next -> {'foo'}, 'Apple' );
is( $s -> next -> {'foo'}, 'Pear' );
is( $s -> next -> {'foo'}, 'Banana' );

my $p = Pipeline(
            CSV( file_has_header => 1 ),
            Count,
            CSV( column_names => [qw(count)] )
);

my $out;

$p -> from( file => $file ) -> to( \$out );

is( 0+$out, 3 );
