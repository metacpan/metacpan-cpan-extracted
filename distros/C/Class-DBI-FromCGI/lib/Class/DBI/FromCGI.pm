package Class::DBI::FromCGI;

$VERSION = '1.00';

use strict;
use Exporter;

use vars qw/@ISA @EXPORT/;
use base 'Exporter';
@EXPORT = qw/update_from_cgi create_from_cgi untaint_columns
	cgi_update_errors untaint_type/;

sub untaint_columns {
	die "untaint_columns() needs a hash" unless @_ % 2;
	my ($class, %args) = @_;
	$class->mk_classdata('__untaint_types')
		unless $class->can('__untaint_types');
	my %types = %{ $class->__untaint_types || {} };
	while (my ($type, $ref) = each(%args)) {
		$types{$type} = $ref;
	}
	$class->__untaint_types(\%types);
}

sub cgi_update_errors { %{ shift->{_cgi_update_error} || {} } }

sub update_from_cgi {
	my $self = shift;
	die "update_from_cgi cannot be called as a class method" unless ref $self;
	__PACKAGE__->_run_update($self, @_);
}

sub create_from_cgi {
	my $class = shift;
	die "create_from_cgi can only be called as a class method" if ref $class;
	__PACKAGE__->_run_create($class, @_);
}

sub untaint_type {
	my ($class, $field) = @_;
	my %handler = __PACKAGE__->_untaint_handlers($class);
	return $handler{$field} if $handler{$field};
	my $handler = eval {
		local $SIG{__WARN__} = sub { };
		my $type = $class->column_type($field) or die;
		_column_type_for($type);
	};
	return $handler || undef;
}

#----------------------------------------------------------------------

sub _validate {
	my ($me, $them, $h, $wanted, $extra_ignore) = @_;

	my %wanted = $me->_parse_columns($them => @$wanted);
	my %required = map { $_ => 1 } @{ $wanted{required} };

	my %seen;
	$seen{$_}++ foreach @$extra_ignore, @{ $wanted{ignore} };

	$them->{_cgi_update_error} = {};
	my $fields = {};
	foreach my $field (@{ $wanted{required} }, @{ $wanted{all} }) {
		next if $seen{$field}++;
		my $type = $them->untaint_type($field) or next;
		my $value = $h->extract("-as_$type" => $field);
		my $err = $h->error;
		if ($required{$field} and not $value) {
			$them->{_cgi_update_error}->{$field} = "You must supply '$field'";
		} elsif ($err) {
			$them->{_cgi_update_error}->{$field} = $err
				unless $err =~ /^No parameter for/;
		} else {
			$fields->{$field} = $value;
		}
	}
	return ($them, $fields);
}

sub _run_update {
	my ($me, $them, $h, @wanted) = @_;
	my $class = ref($them);

	my $to_update;
	($them, $to_update) =
		$me->_validate($them, $h, \@wanted, [ $them->primary_column ]);

	return if $them->cgi_update_errors;
	$them->set(%$to_update);
	return 1;
}

sub _run_create {
	my ($me, $class, $h, @wanted) = @_;
	my $them = bless {}, $class;

	my $to_update;
	($them, $to_update) = $me->_validate($them, $h, \@wanted, []);

	# TODO overload to false in boolean?

	return $them if $them->cgi_update_errors;
	return $class->create($to_update);
}

sub _parse_columns {
	my ($me, $them, @cols) = @_;
	my %cols;
	if (ref($cols[0]) eq "HASH") {
		my %hash = %{ $cols[0] };
		@cols{ keys %hash } = values %hash;
	} else {
		$cols{all} = [@cols] if @cols;
	}
	$cols{all} = [ $them->columns('All') ] if not @{ $cols{all} || [] };
	return %cols;
}

sub _untaint_handlers {
	my ($me, $them) = @_;
	return () unless $them->can('__untaint_types');
	my %type = %{ $them->__untaint_types || {} };
	my %h;
	@h{ @{ $type{$_} } } = ($_) x @{ $type{$_} } foreach keys %type;
	return %h;
}

sub _column_type_for {
	my $type = lc shift;
	$type =~ s/\(.*//;
	my %map = (
		varchar   => 'printable',
		char      => 'printable',
		text      => 'printable',
		tinyint   => 'integer',
		smallint  => 'integer',
		mediumint => 'integer',
		int       => 'integer',
		bigint    => 'integer',
		year      => 'integer',
		date      => 'date',
	);
	return $map{$type} || "";
}

1;

__END__

=head1 NAME

Class::DBI::FromCGI - Update Class::DBI data using CGI::Untaint

=head1 SYNOPSIS

  package Film;
  use Class::DBI::FromCGI;
  use base 'Class::DBI';
  # set up as any other Class::DBI class.

  __PACKAGE__->untaint_columns(
    printable => [qw/Title Director/],
    integer   => [qw/DomesticGross NumExplodingSheep/],
    date      => [qw/OpeningDate/],
  );

  # Later on, over in another package ...

  my $h = CGI::Untaint->new( ... );
  my $film = Film->retrieve('Godfather II');
     $film->update_from_cgi($h);

  my $new_film = Film->create_from_cgi($h);

  if (my %errors = $film->cgi_update_errors) {
    while (my ($field, $problem) = each %errors) {
      warn "Problem with $field: $problem\n";
    }
  }

  # or
  $film->update_from_cgi($h => @columns_to_update);

  # or
  $film->update_from_cgi($h => { ignore => \@cols_to_ignore,
                                 required => \@cols_needed,
                                 all => \@columns_which_may_be_empty });


  my $how = $film->untaint_type('Title'); # printable

=head1 DESCRIPTION

Lots of times, Class::DBI is used in web-based applications. (In fact,
coupled with a templating system that allows you to pass objects, such
as Template::Toolkit, Class::DBI is very much your friend for these.)

And, as we all know, one of the most irritating things about writing
web-based applications is the monotony of writing much of the same stuff
over and over again. And, where there's monotony there's a tendency to
skip over stuff that we all know is really important, but is a pain to
write - like Taint Checking and sensible input validation. (Especially
as we can still show a 'working' application without it!). So, we now
have CGI::Untaint to take care of a lot of that for us.

It so happens that CGI::Untaint also plays well with Class::DBI.
Class::DBI::FromCGI is a little wrapper that ties these two together.

=head1 METHODS

=head2 untaint_columns

All you need to do is to 'use Class::DBI::FromCGI' in your class (or
in your local Class::DBI subclass that all your other classes inherit
from. You do do that, don't you?).

Then, in each class in which you want to use this, you declare how you
want to untaint each column:

  __PACKAGE__->untaint_columns(
    printable => [qw/Title Director/],
    integer   => [qw/DomesticGross NumExplodingSheep/],
    date      => [qw/OpeningDate/],
  );

(where the keys are the CGI::Untaint package to be used, and the values
a listref of the relevant columns).

=head2 update_from_cgi

When you want to update based on the values coming in from a
web-based form, you just call:

  $obj->update_from_cgi($h => @columns_to_update);

If every value passed in gets through the CGI::Untaint process, the object
will be updated (but not committed, in case you want to do anything else
with it). Otherwise the update will fail (there are no partial updates),
and $obj->cgi_update_errors will tell you what went wrong (as a hash of
problem field => error from CGI::Untaint).

=head2 create_from_cgi

Similarly, if you wish to create a new object, then you can call:

  my $obj = Class->create_from_cgi($h => @columns_to_update);

If this fails, $obj will be a defined object, containing the errors,
as with an update, but will not contain the values submitted, nor have
been written to the database.

=head2 untaint_type

  my $how = $film->untaint_type('Title'); # printable

This tells you how we're going to untaint a given column.

=head2 cgi_update_errors

  if (my %errors = $film->cgi_update_errors) {
    while (my ($field, $problem) = each %errors) {
      warn "Problem with $field: $problem\n";
    }
  }

This returns a hash of any errors when updating. Despite its name it
also applies when inserting.

=head1 Column Auto-Detection

As Class::DBI knows all its columns, you don't even have to say
what columns you're interested in, unless it's a subset, as we can
auto-fill these:

  $obj->update_from_cgi($h);

You can also specify columns which must be present, or columns to be
ignored even if they are present:

  $film->update_from_cgi($h => {
    all      => \@all_columns, # auto-filled if left blank
    ignore   => \@cols_to_ignore,
    required => \@cols_needed,
  });

Doesn't this all make your life so much easier?

=head1 NOTE

Don't try to update the value of your primary key. Class::DBI doesn't
like that. If you try to do this it will be silently skipped.

=head1 ANOTHER NOTE

If you haven't set up any 'untaint_column' information for a column which
you later attempt to untaint, then we try to call $self->column_type to
ascertain the default handler to use. Currently this will only use if
you're using Class::DBI::mysql, and only for certain column types.

=head1 SEE ALSO

L<Class::DBI>. L<CGI::Untaint>. L<Template>.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-FromCGI@rt.cpan.org

=head1 COPYRIGHT

Copyright (C) 2001-2005 Kasei. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

