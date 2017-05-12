## no critic (RequireUseStrict)
package Bash::Completion::Plugins::dzil;
{
  $Bash::Completion::Plugins::dzil::VERSION = '0.02';
}

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Bash::Completion::Plugins::App::Cmd';

use Bash::Completion::Utils qw(command_in_path);

sub should_activate {
    return [ grep { command_in_path($_) } qw(dzil) ];
}

sub command_class { 'Dist::Zilla::App' }

1;



=pod

=head1 NAME

Bash::Completion::Plugins::dzil - Bash::Completion support for Dist::Zilla

=head1 VERSION

version 0.02

=head1 DESCRIPTION

L<Bash::Completion> support for L<Dist::Zilla>.

=head1 SEE ALSO

L<Bash::Completion>, L<Dist::Zilla>

=begin comment

=over

=item should_activate

=item command_class

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/bash-completion-plugins-dzil/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Bash::Completion support for Dist::Zilla

