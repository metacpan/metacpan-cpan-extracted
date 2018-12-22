package main;

use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

eval {
    require ExtUtils::Manifest;
    1;
} or plan skip_all => 'Unable to load ExtUtils::Manifest';

eval {
    require Perl::MinimumVersion;
    1;
} or plan skip_all => 'Unable to load Perl::MinimumVersion';

eval {
    require version;
    1;
} or plan skip_all => 'Unable to load version';

my $min_perl = '5.008004';
my $min_perl_vers = version->parse( $min_perl );

my $manifest = ExtUtils::Manifest::maniread();

foreach my $fn ( sort keys %{ $manifest } ) {
    $fn =~ m{ \A xt/ }smx
	and next;
    is_perl( $fn )
	or next;
    my $doc = Perl::MinimumVersion->new( $fn );
    cmp_ok $doc->minimum_version(), 'le', $min_perl,
	"$fn works under Perl $min_perl";
    my $ppi_doc = $doc->Document();
    foreach my $inc (
	@{ $ppi_doc->find( 'PPI::Statement::Include' ) || [] } ) {
	my $vers = $inc->version()
	    or next;
	cmp_ok( version->parse( $vers ), '==', $min_perl_vers,
	    "$fn has use $min_perl, rather than some other version" );
	last;
    }
}

done_testing;

sub is_perl {
    my ( $fn ) = @_;
    $fn =~ m/ [.] (?: pm | t | pod | (?i: pl ) ) \z /smx
	and return 1;
    -f $fn
	and -T _
	or return 0;
    open my $fh, '<', $fn
	or return 0;
    local $_ = <$fh>;
    close $fh;
    return m/ perl /smx;
}

1;

# ex: set textwidth=72 :
