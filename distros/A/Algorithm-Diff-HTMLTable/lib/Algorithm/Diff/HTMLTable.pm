package Algorithm::Diff::HTMLTable;

# ABSTRACT: Show differences of a file as a HTML table

use strict;
use warnings;

use Algorithm::Diff;
use Carp;
use HTML::Entities;
use Time::Piece;

our $VERSION = '0.05';

sub new {
    my ($class, @param) = @_;

    return bless {@param}, $class;
}

sub diff {
    my $self = shift;

    croak "need two filenames" if @_ != 2;

    my %files;

    @files{qw/a b/} = @_;

    NAME:
    for my $name ( qw/a b/ ) {

        croak 'Need either filename or array reference' if ref $files{$name} && ref $files{$name} ne 'ARRAY';
        next NAME if ref $files{$name};

        croak $files{$name} . " is not a file" if !-f $files{$name};
        croak $files{$name} . " is not a readable file" if !-r $files{$name};
    }

    my $html = $self->_start_table( %files );
    $html   .= $self->_build_table( %files );
    $html   .= $self->_end_table( %files );

    return $html;
}

sub _start_table {
    my $self = shift;
    my %files = @_;

    my $old = $self->_file_info( $files{a}, 'old' );
    my $new = $self->_file_info( $files{b}, 'new' );
    
    my $id = defined $self->{id} ? qq~id="$self->{id}"~ : '';

    return qq~
        <table $id style="border: 1px solid;">
            <thead>
                <tr>
                    <th colspan="2"><span id="diff_old_info">$old</span></th>
                    <th colspan="2"><span id="diff_new_info">$new</span></th>
                </tr>
            </thead>
            <tbody>
    ~;
}

sub _build_table {
    my $self = shift;

    my %files = @_;

    my @seq_a = $self->_read_file( $files{a} );
    my @seq_b = $self->_read_file( $files{b} );

    my $diff = Algorithm::Diff->new( \@seq_a, \@seq_b );

    $diff->Base(1);

    my $rows = '';

    my ($line_nr_a, $line_nr_b) = (1, 1);
    while ( $diff->Next ) {
        if ( my $count = $diff->Same ) {
            for my $string ( $diff->Same ) {
                $rows .= $self->_add_tablerow(
                    line_nr_a => $line_nr_a++,
                    line_nr_b => $line_nr_b++,
                    line_a    => $string,
                    line_b    => $string,
                    color_a   => '',
                    color_b   => '',
                );
            }
        }
        elsif ( !$diff->Items(2) ) {
            my @items_1 = $diff->Items(1);
            my @items_2 = $diff->Items(2);
            
            my $max = @items_1 > @items_2 ? scalar( @items_1 ) : scalar( @items_2 );
            
            for my $index ( 1 .. $max ) {
                $rows .= $self->_add_tablerow(
                    line_nr_a => $line_nr_a++,
                    line_nr_b => '',
                    line_a    => $items_1[ $index - 1 ] // '',
                    line_b    => $items_2[ $index - 1 ] // '',
                    color_a   => 'red',
                    color_b   => '',
                );
            }
        }
        elsif ( !$diff->Items(1) ) {
            my @items_1 = $diff->Items(1);
            my @items_2 = $diff->Items(2);
            
            my $max = @items_1 > @items_2 ? scalar( @items_1 ) : scalar( @items_2 );
            
            for my $index ( 1 .. $max ) {
                $rows .= $self->_add_tablerow(
                    line_nr_a => '',
                    line_nr_b => $line_nr_b++,
                    line_a    => $items_1[ $index - 1 ] // '',
                    line_b    => $items_2[ $index - 1 ] // '',
                    color_a   => '',
                    color_b   => 'green',
                );
            }
        }
        else {
            my @items_1 = $diff->Items(1);
            my @items_2 = $diff->Items(2);
            
            my $max = @items_1 > @items_2 ? scalar( @items_1 ) : scalar( @items_2 );
            
            for my $index ( 1 .. $max ) {
                $rows .= $self->_add_tablerow(
                    line_nr_a => $line_nr_a++,
                    line_nr_b => $line_nr_b++,
                    line_a    => $items_1[ $index - 1 ] // '',
                    line_b    => $items_2[ $index - 1 ] // '',
                    color_a   => 'red',
                    color_b   => 'green',
                );
            }
        }
    }

    return $rows;
}

sub _add_tablerow {
    my $self = shift;

    my %params = @_;

    my ($line_nr_a, $line_a, $color_a) = @params{qw/line_nr_a line_a color_a/};
    my ($line_nr_b, $line_b, $color_b) = @params{qw/line_nr_b line_b color_b/};

    $color_a = $color_a ? qq~style="color: $color_a;"~ : '';
    $color_b = $color_b ? qq~style="color: $color_b;"~ : '';

    $line_a = encode_entities( $line_a // '' );
    $line_b = encode_entities( $line_b // '' );

    $line_a =~ s{ }{&nbsp;}g;
    $line_b =~ s{ }{&nbsp;}g;

    my $row = qq~
        <tr style="border: 1px solid">
            <td style="background-color: gray">$line_nr_a</td>
            <td $color_a>$line_a</td>
            <td style="background-color: gray">$line_nr_b</td>
            <td $color_b>$line_b</td>
        </tr>
    ~;
}

sub _end_table {
    my $self = shift;

    return qq~
            </tbody>
        </table>
    ~;
}

sub _file_info {
    my ($self, $file, $index) = @_;

    if ( $self->{"title_$index"} ) {
        return $self->{"title_$index"};
    }

    return '' if !-f $file;

    my $mtime = (stat $file)[9];
    my $date  = _format_date( $mtime );

    return "$file<br />$date";
}

sub _format_date {
    my ($time) = @_;

    my $date = localtime $time;
    return $date->cdate;
}

sub _read_file {
    my ($self, $file) = @_;
    
    return if !$file;

    if ( ref $file && ref $file eq 'ARRAY' ) {
        return @{ $file };
    }

    return if !-r $file;
    
    my @lines;
    open my $fh, '<', $file;
    if ( $self->{encoding} ) {
        binmode $fh, ':encoding(' . $self->{encoding} . ')';
    }
    
    local $/ = $self->{eol} // "\n";
    
    @lines = <$fh>;
    close $fh;
    
    return @lines;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Diff::HTMLTable - Show differences of a file as a HTML table

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my $builder = Algorithm::Diff::HTMLTable->new(
       id       => 'diff_table',
       encoding => 'utf8',
    );
    
    $diff = $builder->diff( $sourcefile, $targetfile );

=head1 DESCRIPTION

=head1 METHODS

=head2 new

    my $builder = Algorithm::Diff::HTMLTable->new(
       id       => 'diff_table',
       encoding => 'utf8',
    );

Available options:

=over 4

=item * id

=item * encoding

=item * eol

=back

=head2 diff

    $diff = $builder->diff( $sourcefile, $targetfile );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
