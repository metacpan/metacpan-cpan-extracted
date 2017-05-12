package t::Object::Animal::Jackalope;

BEGIN { 
    for ( 't::Object::Animal::Antelope', 't::Object::Animal::JackRabbit' ) {
        eval "require $_";
        push @t::Object::Animal::Jackalope::ISA, $_;
    }
}

use Class::InsideOut qw( private property id );

# superclass is handling new()

Class::InsideOut::options( { privacy => 'public' } );

property kills    => my %kills;
private  whiskers => my %whiskers; 
private  sidekick => my %sidekick, { privacy => 'public' };

use vars qw( $freezings $thawings );

sub FREEZE {
    my $self = shift;
    $freezings++;
}

sub THAW {
    my $self = shift;
    $thawings++;
}

1;
