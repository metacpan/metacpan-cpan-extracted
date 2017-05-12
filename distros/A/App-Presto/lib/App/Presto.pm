package App::Presto;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::VERSION = '0.010';
# ABSTRACT: provides CLI for performing REST operations

use Moo;
use App::Presto::CommandFactory;
use App::Presto::Config;
use App::Presto::Client;
use App::Presto::ShellUI;
use App::Presto::Stash;

has client => (
	is       => 'lazy',
);

sub _build_client {
	my $self = shift;
	return App::Presto::Client->new(config => $self->config);
}

has config => (
	is       => 'rw',
	handles  => ['endpoint'],
);

has _stash => (
	is       => 'lazy',
	handles  => ['stash'],
);

sub _build__stash {
	my $self = shift;
	return App::Presto::Stash->new;
}

has term => (
	is => 'lazy',
);
sub _build_term {
	my $self = shift;
		my $help_categories = $self->command_factory->help_categories;
    my $term = App::Presto::ShellUI->new(
        commands => {
            "help" => {
                exclude_from_completion => 1,
                exclude_from_history    => 1,
                desc                    => "Print helpful information",
                args => sub { shift->help_args( $help_categories, @_ ); },
                method => sub { shift->help_call( $help_categories, @_ ); }
            },
            "h" => {
                alias                   => "help",
                exclude_from_completion => 1,
                exclude_from_history    => 1,
            },
						echo => {
							desc => 'Print arguments (possibly interpolated) to the screen',
							proc => sub { use Data::Dumper; print join ' ', map {ref($_) ? Dumper($_) : $_} @_; print "\n" },
						},
            quit => {
                desc                    => "Exits the REST shell",
                maxargs                 => 0,
                exclude_from_completion => 1,
                exclude_from_history    => 1,
                method                  => sub { shift->exit_requested(1) },
            },
			exit => {
				alias                   => "quit",
				exclude_from_completion => 1,
				exclude_from_history    => 1,
			},
            "history" => {
                exclude_from_completion => 1,
                exclude_from_history    => 1,
                desc                    => "Prints the command history",
                args                    => "[-c] [-d] [number]",
                method                  => sub { shift->history_call(@_) },
                doc => "Specify a number to list the last N lines of history Pass -c to clear the command history, -d NUM to delete a single item\n",
            },
        },
        prompt       => sprintf( '%s> ', $self->endpoint ),
        history_file => $self->config->file('history'),
    );
		$term->ornaments('md,me,,');
		return $term;
}

has command_factory => (
	is => 'lazy',
);
sub _build_command_factory { return App::Presto::CommandFactory->new }

my $SINGLETON;
sub instance {
	my $class = shift;
	return $SINGLETON ||= $class->new(@_);
}
sub run {
	my $class = shift;
	my $self = $class->instance;
	my @args  = shift;
	my $config;
	if(my $endpoint = shift(@args)){
		$self->config( $config = App::Presto::Config->new( endpoint => $endpoint ) );
	} else {
		die "Base endpoint (i.e. http://some-host.com) must be specified as command-line argument\n";
	}

	$config->init_defaults;

	$self->command_factory->install_commands($self);

	my $binmode = $config->get('binmode');
	binmode(STDOUT,":encoding($binmode)");
	binmode(STDIN,":encoding($binmode)");

	my $term = $self->term;
	return $term->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto - provides CLI for performing REST operations

=head1 VERSION

version 0.010

=head1 SYNOPSIS

All user-facing documentation can be found in L<presto>.

=head1 DESCRIPTION

A L<Term::ShellUI>-based CLI for REST web applications.

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
