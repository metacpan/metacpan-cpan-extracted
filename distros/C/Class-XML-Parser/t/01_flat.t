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
</parser>
EOXML

# with no lower-level parse classes defined, will collapse all elements
# and attributes to the current class.  As no prune is specified,
# whitespace in the xml file will be preserved in the elements
my $parser = Class::XML::Parser->new(
    root_class      => 'ParseResult::Flat',
);

my $res = $parser->parse( $xml );

my $expected = {
    attr1           => 'attr_val1',
    attr2           => 'attr_val2',
    attr_bottom     => 'attr_bottom_val',
    y               => '64',
    elem1           => "\n    ",
    elem2           => 'Element2 text, 2nd run',
    elem3           => "\n        ",
    elem4           => "    whitespace abounds    ",
    elem_bottom     => 'bottom_value',
    parser          => "\n",
};

ok( ref $res, "expect a reference back" );
is_deeply( $res, $expected, 'datastructure' );

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
