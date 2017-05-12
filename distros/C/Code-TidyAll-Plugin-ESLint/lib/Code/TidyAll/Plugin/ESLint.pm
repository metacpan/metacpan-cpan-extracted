package Code::TidyAll::Plugin::ESLint;

use strict;
use warnings;

our $VERSION = '1.000000';

use IPC::Run3 qw( run3 );
use Moo;

extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'eslint' }

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

Code::TidyAll::Plugin::ESLint - Use eslint with tidyall


=head1 SYNOPSIS

   In configuration:

   [ESLint]
   select = static/**/*.js
   argv = -c $ROOT/.eslintrc --color

=head1 DESCRIPTION

Runs L<eslint|http://eslint.org//>, pluggable linting utility for JavaScript
and JSX.

=head1 INSTALLATION

Install L<npm|https://npmjs.org/>, then run

    npm install eslint

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to eslint. Use C<--color> to force color output.

=item cmd

Full path to eslint

=back

=cut
