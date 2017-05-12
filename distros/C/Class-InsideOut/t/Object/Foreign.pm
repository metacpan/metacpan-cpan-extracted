package t::Object::Foreign;
use strict;

use Class::InsideOut qw( register public id );
BEGIN {
    require IO::File;
    @t::Object::Foreign::ISA = 'IO::File';
}

public name => my %name;

sub new {
    my ($class, $filename) = @_;
    my $self = IO::File->new;
    $self->open( $filename ) if defined $filename && length $filename;
    register( bless $self, $class );
}


1;
