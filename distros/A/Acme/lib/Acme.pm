package Acme;
use Spiffy -Base;
our $VERSION = '1.11111111111';
our @EXPORT = qw(acme);

sub acme() { Acme->new(@_) }

package
UNIVERSAL;
no warnings 'once';

sub is_acme { $self->isa('Acme') }

*is_perfect = \&is_acme;
*is_the_highest_point = \&is_acme;
*is_the_highest_stage = \&is_acme;
*is_the_highest_point_or_stage = \&is_acme;
*is_one_that_represents_perfection_of_the_thing_expressed = \&is_acme;
*is_the_bizzity_bomb = \&is_acme;
*is_teh_shiznit = \&is_acme;
*is_leon_brocard = \&is_acme;
