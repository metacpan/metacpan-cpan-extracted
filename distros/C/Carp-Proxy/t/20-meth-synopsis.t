# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN{
    package Derived;
    use Moose;
    extends 'Carp::Proxy';

    #-----
    # Our goal here is to override Carp::Proxy's synopsis() method by
    # sub-classing.  The override should produce a section containing
    # the DESCRIPTION rather than the SYNOPSIS
    #-----
    sub synopsis {
        my( $self, @tag_value_pairs ) = @_;

        $self->SUPER::synopsis( -verbose => 99,
                                -sections => [qw( DESCRIPTION )],
                                @tag_value_pairs,
                              );
        return;
    }
    no Moose;
    __PACKAGE__->meta->make_immutable;
}

package main;

use Carp::Proxy;
BEGIN{
    Derived->import( fatal1 => {} );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, @tag_value_pairs ) = @_;

    $cp->synopsis( @tag_value_pairs );
    return;
}

sub main {

    throws_ok{ fatal 'handler' }
        qr{
              \QExamples and usage text go here.\E
          }x,
        'SYNOPSIS was extracted from Pod';

    throws_ok{ fatal 'handler', -verbose => 99, -sections => [qw(NAME)] }
        qr{
              \QA terse summary of our purpose.\E
          }x,
        'SYNOPSIS was extracted from Pod';

    throws_ok{ fatal1 'handler' }
        qr{
              \QA brief description of what the module does.\E
          }x,
        'DESCRIPTION extracted from POD by sub-class';

    throws_ok{ fatal 'handler', qw( odd number of supplemental arguments) }
        qr{
              \QOops << odd synopsis augmentation >>\E
          }x,
        'synopsis() catches odd number of arguments';

    throws_ok{ Carp::Proxy::error 'cannot_open_string' }
        qr{
              \QOops << cannot open string >>\E
          }x,
        'cannot_open_string internal handler looks OK';

    throws_ok{ Carp::Proxy::error 'cannot_close_string' }
        qr{
              \QOops << cannot close string >>\E
          }x,
        'cannot_close_string internal handler looks OK';

    return;
}

__END__

=pod

=head1 NAME

A terse summary of our purpose.

=head1 SYNOPSIS

Examples and usage text go here.

=head1 DESCRIPTION

A brief description of what the module does.

=cut

