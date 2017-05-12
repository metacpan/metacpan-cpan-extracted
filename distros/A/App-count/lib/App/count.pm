package App::count;

use strict;
use warnings;

# ABSTRACT: Counting utility for a file consisting of the fixed number of fields like CSV
our $VERSION = 'v0.1.1'; # VERSION

use Getopt::Long qw(GetOptionsFromArray);
use Getopt::Config::FromPod;
use Pod::Usage;
use YAML::Any;
use Encode;
use String::Unescape;

Getopt::Long::Configure('posix_default', 'no_ignore_case');

my $yaml = YAML::Any->implementation;
my $encoder = $yaml eq 'YAML::Syck' || $yaml eq 'YAML::Old' ? sub { shift; } : sub { Encode::encode('utf-8', shift); };

my $reorder = sub {
	my ($spec, @F) = @_;
	return @F unless length($spec);
	my (@ret, %used);
	foreach my $idx (0..$#F) {
		my $index;
		if($idx < @$spec && $spec->[$idx] ne '') {
			$index = ($spec->[$idx] > 0) ? ($spec->[$idx] - 1) : ($spec->[$idx] + @F);
		} else {
			my $index_ = 0;
			while(exists $used{$index_}) { ++$index_; }
			$index = $index_;
		}
		push @ret, $F[$index];
		$used{$index} = 1;
	}
	return @ret;
};

sub run
{
	shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
	my @spec;
	my $max_col = 0;
	my $handler = sub { my $key = $_[0]; push @spec, map { $max_col = $_ if $max_col < $_; [$key, $_-1 ] } split /,/, $_[1]; };
	my %opts = (
		c => sub { push @spec, ['count']; },
		sum => $handler, max => $handler, min => $handler, avg => $handler,
		'map' => sub {
			my @t = split /,/, $_[1];
			while(my ($idx, $key) = splice(@t, 0, 2)) {
				$max_col = $idx if $max_col < $idx;
				push @spec, ['map', $idx-1, $key];
			}
		}
	);
	GetOptionsFromArray(\@_, \%opts, Getopt::Config::FromPod->array) or pod2usage(-verbose => 0);
	pod2usage(-verbose => 0) if exists $opts{h};
	pod2usage(-verbose => 2) if exists $opts{help};
	die "Column number MUST be more than 0" if grep { $_->[1] < 0 } @spec;

	my $map;
	$map = YAML::Any::LoadFile($opts{M}) or die "Can't load map file" if exists $opts{M};
	die "map is specified but map file is not specified" if ! defined $map && grep { $_->[0] eq 'map' } @spec;
	die "Map key is not found in map file" if defined $map && grep { ! exists $map->{$_} } map { $_->[2] } grep { $_->[0] eq 'map' } @spec;
	my $group;
	if(exists $opts{g}) {
		if(@{$opts{g}} == 1 && $opts{g}[0] eq '*') {
			$group = [];
		} else {
			$group = [map { $max_col = $_ if $max_col < $_; $_-1 } map { split /,/ } @{$opts{g}}];
		}
	}
	die "Column number MUST be more than 0" if defined $group && grep { $_ < 0 } @$group; 
	push @spec, ['count'] if ! @spec;
	if(exists $opts{r}) {
		$opts{r} = [ split /,/, $opts{r} ];
		foreach my $idx (@{$opts{r}}) {
			$max_col = $idx if $max_col < $idx;
		}
	}
	die 'Column number MUST NOT be 0' if exists $opts{r} && grep { length != 0 && $_ == 0 } @{$opts{r}};
	my $odelimiter = defined($opts{t}) ? String::Unescape->unescape($opts{t}) : "\t";
	$opts{t} = defined($opts{t}) ? String::Unescape->unescape($opts{t}) : '\s+';

	my %init = (
		max => sub { undef },
		min => sub { undef },
		avg => sub { [0,0] }, # Return new array reference
		sum => sub { 0 },
		count => sub { 0 },
		'map' => sub { undef },
	);

	push @_, '-' if ! @_;
	while(my $file = shift @_) {
		my $fh;
		if($file ne '-') {
			open $fh, '<', $file or die "Can't open $file";
		} else {
			$fh = \*STDIN;
		}

		my %data;
		my %proc = ( # $key, $idx, \@F
			max   => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] = $F->[$spec[$idx][1]] if ! defined $data{$key}[$idx] || $data{$key}[$idx] < $F->[$spec[$idx][1]]; },
			min   => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] = $F->[$spec[$idx][1]] if ! defined $data{$key}[$idx] || $data{$key}[$idx] > $F->[$spec[$idx][1]]; },
			avg   => sub { my ($key, $idx, $F) = @_; ++$data{$key}[$idx][0]; $data{$key}[$idx][1] += $F->[$spec[$idx][1]]; },
			sum   => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] += $F->[$spec[$idx][1]]; },
			count => sub { my ($key, $idx, $F) = @_; ++$data{$key}[$idx]; },
			'map' => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] ||= $encoder->($map->{$spec[$idx][2]}{$F->[$spec[$idx][1]]}); },
		);
		while(<$fh>) {
			s/[\r\n]+$//;
			my @F = split /$opts{t}/;
			if(@F < $max_col) {
				warn 'Wrong delimiter?: '.scalar(@F).' field(s) is/are fewer than '.$max_col.' specified in the option';
				$max_col = 0; # Avoid repeated warnings
			}
			my $key = defined $group ? join("\x00", @$group == 0 ? @F : @F[@$group]) : '_';

			foreach my $idx (0..$#spec) {
				$data{$key}[$idx] ||= $init{$spec[$idx][0]}->();
				$proc{$spec[$idx][0]}->($key, $idx, \@F);
			}
		}

		if($file ne '-') {
			close $fh;
		}

		foreach my $key (sort keys %data) {
			my @F;
			push @F, split /\x00/, $key if exists $opts{g};
			push @F, map { ref $_ ? $_->[1]/$_->[0] : $_ } @{$data{$key}};
			print join($odelimiter, $reorder->($opts{r}, @F)), "\n";
		}
	}
}

1;

__END__

=pod

=head1 NAME

App::count - Counting utility for a file consisting of the fixed number of fields like CSV

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

  App::count->run(@ARGV);

=head1 DESCRIPTION

This is an implementation module of a counting utility for a file consisting of the fixed number of fields.

=head1 METHODS

=head2 C<run(@arg)>

Process arguments. Typically, C<@ARGV> is passed. For argument details, see L<count>.

=head1 SEE ALSO

=over 4

=item *

L<count>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
