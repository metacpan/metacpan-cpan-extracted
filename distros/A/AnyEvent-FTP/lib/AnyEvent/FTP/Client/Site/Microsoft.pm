package AnyEvent::FTP::Client::Site::Microsoft;

use strict;
use warnings;
use 5.010;
use Moo;

extends 'AnyEvent::FTP::Client::Site::Base';

# ABSTRACT: Site specific commands for Microsoft FTP Service
our $VERSION = '0.16'; # VERSION


# TODO add a test for this
sub dirstyle { shift->client->push_command([SITE => 'DIRSTYLE'] ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Site::Microsoft - Site specific commands for Microsoft FTP Service

=head1 VERSION

version 0.16

=head1 SYNOPSIS

 use AnyEvent::FTP::Client;
 my $client = AnyEvent::FTP::Client->new;
 $client->connect('ftp://iisserver')->cb(sub {
   # toggle dir style
   $client->site->microsoft->dirstyle->cb(sub {

     $client->list->cb(sub {
       my $list = shift
       # $list is in first style.

       $client->site->microsoft->dirstyle->cb(sub {

         $client->list->cb(sub {
           my $list = shift;
           # list is in second style.
         });

       });
     });

   });
 });

=head1 DESCRIPTION

This class provides Microsoft's IIS SITE commands.

=head1 METHODS

=head2 dirstyle

 $client->site->microsoft->dirstyle

Toggle between directory listing output styles.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
