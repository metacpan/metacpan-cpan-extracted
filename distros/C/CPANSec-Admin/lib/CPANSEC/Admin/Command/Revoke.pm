use v5.38;
use feature 'class';
no warnings qw(
    experimental::class
);

class CPANSEC::Admin::Command::Revoke {
    method name { 'revoke' }

    method command ($manager, @args) {
        die 'not implemented yet';
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::Revoke - revokes and withdraws a published CPANSEC advisory.


=head1 SYNOPSIS

    cpansec-admin revoke  <filepath>

=head1 DESCRIPTION

This command lets you easily revoke advisories that have been
wrongfully published.

=head1 ARGUMENTS

The 'revoke' command takes no arguments except for a file path
pointing to the published advisory that will be revoked.