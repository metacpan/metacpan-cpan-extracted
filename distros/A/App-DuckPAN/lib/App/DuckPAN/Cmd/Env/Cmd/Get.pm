package App::DuckPAN::Cmd::Env::Cmd::Get;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Gets the specified env variable
$App::DuckPAN::Cmd::Env::Cmd::Get::VERSION = '1021';
use Moo;
with qw( App::DuckPAN::Cmd::Env::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ($self, $name) = @_;
	$self->env->help("<name>") if !$name;
	my $data = $self->env->load_env_ini;
	$name = uc $name;
	$data->{$name} ? $self->root->emit_info("export ". $name ."=". $data->{$name}) : $self->root->emit_error("'". $name ."' is not set!");
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Env::Cmd::Get - Gets the specified env variable

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
