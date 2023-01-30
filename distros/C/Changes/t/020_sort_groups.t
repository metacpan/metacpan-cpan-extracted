#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use DateTime;
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes' ) || BAIL_OUT( "Failed to load Changes" );;
    use_ok( 'Changes::Change' ) || BAIL_OUT( "Failed to load Changes" );;
};

use strict;
use warnings;

my $raw_data = <<'EOT';
1.05 2011-04-17
    [A]
    - stuff
    [B]
    - mo' stuff
1.04 2011-04-16
    [C]
    - stuff
    [D]
    - mo' stuff
EOT
my $tests =
[
    { version => '1.05', datetime => '2011-04-17', groups => [qw( A B )], changes => ['stuff',q{mo' stuff}] },
    { version => '1.04', datetime => '2011-04-16', groups => [qw( C D )], changes => ['stuff',q{mo' stuff}] },
];

my $c = Changes->load_data( $raw_data, debug => $DEBUG );
isa_ok( $c, 'Changes' );
is( $c->preamble, undef, 'no preamble' );
is( $c->releases->length, scalar( @$tests ), 'No of releases' );
my $changes_data = $c->as_string;
is( "$changes_data", $raw_data, 'as_string reproduces same original data' );

for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    my $def = $tests->[$i];
    my $rel = $c->releases->index($i);
    isa_ok( $rel, 'Changes::Release' );
    is( $rel->changes->length, 2, 'No of changes' );
    diag( "Changes found are: '", $rel->changes->join( "', '" ), "'" ) if( $DEBUG );
    subtest "Release No " . ( $i + 1 ) => sub
    {
        SKIP:
        {
            skip( 'No release object found.', 9 ) if( !$rel );
            is( $rel->version, $def->{version}, 'version' );
            is( $rel->datetime, $def->{datetime}, 'datetime' );
            my $groups = $rel->groups;
            is( scalar( @{$def->{groups}} ), $groups->length, 'No of groups' );
            for( my $j = 0; $j < scalar( @{$def->{groups}} ); $j++ )
            {
                my $g = $groups->index($j);
                isa_ok( $g, 'Changes::Group' ) || next;
                my $changes = $g->changes;
                is( $changes->length, 1, 'No of changes' );
                isa_ok( $changes->first, 'Changes::Change' );
                is( $changes->first->text, $def->{changes}->[$j], 'change' );
            }
            my $reverse = $groups->reverse;
            is( $reverse->map(sub{ $_->name })->join( '' ), reverse( @{$def->{groups}} ), 'reverse order' );
        };
    };
}

done_testing();

__END__

