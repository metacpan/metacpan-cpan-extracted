package App::DuckPAN::Cmd::Env::Cmd::Rm;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Removes the specified env variable
$App::DuckPAN::Cmd::Env::Cmd::Rm::VERSION = '1019';
use Moo;
with qw( App::DuckPAN::Cmd::Env::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ( $self, $name ) = @_;
	$self->env->help("<name>") if !$name;
	my $data = $self->env->load_env_ini;
	$name = uc $name;
	defined $data->{$name} ? delete $data->{$name} && $self->root->emit_info("Successfully removed '". $name ."'!") : $self->root->emit_error("'". $name ."' not found!");
	$self->env->save_env_ini($data);
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Env::Cmd::Rm - Removes the specified env variable

=head1 VERSION

version 1019

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
