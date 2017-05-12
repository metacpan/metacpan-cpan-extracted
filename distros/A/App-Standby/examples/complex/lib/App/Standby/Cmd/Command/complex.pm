package App::Standby::Cmd::Command::complex;

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
use Try::Tiny;

use App::Standby::Group;

# extends ...
extends 'App::Standby::Cmd::Command';
# has ...
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    # we need all groups which have an complex service defined
    my $sql = 'SELECT g.id,g.name,gs.name FROM groups AS g LEFT JOIN group_services AS gs ON g.id = gs.group_id WHERE gs.class = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute('Complex');

    while(my ($id,$name,$gsname) = $sth->fetchrow_array()) {
        my $grp = try {
            my $Group = App::Standby::Group::->new({
                'group_id' => $id,
                'name' => $name,
                'dbh' => $self->dbh(),
                'logger' => $self->logger(),
            });
            # get the current user list and just update the Complex services ...
            if($Group->services()->{$gsname}->update($Group->get_contacts())) {
                $self->logger()->log( message => 'Updated Service '.$gsname.' for group '.$name, level => 'debug', );
            } else {
                $self->logger()->log( message => 'Failed to update service '.$gsname.' for group '.$name, level => 'warning', );
            }
        } catch {
            $self->logger()->log( message => 'Failed to instantiate the new class due to an error: '.$_, level => 'warning', );
        };
    }
    return 1;
}

sub abstract {
    return "Update the current janitor in the Complex-Endpoint";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

App::Standby::Cmd::Command::complex - Example for a command to be run as a cronjob

=head1 DESCRIPTION

This class implements an example for a cronjob that is run once a day to keep some
complex endpoint up-to-date.

=cut
