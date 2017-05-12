package Dancer::Plugin::LibraryThing;

use 5.006;
use strict;
use warnings;

use Dancer::Plugin;
use WWW::LibraryThing::Covers;

=head1 NAME

Dancer::Plugin::LibraryThing - Plugin for LibraryThing APIs.

=head1 VERSION

Version 0.0003

=cut

our $VERSION = '0.0003';

my %lt_object;

=head1 SYNOPSIS

    use Dancer::Plugin::LibraryThing;

    get '/images/covers/*.jpg' => sub {
        my ($isbn) = splat;

        unless (-f "public/images/covers/$isbn.jpg") {
	    @ret = librarything_cover($isbn);

	    if (@ret < 3) {
	        debug("Error retrieving cover for ISBN $isbn");
	        status 'not_found';
	        forward 404;
	    }
        }

        return send_file "images/covers/$isbn.jpg";
    }

=head1 DESCRIPTION

Retrieves book covers from LibraryThing based on ISBN-10 numbers.

Please checkout the terms of use first.

=head1 CONFIGURATION

    plugins:
      LibraryThing:
        api_key: d231aa37c9b4f5d304a60a3d0ad1dad4
        directory: public/images/covers
        size: large

Size defaults to medium.

=head1 FUNCTIONS

=head2 librarything_cover

Requests a cover from LibraryThing and stores it in the
directory set in the configuration.

First (mandatory) parameter is the ISBN-10 number. Optional
parameters can be given as hash (directory and size), defaults
are given in the configuration.

=cut

register librarything_cover => sub {
    my ($isbn, %arg) = @_;

    my $directory = $arg{directory} || plugin_setting->{directory};
    my $size      = $arg{size}      || plugin_setting->{size};

    my $key = $size . "\t" . $directory;

    unless ($lt_object{$key}) {
        $lt_object{$key} = WWW::LibraryThing::Covers->new(
            api_key   => plugin_setting->{api_key},
            directory => $directory,
            size      => $size
        );
    }

    $lt_object{$key}->get($isbn);
};

register_plugin;

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-librarything at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-LibraryThing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::LibraryThing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-LibraryThing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-LibraryThing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-LibraryThing>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-LibraryThing/>

=back


=head1 ACKNOWLEDGEMENTS

None so far.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::LibraryThing
