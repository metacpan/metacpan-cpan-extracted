package Code::TidyAll::Plugin::TSLint;

use strict;
use warnings;

our $VERSION = '1.000001';

use IPC::Run3 qw( run3 );
use Moo;

extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'tslint' }

# We use transform-file in order to support --fix
sub transform_file {
    my ( $self, $file ) = @_;

    my $cmd = join q{ }, $self->cmd, $self->argv, $file;

    my $output;
    run3( $cmd, \undef, \$output, \$output );
    if ( $? > 0 ) {
        $output ||= 'problem running ' . $self->cmd;
        die "$output\n";
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::TSLint - Use tslint with tidyall


=head1 SYNOPSIS

   In configuration:

   [TSLint]
   select = static/**/*.ts
   argv = -c $ROOT/.tslintrc --color

=head1 DESCRIPTION

Runs L<tslint|https://github.com/palantir/tslint>, pluggable linting utility
for TypeScript.

=head1 INSTALLATION

Install L<npm|https://npmjs.org/>, then run

    npm install tslint

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to tslint. Use C<--color> to force color output.

=item cmd

Full path to tslint

=back

=head1 CREDITS

Based on L<https://metacpan.org/release/Code-TidyAll-Plugin-ESLint> by
MaxMind, Inc. Modified by Shlomi Fish while disclaiming all rights.

=cut
