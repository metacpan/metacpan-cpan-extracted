package Catalyst::Plugin::UserAgent;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw/ Class::Data::Inheritable /;
use LWP::UserAgent;

=head1 NAME

Catalyst::Plugin::UserAgent - Add a singleton LWP::UserAgent to the context

=head1 SYNOPSIS

  use Catalyst qw/ UserAgent /;

  __PACKAGE__->config(
      name => 'MyApp',
      lwp_user_agent => {
          agent      => 'MyApp/1.0',
          cookie_jar => {},
      },
  );

  sub foo : Local {
      my ($self, $c) = @_;

      my $content = $c->user_agent->get('http://example.com/')->content;

      $c->stash->{template} = 'show_example.com.tt2';
      $c->stash->{content} = $content;
  }

=head1 DESCRIPTION

Just creates a single L<LWP::UserAgent> available to the context. This object is created on-demand.

If you wish to pass any startup options to the constructor. Place those into the configuration under the key: "lwp_user_agent":

  __PACKAGE__->config(
      name => 'MyApp',
      lwp_user_agent => {
          agent      => 'MyApp/1.0',
          cookie_jar => {},
      },
  );

To get the user agent instance, use the C<user_agent> method of the Catalyst context:

  my $ua = $c->user_agent;

=cut

BEGIN {
    __PACKAGE__->mk_classdata(qw/ _user_agent /);
}

sub user_agent {
    my $c = shift;

    if (!defined $c->_user_agent) {
        my %options;
        if (defined $c->config->{lwp_user_agent}) {
            %options = %{ $c->config->{lwp_user_agent} };
        }

        $c->_user_agent(LWP::UserAgent->new(%options));
    }

    return $c->_user_agent;
}

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
