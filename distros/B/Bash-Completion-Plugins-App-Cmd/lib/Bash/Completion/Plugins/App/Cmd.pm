## no critic (RequireUseStrict)
package Bash::Completion::Plugins::App::Cmd;
$Bash::Completion::Plugins::App::Cmd::VERSION = '0.02';
## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(prefix_match);
use Class::Load qw(load_class);

sub complete {
    my ( $self, $r ) = @_;

    my $class = $self->command_class;
    load_class($class);

    my @names = $class->command_names;

    $r->candidates(prefix_match($r->word, @names));
}

1;

=pod

=encoding UTF-8

=head1 NAME

Bash::Completion::Plugins::App::Cmd - A Bash::Completion plugin for writing App::Cmd plugins

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use parent 'Bash::Completion::Plugins::App::Cmd';

  # fill in everything you normally would for Bash::Completion,
  # except for complete

  sub command_class { 'My::Cmd' } # mandatory

=head1 DESCRIPTION

This is a L<Bash::Completion> plugin that assists in writing other
L<Bash::Completion> plugins for programs that use L<App::Cmd>.  Everything
is done similar to writing a normal L<Bash::Completion> plugin, except you
need to define the L</command_class> method rather than the
L<'Bash::Completion::Plugin'/complete> method.  L</command_class> is
the name of the class that you use C<use App::Cmd::Setup -app> from.

=head1 METHODS

=head2 complete

Populates the L<Bash::Completion> request with commands from the
given L<App::Cmd> class.

=head2 command_class

Returns the name of the class that this plugin will extract command
names from.  This method must be implemented by subclasses.

=head1 SEE ALSO

L<App::Cmd>, L<Bash::Completion>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A Bash::Completion plugin for writing App::Cmd plugins

