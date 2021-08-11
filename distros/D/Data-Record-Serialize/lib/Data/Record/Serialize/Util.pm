package Data::Record::Serialize::Util;

# ABSTRACT: Useful things

use strict;
use warnings;
our $VERSION = '0.28';

use parent 'Exporter::Tiny';

my @TYPE_CATEGORY_NAMES;
my %TYPES;
BEGIN {
    @TYPE_CATEGORY_NAMES = qw(
      ANY
      INTEGER
      FLOAT
      NUMBER
      STRING
      NOT_STRING
      BOOLEAN
    );

    %TYPES = (
        T_INTEGER        => 'I',
        T_NUMBER         => 'N',
        T_STRING         => 'S',
        T_BOOLEAN        => 'B',
    );
}

use enum @TYPE_CATEGORY_NAMES;
use constant \%TYPES;

our @TYPE_CATEGORIES = map {;  # add a ; to help 5.10
    no strict 'refs'; ## no critic(ProhibitNoStrict)
    $_->();
} @TYPE_CATEGORY_NAMES;

our %EXPORT_TAGS = (
    types     => [ keys %TYPES ],
    categories => \@TYPE_CATEGORY_NAMES,
    subs       => [ qw( is_type index_types ) ],
);

our @EXPORT_OK = map { @{$_} } values %EXPORT_TAGS;

my @TypeRE;
$TypeRE[ $_->[0] ] = $_->[1]
  for
  [ ANY             ,=> qr/.*/     ],
  [ STRING          ,=> qr/^S/i    ],
  [ FLOAT           ,=> qr/^N/i    ],
  [ INTEGER         ,=> qr/^I/i    ],
  [ BOOLEAN         ,=> qr/^B/i    ],
  [ NUMBER          ,=> qr/^[NI]/i ],
  [ NOT_STRING      ,=> qr/^[^S]+/ ];

sub is_type {
    my ( $type, $type_enum ) = @_;
    $type =~ $TypeRE[$type_enum];
}

sub index_types {
    my ( $types ) = @_;

    my @fields = keys %$types;
    my @type_index;

    for my $category ( @TYPE_CATEGORIES ) {
        my $re = $TypeRE[$category];
        $type_index[$category] = [ grep { $types->{$_} =~ $re } @fields ];
    }

    return \@type_index;
}

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

Data::Record::Serialize::Util - Useful things

=head1 VERSION

version 0.28

=for Pod::Coverage index_types
is_type

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
