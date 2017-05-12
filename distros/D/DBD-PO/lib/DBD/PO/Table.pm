package DBD::PO::Table;

use strict;
use warnings;

our $VERSION = '2.00';

use DBD::File;
use parent qw(-norequire DBD::File::Table);

use Carp qw(croak);
use English qw(-no_match_vars $INPUT_RECORD_SEPARATOR);

sub fetch_row {
    my ($self, $data) = @_;

    my $file_handle = $self->{fh};
    my $file_name   = $self->{file};
    my $fields;
    if (exists $self->{cached_row}) {
        $fields = delete $self->{cached_row};
    }
    else {
        my $po = $self->{po_po};
        local $INPUT_RECORD_SEPARATOR = $po->{eol};
        $fields = $po->read_entry($file_name, $file_handle);
    }

    return $self->{row} = @{$fields} ? $fields : ();
}

sub push_row {
    my ($self, $data, $fields) = @_;

    my $po          = $self->{po_po};
    my $file_handle = $self->{fh};
    my $file_name   = $self->{file};

    #  Remove undef from the right end of the fields, so that at least
    #  in these cases undef is returned from FetchRow
    while (@{$fields} && ! defined $fields->[-1]) {
        pop @{$fields};
    }
    $po->write_entry($file_name, $file_handle, $fields);

    return 1;
}

sub push_names {
    my ($self, $data, $fields) = @_;

    return 1;
}

1;

__END__

=head1 NAME

DBD::PO::Table - table class for DBD::File

$Id: Table.pm 289 2008-11-09 13:10:28Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/Table.pm $

=head1 VERSION

2.00

=head1 SYNOPSIS

do not use

=head1 DESCRIPTION

table class for DBD::File

=head1 SUBROUTINES/METHODS

=head2 method fetch_row

=head2 method push_row

=head2 method push_names

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

parent

Carp

English

L<DBD::File>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut