use strict;
use warnings;

package App::Cmd::Command::version 0.337;

use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command'; }

# ABSTRACT: display an app's version

#pod =head1 DESCRIPTION
#pod
#pod This command will display the program name, its base class
#pod with version number, and the full program name.
#pod
#pod =cut

sub command_names { qw/version --version/ }

sub version_for_display {
  $_[0]->version_package->VERSION
}

sub version_package {
  ref($_[0]->app)
}

sub execute {
  my ($self, $opts, $args) = @_;

  printf "%s (%s) version %s (%s)\n",
    $self->app->arg0, $self->version_package,
    $self->version_for_display, $self->app->full_arg0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cmd::Command::version - display an app's version

=head1 VERSION

version 0.337

=head1 DESCRIPTION

This command will display the program name, its base class
with version number, and the full program name.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
