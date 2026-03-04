package Alien::pugixml;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Alien::pugixml - Find or build pugixml C++ XML parser library

=head1 SYNOPSIS

    use Alien::pugixml;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        ...
        CONFIGURE_REQUIRES => {
            'Alien::pugixml' => 0,
        },
        CCFLAGS => Alien::pugixml->cflags,
        LIBS    => Alien::pugixml->libs,
    );

=head1 DESCRIPTION

This module provides the pugixml C++ XML parsing library. It will either
use the system library if available, or download and build it from source.

=head1 METHODS

All methods are inherited from L<Alien::Base>.

=head1 SEE ALSO

L<Alien::Base>, L<pugixml|https://pugixml.org/>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
