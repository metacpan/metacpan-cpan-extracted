package NewFilm;

BEGIN { unshift @INC, './t/testlib'; }
use base 'CDBase';
use strict;
use Class::DBI::Plugin::Iterator;

__PACKAGE__->table('NewMovies');
__PACKAGE__->columns('Primary',   'Title');
__PACKAGE__->columns('Essential', qw( Title ));
__PACKAGE__->columns('Directors', qw( Director CoDirector ));
__PACKAGE__->columns('Other',     qw( Rating NumExplodingSheep HasVomit ));

sub CONSTRUCT {
	my $class = shift;
	$class->create_movies_table;
	#$class->make_bad_taste;
}

sub create_movies_table {
	my $class = shift;
	$class->db_Main->do(
		qq{
     CREATE TABLE NewMovies (
        title                   VARCHAR(255),
        director                VARCHAR(80),
        codirector              VARCHAR(80),
        rating                  CHAR(5),
        numexplodingsheep       INTEGER,
        hasvomit                CHAR(1)
    )
  }
	);
}

sub make_bad_taste {
	my $class = shift;
	$class->create(
		{
			Title             => 'Bad Taste',
			Director          => 'Peter Jackson',
			Rating            => 'R',
			NumExplodingSheep => 1
		}
	);
}


1;
