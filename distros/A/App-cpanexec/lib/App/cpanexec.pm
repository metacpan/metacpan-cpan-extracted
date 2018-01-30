package App::cpanexec;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.09";



1;
__END__

=encoding utf-8

=head1 NAME

App::cpanexec - Execute application within local environment.

=head1 SYNOPSIS

    cpane myscript arg1 arg2 ...

    cpane plackup hello.psgi

    cpane env

=head1 DESCRIPTION

The program C<cpane> executes command within the local environment.

Perl package managers like L<Carton> or L<cpm> install the dependencies into
C<local> folder near the C<cpanfile>.

The library L<local::lib> prepares appropriate environment for executing script
or executable program within such local environment. However it is necessary
to do some passes to configure such environment and configured environment
need to be deconfigured.

This program C<cpane> requires command line passed as its arguments. The command
line may be script installed in local folder or generic executable may be with
arguments. It runs passed command line in the local environment configured for
the current dir and does not modify current environment. Folder C<local> must
be exists in current dir.

The C<cpane> may be used with Carton or cpm or without it. It works like
C<exec> subcommand of ruby L<bundler|http://bundler.io/man/bundle-exec.1.html>
or perl L<Carton> or like C<run> subcommand of node
L<npm|https://docs.npmjs.com/cli/run-script>. It configures runtime
environments accordings to the generaly accepted perl workflows provided by
L<local::lib>.

=head1 DEPENDENCIES

L<local::lib>

=head1 SEE ALSO

L<Carton>

L<cpm>

L<perlrocks>

L<cpanfile>

L<bundler|http://bundler.io/man/bundle-exec.1.html>

L<npm|https://docs.npmjs.com/cli/run-script>

=head1 LICENSE

MIT

=head1 AUTHOR

Serguei Okladnikov E<lt>oklaspec@gmail.comE<gt>

=cut

