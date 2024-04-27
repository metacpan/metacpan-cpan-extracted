package Data::TableReader::Decoder::HTML;
$Data::TableReader::Decoder::HTML::VERSION = '0.015';
use Moo 2;
use Try::Tiny;
use Carp;
use IO::Handle;
use HTML::Parser;
extends 'Data::TableReader::Decoder';

# ABSTRACT: Access the tables of an HTML document


has _tables => ( is => 'lazy' );
sub parse {
	shift->_tables;
	return 1;
}

sub _build__tables {
	my $self= shift;
	# TODO: determine encoding from BOM, or from meta-equiv while parsing...
	binmode $self->file_handle;
	return $self->_parse_html_tables($self->file_handle);
}

sub _parse_html_tables {
	my ($self, $handle)= @_;
	# These variables track the state of the HTML parse.
	# cur_row is only defined when we are in a table row, and $cur_cell
	# is a scalar ref only defined when we are in a cell.
	my (@tables, $cur_table, $cur_row, $cur_cell);
	my $nested_tables= 0;
	my $ignore_all= 0;

	my $tag_start= sub {
		next if $ignore_all;
		my ($tagname, $attr)= (uc $_[0], $_[1]);
		if ($tagname eq 'TABLE') {
			if ($cur_table) {
				$self->_log->('warn','tables within tables are currently returned as a single cell value');
				$nested_tables++;
				$ignore_all++;
			}
			else {
				push @tables, ($cur_table= []);
			}
		}
		elsif ($tagname eq 'TR') {
			$cur_table or croak "found <tr> outside any <table>";
			$cur_row and $self->_log->('warn', 'found <tr> before end of previous row');
			push @$cur_table, ($cur_row= []);
		}
		elsif ($tagname eq 'TD' or $tagname eq 'TH') {
			$cur_table or croak "found <$tagname> outside any <table>";
			$cur_row or croak "found <$tagname> outside any <tr>";
			$cur_cell and $self->_log->('warn', "found <$tagname> before previous </$tagname>");
			push @$cur_row, '';
			$cur_cell= \$cur_row->[-1];
		}
	};
	my $content= sub {
		my ($text)= @_;
		if ($cur_cell) {
			$$cur_cell .= $text
		}
		elsif ($cur_row && $text =~ /\S/) {
			$self->_log->('warn', "Encountered text within a row but not in a cell: '$text'");
		}
	};
	my $tag_end= sub {
		my ($tagname)= (uc($_[0]));
		if ($ignore_all) {
			if ($tagname eq 'TABLE') {
				--$nested_tables;
				$ignore_all= 0 if $nested_tables <= 0;
			}
		}
		elsif ($tagname eq 'TD' or $tagname eq 'TH') {
			$cur_cell or $self->_log->('warn', "Found </$tagname> without matching <$tagname>");
			$cur_cell= undef;
		}
		elsif ($tagname eq 'TR') {
			$cur_row or $self->_log->('warn', "Found </tr> without matching <tr>");
			$cur_cell and $self->_log->('warn', "Found </tr> while still in <td>");
			$cur_row= undef;
			$cur_cell= undef;
		}
		elsif ($tagname eq 'TABLE') {
			$cur_table or $self->_log->('warn', "Found </table> without matching <table>");
			$cur_row and $self->_log->('warn', "Found </table> while still in <tr>");
			$cur_cell and $self->_log->('warn', "Found </table> while still in <td>");
			$cur_table= undef;
			$cur_row= undef;
			$cur_cell= undef;
		}
	};
   
	HTML::Parser->new(
		api_version => 3,
		start_h => [ $tag_start, 'tagname,attr' ],
		text_h  => [ $content, 'dtext' ],
		end_h   => [ $tag_end, 'tagname' ]
	)->parse_file($handle);
	
	$nested_tables == 0 or $self->_log->('warn', "Found EOF while expecting </table> tag");
	return \@tables;
}


sub iterator {
	my $self= shift;
	my ($tables, $table_i, $row_i)= ($self->_tables, 0, 0);
	my $table= $tables->[$table_i] || [];
	my $n_records= 0; $n_records += @$_ for @$tables;
	return Data::TableReader::Decoder::HTML::_Iter->new(
		sub {
			my $row= $table->[$row_i]
				or return undef;
			$row_i++;
			my @r= $_[0]? @{$row}[ @{$_[0]} ] : @$row; # optional slice argument
			return \@r;
		},
		{
			table   => \$table,
			table_i => \$table_i,
			row_i   => \$row_i,
			total_records => $n_records,
			table_record_ofs => 0,
			tables => $tables,
		}
	);
}

# If you need to subclass this iterator, don't.  Just implement your own.
# i.e. I'm not declaring this implementation stable, yet.
use Data::TableReader::Iterator;
BEGIN { @Data::TableReader::Decoder::HTML::_Iter::ISA= ('Data::TableReader::Iterator'); }

sub Data::TableReader::Decoder::HTML::_Iter::position {
	my $f= shift->_fields;
	'table '.${ $f->{table_i} }.' row '.${ $f->{row_i} };
}

sub Data::TableReader::Decoder::HTML::_Iter::row {
	${ shift->_fields->{row_i} };
}

sub Data::TableReader::Decoder::HTML::_Iter::progress {
	my $f= shift->_fields;
	return ! $f->{total_records}? 0
		: (( $f->{table_record_ofs} + ${$f->{row_i}} ) / $f->{total_records});
}

sub Data::TableReader::Decoder::HTML::_Iter::tell {
	my $f= shift->_fields;
	return [ ${$f->{table_i}}, ${$f->{row_i}} ];
}

sub Data::TableReader::Decoder::HTML::_Iter::seek {
	my ($self, $to)= @_;
	my $f= $self->_fields;
	${$f->{table_i}}= $to->[0];
	${$f->{row_i}}= $to->[1];
	${$f->{table}}= $f->{tables}[${$f->{table_i}}] || [];
	# re-calculate table_record_ofs
	my $t= 0; $t += @$_ for @{$f->{tables}}[0 .. $to->[1]-1];
	$f->{table_record_ofs}= $t;
	1;
}

sub Data::TableReader::Decoder::HTML::_Iter::next_dataset {
	my $f= $_[0]->_fields;
	return if ${$f->{table_i}} >= @{$f->{tables}};
	$_[0]->seek([ ${$f->{table_i}}+1, 0 ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder::HTML - Access the tables of an HTML document

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This decoder iterates the <TR> tags of the <TABLE>s of an HTML file.

=head1 METHODS

=head2 parse

Unfortunately, I'm not aware of any HTML parsers that properly parse a stream on demand rather
than using callbacks, so this module simply parses all the HTML up-front and iterates the perl
data structure.  This would be a problem if you have more HTML than can fit into memory
comfortably.  Buf if that's the case, you have bigger problems ;-)

This method is called automatically the first time you invoke the iterator.  You might choose
to call it earlier in order to report errors better.

=head2 iterator

  my $iterator= $decoder->iterator;

Return an L<iterator|Data::TableReader::Iterator> which returns each row of the table as an
arrayref.  The iterator supports C<< $i->next_dataset >> to move to the next table element.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 CONTRIBUTOR

=for stopwords Christian Walde

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
