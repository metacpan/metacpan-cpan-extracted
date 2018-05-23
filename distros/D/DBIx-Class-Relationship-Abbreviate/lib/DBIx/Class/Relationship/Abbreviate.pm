use strict;
use warnings;

package DBIx::Class::Relationship::Abbreviate;

use Carp qw/ croak /;

sub import {
    my (undef, @fns) = @_;

    my ($ns) = caller =~ m/([\w:]+::Result)::\w+$/;

    croak qq{Cannot find result namespace in '@{[ scalar caller ]}'} unless $ns;

    my %export = (
        result => sub { my ($class) = @_; $ns.'::'.$class },
    );

    for my $fn (@fns) {
        if ($export{$fn}) {
            no strict 'refs';
            *{caller.'::'.$fn} = $export{$fn};
        } else {
            croak qq{Illegal function name '$fn'};
        }
    }
}

1;

# ABSTRACT: allows you to abbreviate result class names in your relationships
