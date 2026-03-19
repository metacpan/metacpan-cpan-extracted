package App::Workflow::Lint;

use strict;
use warnings;
use Carp qw(croak carp);

use App::Workflow::Lint::Engine;

# VERSION MUST be simple for MakeMaker to parse
our $VERSION = '0.01';

=head1 NAME

App::Workflow::Lint - Linter for GitHub Actions workflow files

=head1 SYNOPSIS

  use App::Workflow::Lint;

  my $linter = App::Workflow::Lint->new;
  my @diagnostics = $linter->check_file('workflow.yml');

  # Or via CLI:
  #   workflow-lint check workflow.yml

=head1 DESCRIPTION

C<App::Workflow::Lint> provides the core interface for linting GitHub
Actions workflow files. It loads a workflow, applies a set of linting
rules, and returns diagnostics describing any issues found.

This module is used internally by the C<workflow-lint> command-line tool,
but can also be used programmatically.

=head1 METHODS

=head2 new

  my $linter = App::Workflow::Lint->new(%opts);

Constructs a new linter instance.

=head2 check_file

  my @diagnostics = $linter->check_file($file);

Loads the workflow from C<$file>, applies all linting rules, and returns
a list of diagnostics. Each diagnostic is a hashref describing the issue.

=head2 fix_file

  my ($workflow, $diagnostics) = $linter->fix_file($file);

Loads the workflow, applies all rules, executes any available fixes, and
returns the modified workflow structure along with the list of diagnostics.

=cut

#----------------------------------------------------------------------
# Constructor
#----------------------------------------------------------------------
sub new {
	my ($class, %opts) = @_;
	return bless { %opts }, $class;
}

#----------------------------------------------------------------------
# check_file($path)
#
# Convenience wrapper around the engine. Loads the workflow file,
# runs all rules, and returns a list of diagnostics.
#----------------------------------------------------------------------
sub check_file {
	my ($self, $file) = @_;
	croak "check_file() requires a filename" unless defined $file;

	my $engine = App::Workflow::Lint::Engine->new(%$self);
	return $engine->check_file($file);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

is_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smartphones.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

=head1 SEE ALSO

=over 4

=item * L<App::Test::Generator>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/App-Workflow-Lint>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-app-workflow-lint at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Workflow-Lint>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc App::Workflow::Lint

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/App-Workflow-Lint>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Workflow-Lint>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=App-Workflow-Lint>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=App::Workflow::Lint>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
