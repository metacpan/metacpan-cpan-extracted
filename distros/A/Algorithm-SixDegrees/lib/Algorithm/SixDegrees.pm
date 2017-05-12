package Algorithm::SixDegrees;

require 5.006;
use warnings;
use strict;
use UNIVERSAL qw(isa);

=head1 NAME

Algorithm::SixDegrees - Find a path through linked elements in a set

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our $ERROR = '';

=head1 SYNOPSIS

	use Algorithm::SixDegrees;

	my $sd1 = Algorithm::SixDegrees->new();
	$sd1->data_source( actors => \&starred_in );
	$sd1->data_source( movies => \&stars_of );
	@elems = $sd1->make_link('actors', 'Tom Cruise', 'Kevin Bacon');

	my $sd2 = Algorithm::SixDegrees->new();
	$sd2->forward_data_source( friends => \&friends, @args );
	$sd2->reverse_data_source( friends => \&friend_of, @args );
	@elems = $sd2->make_link('friends', 'Bob', 'Mark');

=head1 DESCRIPTION

C<Algorithm::SixDegrees> is a Perl implementation of a breadth-first
search through a set of linked elements in order to find the shortest
possible chain linking two specific elements together.

In simpler terms, this module will take a bunch of related items and
attempt to find a relationship between two of them.  It looks for the
shortest (and generally, simplest) relationship it can find.

=head1 CONSTRUCTOR

=head2 new()

C<Algorithm::SixDegrees> requires use as an object; it can't (yet) be used
as a stand-alone module.  C<new> takes no arguments, however.

=cut

sub new {
	my $class = shift;
	my $self = {
		_source_left  => {},
		_source_right => {},
		_sources      => [],
		_investigated => {},
	};
	return bless $self,$class;
}

=head1 FUNCTIONS

=head2 forward_data_source( name => \&sub, @args );

Tells C<Algorithm::SixDegrees> that all items in the data set relating to
C<name> can be retrieved by calling C<sub>.  See L</SUBROUTINE RULES>.

In our friends example above, if Bob considers Mark a friend, but Mark
doesn't consider Bob a friend, calling the sub with "Bob" as an argument
should return "Mark", but calling the sub with "Mark" as an argument
should not return "Bob".

=cut

sub forward_data_source {
	my ($self, $name, $sub, @args) = @_;
	die "Data sources must be named\n" unless defined($name);
	die "Data sources must have code supplied\n" unless defined($sub);
	die "Data sources must have a coderef argument\n" unless ref($sub) && isa($sub,'CODE');
	$self->{'_source_left'}{$name}{'sub'} = $sub;
	$self->{'_source_left'}{$name}{'args'} = \@args;
	foreach my $source (@{$self->{'_sources'}}) {
		return if $source eq $name;
	}
	push(@{$self->{'_sources'}},$name);
	return;
}

=head2 reverse_data_source( name => \&sub, @args );

Tells C<Algorithm::SixDegrees> that all items in the data set related to 
by C<name> can be retrieved by calling C<sub>.  See L</SUBROUTINE RULES>.

In the same friends example, calling the sub with "Bob" as an argument
should not return "Mark", but calling the sub with "Mark" as an argument
should return "Bob".

=cut

sub reverse_data_source {
	my ($self, $name, $sub, @args) = @_;
	die "Data sources must be named\n" unless defined($name);
	die "Data sources must have code supplied\n" unless defined($sub);
	die "Data sources must have a coderef argument\n" unless ref($sub) && isa($sub,'CODE');
	$self->{'_source_right'}{$name}{'sub'} = $sub;
	$self->{'_source_right'}{$name}{'args'} = \@args;
	foreach my $source (@{$self->{'_sources'}}) {
		return if $source eq $name;
	}
	push(@{$self->{'_sources'}},$name);
	return;
}

=head2 data_source( name => \&sub, @args );

Sets up a data source as both forward and reverse.  This is useful if
the data source is mutually relational; that is, in our actors/movies
example, Kevin Bacon is always in Mystic River, and Mystic River always
has Kevin Bacon in it.

=cut

sub data_source {
	my ($self, $name, $sub, @args) = @_;
	$self->forward_data_source($name,$sub,@args);
	$self->reverse_data_source($name,$sub,@args);
	return;
}

=head2 make_link

Does the work of making the link.  Returns a list or arrayref, based
on calling context.

=cut

sub make_link {
	my ($self, $mainsource, $start, $end) = @_;
	$ERROR = undef;

	unless (ref($self) && isa($self,__PACKAGE__)) {
		$ERROR = 'Invalid object reference used to call make_link';
		return;
	}
	unless (defined($mainsource)) {
		$ERROR = 'Data set name is not defined';
		return;
	}
	unless (defined($start)) {
		$ERROR = 'Starting identifier is not defined';
		return;
	}
	unless (defined($end)) {
		$ERROR = 'Ending identifier is not defined';
		return;
	}

	# Assume working from "left to right"; therefore, links leading
	# from the starting identifier are on the "left side", and links
	# leading to the ending identifier are on the "right side".
	my %leftside = (); 
	my %rightside = ();

	# If $altsource gets defined, that means there are two sources used.
	my $altsource;

	unless (exists($self->{'_sources'}) && isa($self->{'_sources'},'ARRAY')) {
		$ERROR = 'No data sources defined';
		return;
	}
	my @sources = @{$self->{'_sources'}};
	my $source_exists = 0;
	foreach my $source (@sources) {
		if ($mainsource eq $source) {
			$source_exists = 1;
			$leftside{$source} = {$start, undef};
			$rightside{$source} = {$end, undef};
		} else {
			$altsource = $source;
			$leftside{$source} = {};
			$rightside{$source} = {};
		}
		unless (ref($self->{'_source_left'}) && 
			ref($self->{'_source_left'}{$source}) &&
			isa($self->{'_source_left'}{$source}{'sub'},'CODE')) {
			$ERROR = "Source '$source' does not have a valid forward subroutine";
			return;
		}
		unless (ref($self->{'_source_right'}) && 
			ref($self->{'_source_right'}{$source}) &&
			isa($self->{'_source_right'}{$source}{'sub'},'CODE')) {
			$ERROR = "Source '$source' does not have a valid reverse subroutine";
			return;
		}
		$self->{'_investigated'}{$source} = {};
	}
	unless ($source_exists) {
		$ERROR = "Source '$mainsource' was not defined";
		return;
	}
	if (scalar(keys(%leftside)) > 2) {
		$ERROR = 'Too many defined data sources; maximum is 2';
		return;
	}


	if ($start eq $end) {
		# Only one element if the start and end are the same.
		return wantarray ? ($start) : [$start];
	}

	my $leftcount = 1;
	my $rightcount = 1;

	# If altsource exists, pull the left side main, then pull the right side main,
	# and check for middle matches.  This reduces database hits as opposed to
	# where it's pulled left main - left alt; left alt >= 1 at that point, whereas
	# right main on the first loop == 1.  Following that, pull the left alt and 
	# then the right alt, which gets the CHAINLOOP back in synch.

	if (defined($altsource)) {
		my ($count,$id,$err) = $self->_match('left',$mainsource,$altsource,\%leftside,\%rightside);
		if (defined($err)) { $ERROR = $err; return; };
		if (defined($id)) { $ERROR = 'Internal error, id cannot match here'; return; };
		return if !defined($count) || $count == 0;

		($count,$id,$err) = $self->_match('right',$mainsource,$altsource,\%rightside,\%leftside);
		if (defined($err)) { $ERROR = $err; return; };
		if (defined($id)) { 
			my @abc = ($leftside{$altsource}{$id},$id,$rightside{$altsource}{$id});
			return wantarray ? @abc : \@abc;
		};
		return if !defined($count) || $count == 0;

		($leftcount,$id,$err) = $self->_match('left',$altsource,$mainsource,\%leftside,\%rightside);
		if (defined($err)) { $ERROR = $err; return; };
		if (defined($id)) { $ERROR = 'Internal error, id cannot match here'; return; };
		return if !defined($leftcount) || $leftcount == 0;

		($rightcount,$id,$err) = $self->_match('right',$altsource,$mainsource,\%rightside,\%leftside);
		if (defined($err)) { $ERROR = $err; return; };
		if (defined($id)) { 
			my $la = $leftside{$mainsource}{$id};
			my $lm = $leftside{$altsource}{$la};
			my $ra = $rightside{$mainsource}{$id};
			my $rm = $rightside{$altsource}{$ra};
			unless (defined($la) && defined($lm) && defined($ra) && defined($rm)) {
				$ERROR = 'Internal error, identifier not defined';
				return;
			}
			return wantarray ? ($lm,$la,$id,$ra,$rm) : [$lm,$la,$id,$ra,$rm];
		};
		return if !defined($rightcount) || $rightcount == 0;

	}

	# There is bias here, but the tie needs to be broken, so in the
	# event of a tie, move left to right in the chain.

	CHAINLOOP: {
		my $id;
		my $err;
		if ($leftcount <= $rightcount) {
			if (defined($altsource)) {
				($leftcount,$id,$err) = $self->_match_two('left',$mainsource,$altsource,\%leftside,\%rightside);
			} else {
				($leftcount,$id,$err) = $self->_match_one('left',$mainsource,\%leftside,\%rightside);
			}
		} else {
			if (defined($altsource)) {
				($rightcount,$id,$err) = $self->_match_two('right',$mainsource,$altsource,\%rightside,\%leftside);
			} else {
				($rightcount,$id,$err) = $self->_match_one('right',$mainsource,\%rightside,\%leftside);
			}
		}
		if(defined($err)) {
			$ERROR = $err;
			return;
		}
		if(defined($id)) {
			# If _match returns an id, that means a match was found.
			# To get it, we simply have to trace out from the "middle"
			# to get the full link.
			my @match = ($id);
			# middle, building to left.
			while($match[0] ne $start) {
				unshift(@match,$leftside{$mainsource}{$match[0]});
				unshift(@match,$leftside{$altsource}{$match[0]}) if defined($altsource);
				if (!defined($match[0])) {
					$ERROR = 'Internal error, left identifier was not defined';
					return;
				}
			}
			# middle building to right
			while($match[-1] ne $end) {
				push(@match,$rightside{$mainsource}{$match[-1]});
				push(@match,$rightside{$altsource}{$match[-1]}) if defined($altsource);
				if (!defined($match[-1])) {
					$ERROR = 'Internal error, right identifier was not defined';
					return;
				}
			}
			return wantarray ? @match : \@match;
		} 
		if ($leftcount == 0 || $rightcount == 0) {
			last CHAINLOOP;
		}
		redo CHAINLOOP;
	}

	return wantarray ? () : [];
}

=head2 error

Returns the current value of C<$Algorithm::SixDegrees::ERROR>.  See
L</SUBROUTINE RULES>.

=cut

sub error {
	return $ERROR;
}

sub _match_two {
	my ($self,$side,$mainsource,$altsource,$thisside,$thatside) = @_;
	# Assume $self is OK since this is an internal function
	my ($count,$id,$err) = $self->_match($side,$mainsource,$altsource,$thisside,$thatside);
	return (undef,undef,$err) if defined($err);
	return ($count,$id,$err) if defined($id);
	return (0,undef,undef) if !defined($count) || $count == 0;
	# mental note: this should never return an id
	# after all, you can't have two mains together in a true
	# alternating chain
	return $self->_match($side,$altsource,$mainsource,$thisside,$thatside);
}

sub _match_one {
	my ($self,$side,$source,$thisside,$thatside) = @_;
	# Assume $self is OK since this is an internal function
	return $self->_match($side,$source,$source,$thisside,$thatside);
}

sub _match {
	my ($self,$side,$fromsource,$tosource,$thisside,$thatside) = @_;
	# Assume $self is OK since this is an internal function
	return (undef,undef,'Internal error: missing code') unless isa($self->{"_source_$side"}{$fromsource}{'sub'},'CODE');
	return (undef,undef,'Internal error: missing side (1)') unless isa($thisside,'HASH');
	return (undef,undef,'Internal error: missing side (2)') unless exists($thisside->{$fromsource});
	return (undef,undef,'Internal error: missing side (3)') unless isa($thatside,'HASH');
	return (undef,undef,'Internal error: missing side (4)') unless exists($thatside->{$tosource});

	my $newsidecount = 0;
	foreach my $id (keys %{$thisside->{$fromsource}}) {
		next if exists($self->{"_investigated"}{$fromsource}{$id});
		$self->{"_investigated"}{$fromsource}{$id} = 1;

		my $use_args = isa($self->{"_source_$side"}{$fromsource}{'args'},'ARRAY') ? 1 : 0;

		my @ids = &{$self->{"_source_$side"}{$fromsource}{'sub'}}($id,($use_args?@{$self->{"_source_$side"}{$fromsource}{'args'}}:()));
		return (undef,undef,$ERROR) if scalar(@ids) == 1 && !defined($ids[0]);
		foreach my $thisid (@ids) {
			unless (exists($thisside->{$tosource}{$thisid})) {
				$thisside->{$tosource}{$thisid} = $id;
				$newsidecount++;
			}
			return (0,$thisid,undef) if exists($thatside->{$tosource}{$thisid});
		}
	}

	return $newsidecount;
}

=head1 SUBROUTINE RULES

Passed-in subroutines should take at least one argument, which
should be some form of unique identifier, and return a list of
unique identifiers that have a relation to the argument.

The unique identifiers must be able to be compared with C<eq>.

The identifiers should be unique in datatype; that is, in an
actor/movie relationship, "Kevin Bacon" can be both the name of an
actor and a movie.

A linked data type must return identifiers that relate across the
link; that is, for an actor/movie relationship, an actor subroutine
should return movies, and a movie subroutine should return actors.

Additional arguments can be provided; these will be stored in the
object and passed through as the second and further arguments to
the subroutine.  This may be useful, for example, if you're using
some form of results caching and need to pass a C<tie>d handle
around.

If you return explicit undef, please set C<$Algorithm::SixDegrees::ERROR>
with an error code.  Explicit undef means that an error occurred
that should terminate the search; it should be returned as a
one-element list.

=head1 AUTHOR

Pete Krawczyk, C<< <petek@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-sixdegrees@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Andy Lester and Ricardo Signes wrote Module::Starter, which helped
get the framework up and running fairly quickly.

Brad Fitzpatrick of L<http://livejournal.com> for giving me access
to a LiveJournal interface to determine linking information on that
site, which enabled me to write the algorithm that has been reduced
into this module.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Pete Krawczyk, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Algorithm::SixDegrees
