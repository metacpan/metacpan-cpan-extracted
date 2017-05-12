package App::Maisha::Plugin::Base;

use strict;
use warnings;

our $VERSION = '0.21';

#----------------------------------------------------------------------------
# Public API

sub new {
    my $class = shift;
    my $self = {
        source      => 'maisha',
        useragent   => 'Maisha/0.18 (Perl)',
        clientname  => 'Maisha',
        clientver   => '0.18',
        clienturl   => 'http://maisha.grango.org'
    };

    bless $self, $class;
    return $self;
}

sub login { return 0 }

sub api_update                  {}
sub api_friends                 {}
sub api_user                    {}
sub api_user_timeline           {}
sub api_friends_timeline        {}
sub api_public_timeline         {}
sub api_followers               {}

sub api_replies                 {}
sub api_send_message            {}
sub api_direct_messages_to      {}
sub api_direct_messages_from    {}

sub api_follow                  {}
sub api_unfollow                {}

sub api_search                  {}

1;

__END__

=head1 NAME

App::Maisha::Plugin::Base - Maisha interface base module

=head1 DESCRIPTION

This module is used as a base for services. Where services do not provide
functionality, they will use the methods provided here.

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

The API methods are used to interface to with the Twitter API.

=over 4

=item * api_follow

=item * api_unfollow

=item * api_user

=item * api_user_timeline

=item * api_friends

=item * api_friends_timeline

=item * api_public_timeline

=item * api_followers

=item * api_update

=item * api_replies

=item * api_send_message

=item * api_direct_messages_to

=item * api_direct_messages_from

=item * api_search

=back

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
