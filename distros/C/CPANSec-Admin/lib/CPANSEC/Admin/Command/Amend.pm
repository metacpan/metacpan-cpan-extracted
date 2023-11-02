use v5.38;
use feature 'class';
no warnings qw(
    experimental::class
);

class CPANSEC::Admin::Command::Amend {
    method name { 'amend' }

    method command ($manager, @args) {
        die 'not implemented yet';
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::Amend - edits and amends a published CPANSEC advisory.


=head1 SYNOPSIS

    cpansec-admin amend  <filepath>

=head1 DESCRIPTION

This command lets you easily edit/amend published advisories.

=head1 ARGUMENTS

The 'amend' command takes no arguments except for a file path
pointing to the published advisory that will be edited.