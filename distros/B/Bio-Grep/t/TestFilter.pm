package TestFilter;

use strict;
use warnings;

use Bio::Grep::Filter::FilterI;

use base 'Bio::Grep::Filter::FilterI';

use Class::MethodMaker
 [ new => [ qw / new2 / ],
   # here some local variables, see perldoc Class::MethodMaker
 ];

sub new {
   my $self = shift->new2;
   $self->delete(1); # a filter that actually filters, not only adds
                     # remarks to $self->search_result->remark
    
   $self->supports_alphabet( dna => 1, protein => 1);
   $self;
}

sub filter {
   my $self = shift;
   # code that examines $self->search_result
   # and returns 0 (not passed) or 1 (passed)
   $self->search_result->dG(-1 * int(rand(100)));
   $self->message('passed');
   return 1;
}   

sub reset_filter {
   my $self = shift;
   # if you need local variables, you can clean up here
}

1;# Magic true value required at end of module
