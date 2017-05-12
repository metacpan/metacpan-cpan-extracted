package DB_File::Utils::Command::new;
$DB_File::Utils::Command::new::VERSION = '0.006';
use v5.20;
use DB_File::Utils -command;
use strict;
use warnings;

use DB_File;
use Fcntl;

sub abstract { "Creates an empty DB_File" }

sub description { "Creates an empty BD_File" }

sub usage_desc { $_[0]->SUPER::usage_desc . ' <dbfile>' }

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->usage_error("One argument mandatory") unless scalar(@$args)==1;

#	$self->usage_error("$args->[0] already exists!") if -f $args->[0];

}

sub execute {
	my ($self, $opt, $args) = @_;

	$opt = { %{$self->app->global_options}, %$opt};

	my $file = $args->[0];
	$opt->{_create_} = 1;
	my $hash = $self->app->do_tie( $file, $opt );
	untie $hash;
}
