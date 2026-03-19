# NAME

App::Workflow::Lint - Linter for GitHub Actions workflow files

# SYNOPSIS

    use App::Workflow::Lint;

    my $linter = App::Workflow::Lint->new;
    my @diagnostics = $linter->check_file('workflow.yml');

    # Or via CLI:
    #   workflow-lint check workflow.yml

# DESCRIPTION

`App::Workflow::Lint` provides the core interface for linting GitHub
Actions workflow files. It loads a workflow, applies a set of linting
rules, and returns diagnostics describing any issues found.

This module is used internally by the `workflow-lint` command-line tool,
but can also be used programmatically.

# METHODS

## new

    my $linter = App::Workflow::Lint->new(%opts);

Constructs a new linter instance.

## check\_file

    my @diagnostics = $linter->check_file($file);

Loads the workflow from `$file`, applies all linting rules, and returns
a list of diagnostics. Each diagnostic is a hashref describing the issue.

## fix\_file

    my ($workflow, $diagnostics) = $linter->fix_file($file);

Loads the workflow, applies all rules, executes any available fixes, and
returns the modified workflow structure along with the list of diagnostics.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

is\_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smartphones.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

# SEE ALSO

- [App::Test::Generator](https://metacpan.org/pod/App%3A%3ATest%3A%3AGenerator)

# REPOSITORY

[https://github.com/nigelhorne/App-Workflow-Lint](https://github.com/nigelhorne/App-Workflow-Lint)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-app-workflow-lint at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Workflow-Lint](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Workflow-Lint).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc App::Workflow::Lint

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/App-Workflow-Lint](https://metacpan.org/dist/App-Workflow-Lint)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Workflow-Lint](https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Workflow-Lint)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=App-Workflow-Lint](http://matrix.cpantesters.org/?dist=App-Workflow-Lint)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=App::Workflow::Lint](http://deps.cpantesters.org/?module=App::Workflow::Lint)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
