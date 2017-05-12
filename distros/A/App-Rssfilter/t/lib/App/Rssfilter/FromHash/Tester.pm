use strict;
use warnings;

package App::Rssfilter::FromHash::Tester;

use Moose;
extends 'App::Rssfilter::Group';
with 'App::Rssfilter::FromHash';
use Method::Signatures;

has fake_class_name => (
    is => 'ro',
    default => sub { 'fake_class'; },
);

has fake_class => (
    is => 'ro',
    lazy => 1,
    default => method {
        my $name = $self->fake_class_name;
        my $fake_class = Test::MockObject->new();
        $fake_class->set_always( ctor => $fake_class );
        $fake_class->fake_module( $name, new => method( @_ ) { $fake_class->ctor( @_ ) } );
        return $fake_class;
    },
);

has results_of_split_for_ctor => (
    is => 'rw',
    default => sub { [ ] },
);

1;
