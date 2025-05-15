package Data::Record::Serialize::Sink::stream;

# ABSTRACT: output encoded data to a stream.

use v5.10;
use Moo::Role;

our $VERSION = '2.02';

use namespace::clean;

with 'Data::Record::Serialize::Role::Sink::Stream';

## no critic( Subroutines::ProhibitBuiltinHomonyms )






sub print { shift->fh->print( @_ ) }
sub say   { shift->fh->say( @_ ) }

with 'Data::Record::Serialize::Role::Sink';

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Sink::stream - output encoded data to a stream.

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'stream', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> outputs encoded data to a
file handle.

It performs the L<Data::Record::Serialize::Role::Sink> role.

=head1 INTERNALS

=for Pod::Coverage print
 say

=head1 INTERFACE

The following attributes may be passed to
L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:

=over

=item C<output>

The name of an output file or a reference to a scalar to which the records will be written.
C<output> may be set to C<-> to indicate output to the standard output stream.

=item C<fh>

A file handle.

=back

If neither is specified, output is written to the standard output
stream.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
