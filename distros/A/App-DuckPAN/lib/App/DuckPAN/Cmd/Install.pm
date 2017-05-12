package App::DuckPAN::Cmd::Install;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Install the distribution in current directory
$App::DuckPAN::Cmd::Install::VERSION = '1018';
use Moo;
with qw( App::DuckPAN::Cmd );

use MooX::Options protect_argv => 0;

sub run {
	my ( $self, @args ) = @_;

	if (-f 'dist.ini') {
		$self->app->emit_info("Found a dist.ini, suggesting a Dist::Zilla distribution");

		$self->app->perl->cpanminus_install_error
			if (system("dzil install --install-command 'cpanm .' @args"));
		$self->app->emit_info("Everything fine!");
	}

}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Install - Install the distribution in current directory

=head1 VERSION

version 1018

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
