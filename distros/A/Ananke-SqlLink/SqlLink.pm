#!/usr/bin/perl -w
# Efetua conexao com o banco de dados
# By: Udlei Nattis <nattis@anankeit.com.br>
# Date: Tue Nov 27 13:56:34 BRST 2001

# {type},{db},{host},{username},{passwd}
# MySQL vars: host,username,passwd,db

package Ananke::SqlLink;

use vars qw($conn);
use DBI;
use strict;

our $VERSION = '1.1.1';

# Inicia conexao
sub new {
	my($self,$vars) = @_;
	my ($conn);

	# Verifica se é mysql
	if ($vars->{type} eq "mysql") {
		$conn =  DBI->connect("DBI:$vars->{type}:$vars->{db}:$vars->{host}",
					$vars->{username},$vars->{passwd})
						or die DBI::errstr;

		bless {
			conn => $conn,
			type => $vars->{type},
			error => undef,
			pre => undef,
		}, $self;
	}

}

# Recupera dados do db
sub return {
	my ($self,$q,$t) = @_;
	my (@array,@row,$row);

	# Verifica formato de dados que deve retorna
	$t = "scalar" if (!$t);

	# Prepara query
	eval { $self->{pre} = $self->{conn}->prepare($q); };

	# Verifica se conseguiu executar a query
	eval { $self->{pre}->execute } or die DBI::errstr;
	
	# Retorna em formato array
	if ($t eq "array") {
		while (@row = $self->{pre}->fetchrow_array) {
			push(@array,[ @row ]);
		}
	}

	# Retorna em formato hash
	elsif ($t eq "scalar") {
		eval { 
			while ($row = $self->{pre}->fetchrow_hashref) {
				push(@array,$row);
			}
		};
	}

	eval { $self->{pre}->finish };

	# Apaga variaveis indesejadas
	undef $q; undef $t;

	# Retorna os resultados do select
	return @array;
}

# executa funcao 'do'
sub do {
	my ($self,$q) = @_;

	$self->{conn}->do($q);
	
	if (DBI::errstr) {
		$self->{error} = DBI::errstr;
		return 0;
	}
	
	undef $q;

	return 1;
}

# Adiciona quote
sub quote {
	my ($self,$buf) = @_;
	my($r);
	
	$r = $self->{conn}->quote($buf);
	$r = "''" if ($r eq "NULL");
	return $r;
}

# Desconecta do banco de dados
sub disconnect {
	my ($self) = @_;

	$self->{conn}->disconnect;

	# Apaga variaveis
	delete $self->{conn};
	delete $self->{type};
	$self = undef;
}

# Recupera numero de linhas
sub rows {
	my ($self) = @_;

	return $self->{pre}->rows;
}

# Recupera ultima linha inserida
sub insertid {
   my ($self) = @_;

	# mysql
	if ($self->{type} eq "mysql") { $self->{conn}->{mysql_insertid}; }
}

# retorn erro
sub error {
	my ($self) = @_;
	return $self->{error};
}

1;

=head1 NAME

Ananke::SqlLink - Front-end module to MySQL

=head1 DESCRIPTION

MySQL easy access

=head1 SYNOPSIS

	#!/usr/bin/perl]

	use strict;
	use Ananke::SqlLink;
	my(@r,$c,$q,$i);

	# Open DB
	$c = new Ananke::SqlLink({
		'type'      => 'mysql',
		'db'        => 'test',
		'host'      => 'localhost',
		'username'  => 'root',
		'passwd'    => '',
	});

	# Query Insert
	$q = "INSERT INTO test (id,name) VALUES (null,'user')";
	$c->do($q); undef $q;

	# Query Select
	$q = "SELECT id,name FROM test";

	# Result 1
	print "- Scalar\n";
	@r = $c->return($q,'scalar');
	foreach $i (@r) {
		print "ID: ".$i->{id}." - Name: ".$i->{name}."\n";
	}

	# Result 2
	print "- Array\n";
	@r = $c->return($q,'array');
	foreach $i (@r) {
		print "ID: ".${$i}[0]." - Name: ".${$i}[1]."\n";
	}

	# Close DB
	$c->disconnect;

=head1 METHODS

=head2 new({type,db,host,username,passwd})

	Create a new SqlLink object.

	my $c = new Ananke::SqlLink({
		'type'		=>	'mysql',
		'db'        => 'test',
		'host'      => 'localhost',
		'username'  => 'root',
		'passwd'    => '',
	});

=head2 $c->return(type,query)
	
	only for select

=head3 scalar type

	@r = $c->return($q,'scalar');
	foreach $i (@r) {
		print "ID: ".$i->{id}." - Name: ".$i->{name}."\n";
	}

=head3 array type

	@r = $c->return($q,'array');
	foreach $i (@r) {
		print "ID: ".${$i}[0]." - Name: ".${$i}[1]."\n";
	}

=head2 $c->do(query)
	
	to insert,update,replace,etc...

	$q = "INSERT INTO test (id,name) VALUES (null,'user')";
	$c->do($q); undef $q;


=head2 $c->disconnect()

	disconnect
	
	$c->disconnect();

=head2 $c->insertid()

	return last insert id

=head2 $c->quote(string)

	AddSlashes

	$q = "INSERT INTO test (id,name) VALUES (null,'".$c->quote($user)."')";

=head1 AUTHOR

   Udlei D. R. Nattis
   nattis@anankeit.com.br
   http://www.nobol.com.br
   http://www.anankeit.com.br

=cut
