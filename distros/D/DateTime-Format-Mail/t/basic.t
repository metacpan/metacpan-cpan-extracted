# $Id$
use strict;
use Test::More tests => 8;
use vars qw( $class );

BEGIN {
    $class = 'DateTime::Format::Mail';
    use_ok $class;
}

# Do new() and clone() work properly?
{
    eval { $class->new('fnar') };
    ok( ($@ and $@ =~ /^Odd number/), "Odd number of args spotted." );

    my $obj = eval { $class->new( loose => 1, year_cutoff => 4 ) };
    ok( !$@, "Created object" );
    diag $@ if $@;
    isa_ok( $obj, $class );

    my $clone = $obj->clone;
    ok( eq_hash( $obj, $clone ), "Clones are equal" );

    my $second = $clone->new;
    my $third = $obj->new;
    ok( eq_hash( $obj, $second ), "2nd clone equal" );
    ok( eq_hash( $obj, $third ), "3rd clone equal" );
    ok( eq_hash( $third, $clone ), "3rd and 1st clones equal" );
}

