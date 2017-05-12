package App::DuckPAN::Cmd::Env::Cmd::List;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: List all env variables
$App::DuckPAN::Cmd::Env::Cmd::List::VERSION = '1018';
use Moo;
with qw( App::DuckPAN::Cmd::Env::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ( $self )  = @_;
	my $data = $self->env->load_env_ini;
	if (keys %{$data}) {
		$self->root->emit_info("export ". $_ ."=". $data->{$_} ) for (sort keys %{$data});
	}
	else {
		$self->root->emit_notice("There are no env variables set currently.");
	}
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Env::Cmd::List - List all env variables

=head1 VERSION

version 1018

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
