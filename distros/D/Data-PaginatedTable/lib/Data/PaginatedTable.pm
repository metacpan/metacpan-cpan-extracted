use 5.18.2;
use Modern::Perl;
use Moops;

class Data::PaginatedTable 1.0.0 {
    use Types::XSD::Lite qw( PositiveInteger );
    use Text::Table;
    use XML::Simple;
    use XML::Simple::Sugar;
    use POSIX qw(ceil);
    use overload '""'         => 'as_string';
    use overload '@{}'        => 'pages';
    use constant VERTICAL     => 'vertical';
    use constant HORIZONTAL   => 'horizontal';
    use constant HTML         => 'html';
    use constant PREFORMATTED => 'preformatted';
    use constant RAW          => 'raw';

    has rows    => ( is => 'rw', isa => PositiveInteger, default  => 4 );
    has columns => ( is => 'rw', isa => PositiveInteger, default  => 3 );
    has data    => ( is => 'rw', isa => ArrayRef,        required => true );
    has fill_direction => (
        is      => 'rw',
        isa     => Enum [ VERTICAL, HORIZONTAL ],
        default => HORIZONTAL
    );
    has string_mode =>
      ( is => 'rw', isa => Enum [ HTML, PREFORMATTED, RAW ], default => RAW );
    has current => ( is => 'rw', isa => PositiveInteger, default => 1 );

    method page ( $page? ) {
        $self->current($page) if defined $page;

        my $data = $self->data;
        my $min  = $self->rows * $self->columns * ( $self->current - 1 );
        my $max  = $self->rows * $self->columns * $self->current - 1;

        my $i       = 0;
        my $k       = 0;
        my $next_ik = $self->fill_direction eq VERTICAL
          ? sub {
            $i++;
            if ( $i == $self->rows ) { $i = 0; $k++; }
          }
          : sub {
            $k++;
            if ( $k == $self->columns ) { $k = 0; $i++; }
          };

        my @table;
        foreach my $row ( @{$data}[ $min .. $max ] ) {
            $table[$i][$k] = $row;
            $next_ik->();
        }

        \@table;
    }

    method pages {
        [ map { $self->page($_) } 1 .. $self->page_count ];
    }

    method as_string {
        my $string_mode = 'as_' . $self->string_mode;
        $self->$string_mode;
    }

    method as_raw {
        my $string;
        foreach my $row ( @{ $self->page } ) {
            $string .= "$row->[$_]" for 0 .. @$row - 1;
        }
        $string;
    }

    method as_preformatted {
        my $text_table = Text::Table->new;
        $text_table->load( @{ $self->page } );
        "$text_table";
    }

    method as_html {
        my $xs = XML::Simple::Sugar->new(
            { xml_xs => XML::Simple->new( XMLDecl => '' ) } );
        my $table = $xs->table;

        my $i = 0;
        foreach my $row ( @{ $self->page } ) {
            $table->tr( [$i] )->td( [ $_, "$row->[$_]" ] ) for 0 .. @$row - 1;
            $i++;
        }

        $xs->xml_write;
    }

    method page_count {
        ceil( @{ $self->data } / $self->columns / $self->rows );
    }

    method next {
        return if $self->current >= $self->page_count;
        $self->current( $self->current + 1 );
        $self;
    }

    method previous {
        return if $self->current <= 1;
        $self->current( $self->current - 1 );
        $self;
    }

    method last {
        $self->current( $self->page_count );
        $self;
    }

    method first {
        $self->current(1);
        $self;
    }
}

1;

# ABSTRACT: Paginate lists as two-dimensional arrays and stringify
# PODNAME: Data::PaginatedTable

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::PaginatedTable - Paginate lists as two-dimensional arrays and stringify

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    use Modern::Perl;
    use Data::PaginatedTable;
    use Data::Printer;
    
    my @series = 'aaa' .. 'zzz';
    
    my $pt = Data::PaginatedTable->new(
        {
            data           => \@series,
            string_mode    => 'preformatted',
            fill_direction => 'vertical',
        }
    );
    
    do { say $pt } while ( $pt->next );
    
    # aaa aae aai
    # aab aaf aaj
    # aac aag aak
    # aad aah aal
    # 
    # ...
    # 
    # zzg zzk zzo
    # zzh zzl zzp
    # zzi zzm zzq
    # zzj zzn zzr
    # 
    # zzs zzw
    # zzt zzx
    # zzu zzy
    # zzv zzz


    say Data::Printer::p( $pt->page( 32 ) );

    # \ [
    #     [0] [
    #         [0] "aoi",
    #         [1] "aom",
    #         [2] "aoq"
    #     ],
    #     [1] [
    #         [0] "aoj",
    #         [1] "aon",
    #         [2] "aor"
    #     ],
    #     [2] [
    #         [0] "aok",
    #         [1] "aoo",
    #         [2] "aos"
    #     ],
    #     [3] [
    #         [0] "aol",
    #         [1] "aop",
    #         [2] "aot"
    #     ]
    # ]

=head1 DESCRIPTION

This is yet another class to generate tables and paginate data.  Each page represents a two-dimensional array of given dimensions, and can be filled horizontally or vertically.  In string context, an instance of C<Data::PaginatedTable> will invoke one of the C<string_mode> methods to render the C<current> page.

=head1 ATTRIBUTES

=head2 data, data ( ArrayRef REQUIRED )

Gets or sets the data to be transformed by the instance of C<Data::PaginatedTable>.

=head2 rows, rows ( PositiveInteger default => 4 )

Gets or sets the number of rows per C<page>.

=head2 columns, columns ( PositiveInteger default => 3 )

Gets or sets the number of columns per C<row>.

=head2 fill_direction, fill_direction ( Enum[ 'vertical', 'horizontal' ] default => 'horizontal' )

Gets or sets the order in which C<data> elements will be used to fill the two-dimensional array of each C<page>.

    use Modern::Perl;
    use Data::PaginatedTable;
    
    my @series = 1 .. 9;
    
    my $pt = Data::PaginatedTable->new(
        {
            data           => \@series,
            rows           => 3,
            columns        => 3,
            fill_direction => 'vertical', # default horizontal
            string_mode    => 'preformatted'
        }
    );
    say $pt;
    
    # 1 4 7
    # 2 5 8
    # 3 6 9
    
    $pt->fill_direction( 'horizontal' );
    say $pt;

    # 1 2 3
    # 4 5 6
    # 7 8 9

=head2 string_mode, string_mode ( Enum[ 'html', 'preformatted', 'raw' ] default => 'raw' );

Gets or sets the method to use when a Data::PaginatedTable object is used in string context.  See L</STRING MODES>.

=head2 current, current ( PositiveInteger default => 1 );

Gets or sets the current C<page>.

=head1 METHODS

=head2 page_count

Returns the total number of pages based on the number of C<rows> and C<columns>.

=head2 page, page( PositiveInteger )

Returns the two-dimensional array with the given number of C<rows> and C<columns> representing the C<current> page, or optionally returns a specific page when passed an integer argument.

=head2 pages

Returns an array reference containing each C<page> of C<data>.

=head2 first

Sets the C<current> page to the first C<page> and returns the instance.

=head2 next

Sets the C<current> page to the next C<page> and returns the instance or undef if there are no next pages.

=head2 previous

Sets the C<current> page to the previous C<page> and returns the instance or undef if there are no previous pages.

=head2 last

Sets the C<current> page to the last C<page> and returns the instance.

=head1 STRING MODES

=head2 as_string

This is a wrapper around the as_* C<string_mode> methods.  This method is called implicitly when the instance is in string context.

=head2 as_html

The html C<string_mode> stringifies the C<current> C<page> as a plain html table.  All C<page> elements are placed in string context (see L<overload>).

    use Modern::Perl;
    use Data::PaginatedTable;
    
    my @series = 1 .. 12;
    
    my $pt = Data::PaginatedTable->new(
        {
            data        => \@series,
            string_mode => 'html'
        }
    );
    
    say $pt;
    
    # <table>
    #   <tr>
    #     <td>1</td>
    #     <td>2</td>
    #     <td>3</td>
    #   </tr>
    #   <tr>
    #     <td>4</td>
    #     <td>5</td>
    #     <td>6</td>
    #   </tr>
    #   <tr>
    #     <td>7</td>
    #     <td>8</td>
    #     <td>9</td>
    #   </tr>
    #   <tr>
    #     <td>10</td>
    #     <td>11</td>
    #     <td>12</td>
    #   </tr>
    # </table>

=head2 as_preformatted

The preformatted C<string_mode> uses L<Text::Table> to format the C<current> C<page>. All C<page> elements are placed in string context (see L<overload>).

    use Modern::Perl;
    use Data::PaginatedTable;
    
    my @series = 1 .. 12;
    
    my $pt = Data::PaginatedTable->new(
        {
            data        => \@series,
            string_mode => 'preformatted'
        }
    );
    
    say $pt;
    
    #  1  2  3
    #  4  5  6
    #  7  8  9
    # 10 11 12

=head2 as_raw

The C<as_raw> method iterates over the C<page> elements and invokes each in string context (see L<overload>), without seperating C<rows> with newlines.  This method is likely not how you want to render your data unless your C<data> elements are string L<overload>ed objects with their own rendering logic.

=head1 VERSIONING

This module adopts semantic versioning (L<http://www.semver.org>).

=head1 REPOSITORY

L<https://github.com/Camspi/Data-PaginatedTable>

=head2 SEE ALSO

=over 4

*
L<Text::Table>

*
L<Data::Table>

*
L<Data::Tabular>

*
L<Data::Tabulate>

*
L<Data::Tabulator>

*
L<Data::Paginated>

=back

=head1 AUTHOR

Chris Tijerina

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Tijerina.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
