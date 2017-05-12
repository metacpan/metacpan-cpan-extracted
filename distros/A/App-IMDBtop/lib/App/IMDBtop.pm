package App::IMDBtop;

use 5.014000;
use strict;
use warnings;

use Getopt::Long;
use IMDB::Film;
use IMDB::Persons;

our $VERSION = '0.001001';

our $warned = 0;

our (%cast_cache, %cast_count);
our ($nr, $min_count, $cache, $cache_root);

sub patched_cast {
	my IMDB::Film $self = shift;

	my (@cast, $tag, $person, $id, $role);
	my $parser = $self->_parser(1);

	while($tag = $parser->get_tag('table')) {
		last if $tag->[1]->{class} && $tag->[1]->{class} =~ /^cast_list$/i;
	}
	while($tag = $parser->get_tag()) {
		last if $tag->[0] eq 'a' && $tag->[1]{href} && $tag->[1]{href} =~ /fullcredits/i;
	#	if($tag->[0] eq 'td' && $tag->[1]{class} && $tag->[1]{class} eq 'name') {
			$tag = $parser->get_tag('a');
			if($tag->[1]{href} && $tag->[1]{href} =~ m#name/nm(\d+?)/#) {
				$person = $parser->get_text;
				$id = $1;
				my $text = $parser->get_trimmed_text('/tr');
				($role) = $text =~ /\.\.\. (.*)$/;
				push @cast, {id => $id, name => $person, role => $role} if $person;
			}
	#	}
	}

	\@cast
}

sub add_film {
	my ($crit) = @_;
	chomp $crit;
	my @args = (crit => $crit);
	push @args, cache => $cache if defined $cache;
	push @args, cache_root => $cache_root if defined $cache_root;
	my $film = IMDB::Film->new(@args);
	my @cast = @{ $film->cast() };
	unless (@cast) {
		warn "Installed IMDB::Film is broken, using patched cast() method\n" unless $warned;
		$warned = 1;
		@cast = @{ patched_cast $film };
	}
	for my $cast (@cast) {
		my ($id, $name) = ($cast->{id}, $cast->{name});
		$cast_cache{$id} = $name;
		$cast_count{$id}++
	}
}

sub print_results {
	my $cnt = 0;
	for (
		sort {
			$cast_count{$b} <=> $cast_count{$a}
			  or $cast_cache{$a} cmp $cast_cache{$b}
		  }
		  grep {
			  !$min_count || $cast_count{$_} > $min_count
		  } keys %cast_count) {
		last if $nr && $cnt++ >= $nr;
		say $cast_count{$_} . ' ' . $cast_cache{$_}
	}
}

sub run {
	GetOptions (
		'n|nr=i'        => \$nr,
		'm|min-count=i' => \$min_count,
		'c|cache!'      => \$cache,
		'cache-root=s'  => \$cache_root,
	);

	add_film $_ while <>;
	print_results
}

1;
__END__

=encoding utf-8

=head1 NAME

App::IMDBtop - list actors that are popular in your movie collection

=head1 SYNOPSIS

  use App::IMDBtop;
  App::IMDBtop->run

=head1 DESCRIPTION

This module solves a simple problem: you have a list of movies you've
watched (in the form of IMDB IDs), and you are looking for the actors
that have starred most often in these movies.

This module is the backend for the B<imdbtop> script.

=head1 SEE ALSO

L<http://imdb.com>, L<imdbtop>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.



=cut
