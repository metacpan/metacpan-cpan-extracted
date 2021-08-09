package Data::Record::Serialize::Encode::ddump;

# ABSTRACT:  encoded a record using Data::Dumper

use Moo::Role;

our $VERSION = '0.25';

use Data::Dumper;

use namespace::clean;

sub _needs_eol { 1 }






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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::ddump - encoded a record using Data::Dumper

=head1 VERSION

version 0.25

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
L<< Data::Record::Serialize::new|Data::Record::Serialize/new >>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

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
