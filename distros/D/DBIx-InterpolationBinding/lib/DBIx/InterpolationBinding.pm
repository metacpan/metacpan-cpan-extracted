#!/usr/bin/perl -w

package DBIx::InterpolationBinding;

use 5.005;
use strict;
use vars qw($VERSION $DEBUG);

use overload '""'       => \&_convert_object_to_string,
             '.'        => \&_append_item_to_object,
             'fallback' => 1;
require DBI;

$VERSION = '1.01';

$DEBUG = 0;

sub import {
	overload::constant 'q' => \&_prepare_object_from_string;

	# Bind the execute method into the DBI namespace
	# We do it twice to avoid a tedious warning
	# We would use the warnings pragma, but this is 5.005 :-)
	*DBI::db::execute = \&dbi_exec;
	*DBI::db::execute = \&dbi_exec;
}

sub unimport {
	overload::remove_constant 'q';
}

sub dbi_exec {
	my ($dbi, $sql) = @_;

	return $dbi->set_err(1,
		'\$dbh->execute can only be used with a magic string.')
		unless (ref $sql and $sql->isa(__PACKAGE__));
	($sql, my @params) = _create_sql_and_params($sql);

	print STDERR "DBI::prepare($sql)\nDBI::execute(", join(", ",
		@params) , ")\n" if $DEBUG;
	my $sth = $dbi->prepare($sql) or return;
	$sth->execute(@params) or return;
	return $sth;
}

sub _create_sql_and_params {
	my ($sql, @params) = @_;

	if (ref $sql and $sql->isa(__PACKAGE__)) {
		# We have a DBOx::InterpolationBinding string
		unshift @params, @{ $sql->{bind_params} };
		$sql = $sql->{sql_string}
	}

	return ($sql, @params);
}

sub _prepare_object_from_string {
	my (undef, $string, $mode) = @_;

	# We only want to affect double-quoted strings
	return $string unless ($mode eq "qq");

	# Make an object out of the string
	my $self = {
		string => $string,
		sql_string => $string,
		bind_params => [ ]
	};
	return bless $self => __PACKAGE__;
}

sub _convert_object_to_string {
	my ($self) = @_;

	# We need a string for this (eg. to print or use outside DBI)
	return $self->{string};
}

sub _append_item_to_object {
	my ($self, $string, $flipped) = @_;

	# $new_hash will become the object we return, so the old one
	# isn't mashed.
	my $new_hash = { %$self };
	$new_hash->{bind_params} = [ @{ $self->{bind_params} } ];

	# At this point, the thing that isn't $self is either an object of
	# this class, or it's a boring string. Also, we either need to append
	# the other thingy before this one, or after, depending on $flipped.
	my $string_is_this_class = ref($string) && $string->isa(__PACKAGE__);

	if ($string_is_this_class and not $flipped) {
		$new_hash->{sql_string} .= $string->{sql_string};
		$new_hash->{string} .= $string->{string};
		push @{ $new_hash->{bind_params} }, @{ $string->{bind_params} };
	}
	if ($string_is_this_class and $flipped) {
		$new_hash->{sql_string} = $string->{sql_string} .
			$new_hash->{sql_string};
		$new_hash->{string} = $string->{string} . $new_hash->{string};
		unshift @{ $new_hash->{bind_params} }, @{ $string->{bind_params} };
	}

	if ($flipped and not $string_is_this_class) {
		$new_hash->{sql_string} = "?" . $new_hash->{sql_string};
		$new_hash->{string} = $string . $new_hash->{string};
		unshift @{ $new_hash->{bind_params} }, $string;
	}
	if (not($flipped) and not $string_is_this_class) {
		$new_hash->{sql_string} .= "?";
		$new_hash->{string} .= $string;
		push @{ $new_hash->{bind_params} }, $string;
	}

	# Make the new thing an object
	return bless $new_hash => ref($self);
}

1;
__END__

=head1 NAME

DBIx::InterpolationBinding - Perl extension for turning perl
double-quote string interpolation into DBI bind parameters.

=head1 SYNOPSIS

  my $dbh = DBI->connect(...);

  {
    use DBIx::InterpolationBinding;
    my $sth = $dbh->execute("SELECT * FROM table WHERE id=$id");
  }

  my $result = $sth->fetchrow_hashref();

=head1 DESCRIPTION

DBIx::InterpolationBinding uses the magic of Perl 5's constant
overloading to cause interpolation into strings to be treated as though
the values being interpolated were used as bind parameters.

Because of limitations in the way in which this module works, it is
typically better to keep this module in force for the minimum amount of
code, as in the above example. For an in-depth discussion of bugs, see
the BUGS section below.

=head2 EXPORT

=head3 $dbh->execute($sql);

Rather rudely, this module exports an execute method into class DBI::db,
so you can call execute() on DBI database handles.

This method only accepts overloaded strings (ie. those created when
DBIx::InterpolationBinding is in force) - this makes it harder to shoot
yourself in the foot by using it with strings that have been
interpolated in an unsafe way.

Returns a DBI statement handle, or undef on failure.

=head3 $DBIx::InterpolationBinding::DEBUG

Set this to 1 (default 0) to see the statement being prepared and the bind
parameters passed to DBI.

=head2 BUGS

Because of limitations in the way Perl 5's overloading interacts with
this module, the limitations below may apply. Some of these are fairly
major, so you may wish to take care.

=over

=item You cannot build up SQL through interpolation

The system doesn't know which bits are SQL and which are bind variables.
The following doesn't work as expected:

  $dbh->execute("SELECT * FROM table WHERE id=$id $where_clause");

You need to build it outside the scope of DBIx::InterpolationBinding in
this case, using conventional bind params.

=item String passed in from outside the lexical scope will not have been
overloaded

If the string passed in is to be interpolated or concatenated into a
string in the lexical scope this is fine, but if a string from
outside is a bit of SQL the effects may be curious.

=item Trying to concat (. operator) an overloaded object with a string
created in scope may have unexpected effects.

This is because the strings in scope are actually objects with an
overloaded concat operator. The overloaded function you're expecting
may not be the one you get!

=back

=head1 SEE ALSO

SQL::Interpolate::Filter achieves a similar thing using source filters.
I wanted to write a solution which didn't use source filters because of
the difficulty in writing filters which can correctly handle all Perl
syntax without incorrectly modifying the code. I also personally prefer
my syntax.

=head1 AUTHOR

Luke Ross, E<lt>luke@lukeross.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2011 by Luke Ross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
