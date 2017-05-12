#!/usr/bin/perl

use lib './lib';

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 3;

use_ok( 'Class::XML::Parser' );

my $xml = <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>

<parser>
    <elem1 y="64">
        <elem2>Element2 text, 1st run</elem2>
        <elem2>Element2 text, 2nd run</elem2>
        <elem3 attr1="attr_val1" attr2="attr_val2">
            <elem_bottom attr_bottom="attr_bottom_val">bottom_value</elem_bottom>
            <empty_element />
        </elem3>
        <elem4>    whitespace abounds    </elem4>
    </elem1>
EOXML

# missing final '</parser>' value causes last_error to be defined
my $parser = Class::XML::Parser->new(
    root_class      => 'ParseResult::Flat',
);

my $res = $parser->parse( $xml );
ok( ! defined $res, 'parse result not defined on parse error' );
like( $parser->last_error(), qr/no element found/, 'last_error value' );

# this just defines an AUTOLOADER, for quick-and-easy accessors/mutators
package ParseBase;

use vars qw( $AUTOLOAD );

sub new { bless {}, shift }

sub AUTOLOAD {
    my ( $self, $val ) = @_;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return if $method eq 'DESTROY';

    if ( defined $val ) {
        $self->{ $method } = $val;
    }

    return $self->{ $method };
}

package ParseResult::Flat;

use base qw( ParseBase );

1;
