use strict;
use warnings;
use Bread::Board;

sub {
    my $c        = shift;
    my $orig_tag = $c->get_service('tag');
    container $c => as {
        service tag => (
            block => sub {
                $orig_tag->get . ', modified by ExtSite';
            }
        );
    };
};

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 
