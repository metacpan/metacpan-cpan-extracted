package App::DuckPAN::Cmd::Check;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Command for checking the requirements
$App::DuckPAN::Cmd::Check::VERSION = '1021';
use Moo;
with qw( App::DuckPAN::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ($self) = @_;

	$self->app->empty_cache;
	$self->app->check_requirements; # Exits on missing requirements.
	$self->app->emit_info("EVERYTHING OK! You can now go hacking! :)");
	exit 0;
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Check - Command for checking the requirements

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
