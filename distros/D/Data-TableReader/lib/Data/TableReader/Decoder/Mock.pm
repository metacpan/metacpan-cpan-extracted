package Data::TableReader::Decoder::Mock;
use Moo 2;
use Carp 'croak';
use IO::Handle;

extends 'Data::TableReader::Decoder';

# ABSTRACT: Mock decoder for test cases
our $VERSION = '0.011'; # VERSION


has data => ( is => 'rw' );

sub iterator {
	my $self= shift;
	my $data= $self->data;
	my $table= $data->[0];
	my $colmax= $table? scalar(@{$table->[0]})-1 : -1;
	my $rowmax= $table? $#$table : -1;
	my $row= -1;
	Data::TableReader::Decoder::Mock::_Iter->new(
		sub {
			my $slice= shift;
			return undef unless $row < $rowmax;
			++$row;
			my $datarow= $table->[$row];
			return [ @{$datarow}[@$slice] ] if $slice;
			return $datarow;
		},
		{
			data => $data,
			table_idx => 0,
			table_ref => \$table,
			row_ref => \$row,
			colmax_ref => \$colmax,
			rowmax_ref => \$rowmax,
			origin => [ $table, $row ],
		}
	);
}

# If you need to subclass this iterator, don't.  Just implement your own.
# i.e. I'm not declaring this implementation stable, yet.
use Data::TableReader::Iterator;
BEGIN { @Data::TableReader::Decoder::Mock::_Iter::ISA= ('Data::TableReader::Iterator'); }

sub Data::TableReader::Decoder::Mock::_Iter::position {
	my $f= shift->_fields;
	'row '.${ $f->{row_ref} };
}

sub Data::TableReader::Decoder::Mock::_Iter::progress {
	my $f= shift->_fields;
	return ${ $f->{row_ref} } / (${ $f->{rowmax_ref} } || 1);
}

sub Data::TableReader::Decoder::Mock::_Iter::tell {
	my $f= shift->_fields;
	return [ $f->{table_idx}, ${$f->{row_ref}} ];
}

sub Data::TableReader::Decoder::Mock::_Iter::seek {
	my ($self, $to)= @_;
	my $f= $self->_fields;
	$to ||= $f->{origin};
	my ($table_idx, $row)= @$to;
	my $table= $f->{data}[$table_idx];
	my $colmax= $table? scalar(@{$table->[0]})-1 : -1;
	my $rowmax= $table? $#$table : -1;
	$row= -1 unless defined $row;
	$f->{table_idx}= $table_idx;
	${$f->{table_ref}}= $table;
	${$f->{row_ref}}= $row;
	${$f->{colmax_ref}}= $colmax;
	${$f->{rowmax_ref}}= $rowmax;
	1;
}

sub Data::TableReader::Decoder::Mock::_Iter::next_dataset {
	my $self= shift;
	my $f= $self->_fields;
	return defined $f->{data}[ $f->{table_idx}+1 ]
		&& $self->seek([ $f->{table_idx}+1 ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder::Mock - Mock decoder for test cases

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    decoder => {
      CLASS => 'Mock',
      data => [
        [ # Data Set 0
           [ 1, 2, 3, 4, 5 ],
           ...
        ],
        [ # Data Set 1
           [ 1, 2, 3, 4, 5 ],
           ...
        ],
      ]
    }

This doesn't actually decode anything; it just returns verbatim rows of data from arrayrefs
that you supply.

=head1 ATTRIBUTES

See attributes from parent class: L<Data::TableReader::Decoder>.

=head2 data

The verbatim data which will be returned by the iterator.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
