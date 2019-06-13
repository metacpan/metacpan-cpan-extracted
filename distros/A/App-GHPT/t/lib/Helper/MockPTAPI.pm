package Helper::MockPTAPI;

use App::GHPT::Wrapper::OurMoose;

use Hash::Objectify qw( objectify );

extends 'WebService::PivotalTracker';

sub projects ( $self ) {
    [
        objectify( { name => 'Team Scotty', id => 123 } ),
        objectify( { name => 'Team Uhura',  id => 456 } ),
        objectify( { name => 'Team Data',   id => 789 } ),
        objectify( { name => 'SRE',         id => 303 } ),
    ];
}

1;
