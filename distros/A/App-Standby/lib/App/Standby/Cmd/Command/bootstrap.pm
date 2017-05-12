package App::Standby::Cmd::Command::bootstrap;
$App::Standby::Cmd::Command::bootstrap::VERSION = '0.04';
BEGIN {
  $App::Standby::Cmd::Command::bootstrap::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Command to intialize the database

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
use Data::Pwgen;

# extends ...
extends 'App::Standby::Cmd::Command';
# has ...
has 'name' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'n',
    'documentation' => 'Name of the new group',
);

has 'key' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 0,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'k',
    'documentation' => 'Key of the new group',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    my $sql = 'SELECT COUNT(*) FROM groups';
    my $sth = $self->dbh()->prepexec($sql);
    my $cnt = $sth->fetchrow_array();

    if($cnt > 0) {
        print "You can not use this command once there is already at least one group\n";
        return;
    }

    my $key = $self->key() || Data::Pwgen::pwgen(16);

    $sql = 'INSERT INTO groups (name,key) VALUES (?,?)';
    $sth = $self->dbh()->prepexec($sql,$self->name(),$key);
    if($sth) {
        print "Created new group '".$self->name()."' with key '".$key."'\n";
    }

    return 1;
}

sub abstract {
    return 'Initialize the database';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Cmd::Command::bootstrap - Command to intialize the database

=head1 DESCRIPTION

This class implements a command initialize the database.

=head1 METHODS

=head2 execute

Run the bootstrap command

=head2 abstract

Workaround

=head1 NAME

App::Standby::Cmd::Command::bootstrap - Command to intialize the database

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
