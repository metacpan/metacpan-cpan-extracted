package App::DuckPAN::Cmd::Help;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Launch help page
$App::DuckPAN::Cmd::Help::VERSION = '1021';
use Moo;
with qw( App::DuckPAN::Option::Global );

use MooX::Options protect_argv => 0;
use Pod::Usage qw(pod2usage);

sub run {
	my ($self, $short_output) = @_;


	pod2usage(-verbose => 2) unless $short_output;
	pod2usage(-verbose => 1);
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Cmd::Help - Launch help page

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
