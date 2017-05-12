#!/usr/bin/env perl
use Test::More;
use CPAN::Source;
use CPAN::Source::Dist;

my $source = CPAN::Source->new;

my $dist = CPAN::Source::Dist->new({
    name => 'Moose', 
    version_name => 'Moose-2.0205',
    version => '2.0205', 
    source_path => 'http://cpansearch.perl.org/src/DOY/Moose-2.0205',
    _parent => $source });
ok( $dist );
ok( $dist->to_string );
ok( $dist . '' );

ok( $dist->name );
ok( $dist->version_name );

my $meta;
ok( $meta = $dist->fetch_meta );
ok( $meta->{version} );
ok( $meta->{abstract} );
done_testing;
