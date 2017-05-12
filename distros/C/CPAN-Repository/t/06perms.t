#!/usr/bin/perl

use strict;
use warnings;

use CPAN::Repository::Perms;
use Test::More;

my $perms = CPAN::Repository::Perms->new(
    {
        repository_root => 'foo',
        written_by      => 'MetaCPAN',
    }
);

my %authors = (
    FOOBAR => {
        'Baz::Qux'    => 'f',
        'Acme::Perms' => 'm',
    },
    BARFOO => { 'Thing::One' => 'c', },
);

foreach my $pauseid ( keys %authors ) {
    my $modules = $authors{$pauseid};
    foreach my $module ( keys %{$modules} ) {
        $perms->set_perms( $module, $pauseid, $modules->{$module} );
    }
}

my $content = $perms->generate_content;
my @lines = split m{\n}, $content;
my @expected
    = ( 'Acme::Perms,FOOBAR,m', 'Baz::Qux,FOOBAR,f', 'Thing::One,BARFOO,c' );

is_deeply( [ @lines[ -3 .. -1 ] ], \@expected, 'rows are on newlines' );

done_testing();
