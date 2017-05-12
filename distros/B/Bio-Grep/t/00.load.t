#!perl -T

BEGIN {
    use lib 't';
    use Test::More;
    use Test::NoWarnings;
    use BioGrepSkip; 
    my ($skip,$msg) = BioGrepSkip::skip_all( );
    plan skip_all => $msg if $skip;
    plan tests => 12;

    use_ok( 'Bio::Grep' );
    use_ok( 'Bio::Grep::Root' );
    use_ok( 'Bio::Grep::Backend::Agrep' );
    use_ok( 'Bio::Grep::Backend::BackendI' );
    use_ok( 'Bio::Grep::Backend::GUUGle' );
    use_ok( 'Bio::Grep::Backend::RE' );
    use_ok( 'Bio::Grep::Backend::Vmatch' );
    use_ok( 'Bio::Grep::SearchResult' );
    use_ok( 'Bio::Grep::SearchSettings' );
    use_ok( 'Bio::Grep::Filter::FilterI' );
    use_ok( 'Bio::Grep::Filter::FilterRemoveDuplicates' );
}

diag( "Testing Bio::Grep $Bio::Grep::VERSION" );

