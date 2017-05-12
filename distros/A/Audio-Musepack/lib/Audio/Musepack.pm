package Audio::Musepack;

use strict;
use base qw(Audio::APETags);

our $VERSION = '1.0.1';

1;

__END__

=head1 NAME

Audio::Musepack - An object-oriented interface to Musepack file information and APE tag fields.

=head1 SYNOPSIS

    use Audio::Musepack;
    my $mpc = Audio::Musepack->new("song.mpc");

    my $mpcInfo = $mpc->info();

    foreach (keys %$mpcInfo) {
        print "$_: $mpcInfo->{$_}\n";
    }

    my $mpcTags = $mpc->tags();

    foreach (keys %$mpcTags) {
        print "$_: $mpcTags->{$_}\n";
    }

=head1 DESCRIPTION

This module returns a hash containing basic information about a Musepack
file, as well as tag information contained in the Musepack file's APE tags.

=head1 CONSTRUCTORS

=over 4

=item * new( $filename )

Opens a Musepack file, ensuring that it exists and is actually an
Musepack stream, then loads the information and comment fields.

=back

=head1 INSTANCE METHODS

=over 4

=item * info( [$key] )

Returns a hashref containing information about the Musepack file from
the file's information header.

The optional parameter, key, allows you to retrieve a single value from
the info hash.  Returns C<undef> if the key is not found.

=item * tags( [$key] )

Returns a hashref containing tag keys and values of the Musepack file from
the file's APE tags.

The optional parameter, key, allows you to retrieve a single value from
the tag hash.  Returns C<undef> if the key is not found.

=back

=head1 NOTE

This module is now a wrapper around Audio::Scan.

=head1 SEE ALSO

L<http://www.personal.uni-jena.de/~pfk/mpp/index2.html>, Audio::Scan

=head1 AUTHOR

Dan Sully, E<lt>daniel@cpan.orgE<gt>

Original Author: Erik Reckase, E<lt>cerebusjam at hotmail dot comE<gt>

=head1 COPYRIGHT

Copyright (c) 2003-2006, Erik Reckase.
Copyright (c) 2003-2007, Dan Sully & Slim Devices.
Copyright (c) 2003-2010, Dan Sully.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
