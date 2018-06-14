package App::DuckPAN::Cmd;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Base class for commands of DuckPAN
$App::DuckPAN::Cmd::VERSION = '1021';
use Moo::Role;

requires 'run';

has app => (
	is => 'rw',
);

sub initialize {
	my $self = shift;
	$self->app->initialize_working_directory();
}

sub execute {
	my ( $self, $args, $chain ) = @_;
	my $app = shift @{$chain};
	$self->app($app);
	$self->initialize();
	$self->run(@{$args});
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd - Base class for commands of DuckPAN

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
