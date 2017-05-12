package DJabberd::Plugin::PrivateStorage::InMemoryOnly;
use strict;
use base 'DJabberd::Plugin::PrivateStorage';
use warnings;

=head2 load_privatestorage($self, $user,  $element)

Load the element $element for $user from memory.

=cut


sub load_privatestorage {
    my ($self, $user,  $element) = @_;
    $self->{private_storage} ||= {};
    if (exists $self->{private_storage}{$user}) {
         if (exists $self->{private_storage}{$user}{$element})
         {   
             return $self->{private_storage}{$user}{$element}->as_xml();
         }
    }    
    return undef;
}

=head2 store_privatestorage($self, $user,  $element, $content)

Store $content for $element and $user in memory.

=cut

sub store_privatestorage {
    my ($self, $user, $element, $content) = @_;
    $self->{private_storage} ||= {};
    $self->{private_storage}{$user}{$element} = $content;
}
1;

__END__

=head1 NAME

DJabberd::Plugin::PrivateStorage::InMemoryOnly - implement private storage, stored in memory

=head1 SYNOPSIS

  <Plugin DJabberd::Plugin::PrivateStorage::InMemoryOnly />

=head1 DESCRIPTION

This plugin is derived from DJabberd::Plugin::PrivateStorage. It implement a memory backend,
using a simple hash.

=head1 WARNING

This is just for testing purpose, beware this is will not survive to a restart of the server.

=head1 COPYRIGHT

This module is Copyright (c) 2006 Michael Scherer
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Michael Scherer <misc@zarb.org>
