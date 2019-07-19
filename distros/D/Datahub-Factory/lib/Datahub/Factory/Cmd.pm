package Datahub::Factory::Cmd;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

use parent qw(App::Cmd::Command);
use namespace::clean;

1;

__END__

=head1 NAME

Datahub::Factory::Cmd - A base class for extending the Datahub Factory command
line

=head1 SYNOPSIS

=head1 DESCRIPTION

Datahub::Factory::Cmd is a base class to extend the commands that can be
provided for the 'dhconveyor' command line tools.  New dhconveyor commands
should be defined in the Datahub::Factory::Command namespace and extend
Datahub::Factory::Cmd.

=head1 METHODS

=cut
