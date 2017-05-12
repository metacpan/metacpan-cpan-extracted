package DBD::PO::Statement;

use strict;
use warnings;

our $VERSION = '2.09';

use DBD::File;
use parent qw(-norequire DBD::File::Statement);

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR);
use DBD::PO::Text::PO qw($EOL_DEFAULT $SEPARATOR_DEFAULT @COL_NAMES);

sub open_table { ## no critic (ExcessComplexity)
    my ($self, $data, $table, $create_mode, $lock_mode) = @_;

    my $dbh = $data->{Database};
    my $tables = $dbh->{po_tables};
    if (! exists $tables->{$table}) {
        $tables->{$table} = {};
    }
    my $meta = $tables->{$table} || {};
    my $po = $meta->{po} || $dbh->{po_po};
    if (! $po) {
        @{ $dbh->FETCH('f_valid_attrs') }{qw(po_eol po_separator po_charset)}
            = (1) x 3; ## no critic (MagicNumbers)
        my $class = $meta->{class}
                    || $dbh->{po_class}
                    || 'DBD::PO::Text::PO';
        my %opts = (
            eol       => exists $meta->{eol}
                         ? $meta->{eol}
                         : exists $dbh->{po_eol}
                           ? $dbh->{po_eol}
                           : $EOL_DEFAULT,
            separator => exists $meta->{separator}
                         ? $meta->{separator}
                         : exists $dbh->{po_separator}
                           ? $dbh->{po_separator}
                           : $SEPARATOR_DEFAULT,
            charset   => exists $meta->{charset}
                         ? $meta->{charset}
                         : $dbh->{po_charset}
                           ? $dbh->{po_charset}
                           : undef,
        );
        $po = $meta->{po}
            = $class->new(\%opts);
    }
    my $file = $meta->{file}
               || $table;
    my $tbl = $self->SUPER::open_table($data, $file, $create_mode, $lock_mode);
    if ($tbl) {
        {
            my $po_charset = exists $meta->{charset}
                             ? $meta->{charset}
                             : $dbh->{po_charset}
                               ? $dbh->{po_charset}
                               : undef;
            if ($po_charset && $tbl->{fh}) {
                $tbl->{fh}->binmode("encoding($po_charset)")
                    or croak "binmode $OS_ERROR";
            }
        }
        $tbl->{po_po} = $po;
        my $types = $meta->{types};
        if ($types) {
           # The 'types' array contains DBI types, but we need types
           # suitable for DBD::Text::PO.
           my $t = [];
           for (@{$types}) {
               if ($_) {
                   $_ = $DBD::PO::PO_TYPES[$_ + 6] ## no critic (MagicNumbers)
                        || $DBD::PO::PV;
               }
               else {
                   $_ = $DBD::PO::PV;
               }
               push @{$t}, $_;
           }
           $tbl->{types} = $t;
        }
        if (
           ! $create_mode
           && ! $self->{ignore_missing_table}
           && $self->command() ne 'DROP'
        ) {
            $tbl->{col_names} = \@COL_NAMES;
        }
    }

    return $tbl;
}

sub command {
    return shift->{command};
}

1;

__END__

=head1 NAME

DBD::PO::Statement - statement class for DBD::File

$Id: Statement.pm 420 2009-12-22 07:36:43Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/Statement.pm $

=head1 VERSION

2.09

=head1 SYNOPSIS

do not use

=head1 DESCRIPTION

statement class for DBD::File

=head1 SUBROUTINES/METHODS

=head2 method open_table

=head2 method command

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

parent

Carp

English

L<DBD::File>

L<DBD::PO::Text::PO>

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
