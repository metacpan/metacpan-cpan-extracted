package Class::DBI::Loader::mysql::Grok;
our $VERSION = '0.19';

package Class::DBI::Loader::mysql;
use strict;
use warnings;

use Lingua::EN::Inflect qw(PL);
use Class::DBI::Loader 0.22;
use Class::DBI::Loader::mysql 0.22;
use Time::Piece::MySQL 0.05;

no warnings 'redefine';

sub _relationships {
    my $self   = shift; print "Entering Grok::_relationships\n" if $self->debug;
    my @tables = $self->tables;
    my $dbh    = $self->find_class( $tables[0] )->db_Main;

	# keys are table names, 
	# values are hrefs where keys 
	# are column names and values are pri & type
	my %tables = ();
	for my $table ($self->tables) {
		my $sth = $dbh->prepare(qq[ SELECT * FROM $table WHERE 0=1 ]);
		$sth->execute;
		for(my $i = 0; $i < @{$sth->{NAME}}; $i++) { # MySQL-specific
			$tables{$table}->{$sth->{NAME}->[$i]} = {
				type	=>	$sth->{mysql_type_name}->[$i],
				pri		=>	$sth->{mysql_is_pri_key}->[$i],
#				uni		=>	($sth->{mysql_is_key}->[$i] && ! $sth->{mysql_is_pri_key}->[$i]), # unique
			};
		}
	}

	# for each table, go through the columns to see if they refer to another table
	#
	for my $subject_table (@tables) { print "$subject_table\n" if $self->debug;
		for my $column (sort keys %{$tables{$subject_table}}) {
			my $subject_class = $self->find_class($subject_table);
			$subject_class->autoinflate(dates => 'Time::Piece');
			my $object_class  = $self->find_class($column);
			if($tables{$subject_table}->{$column}->{type} eq 'time') { print "\t$subject_class->has_a($column, Time::Piece) time\n" if $self->debug;
				$subject_class->has_a($column, 'Time::Piece',
					inflate => sub { Time::Piece->strptime(shift(),'%H:%M:%S') },
					deflate => sub { shift->strftime('%H:%M:%S') },
				);
			# this points to another table; don't point to this table
			#
			} elsif($tables{$column} and $subject_table ne $column) { print "\t$column matches another table\n" if $self->debug;

				# referring column is a primary key and this is NOT a _ref table: liner notes
				# load all of the _other_ columns in $subject_table into $object_class
				if($tables{$subject_table}->{$column}->{pri} && $subject_table !~ /_ref$/i) {
					for my $col (keys %{$tables{$subject_table}}) {
						
						# this is the primary column, so we can skip it
						#
						next if $col eq $column; print "\t\t$object_class->might_have($subject_table.'_'.$col, $subject_class, $col)\n" if $self->debug;
						$object_class->might_have($subject_table.'_'.$col, $subject_class, $col); # might_have
					}
				} else { print "\t\t$subject_class->has_a($column, $object_class)\n" if $self->debug;
					# this is a non-primary column so there's a has_a relationship here
					# 
					$subject_class->has_a($column, $object_class); # has_a

					# as for the has_many in the reverse direction, is this mapping or simple?
					#
					if($subject_table =~ /_ref$/i) { # $subject_table is a mapping table
						my($other_column) = grep { $tables{$_} && $column ne $_ } # not the key, and not this col
												keys %{$tables{$subject_table}}; # get the column which points to the mapped table
						my $plural = PL($other_column); print "\t\t$object_class->has_many($plural, [ $subject_class, $other_column ] )\n" if $self->debug;
						$object_class->has_many($plural, [ $subject_class, $other_column ]); # has_many
					} else { # simple has_many
						my $plural = PL($subject_table); print "\t\t$object_class->has_many($plural, $subject_class)\n" if $self->debug;
						$object_class->has_many($plural, $subject_class); # has_many
					}
				}
			}
		}
	}
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::DBI::Loader::mysql::Grok - Build Quality Table Relationships Automatically

=head1 SYNOPSIS

  use Class::DBI::Loader; # optional
  use Class::DBI::Loader::mysql::Grok;

  my $loader = Class::DBI::Loader->new(
    ...
    namespace     => "Music",
    relationships => 1,
  );
  
  my $class  = $loader->find_class('artist'); # $class => Music::Artist
  my $artist = $class->retrieve(1);
  
  for my $cd ($artist->cds) {
  	print $cd->artist->name,"\n";
	print $cd->reldate->ymd,"\n"; # a Time::Piece object
  }

  # etc ...

=head1 DESCRIPTION

If you name your tables and columns using some common sense rules,
there's no need for you to do any work to have proper db abstraction.
The following examples mostly follow the Class::DBI perldoc. To see where
they differ (immaterially), see the test script and the accompanying SQL.

The kinds of relationships which are created include:

=item has_a

In the example above, the cd table contains a column which matches the 
name of another table: artist. In this case, Music::Cd objects have a has_a
relationship with Music::Artist. As a result, you can call
$cd->artist->name, etc.

=item has_many

Similar to the has_a example above, the fact that the cd table contains a column
which matches the name of another table means that Music::Artist objects
have a has_many relationship with Music::CD. As a result, you can
call $artist->cds->next->title, etc.

=item has_many mapping

When we're working with a mapping table like Music::StyleRef in the Class::DBI
perldoc, which maps a many-to-many relationship, the mapping table name 
must =~ /_ref$/i, and the columns in that table must be named after the 
tables to which they refer.

=item might_have

The liner_notes table's primary key is named 'cd'. Since that's so, and the table
name (liner_notes) !~ /_ref$/i:
Music::Cd->might_have(liner_notes_notes => Music::LinerNotes => 'notes');

=item Time::Piece support

While not a multi-table relationship, Time::Piece support is included for date, time,
datetime, and timestamp types.

=head2 EXPORT

None by default, but it does redefine the _relationships routine in
Class::DBI::Loader::mysql.

=head1 SEE ALSO

Class::DBI Class::DBI::Loader, Class::DBI::Loader::mysql, Time::Piece

=head1 AUTHOR

James Tolley, E<lt>james@bitperfect.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by James Tolley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
