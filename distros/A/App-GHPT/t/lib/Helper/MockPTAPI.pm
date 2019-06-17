package Helper::MockPTAPI;

use App::GHPT::Wrapper::OurMoose;

use Hash::Objectify qw( objectify );

extends 'WebService::PivotalTracker';

{
    my $Projects = [
        objectify( { name => 'SRE',       id => 303 } ),
        objectify( { name => 'Team Data', id => 789 } ),
        objectify(
            {
                name        => 'Team Scotty',
                id          => 123,
                memberships => [
                    objectify(
                        {
                            person =>
                                objectify( { name => 'Scotty Member One' } )
                        }
                    ),
                    objectify(
                        {
                            person =>
                                objectify( { name => 'Scotty Member Two' } )
                        }
                    ),
                ],
            }
        ),
        objectify( { name => 'Team Uhura', id => 456 } ),
    ];

    sub projects ($self) {
        return $Projects;
    }

    sub team_data ($self) {
        return $Projects->[1];
    }

    sub team_scotty ($self) {
        return $Projects->[2];
    }

    sub team_uhura ($self) {
        return $Projects->[3];
    }

    sub team_scotty_member_one_person ($self) {
        return $self->team_scotty->memberships->[0]->person;
    }

    sub team_scotty_member_two_person ($self) {
        return $self->team_scotty->memberships->[1]->person;
    }
}

1;
