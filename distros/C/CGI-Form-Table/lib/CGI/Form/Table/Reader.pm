
package CGI::Form::Table::Reader;

use strict;
use warnings;

our $VERSION = '0.161';

=head1 NAME

CGI::Form::Table::Reader - read a table of form inputs

=head1 VERSION 

version 0.161

 $Id: /my/cs/projects/formtable/trunk/lib/CGI/Form/Table/Reader.pm 27836 2006-11-11T04:19:45.102963Z rjbs  $

=head1 SYNOPSIS

 use CGI;
 use CGI::Form::Table::Reader;

 my $query = CGI->new;
 my $form = CGI::Form::Table::Reader->new(query => $query, prefix => 'user');

 my $users = $form->rows;

=head1 DESCRIPTION


=head1 METHODS

=head2 C<< CGI::Form::Table::Reader->new(query => $query, prefix => $prefix) >>

=cut

sub new {
	my ($class, %args) = @_;
	return unless $args{prefix} and $args{query};
	bless \%args => $class;
}

=head2 C<< CGI::Form::Table::Reader->rows >>

Returns an arrayref of hashrefs from the CGI inputs with the given prefix.

=cut

sub rows {
	my ($self) = @_;

	my @positions = $self->_read_positions;
	return unless @positions;

	my @rows;
	push @rows, $self->_read_row($_) for @positions;

	\@rows;
}

sub _read_row {
	my ($self, $position) = @_;

	my $row_prefix = $self->{prefix} . '_' . $position . '_';

	my %row;
	for (grep { /^$row_prefix/ } $self->{query}->param) {
		(my $name = $_) =~ s/^$row_prefix//;
		$row{$name} = $self->{query}->param($_);
	}

	return \%row;
}

# _read_positions
#
# returns a list of the positions found in the params

sub _read_positions {
	my ($self) = @_;

	my %temp;
	my @positions =
		sort { $a <=> $b }
		grep { ! $temp{0+$_} ++ }
		map  { /^$self->{prefix}_(\d+)_/; }
		$self->{query}->param;
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
