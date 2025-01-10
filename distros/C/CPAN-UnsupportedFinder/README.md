# NAME

CPAN::UnsupportedFinder - Identify unsupported or poorly maintained CPAN modules

# DESCRIPTION

CPAN::UnsupportedFinder analyzes CPAN modules for test results and maintenance status, flagging unsupported or poorly maintained distributions.

# VERSION

Version 0.05

# SYNOPSIS

    use CPAN::UnsupportedFinder;

    # Note use of hyphens not colons
    my $finder = CPAN::UnsupportedFinder->new(verbose => 1);
    my $results = $finder->analyze('Some-Module', 'Another-Module');

    for my $module (@$results) {
          print "Module: $module->{module}\n";
          print "Failure Rate: $module->{failure_rate}\n";
          print "Last Update: $module->{last_update}\n";
    }

# METHODS

## new

Creates a new instance. Accepts the following arguments:

- verbose

    Enable verbose output.

- api\_url

    metacpan URL, defaults to [https://fastapi.metacpan.org/v1](https://fastapi.metacpan.org/v1)

- cpan\_testers

    CPAN testers URL, detaults to [https://api.cpantesters.org/api/v1](https://api.cpantesters.org/api/v1)

- logger

    Where to log messages, defaults to [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)

## analyze(@modules)

Analyzes the provided modules. Returns an array reference of unsupported modules.

## output\_results

    $report = $object->output_results($results, $format);

Generates a report in the specified format.

- `$results` (ArrayRef)

    An array reference containing hashrefs with information about modules (module name, failure rate, last update)
    as created by the analyze() method.

- `$format` (String)

    A string indicating the desired format for the report. Can be one of the following:

    - `text` (default)

        Generates a plain text report.

    - `html`

        Generates an HTML report.

    - `json`

        Generates a JSON report.

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

# BUGS

The cpantesters api, [https://api.cpantesters.org/](https://api.cpantesters.org/), is currently unavailable,
so the routine \_has\_recent\_tests() currently always returns 1.

# LICENCE

This program is released under the following licence: GPL2
