package Data::TableData::Object::aos;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-10'; # DATE
our $DIST = 'Data-TableData-Object'; # DIST
our $VERSION = '0.112'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent 'Data::TableData::Object::Base';

sub new {
    my ($class, $data) = @_;
    bless {
        data         => $data,
        cols_by_name => {elem=>0},
        cols_by_idx  => ["elem"],
    }, $class;
}

sub row_count {
    my $self = shift;
    scalar @{ $self->{data} };
}

sub rows {
    my $self = shift;
    $self->{data};
}

sub rows_as_aoaos {
    my $self = shift;
    [map {[$_]} @{ $self->{data} }];
}

sub rows_as_aohos {
    my $self = shift;
    [map {{elem=>$_}} @{ $self->{data} }];
}

sub uniq_col_names {
    my $self = shift;
    my %mem;
    for (@{$self->{data}}) {
        return () unless defined;
        return () if $mem{$_}++;
    }
    ('elem');
}

sub const_col_names {
    my $self = shift;

    my $i = -1;
    my $val;
    my $val_undef;
    for (@{$self->{data}}) {
        $i++;
        if ($i == 0) {
            $val = $_;
            $val_undef = 1 unless defined $val;
        } else {
            if ($val_undef) {
                return () if defined;
            } else {
                return () unless defined;
                return () unless $val eq $_;
            }
        }
    }
    ('elem');
}

sub del_col {
    die "Cannot delete column in aos table";
}

sub rename_col {
    die "Cannot rename column in aos table";
}

sub switch_cols {
    die "Cannot switch column in aos table";
}

sub add_col {
    die "Cannot add_col in aos table";
}

sub set_col_val {
    my ($self, $name_or_idx, $value_sub) = @_;

    my $col_name = $self->col_name($name_or_idx);
    my $col_idx  = $self->col_idx($name_or_idx);

    die "Column '$name_or_idx' does not exist" unless defined $col_name;

    my $hash = $self->{data};
    for my $i (0..$#{ $self->{data} }) {
        $self->{data}[$i] = $value_sub->(
            table    => $self,
            row_idx  => $i,
            col_name => $col_name,
            col_idx  => $col_idx,
            value    => $self->{data}[$i],
        );
    }
}

1;
# ABSTRACT: Manipulate array of scalars via table object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableData::Object::aos - Manipulate array of scalars via table object

=head1 VERSION

This document describes version 0.112 of Data::TableData::Object::aos (from Perl distribution Data-TableData-Object), released on 2021-04-10.

=head1 SYNOPSIS

To create:

 use Data::TableData::Object qw(table);

 my $td = table([1,2,3]);

or:

 use Data::TableData::Object::aos;

 my $td = Data::TableData::Object::aos->new([1,2,3]);

=head1 DESCRIPTION

This class lets you manipulate an array of scalars as a table object. The table
will have a single column named C<elem>.

=for Pod::Coverage .*

=head1 METHODS

See L<Data::TableData::Object::Base>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-TableData-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-TableData-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
