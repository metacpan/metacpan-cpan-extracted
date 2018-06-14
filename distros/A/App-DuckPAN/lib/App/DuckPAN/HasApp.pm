package App::DuckPAN::HasApp;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Simple role for classes which carry an object of App::DuckPAN
$App::DuckPAN::HasApp::VERSION = '1021';
use Moo::Role;

has app => (
	is => 'rw',
	required => 1,
);

1;

__END__

=pod

=head1 NAME

App::DuckPAN::HasApp - Simple role for classes which carry an object of App::DuckPAN

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
