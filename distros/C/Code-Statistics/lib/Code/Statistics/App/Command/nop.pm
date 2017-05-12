use strict;
use warnings;

package Code::Statistics::App::Command::nop;
{
  $Code::Statistics::App::Command::nop::VERSION = '1.112980';
}

# ABSTRACT: does nothing

use Code::Statistics::App -command;

sub abstract { return 'do nothing' }

sub execute {
    my ( $self, $opt, $arg ) = @_;

    return $self->cstat;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::App::Command::nop - does nothing

=head1 VERSION

version 1.112980

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

