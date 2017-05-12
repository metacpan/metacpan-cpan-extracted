package Biblio::Thesaurus::SQLite;

use 5.008006;
use strict;
use warnings;

require Exporter;
use DBIx::Simple;
use Data::Dumper;
use Biblio::Thesaurus;
use locale;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [
				qw(ISOthe2TheSql
               TheSql2ISOthe
				   getTermAsXHTML
				   getTermAsISOthe
				   getTermAsPerl
				   setTerm
				   deleteTerm
				   changeTerm
				  ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.10';

our ($rel,@terms,$term);

##
# This method converts a ISO Thesaurus file in a SQLite database
# @param ficheiro de texto iso thesaurus
# @param ficheiro com base de dados sqlite
sub ISOthe2TheSql {
	my $file = shift or die;
	my $dbfile = shift or die;

	# parse the thesaurus file
	my $the = thesaurusLoad($file);
	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	# clear the database! TODO: check if the database exists and try
	# to append the new data
	$db->query('DROP TABLE rel');
	$db->query('CREATE TABLE rel (term, rel, def)');
	$db->query('DROP TABLE meta');
	$db->query('CREATE TABLE meta (term, val)');
	$db->query('DROP TABLE lang');
	$db->query('CREATE TABLE lang (ori, lang, dest)');

	# parse metadata (we need this cause I dunno if Biblio::Thesaurus
	# 	handles this the right way O:-))
	open(F, "<$file") or die;
	$db->begin_work;
	my $lang_dest = '';
	while(<F>) {
		chomp;
		# this is metadata (starting with %)
		if($_ =~ /^\%([^\s]+)\s+(.*)/) {
			my @vals = split(/\s+/, $2);
			for (@vals) {
				$db->query(
					'INSERT INTO meta VALUES (?, ?)',
					$1, $_
				);
			}
		}
		# this is language data
		elsif($_ =~ /(.*)==(.*)/) {
			if($1 eq $the->baselang) {
				$lang_dest = $2;
			}
			elsif($lang_dest ne '') {
				$db->query(
					'INSERT INTO lang VALUES (?, ?, ?)',
					$1, $lang_dest, $2
				);
			}
		}
	}
	$db->commit;
	close(F);
	
	# parse all terms :D (the hard work is handed by Biblio::Thesaurus
	$db->begin_work;
	print $the->downtr (
	{ 
		-default => sub {
			# ignore language data...
			return '' if ($term.$rel) =~ /.*==.*/;
			for (@terms) {
				$db->query(
					'INSERT INTO rel VALUES (?, ?, ?)',
					$term, $rel, $_
				);
			}
		},
	}
	);
	$db->commit;

}

##
# This method convert a SQLite database to a ISO thesaurus text file
# @param The SQLite database
# @param The output ISO Thesaurus file
# @note This method is VERY VERY slow! I tried to know why, run a profiller
# 	and saw that most of the time we are consuming CPU in the ->hashes
# 	function of the DBIx::Simple module.... TODO: get this think faster :D
sub TheSql2ISOthe {
	my $dbfile = shift or die;
	my $file = shift or die;

	# ok so this is easy :D	
	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	# process meta-data
	open(F, ">$file");
	for my $row ($db->query('SELECT DISTINCT term FROM meta')->flat) {
		print F '%' . $row . ' ' . 
		      join(' ',
		        $db->query(
		      	  'SELECT val FROM META WHERE term = ?',
			  $row
		        )->flat
		      ), "\n";
	}

	# process translations
	$db->query('SELECT val FROM meta WHERE term = ?', 'baselang')->into(my $baselang);
	if(defined($baselang)) {
		$db->query('SELECT lang FROM lang LIMIT 1')->into(my $lang);
		print F $baselang, '==', $lang, "\n\n";
		for my $row ($db->query('SELECT * FROM lang')->hashes) {
			print F $row->{ori}, '==', $row->{dest}, "\n";
		}
	}

	# process the main data
	for my $row ($db->query('SELECT DISTINCT term FROM rel')->flat) {
		print F "\n\n$row\n";
		for my $row2 ($db->query('SELECT rel, def FROM rel WHERE term = ?', $row)->hashes) {
			print F $row2->{rel}, ' ', $row2->{def}, "\n";
		}
	}
	close(F);
}

##
# this method tries to output the result of a term as a xhtml table
# 	maybe to use with a cgi module
# @param the term to find data
# @param the sqlite database file
sub getTermAsXHTML {
	my $termo = shift or die;
	my $dbfile = shift or die;

	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	# try to see if we got any results avaiable
	my $count;
	$db->query(
		'SELECT COUNT(term) FROM rel WHERE term = ?'
		, $termo
	)->into($count);

	return ( '<h3>Termo <emph>' . $termo .
	         '</emph> nao encontrado</h3>' )
	         if $count == 0;

	# now starting the output of the table
	my $res = '<b1>' . $termo . '<b1><table><th><td>Relacao</td>' .
	          '<td>Definição</td></th>' . "\n";	
	# this is ugly....
	for my $row ($db->query('SELECT * FROM rel WHERE term = ?',
	                        $termo)->hashes) {
		$res .= '<tr><td>' . $row->{rel} .
		        '</td><td>' . $row->{def} .
			'</td></tr>' . "\n";
	}
	$res .= '</table>';

	return $res;
}

##
# Does the same thing as the previous method, but outputs the data in an
# 	ISO Thesaurus format
# @param .....
# @param guess w00t ?
sub getTermAsISOthe {
	my $termo = shift or die;
	my $dbfile = shift or die;

	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	my $count;
	$db->query(
		'SELECT COUNT(term) FROM rel WHERE term = ?'
		, $termo
	)->into($count);

	return '' if $count == 0;
	
	my $res = $termo . "\n";	
	for my $row ($db->query('SELECT * FROM rel WHERE term = ?',
	                        $termo)->hashes) {
		$res .= '- ' . $row->{rel} . ' -> ' . 
		        $row->{def} . "\n";
	}

	chomp($res);
	return $res;
}

##
# bla bla bla (i'm tired of this...)
# ....
# ....
sub getTermAsPerl {
	my $termo = shift or die;
	my $dbfile = shift or die;

	my %res; # our data!
	$res{$termo} = {};

	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	my $count;
	$db->query(
		'SELECT COUNT(term) FROM rel WHERE term = ?'
		, $termo
	)->into($count);

	return Dumper \%res if $count == 0;
	
	for my $row ($db->query('SELECT * FROM rel WHERE term = ?',
	                        $termo)->hashes) {
		my $mainhash = $res{$termo};
		my $termoarray = $mainhash->{$row->{rel}};
		$termoarray = [] unless defined $termoarray;
		push @$termoarray, $row->{def};
		$mainhash->{$row->{rel}} = $termoarray;
		$res{$termo} = $mainhash;
		
	}

	return Dumper \%res;
}

##
# Well, a new method! Add the new term to the sqlite database
# TODO: do some cheking before blinding insert the data?
# @param the term to insert
# @param the relation
# @param the definition
# @param the database file
sub setTerm {
	my $termo = shift or die;
	my $rel   = shift or die;
	my $def   = shift or die;
	my $dbfile = shift or die;

	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	$db->query('INSERT INTO rel VALUES (?, ?, ?)', $termo, $rel, $def);
}

##
# Delete the term
sub deleteTerm {
	my $termo = shift or die;
	my $rel = shift or die;
	my $def = shift or die;
	my $dbfile = shift or die;
	
	# connect to the database
	my $db  = DBIx::Simple->connect('dbi:SQLite:' . $dbfile)
		or die DBIx::Simple->error;

	$db->query('DELETE FROM rel WHERE term = ? AND rel = ? AND def = ?',
	           $termo, $rel, $def);
	$db->query('DELETE FROM rel WHERE term = ? AND rel = ? AND def = ?',
		   $def, $rel, $termo);
}

##
# Change the term in the database
# @param term to change
# @param old relation
# @param old definition
# @param new relation
# @param new definition
# @param the sqlite database file
sub changeTerm {
	my $termo = shift or die;
	my $oldrel = shift or die;
	my $olddef = shift or die;
	my $newrel = shift or die;
	my $newdef = shift or die;
	my $dbfile = shift or die;

	deleteTerm($termo, $oldrel, $olddef, $dbfile);
	# use our beautiful setTerm :)
	setTerm($termo, $newrel, $newdef, $dbfile);
}

1;

__END__

=head1 NAME

Biblio::Thesaurus::SQLite - Perl extension for managing ISO thesaurs into a SQLite database

=head1 SYNOPSIS

  use Biblio::Thesaurus::SQLite;
  ISOthe2TheSql('thesaurus', 'dbfile');
  TheSql2ISOthe('dbfile', 'output_file');
  getTermAsXHTML('term', 'dbfile');
  getTermAsISOthe('term', 'dbfile');
  getTermAsPerl('term', 'dbfile');
  setTerm('term', 'rel', 'definition', 'dbfile');
  deleteTerm('term', 'rel', 'definition');
  changeTerm('term', 'oldrel', 'olddef', 'newrel', 'newdef', 'dbfile');
  

=head1 DESCRIPTION

This module provides transparent methods to maintain Thesaurus files
in a backend SQLite database. The module uses a subset from ISO 2788
which defines some standard
features to be found on thesaurus files. The module also supports
multilingual thesaurus and some extensions to the ISOs standard.

=head1 METHODS

=over

=item ISOthe2TheSql THESAURUS, DBFILE

This method reads a ISO thesaurus ASCII file, and converts it to a 
SQLite database, stored on 'DBFILE'.

B<WARNING>: This method will erase any existing DB with DBFILE filename

=item TheSql2ISOthe DBFILE, THESAURUS

This method dumps the SQLIte thesaurus database DBFILE to a file THESAURUS,
and tries to
write a beautiful (or not) ISO thesaurus format.

=item getTermAs<FORMAT> TERM, DBFILE

Search in the database for info about this term and outputs it in the
following FORMAT:

=over

=item XHTML

Usefull (or not yet) to use in CGI modules. A simple table is used to write
the output of the query.

=item ISOThesaurus

Tries to output the info about the term in a ISO Thesaurus text format.

=item Perl

Constructs a Perl structure (see the "picture" below) and outputs the
text representation of it using the Data::Dumper format

   ovo => {
            NT => [_, _, _]
            SN => [_, _, _]
          }

=back

=item setTerm TERM, RELATION, DEFINITION, DBFILE

This method tries to blindly add information about the term into the 
SQLite database... Much work to be done here...

=item deleteTerm TERM, RELATION, DEFINITION, DBFILE

This simple deletes the TERM with the RELATION and DEFINITION from the database

=item changeTerm TERM, OLDRELATION, OLDDEFINITION, NEWRELATION, NEWDEFINITION, DBFILE

Given the relation and the definition to delete, and the new relation/definition
to insert into the database, this method tries to do just that! (but it's
really really primitive right now...)

=back

=head1 TODO

This module should be extended to work with *any* DBI class, not just
a SQLite one. Also, it should check and try to correct incongruences 
that ca happen loading, adding, changing or deleting a term.

Of course, it needs better docs too :P

=head1 BUGS

For now, please contact me using my email. In the future, I'll find 
something better (I'm still getting used to RT).

=head1 SEE ALSO

perl(1), Data::Dumper(3x), Biblio::Thesaurus(3x), DBIx::Simple(3x) 

=head1 AUTHOR

Ruben Fonseca, E<lt>fonseka@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by krani1

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
