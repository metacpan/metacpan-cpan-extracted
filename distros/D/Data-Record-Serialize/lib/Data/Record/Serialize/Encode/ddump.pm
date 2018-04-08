package Data::Record::Serialize::Encode::ddump;

# ABSTRACT:  encoded a record using Data::Dumper

use Moo::Role;

our $VERSION = '0.16';

use Data::Dumper;

use namespace::clean;

has '+_need_types' => ( is => 'rwp', default => 0 );
has '+_needs_eol' => ( is => 'rwp', default => 1 );

#pod =for Pod::Coverage
#pod   encode
#pod
#pod =cut


sub encode {
    shift;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Trailingcomma = 1;
    Data::Dumper::Dumper( @_ ) . ",\n";
}

with 'Data::Record::Serialize::Role::Encode';


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

=head1 NAME

Data::Record::Serialize::Encode::ddump - encoded a record using Data::Dumper

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'ddump', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::ddump> encodes a record using
L<Data::Dumper>.  The resultant encoding may be decoded via

  @data = eval $buf;

It performs the L<Data::Record::Serialize::Role::Encode> role.

=for Pod::Coverage encode

=head1 INTERFACE

There are no additional attributes which may be passed to
L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

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
