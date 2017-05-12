package App::DuckPAN::Cmd::Env::Cmd::Set;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Sets the specified env variable value
$App::DuckPAN::Cmd::Env::Cmd::Set::VERSION = '1018';
use Moo;
with qw( App::DuckPAN::Cmd::Env::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ($self, $name, @params) = @_;
	$self->env->help("<name> <value>") if !@params || !$name;
	my $data = $self->env->load_env_ini;
	$name = uc $name;
	$data->{$name} = join(" ", @params);
	eval { $self->env->save_env_ini($data) };
	$self->root->emit_and_exit(1,"Please ensure that you are passing a valid value for the variable '". $name ."'!") if $@;
	$self->root->emit_info("Successfully set '". $name ."=". $data->{$name} ."'!");
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Env::Cmd::Set - Sets the specified env variable value

=head1 VERSION

version 1018

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
