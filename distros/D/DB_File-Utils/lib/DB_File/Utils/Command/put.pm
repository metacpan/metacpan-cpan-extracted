package DB_File::Utils::Command::put;
$DB_File::Utils::Command::put::VERSION = '0.006';
use v5.20;
use DB_File::Utils -command;
use strict;
use warnings;

use DB_File;
use Fcntl;
use File::Slurp;

sub abstract { "Sets the value for a specific key" }

sub description { "Given a DB_File with strings as keys, sets or ressets the value for a specific key." }

sub usage_desc { $_[0]->SUPER::usage_desc . ' <dbfile> <key>' }

sub opt_spec {
	return (
       ['input|i=s' => "Read value from filename, instead of stdin."],
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->usage_error("Two arguments are mandatory") unless scalar(@$args)==2;

	$self->usage_error("$args->[0] not found") unless -f $args->[0];

	if (exists($opt->{input})) {
		$self->usage_error("$opt->{input} not found") unless -f $opt->{input};		
	}

	if ($self->app->global_options->{recno} && $args->[1] !~ /^\d+$/) {
		$self->usage_error("RecNo indexing scheme only support integer keys");
	}

}

sub execute {
	my ($self, $opt, $args) = @_;

	$opt = { %{$self->app->global_options}, %$opt};

	my $file = $args->[0];
	my $key  = $args->[1];

	my $contents;
	if ($opt->{input}) {
		$contents = read_file($opt->{input},
							  $opt->{utf8} ? { binmode => ':utf8'} : ());
	}
	else {
		local $/ = undef;
		binmode STDIN, ':utf8' if $opt->{utf8};
		$contents = <STDIN>;
	}

	_store($self, $file, $key, $contents, $opt);
}

sub _store {
	my ($self, $filename, $key, $value, $opt) = @_;
	my $collection = $self->app->do_tie( $filename, $opt);
	if (ref($collection) eq "HASH") {
		$collection->{$key} = $opt->{utf8} ? encode('utf-8', $value) : $value;
	} else {
		$collection->[$key] = $opt->{utf8} ? encode('utf-8', $value) : $value;
	}
	untie $collection;
}

1;