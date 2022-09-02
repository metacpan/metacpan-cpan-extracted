package Alien::Build::Plugin::Fetch::PromptBeforeDownload;

use strict;
use warnings;
use 5.010;
use base qw( Alien::Build::Plugin::Fetch::Prompt );

# ABSTRACT: Backwards compatible plugin name
our $VERSION = '0.61'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Fetch::PromptBeforeDownload - Backwards compatible plugin name

=head1 VERSION

version 0.61

=head1 SYNOPSIS

 % perldoc Alien::Build::Plugin::Fetch::Prompt

=head1 DESCRIPTION

When I first wrote L<Alien::Build::Plugin::Fetch::Prompt>, I gave it
this much too long a name.  It made my dist list on C<metacpan.org>
all kaka.  Sort of like that one episode of The Original Series
"For the World is Hollow and I have Touched the Sky" which is still
the longest episode title in the history of Star Trek.  (In case
you are wondering, and I can see you aren't, the second longest title
goes to the Deep Space 9 episode "Looking for par'Mach in All the
Wrong Places").  I bet by now you are realizing that you have wasted
a minute or two reading this documentation that you won't get back
again.

=head1 SEE ALSO

=over 4

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Fetch::Prompt>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
