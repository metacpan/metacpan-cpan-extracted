package App::DuckPAN::Cmd::Env::Cmd::Help;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: List commands and usage
$App::DuckPAN::Cmd::Env::Cmd::Help::VERSION = '1018';
use Moo;
with qw( App::DuckPAN::Cmd::Env::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ( $self ) = @_;
	$self->env->help();
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Env::Cmd::Help - List commands and usage

=head1 VERSION

version 1018

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
