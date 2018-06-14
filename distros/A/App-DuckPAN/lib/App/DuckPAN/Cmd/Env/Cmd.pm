package App::DuckPAN::Cmd::Env::Cmd;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Base class for Env commands
$App::DuckPAN::Cmd::Env::Cmd::VERSION = '1021';
use Moo::Role;

requires 'run';

has env => (
	is => 'rw',
);

has root => (
	    is => 'rw',
);

sub execute {
	    my ( $self, $args, $chain ) = @_;
	    my $root = shift @{$chain};
	    $self->root($root);
	    my $env = shift @{$chain};
	    $self->env($env);
	    $self->run(@{$args});
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Env::Cmd - Base class for Env commands

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
