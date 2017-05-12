# -*- perl -*-
# vim:ts=4:sw=4:aw:ai:
#
#   DBI::Format::CSV - a package for displaying result tables
#
#   Copyright (c) 2001, 2002  Thomas A. Lowery
#
#   The DBI::Shell::CSV module is free software; you can redistribute
#   it and/or modify it under the same terms as Perl itself.
#

use strict;

package DBI::Format::CSV;

@DBI::Format::CSV::ISA = qw(DBI::Format::Base);

use Text::Abbrev;
use Text::Reform qw(form break_with);
use Text::CSV_XS;

use vars qw($VERSION);

$VERSION = sprintf( "%d.%02d", q$Revision: 11.91 $ =~ /(\d+)\.(\d+)/ );

sub header {
    my($self, $sth, $fh, $sep) = @_;
    $self->{'fh'} = $self->setup_fh($fh);
    $self->{'sth'} = $sth;
    $self->{'data'} = [];
    $self->{'formats'} = [];
    $self->{sep} = $sep if defined $sep;

	$self->{csv_obj} = Text::CSV_XS->new({
			binary			=> 1,
			sep_char		=> $self->{sep},
			always_quote	=> 1,
		});

    my $names = $sth->{'NAME'};
	my $csv = $self->{csv_obj};
	my $status = $csv->print($fh, $names);
	$fh->print( "\n" );
	return 1;
}

sub row {
    my($self, $orig_row) = @_;
    my $i = 0;
    my @row = @$orig_row; # don't mess with the original row

# default value for null, is blank.
	my $null = $self->{'null'} || '';
	my $columns = $self->{'columns'};

	my $breaks	= $self->{'breaks'};

    map {
		if (!defined($_)) {
			$_ = $null;
		} else {
			$_ =~ s/\n/\\n/g;
			$_ =~ s/\t/\\t/g;
			$_ =~ s/\r/\\r/g;
			$_ =~ s/[\000-\037\177-\237]/./g;
		}
		++$i;
    } @row;

    my $fh = $self->{'fh'};
	my $csv = $self->{csv_obj};
	my $status = $csv->print($fh, \@row);
	$fh->print( "\n" );

return ++$self->{rows};
}


sub trailer {
    my $self = shift;
#    $self->SUPER::trailer(@_);
} 

1;

=head1 NAME

DBI::Format::CSV - A package for displaying result tables

=head1 SYNOPSIS

=head1 DESCRIPTION

THIS PACKAGE IS STILL VERY EXPERIMENTAL. THINGS WILL CHANGE.

=head1 AUTHOR AND COPYRIGHT

Orignal Format module is Copyright (c) 1997, 1998

    Jochen Wiedmann
    Am Eisteich 9
    72555 Metzingen
    Germany

    Email: joe@ispsoft.de
    Phone: +49 7123 14887

SQLMinus is Copyright (c) 2001, 2002  Thomas A. Lowery

The DBI::Format::CSV module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<DBI::Shell(3)>, L<DBI(3)>, L<dbish(1)>
