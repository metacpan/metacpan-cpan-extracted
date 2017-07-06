package Apache::Session::Serialize::MongoDB;

use 5.010;
use strict;

our $VERSION = '0.16';

sub serialize {
    my $session = shift;
    &replaceSpecialCharacters( $session->{data} );
}

sub unserialize {
    my $session = shift;
    &restoreSpecialCharacters( $session->{data} );
}

sub replaceSpecialCharacters {
    my $data = shift;

    foreach my $key ( keys %$data ) {
        if ( $key =~ /(\.|\$)/ ) {
            my $oldkey = $key;
            $key =~ s:\$:\\u0024:g;
            $key =~ s:\.:\\u002e:g;
            $data->{$key} = $data->{$oldkey};
            delete $data->{$oldkey};
        }
        if ( ref( $data->{$key} ) eq 'HASH' ) {
            &replaceSpecialCharacters( $data->{$key} );
        }
    }
}

sub restoreSpecialCharacters {
    my $data = shift;

    foreach my $key ( keys %$data ) {
        if ( $key =~ /(\\u0024|\\u002e)/ ) {
            my $oldkey = $key;
            $key =~ s:\\u0024:\$:g;
            $key =~ s:\\u002e:.:g;
            $data->{$key} = $data->{$oldkey};
            delete $data->{$oldkey};
        }
        if ( ref( $data->{$key} ) eq 'HASH' ) {
            &restoreSpecialCharacters( $data->{$key} );
        }
    }
}

1;
__END__

=head1 NAME

Apache::Session::Serialize::MongoDB - Does nothing since MongoDB can store Perl
objects;

=head1 SYNOPSIS

 use Apache::Session::MongoDB;
 
 tie %hash, 'Apache::Session::MongoDB', $id, {};

=head1 DESCRIPTION

This module does nothing.

=head1 SEE ALSO

L<Apache::Session::MongoDB>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
