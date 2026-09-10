package Data::Record::Serialize::Util;

# ABSTRACT: Useful things

use v5.12;
use strict;
use warnings;
our $VERSION = '2.05';

use parent 'Exporter::Tiny';

use Hash::Ordered;

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
        T_INTEGER => 'I',
        T_NUMBER  => 'N',
        T_STRING  => 'S',
        T_BOOLEAN => 'B',
    );
}

use enum @TYPE_CATEGORY_NAMES;
use constant \%TYPES;

## no critic(BuiltinFunctions::ProhibitComplexMappings)
our @TYPE_CATEGORIES = map {
    ;                    # add a ; to help 5.10
    no strict 'refs';    ## no critic(ProhibitNoStrict)
    $_->();
} @TYPE_CATEGORY_NAMES;

our %EXPORT_TAGS = (
    types      => [ keys %TYPES ],
    categories => \@TYPE_CATEGORY_NAMES,
    subs       => [qw( is_type index_types populate_set )],
);

our @EXPORT_OK = map { @{$_} } values %EXPORT_TAGS;

my @TypeRE;
$TypeRE[ $_->[0] ] = $_->[1]
  for [ +( ANY ) => qr/.*/ ],
  [ +( STRING )     => qr/^S/i ],
  [ +( FLOAT )      => qr/^N/i ],
  [ +( INTEGER )    => qr/^I/i ],
  [ +( BOOLEAN )    => qr/^B/i ],
  [ +( NUMBER )     => qr/^[NI]/i ],
  [ +( NOT_STRING ) => qr/^[^S]+/ ];

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



























































sub populate_set {
    my ( $values, $input ) = @_;

    return [] unless @{$input};

    my $output = Hash::Ordered->new;

    # if first element is a deletion, preload all possible values
    if ( substr( $input->[0], 0, 1 ) eq q{-} ) {
        $output->push( $_ ) for @{$values};
    }

    for my $elem ( @{$input} ) {
        if ( $elem eq q{-} ) {
            $output->clear;
            next;
        }

        if ( $elem eq q{+} ) {
            $output->clear;
            $output->push( $_ ) for @{$values};
            next;
        }

        my $op = substr( $elem, 0, 1 );
            $op eq q{-} ? $output->delete( substr( $elem, 1 ) )
          : $op eq q{+} ? $output->push( substr( $elem, 1 ) )
          :               $output->push( $elem );
    }
    return [ $output->keys ];
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

version 2.05

=head1 SUBROUTINES

=head2 populate_set

  \@list = populate_set( \@values, \@input );

Apply set-operations to a sequence of input values and
return the resulting array reference.

C<@input> must be drawn from the following set of values:

=over

=item *

elements of C<@values>

=item *

The C<+> or C<->  characters

=item *

Elements of C<@values> prefixed with C<+> or C<->.

=back

C<@input> is processed in order:

=over

=item *

If the first value is C<-> or begins with C<->, the output set is
initialized with the contents of C<@values>

=item *

A bare C<+> replaces the current contents with the contents of C<@values>, in order.

=item *

A bare C<-> clears the output set.

=item *

A bare value or a value prefixed with C<+> is appended.

=item *

A value prefixed with C<-> is removed from the output set.

=back

The result preserves insertion order and removes leading
duplicates.

=for Pod::Coverage index_types
is_type

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
