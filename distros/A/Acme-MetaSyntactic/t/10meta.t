use strict;
use Test::More;
use Acme::MetaSyntactic;
use lib 't/lib';
use NoLang;
use File::Spec::Functions;
my $dir;
BEGIN { $dir = catdir qw( t lib ); }
use lib $dir;

plan tests => 11;

LIST: {
    my $meta = Acme::MetaSyntactic->new('test_ams_list');
    my %seen;

    my @names = $meta->name;
    is( scalar @names, 1, "name() returned a single item" );

    push @names, $meta->name(3);
    is( scalar @names, 4, "name( 3 ) returned three more items" );

    $seen{$_}++ for @names;
    is_deeply(
        \%seen,
        { John => 1, Paul => 1, George => 1, Ringo => 1 },
        "Got the whole list"
    );
}

NOTEXIST: {
    my $meta = Acme::MetaSyntactic->new('test_ams_nonexistent');

    my @names = eval { $meta->name };
    like(
        $@,
        qr/Metasyntactic list test_ams_nonexistent does not exist!/,
        "Non-existent theme"
    );
}

MORE: {
    my $meta = Acme::MetaSyntactic->new('test_ams_list');
    my %seen;

    my %test;
    @test{ qw( John Paul George Ringo ) } = (1) x 4;

    my @names;
    push @names, $meta->name( 5 );
    is( scalar @names, 5, "name() returned five items out of 4" );

    $test{$names[-1]}++;

    $seen{$_}++ for @names;
    is_deeply( \%seen, \%test, "Got one item twice" );
}

ZERO: {
    my $meta = Acme::MetaSyntactic->new( 'test_ams_list' );
    my @names = sort $meta->name( 0 );

    no warnings;
    my @all   = sort @Acme::MetaSyntactic::test_ams_list::List;

    is_deeply( \@names, \@all, "name(0) returns the whole list" );

    my $count = $meta->name( 0 );
    is( $count, scalar @all, "name(0) is scalar context returns the count" );
}

DEFAULT: {
    my $meta = Acme::MetaSyntactic->new();

    no warnings;
    my @names = $meta->name;
    my %seen = map { $_ => 0 } @{$Acme::MetaSyntactic::foo::MultiList{en}};
    ok( exists $seen{$names[0]}, "From the default list" );

    %seen = map { $_ => 1 } $meta->name( test_ams_list => 4 );
    is_deeply(
        \%seen,
        { John => 1, Paul => 1, George => 1, Ringo => 1 },
        "Got the whole list"
    );

    @names = $meta->name( 'foo/fr' );
    %seen = map { $_ => 0 } @{$Acme::MetaSyntactic::foo::MultiList{fr}};
    ok( exists $seen{$names[0]}, "using name() with a category" );
}

