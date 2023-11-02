use v5.38;
use feature 'class';
no warnings qw(
    experimental::class
);

class CPANSEC::Admin::Command::New {
    method name { 'new' }

    method command ($manager, @args) {
        die 'not implemented yet';
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::New - create a new custom CPANSEC advisory.


=head1 SYNOPSIS

    cpansec-admin new

=head1 DESCRIPTION

This command lets you easily and interactively create new advisories and
set them up for triage.

=head1 ARGUMENTS

The 'new' command takes no arguments.