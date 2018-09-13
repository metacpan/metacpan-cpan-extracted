package Data::Grid;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Scalar::Util ();

# module-loading paraphernalia
use String::RewritePrefix ();
use Class::Load           ();

use Moo;
use Data::Grid::Types qw(FHlike Source Fields HeaderFlags Offsets
                         Checker to_Checker);
use Type::Params qw(compile multisig Invocant);
use Types::Standard qw(slurpy Optional ClassName Any Bool
                       Str ScalarRef HashRef Enum Dict);

#use overload '@{}' => 'tables';

# store it this way then flip it around

my %MAP = (
    CSV   => [qw(text/plain text/csv)],
    Excel => [qw(application/x-ole-storage application/vnd.ms-excel
                 application/msword application/excel)],
    'Excel::XLSX' => [
        qw(application/x-zip application/x-zip-compressed application/zip
           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)],
);
%MAP = map { my $k = $_; my @x = @{$MAP{$k}}; map { $_ => $k } @x } keys %MAP;

=head1 NAME

Data::Grid - Incremental read access to grid-based data

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Data::Grid;

    # Have the parser guess the kind of file, using defaults.

    my $grid = Data::Grid->parse('arbitrary.xls');

    # or

    my $grid = Data::Grid->parse(
        source  => 'arbitrary.csv', # or xls, or xlsx, or filehandle...
        header  => 1,               # first line is a header everywhere
        columns => [qw(a b c)],     # override the header
        options => \%options,       # driver-specific options
    );

    # Each object contains one or more tables.

    for my $table ($grid->tables) {

        # Each table has one or more rows.

        while (my $row = $table->next) {

            # The columns can be dereferenced as an array,

            my @cols = @$row; # or just $row->columns

            # or, if header is present or fields were named in the
            # constructor, as a hash.

            my %cols = %$row;

            # Now we can do stuff.
        }
    }

=head1 DESCRIPTION

=over 4

=item Problem 1

You have a mountain of data files from two decades of using MS Office
(and other) products, and you want to collate their contents into
someplace sane.

=item Problem 2

The files are in numerous different formats, and a consistent
interface would really cut down on the effort of extracting them.

=item Problem 3

You've looked at L<Data::Table> and L<Spreadsheet::Read>, but deemed
their table-at-a-time strategy to be inappropriate for your purposes.

=back

The goal of L<Data::Grid> is to provide an extensible, uniform,
object-oriented interface to all kinds of grid-shaped data. A key
behaviour I'm after is to perform an incremental read over a
potentially large data source, so as not to unnecessarily gobble up
system resources.

=head1 DEVELOPER RELEASE

Odds are I will probably decide to change the interface at some point
before locking in, and I don't want to guarantee consistency yet. If I
do, and you use this, your code will probably break.

Suffice to say this module is B<ALPHA QUALITY> at best.

=head1 METHODS

=head2 parse $FILE | %PARAMS

The principal way to instantiate a L<Data::Grid> object is through the
C<parse> factory method. You can either pass it a filelike thing or a
set of parameters. I<Filelike thing> is either a filename, C<GLOB>
reference, C<SCALAR> reference or C<ARRAY> reference of scalars. If
the filelike thing is passed alone, its type will be detected using
L<File::MMagic>. To tune this behaviour, use the parameters:

=over 4

=item source

This is equivalent to C<$file>.

=item header

If you know that the document you're opening has a header, set this
flag to a true value and it will be consumed for use in
L<Data::Grid::Row/as_hash>. If there is more than one table in the
document, set this value to an C<ARRAY> reference of flags. This
object will be treated as a ring, meaning that, for instance, if the
header designation is C<[1, 0]>, the third table in the document will
be treated as having a header, fourth will not, the fifth will, and so
on.

=cut

my $zero_aref = sub { [0] };

has header => (
    is      => 'ro',
    isa     => HeaderFlags,
    coerce  => 1,
    default => $zero_aref,
);

=item columns

Specify a list of columns in lieu of a header, or otherwise override
any header, which is thrown away. A single C<ARRAY> reference of
strings will be duplicated to each table in the document. An array of
arrays will be applied to each table with the same wrapping behaviour
as C<header>.

=cut

has columns => (
    is      => 'ro',
    isa     => Fields,
    coerce  => 1,
    default => sub { [] },
);

=item start

Set a row offset, i.e, a number of rows to skip I<before> any header.
Since this is an offset, it starts with zero. Same rule applies for
multiple tables in the document.

=cut

has start => (
    is      => 'ro',
    isa     => Offsets,
    coerce  => 1,
    default => $zero_aref,
);

=item skip

Set a number of rows to skip I<after> the header, defaulting, of
course, to zero. Same multi-table rule applies.

=cut

has skip => (
    is      => 'ro',
    isa     => Offsets,
    coerce  => 1,
    default => $zero_aref,
);

=item options

This C<HASH> reference will be passed as-is to the driver.

=item driver

Specify a driver and bypass type detection. Modules under the
L<Data::Grid> namespace can be handed in as L<CSV|Data::Grid::CSV>,
L<Excel|Data::Grid::Excel>, and L<Excel::XLSX|Data::Grid::Excel::XLSX>.
Prefix with a C<+> for other package namespaces.

=item checker

Specify either L<MMagic|File::MMagic> or L<MimeInfo|File::MimeInfo> to
detect the type of file. L<MMagic|File::MMagic> is the default. In
lieu of the class name

=back

=cut


my %CHECK = (
    'File::MMagic' => [
        # filename-based
        sub { $_[0]->checktype_filename($_[1]) },
        # fh-based
        sub { $_[0]->checktype_filehandle($_[1]) },
    ],
    'File::MimeInfo::Magic' => [
        # filename-based
        sub { $_[0]->mimetype($_[1]) },
        # fh-based
        sub { $_[0]->mimetype($_[1]) },
    ],
);

sub parse {
    state $check = Type::Params::multisig(
        [Invocant, Source],
        [Invocant, slurpy Dict[source  => Source,
                               header  => Optional[HeaderFlags],
                               columns => Optional[Fields],
                               options => Optional[HashRef],
                               driver  => Optional[ClassName],
                               checker => Optional[Checker],
                               slurpy Any]]
    );

    my ($class, $p) = $check->(@_);
    my %p = ref $p eq 'HASH' ? %$p : (source => $p);

    # croak unless source is defined
    Carp::croak("I can't do any work unless you specify a data source.")
          unless defined $p{source};

    my $ref = ref $p{source};


    #require Data::Dumper;
    #warn Data::Dumper::Dumper(\%p);

    if ($ref) {
        # if it is a reference, it depends on the kind
        if ($ref eq 'SCALAR') {
            # scalar ref as a literal
            require IO::Scalar;
            $p{fh} = IO::Scalar->new($p{source});
        }
        elsif ($ref eq 'ARRAY') {
            # array ref as a list of lines
            require IO::ScalarArray;
            $p{fh} = IO::ScalarArray->new($p{source});
        }
        elsif ($ref eq 'GLOB' or Scalar::Util::blessed($p{source})
                   && $p{source}->isa('IO::Seekable')) {
            # ioref as just a straight fh
            $p{fh} = $p{source};
        }
        else {
            # dunno
            Carp::croak("Don't know what to do with $ref as a source.");
        }
    }
    else {
        # if it is a string, it is assumed to be a filename
        require IO::File;
        $p{fh} = IO::File->new($p{source}) or Carp::croak($!);
    }

    # binary this because it gets messed up otherwise
    binmode $p{fh};

    # if you didn't specify a driver we pick one for you
    unless ($p{driver}) {
        my $checker ||= to_Checker('MMagic');
        my ($ckey) = grep { $checker->isa($_) } sort keys %CHECK;

        my $type;
        unless ($ref) {
            # check the type by filename
            $type = $CHECK{$ckey}[0]->($checker, $p{source}) // '';
            # do not continue unless we get a match
            undef $type unless $MAP{$type};
        }

        # now check the filehandle
        unless ($type) {
            $type = $CHECK{$ckey}[1]->($checker, $p{fh});
            # reset the filehandle
            seek $p{fh}, 0, 0;
        }

        Carp::croak("There is no driver mapped to the detected type $type")
              unless $MAP{$type};

        $p{driver} = $MAP{$type};
    }

    # now load the driver
    (my $driver) = String::RewritePrefix->rewrite
        ({ '' => 'Data::Grid::', '+' => ''}, delete $p{driver});
    Class::Load::load_class($driver);

    $driver->new(%p);
}

=head2 tables

Generate and return the array of tables.

=cut

sub tables {
    Carp::croak('This is a stub method that must be overridden.');
}

=head2 fh

Retrieve the document's file handle embedded in the grid object.

=cut

has fh => (
    is       => 'ro',
    isa      => FHlike,
    required => 1,
    init_arg => 'fh',
);

=head1 EXTENSION INTERFACE

Take a look at L<Data::Grid::CSV> or L<Data::Grid::Excel> for clues on
how to extend this package.

=head2 table_class

Returns the class to use for instantiating tables. Defaults to
L<Data::Grid::Table>, which is an abstract class. Override this
accessor and its neighbours with your own values for extensions.

=cut

has table_class => (
    is      => 'ro',
    isa     => ClassName,
    default => 'Data::Grid::Table',
);

=head2 row_class

Returns the class to use for instantiating rows. Defaults to
L<Data::Grid::Row>.

=cut

has row_class => (
    is      => 'ro',
    isa     => ClassName,
    default => 'Data::Grid::Row',
);

=head2 cell_class

Returns the class to use for instantiating cells. Defaults to
L<Data::Grid::Cell>, again an abstract class.

=cut

has cell_class => (
    is      => 'ro',
    isa     => ClassName,
    default => 'Data::Grid::Cell',
);

=head2 table_params $POSITION

Generate a set of parameters suitable for passing in as a constructor,
either as a hash or C<HASH> reference, depending on calling context.

=cut

sub table_params {
    my ($self, $pos) = @_;

    my %p = (parent => $self, position => $pos);

    # okay this goes through all similar arrayref members and picks
    # the element that corresponds to the table modulo the length of
    # the list of tables, which frankly is pretty clever
    for my $k (qw(header columns start skip)) {
        my @x = @{$self->$k || []};
        $p{$k} = $x[$pos % @x] if @x;
    }

    wantarray ? %p : \%p;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report bugs to L<GitHub
issues|https://github.com/doriantaylor/p5-data-grid/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Grid

Alternatively, you can read the documentation on
L<MetaCPAN|https://metacpan.org/release/Data::Grid>.

=head1 SEE ALSO

=over 4

=item

L<Text::CSV>

=item

L<Spreadsheet::ParseExcel>

=item

L<Spreadsheet::ParseXLSX>

=item

L<Data::Table>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2018 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Data::Grid
