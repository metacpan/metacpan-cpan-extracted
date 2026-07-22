package Data::Record::Serialize::Encode::table;

# ABSTRACT: encode records as a formatted table and output it

use strict;
use warnings;

our $VERSION = '0.01';

use Types::Standard        qw( ArrayRef Bool Str );
use Types::Common::Numeric qw( PositiveInt );

use Term::Table;
use Moo::Role;

use namespace::clean;

with 'Data::Record::Serialize::Role::Sink::Stream';

use constant BOOLS => qw( allow_overflow auto_columns collapse mark_tail sanitize show_header );

has _rows => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
);

has [ 'max_width', 'pad' ] => (
    is        => 'ro',
    isa       => PositiveInt,
    predicate => 1,
);

has [BOOLS] => (
    is        => 'ro',
    isa       => Bool,
    predicate => 1,
);

has no_collapse => (
    is        => 'ro',
    isa       => ArrayRef [Str],
    default   => sub { [] },
    predicate => 1,
);

has _closed => (
    is       => 'rwp',
    init_arg => undef,
    default  => 1,
);

sub send {    ## no critic( BuiltinHomonyms )
    my $self = shift;
    my $rec  = shift;
    push @{ $self->_rows }, [ @{$rec}{ @{ $self->output_fields } } ];
    $self->_set__closed( 0 );
}

# we've overridden send(), so don't need encode(), but the Encode role
# does, so here's one:
sub encode { }

sub print { }    ## no critic( BuiltinHomonyms )
sub say   { }    ## no critic( BuiltinHomonyms )

sub finalize {
    my $self = shift;
    return if $self->_closed;

    my %options;
    for my $option ( BOOLS, qw( max_width pad no_collapse ) ) {
        my $predicate = "has_$option";
        $options{$option} = $self->$option if $self->$predicate();
    }

    my $table = Term::Table->new(
        %options,
        header => $self->output_fields,
        rows   => $self->_rows,
    );

    my $fh = $self->fh;
    $fh->print( "$_\n" ) for $table->render;
    $self->_set__closed( 1 );
}

with 'Data::Record::Serialize::Role::Encode';
with 'Data::Record::Serialize::Role::Sink';

1;

#
# This file is part of Data-Record-Serialize-Encode-table
#
# This software is Copyright (c) 2026 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::table - encode records as a formatted table and output it

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Data::Record::Serialize;
    my $s = Data::Record::Serialize->new( encode => 'table', ... );
    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::table> encodes records into table form
using L<Term::Table>.

It performs both the L<Data::Record::Serialize::Role::Encode> and
L<Data::Record::Serialize::Role::Sink> roles.

Do not construct this directly; use L<Data::Record::Serialize/new>.
The following named parameters may be passed to it:

=over

=item output

This parameter is required. One of the following:

=over

=item *

The name of an output file (which will be created).  If it is the
string C<->, output will be written to the standard output stream.
Must not be the empty string.

=item *

a reference to a scalar to which the records will be written.

=item *

a GLOB (i.e. C<\*STDOUT>), or a reference to an object which derives
from L<IO::Handle> (e.g. L<IO::File>, L<FileHandle>, etc.).  These
will I<not> be closed upon destruction of the serializer or when the
L</close> method is called.

=back

=item create_output_dir => I<Boolean>

If I<true>, the directory which will contain the output file is created.
Defaults to I<false>.

=back

The following parameters are passed as-is to L<Term::Table/new>.

=over

=item allow_overflow

=item auto_columns

=item collapse

=item mark_tail

=item max_width

=item no_collapse

=item pad

=item sanitize

=item show_header

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-table@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-table>

=head2 Source

Source is available at

  https://codeberg.com/djerius/data-record-serialize-encode-table

and may be cloned from

  https://codeberg.com/djerius/data-record-serialize-encode-table.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize>

=item *

L<Term::Table>

=back

=head1 AUTHOR

Diab Jerius <djerius@cfa.harvard.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
