package Convert::CharMap;
$Convert::CharMap::VERSION = '0.10';

use 5.006;
use strict;
use warnings;

sub new {
    my $class = shift;
    return $class->load(@_);
}

sub load {
    my ( $class, $subclass, $file ) = @_;
    $class = ref($class) if ref($class);
    require "Convert/CharMap/$subclass.pm";

    my $self = "$class\::$subclass"->in($file);
    return bless( $self, $class );
}

sub save {
    my ( $self, $subclass, $file ) = @_;
    my $class = ref($self);
    require "Convert/CharMap/$subclass.pm";

    open my $fh, '>', $file or die "Can't open $file for writing: $!";
    print $fh "$class\::$subclass"->out($self);
    close $fh;
}

1;

__END__

=head1 NAME

Convert::CharMap - Conversion between Unicode Character Maps

=head1 VERSION

This document describes version 0.10 of Convert::CharMap, released
October 14, 2007.

=head1 SYNOPSIS

    use Convert::CharMap;
    my $map = Convert::CharMap->load(CharMapML => 'test.xml');
    $map->save(UCM => 'test.ucm');

=head1 DESCRIPTION

This module transforms between unicode character map formats, using
an in-memory representation of C<CharMapML> as the intermediate format.

Currently this module supports the C<CharMapML>, C<YAML> and C<UCM>
(write-only) backends.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
