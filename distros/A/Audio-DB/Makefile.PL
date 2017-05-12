use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
$VERSION = '0.01';

WriteMakefile(
	      NAME         => 'Audio::DB',
	      VERSION      => $VERSION,
	      PREREQ_PM    => {
			       DBI => '1.38',
			       CGI => '3.00',
			      },
	      PL_FILES     => {
			       'bin/album_distribution.PLS'      => 'bin/album_distribution.pl',
			       'bin/albums_below_threshold.PLS'  => 'bin/albums_below_threshold.pl',
			       'bin/artists_with_multiple_genres.PLS' => 'bin/artists_with_multiple_genres.pl',
			       'bin/create_database.PLS'         => 'bin/create_database.pl',
			       'bin/create_schema.PLS'           => 'bin/create_schema.pl',
			       'bin/generate_album_list.PLS'     => 'bin/generate_album_list.pl',
			       'bin/genre_statistics.PLS'        => 'bin/genre_statistics.pl',
			       'bin/library_statistics.PLS'      => 'bin/library_statistics.pl',
			       'bin/song_distribution.PLS'       => 'bin/song_distribution.pl',
			      },
	      ($] >= 5.005
	       ? (ABSTRACT  => 'Relational databases and statistics of digital audio collections',
		  AUTHOR         => 'Todd Harris (harris@cshl.edu)')
	       : ()),
	     );


1;
