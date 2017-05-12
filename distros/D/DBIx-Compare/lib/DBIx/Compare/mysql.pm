package DBIx::Compare::mysql;

use 5.006;
use strict;
use warnings;
require DBIx::Compare;

our $VERSION = '1.1';

{ package mysql_comparison;
	
	our @ISA = qw( db_comparison );

	sub compare_string_field {
		my ($self,$table,$field) = @_;
		my $statement = "
			SELECT AVG(LENGTH($field)), STDDEV(LENGTH($field)), MIN(LENGTH($field)), MAX(LENGTH($field))
			FROM $table
		";
		return $self->do_compare_field($statement);
	}
	sub compare_numeric_field {
		my ($self,$table,$field) = @_;
		my $statement = "
			SELECT AVG($field), STDDEV($field), MIN($field), MAX($field)
			FROM $table
		";
		return $self->do_compare_field($statement);
	}
	sub compare_datetime_field {
		my ($self,$table,$field) = @_;
		my $statement = "
			SELECT AVG($field), STDDEV($field), MIN($field), MAX($field)
			FROM $table
		";
		return $self->do_compare_field($statement);
	}
}

1;

__END__


=head1 NAME

DBIx::Compare::mysql - Compare MySQL database content

=head1 SYNOPSIS

	use DBIx::Compare::mysql;

	my $oDB_Comparison = db_comparison->new($dbh1,$dbh2);
	$oDB_Comparison->compare;
	$oDB_Comparison->deep_compare;
	

=head1 DESCRIPTION

DBIx::Compare::mysql takes two MySQL database handles and performs comparisons of their table content. See L<DBIx::Compare|DBIx::Compare> for more information.

=head1 SEE ALSO

L<DBIx::Compare|DBIx::Compare>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
