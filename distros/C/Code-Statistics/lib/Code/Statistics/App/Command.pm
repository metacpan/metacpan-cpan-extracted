use strict;
use warnings;

package Code::Statistics::App::Command;
{
  $Code::Statistics::App::Command::VERSION = '1.112980';
}

# ABSTRACT: base class for commands

use App::Cmd::Setup -command;


sub cstat {
    return shift->app->cstat( @_ );
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::App::Command - base class for commands

=head1 VERSION

version 1.112980

=head2 cstat
    Dispatches to the Code::Statistics object creation routine.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

