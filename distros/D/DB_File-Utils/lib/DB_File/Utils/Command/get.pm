package DB_File::Utils::Command::get;
$DB_File::Utils::Command::get::VERSION = '0.006';
use v5.20;
use DB_File::Utils -command;
use strict;
use warnings;
use Encode qw'encode decode';

use DB_File;
use Fcntl;

sub abstract { "Dumps value for a specific key" }

sub description { "Given a DB_File with strings as keys, prints\nto standard output the value associated\nwith a specific key. Dies if key is not found." }

sub usage_desc { $_[0]->SUPER::usage_desc . ' <dbfile> <key>' }

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->usage_error("Two arguments are mandatory") unless scalar(@$args)==2;

	$self->usage_error("$args->[0] not found") unless -f $args->[0];

	if ($self->app->global_options->{recno} && $args->[1] !~ /^\d+$/) {
		$self->usage_error("RecNo indexing scheme only support integer keys");
	}
}

sub execute {
	my ($self, $opt, $args) = @_;

	$opt = { %{$self->app->global_options}, %$opt};

	my $file = $args->[0];
	my $key  = $args->[1];

	binmode STDOUT, ":utf8" if $opt->{utf8};

	_retrieve($self, $file, $key, $opt);
}

sub _retrieve {
	my ($self, $file, $key, $opt) = @_;

	my $collection = $self->app->do_tie( $file, $opt );

	if (ref($collection) eq "HASH") {

		if (exists($collection->{$key})) {
			say $opt->{utf8} ? decode('utf-8', $collection->{$key}) : $collection->{$key};
		} else {
			die "Key $key not found!"
		}
	}
	else {
		if (defined($collection->[$key])) {
			say $opt->{utf8} ? decode('utf-8', $collection->[$key]) : $collection->[$key];
		} else {
			die "Key $key not found or value undefined!"
		}
	}
	untie $collection;
}

1;