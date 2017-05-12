package App::CLI::Extension::Component::RunCommand;

=pod

=head1 NAME

App::CLI::Extension::Component::RunCommand - for App::CLI::Command run_command override module

=head1 VERSION

1.421

=cut

use strict;
use MRO::Compat;
use Error qw(:try);
use base qw(Class::Accessor::Grouped);

our $FAIL_EXIT_VALUE = 255;
our $VERSION         = '1.421';

__PACKAGE__->mk_group_accessors(inherited => "e", "exit_value", "finished");
__PACKAGE__->exit_value(0);
__PACKAGE__->finished(0);


sub run_command {

	my($self, @argv) = @_;

	try {
		$self->setup(@argv);
		$self->prerun(@argv);
		if ($self->finished == 0) {
			$self->run(@argv);
			$self->postrun(@argv);
		}
	}
	catch App::CLI::Extension::Exception with {
		# $self->e is App::CLI::Extension::Exception object. execute $self->throw($message)
		$self->e(shift);
		$self->exit_value($FAIL_EXIT_VALUE);
		$self->fail(@argv);
	}
	otherwise {
		# $self->e is Error::Simple object
		$self->e(shift);
		$self->exit_value($FAIL_EXIT_VALUE);
		$self->fail(@argv);
	}
	finally {
		$self->finish(@argv);
	};

	if (exists $ENV{APPCLI_NON_EXIT}) {
		no strict "refs";  ## no critic
		my $dispatch_pkg = $self->app;
		${"$dispatch_pkg\::EXIT_VALUE"} = $self->exit_value;
	} else {
		exit $self->exit_value;
	}
}

#######################################
# for run_command method
#######################################

sub setup {

	my($self, @argv) = @_;
	# something to do
	$self->maybe::next::method(@argv);
}

sub prerun {

	my($self, @argv) = @_;
	# something to do
	$self->maybe::next::method(@argv);
}

sub finish {

	my($self, @argv) = @_;
	# something to do
	$self->maybe::next::method(@argv);
}

sub postrun {

	my($self, @argv) = @_;
	# something to do
	$self->maybe::next::method(@argv);
}

sub fail {

	my($self, @argv) = @_;
	chomp(my $message = $self->e->stringify);
	warn sprintf("default fail method. error message:%s. override fail method!!\n", $message);
	$self->maybe::next::method(@argv);
}

1;

__END__

=head1 SEE ALSO

L<App::CLI::Extension> L<Error> L<MRO::Compat>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2009 Akira Horimoto

=cut

