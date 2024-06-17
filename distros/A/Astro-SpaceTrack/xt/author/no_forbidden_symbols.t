package main;

use 5.010001;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule;

load_module_or_skip_all 'ExtUtils::Manifest', undef, [ 'maniread' ];
load_module_or_skip_all 'PPI::Document';

my $manifest = maniread();

foreach ( sort keys %{ $manifest } ) {

    is_perl( $_ )
	or next;

    my $doc = PPI::Document->new( $_ );

    my %found;
    foreach my $elem ( @{ $doc->find( 'PPI::Token::Symbol' ) || [] } ) {
	state $find = { map { $_ => 1 } qw{ $DB::single } };
	$find->{ my $symbol = $elem->symbol() }
	    or next;
	$found{$symbol}++;
    }

    is \%found, {}, "$_ does not contain forbidden symbols";
}

done_testing;

sub is_perl {
    my ( $file ) = @_;

    $file =~ m/ [.] (?: pl | PL | pm | t ) \z /smx
	and return 1;
    -B $file
	and return 0;
    open my $fh, '<:encoding(utf-8)', $file
	or return 0;
    my $line = <$fh>;
    close $fh;
    m/ \A \# ! .* perl /smx
	and return 1;
    return 0;
}

1;

# ex: set textwidth=72 :
