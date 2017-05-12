package Class::DBI::DATA::Schema;

=head1 NAME

Class::DBI::DATA::Schema - Execute Class::DBI SQL from DATA sections

=head1 SYNOPSIS

  package Film.pm;
  use base 'Class::DBI';
	  # ... normal Class::DBI setup

  use 'Class::DBI::DATA::Schema';

  Film->run_data_sql;


	__DATA__
	CREATE TABLE IF NOT EXISTS film (....);
	REPLACE INTO film VALUES (...);
	REPLACE INTO film VALUES (...);

=head1 DESCRIPTION

This is an extension to Class::DBI which injects a method into your class
to find and execute all SQL statements in the DATA section of the package.

=cut

use strict;
use warnings;

our $VERSION = '1.00';

=head1 METHODS

=head2 run_data_sql

  Film->run_data_sql;

Using this module will export a run_data_sql method into your class.
This method will find SQL statements in the DATA section of the class
it is called from, and execute them against the database that that class
is set up to use.

It is safe to import this method into a Class::DBI subclass being used
as the superclass for a range of classes.

WARNING: this does not do anything fancy to work out what is SQL. It
merely assumes that everything in the DATA section is SQL, and
applies each thing it finds (separated by semi-colons) in turn to your
database. Similarly there is no security checking, or validation of the
DATA in any way.

=head1 TRANSLATION and CACHING

There are undocumented arguments that will allow this module to translate
the SQL from one database schema to another, and also to cache the result
of that translation. People are relying on these, so they're not going
to go away, but you're going to need to read the source and/or the tests
to work out how to use them.

=cut

sub import {
	my ($self, %args) = @_;
	my $caller = caller();

	my $translating = 0;
	if ($args{translate}) {
		eval "use SQL::Translator";
		$@ ? warn "Cannot translate without SQL::Translator" : ($translating = 1);
	}

	my $CACHE = "";
	if ($args{cache}) {
		eval "use Cache::File; use Digest::MD5";
		$@
			? warn "Cannot cache without Cache::File and Digest::MD5"
			: (
			$CACHE = Cache::File->new(
				cache_root      => $args{cache},
				cache_umask     => $args{cache_umask} || 000,
				default_expires => $args{cache_duration} || '30 day',
			));
	}

	my $translate = sub {
		my $sql = shift;
		if (my ($from, $to) = @{ $args{translate} || [] }) {
			my $key    = $CACHE ? Digest::MD5::md5_base64($sql.$from.$to) : "";
			my $cached = $CACHE ? $CACHE->get($key)             : "";
			return $cached if $cached;

			my $translator = SQL::Translator->new(no_comments => 1, trace => 0);

			# Ahem.
			local $SIG{__WARN__} = sub { };
			local *Parse::RecDescent::_error = sub ($;$) { };
			$sql = eval {
				$translator->translate(
					parser   => $from,
					producer => $to,
					data     => \$sql,
				);
			} || $sql;
			$CACHE->set($key => $sql) if $CACHE;
		}
		$sql;
	};

	my $transform = sub {
		my $sql = shift;
		return join ";", map $translate->("$_;"), grep /\S/, split /;/, $sql;
	};

	my $get_statements = sub {
		my $h = shift;
		local $/ = undef;
		chomp(my $sql = <$h>);
		return grep /\S/, split /;/, $translating ? $transform->($sql) : $sql;
	};

	my %cache;

	no strict 'refs';
	*{"$caller\::run_data_sql"} = sub {
		my $class = shift;
		no strict 'refs';
		$cache{$class} ||= [ $get_statements->(*{"$class\::DATA"}{IO}) ];
		$class->db_Main->do($_) foreach @{ $cache{$class} };
		return 1;
		}

}

=head1 SEE ALSO

L<Class::DBI>. 

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-DATA-Schema@rt.cpan.org

=head1 COPYRIGHT

  Copyright (C) 2003-2005 Kasei 

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;
