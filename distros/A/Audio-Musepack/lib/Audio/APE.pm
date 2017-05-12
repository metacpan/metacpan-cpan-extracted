package Audio::APE;

use strict;
use base qw(Audio::APETags);

our $VERSION = '1.0';

1;

__END__

=head1 NAME

Audio::APE - An object-oriented interface to Monkey's Audio file information and APE tag fields.

=head1 SYNOPSIS

    use Audio::APE;
    my $mac = Audio::APE->new("song.ape");

    foreach (keys %$mac) {
        print "$_: $mac->{$_}\n";
    }

    my $macTags = $mac->tags();

    foreach (keys %$macTags) {
        print "$_: $macTags->{$_}\n";
    }

=head1 DESCRIPTION

This module returns a hash containing basic information about a Monkey's Audio
file, as well as tag information contained in the Monkey's Audio file's APE tags.

=head1 CONSTRUCTORS

=over 4

=item * new( $filename )

Opens a Monkey's Audio file, ensuring that it exists and is actually an
Monkey's Audio stream, then loads the information and comment fields.

=back

=head1 INSTANCE METHODS

=over 4

=item * info( [$key] )

Returns a hashref containing information about the Monkey's Audio file from
the file's information header.

The optional parameter, key, allows you to retrieve a single value from
the info hash.  Returns C<undef> if the key is not found.

=item * tags( [$key] )

Returns a hashref containing tag keys and values of the Monkey's Audio file from
the file's APE tags.

The optional parameter, key, allows you to retrieve a single value from
the tag hash.  Returns C<undef> if the key is not found.

=back

=head1 NOTE

This module is now a wrapper around Audio::Scan.

=head1 SEE ALSO

L<http://www.monkeysaudio.com/>, Audio::Scan

=head1 AUTHOR

Dan Sully, E<lt>daniel@cpan.orgE<gt>

Kevin Deane-Freeman, E<lt>kevindf at shaw dot caE<gt>, based on other work by
Erik Reckase, E<lt>cerebusjam at hotmail dot comE<gt>, and
Dan Sully, E<lt>daniel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004, Kevin Deane-Freeman.
Copyright (c) 2005-2007, Dan Sully & Slim Devices.
Copyright (c) 2007-2010, Dan Sully.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
