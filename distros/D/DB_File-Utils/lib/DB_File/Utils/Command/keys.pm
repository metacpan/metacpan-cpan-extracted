package DB_File::Utils::Command::keys;
$DB_File::Utils::Command::keys::VERSION = '0.006';
use v5.20;
use DB_File::Utils -command;
use strict;
use warnings;

use DB_File;
use Fcntl;

sub abstract { "Lists DB_File keys, one per line." }

sub description { "Given a DB_File with strings as keys, prints all keys, one per line." }

sub usage_desc { $_[0]->SUPER::usage_desc . ' <dbfile> <...>' }

sub opt_spec {
	return ();
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	foreach my $file (@$args) {
		$self->usage_error("$file not found") unless -f $file;
	}
}

sub execute {
	my ($self, $opt, $args) = @_;

	$opt = { %{$self->app->global_options}, %$opt};

	foreach my $file (@$args) {
		_dump($self, $file, $opt);
	}
}

sub _dump {
	my ($self, $filename, $opt) = @_;
	my $collection = $self->app->do_tie( $filename, $opt);
	if (ref($collection) eq "HASH") {
		say while (($_) = each %$collection);
	} else {
		say foreach grep { defined $collection->[$_] } keys @$collection;
	}
	untie $collection;
}

1;