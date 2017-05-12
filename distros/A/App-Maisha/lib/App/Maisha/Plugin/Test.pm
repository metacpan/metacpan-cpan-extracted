package App::Maisha::Plugin::Test;

use strict;
use warnings;

our $VERSION = '0.21';

#----------------------------------------------------------------------------
# Library Modules

use base qw(App::Maisha::Plugin::Base);
use base qw(Class::Accessor::Fast);

#----------------------------------------------------------------------------
# Accessors

__PACKAGE__->mk_accessors($_) for qw(api users);

#----------------------------------------------------------------------------
# Public API

sub login {
    my ($self,$config) = @_;

    $self->api($self);
    return 1;
}

1;

__END__

=head1 NAME

App::Maisha::Plugin::Test - Maisha Test Plugin

=head1 SYNOPSIS

   maisha
   maisha> use Test
   use ok

=head1 DESCRIPTION

App::Maisha::Plugin::Test is used to test Maisha responds correctly when
plugins do not support a particular method call.

=head1 METHODS

=head2 Constructor

=over 4

=item * new

=back

=head2 Process Methods

=over 4

=item * login

Login to the service.

=back

=head2 API Methods

There are no API methods for this plugin.

=head1 SEE ALSO

For further information regarding the commands and configuration, please see
the 'maisha' script included with this distribution.

L<App::Maisha>

=head1 WEBSITES

=over 4

=item * Main Site: L<http://maisha.grango.org>

=item * Git Repo:  L<http://github.com/barbie/maisha/tree/master>

=item * RT Queue:  L<RT: http://rt.cpan.org/Public/Dist/Display.html?Name=App-Maisha>

=back

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
