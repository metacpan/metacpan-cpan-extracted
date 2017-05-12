package Catalyst::Plugin::ConfigLoader::Remote;

use warnings;
use strict;

use File::Fetch;
use Scalar::Util qw(blessed);
use File::Temp qw/tempdir/;

use MRO::Compat;

use base qw/Catalyst::Plugin::ConfigLoader/;

=head1 NAME

Catalyst::Plugin::ConfigLoader::Remote - Load (remote) URIs into config

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module provides support for fetching remote configuration files over HTTP,
FTP or other remote methods.

It will fetch any blessed URI object in the C<files> config entry for the
package via L<File::Fetch>

 package MyApp;

 use Catalyst qw/ConfigLoader::Remote/;

 use URI;

 __PACKAGE__->config(
    'Plugin::ConfigLoader::Remote' => {
        files => [
            URI->new("https://secure.example.com/config/basic.yml"),
            URI->new("https://secure.example.com/config/database.conf"),
        ]
    }
 );

=head1 METHODS

=head2 find_files

find_files will download each file to a temporary directory that is purged on
program exit.  It is then passed to  L<Catalyst::Plugin::ConfigLoader> for 
actual configuration loading and processing.

=cut

sub find_files {
    my $c = shift;

    my $tempdir = tempdir( CLEANUP => 1 );

    # Load up the other files that are coming in.
    my @files = $c->next::method();

    my $config = $c->config->{'Plugin::ConfigLoader::Remote'};

    return @files unless ref $config eq 'HASH' and
                         ref $config->{files} eq 'ARRAY';

    my @incoming_files =
        @{ $config->{files} };

    # replace everything in @files that is a URI object with a downloaded copy
    foreach my $arg ( @incoming_files ) {
        if ( blessed $arg and $arg->isa('URI') ) {
            # Fetch a blessed URI
            my $ff = File::Fetch->new( uri => $arg->as_string );
            if ( $ff ) {
                my $file = $ff->fetch( to => $tempdir );
                if ( $file and -f $file ) {
                    push @files, $file;
                }
            }
        } else {
            push @files, $arg;
        }
    }

    return @files;
}

=head1 AUTHOR

J. Shirley, C<< <jshirley at gmail.com> >>

Eden Cardim

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-configloader-remote at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-ConfigLoader-Remote>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::ConfigLoader::Remote

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-ConfigLoader-Remote>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-ConfigLoader-Remote>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-ConfigLoader-Remote>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-ConfigLoader-Remote>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 J. Shirley and PictureTrail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::ConfigLoader::Remote
