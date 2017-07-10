package App::DuckPAN::Cmd::Query;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Command line tool for testing queries and see triggered instant answers
$App::DuckPAN::Cmd::Query::VERSION = '1019';
use MooX;
with qw( App::DuckPAN::Cmd App::DuckPAN::Restart );

use MooX::Options protect_argv => 0;

sub run {
	my ($self, @args) = @_;

	exit $self->run_restarter(\@args);
}

sub _run_app {
	my ($self, $args) = @_;

	$self->app->check_requirements;    # Will exit if missing
	my @blocks = @{$self->app->ddg->get_blocks_from_current_dir(@$args)};

	require App::DuckPAN::Query;
	App::DuckPAN::Query->run($self->app, \@blocks);
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Query - Command line tool for testing queries and see triggered instant answers

=head1 VERSION

version 1019

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
