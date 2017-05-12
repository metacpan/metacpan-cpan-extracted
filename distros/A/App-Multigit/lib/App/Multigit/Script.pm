package App::Multigit::Script;

use strict;
use warnings;
use 5.014;

use Getopt::Long qw(:config gnu_getopt pass_through require_order);
use Pod::Usage qw(pod2usage);

our $VERSION = '0.18';

=head1 NAME

App::Multigit::Script - Common behaviour for scripts

=head1 DESCRIPTION

If you use App::Multigit::Script, some things are taken care of for you, and
some things can be done on request.

=head1 AUTOMATIC BEHAVIOUR

The default behaviour is to

=over

=item Use L<Getopt::Long> to handle C<--workdir>. This changes directory and is
part of the internal communication between C<mg> itself and your script.

=item Also handle C<--help>, by running Pod::Usage against your script.

=item Read C<STDIN> for a list of directories to work against, if appropriate

=back

=head1 FUNCTIONS

=head2 import

Not your common or garden import. This does the aforementioned things, and
exports a C<%options> into your script's namespace (i.e. C<main>).

=cut

sub import {
    my $package = (caller)[0];
    read_stdin();
    my %options = get_default_options($package);
    chdir $options{workdir};
    _install_symbol( \%options, $package, 'options');
}

=head2 get_default_options

Returns a hash containing the standard options for all C<mg> scripts.

=cut

sub get_default_options {
    my $package = shift;
    my %options = (
        help => sub {
            pod2usage({
                -exitval => 0,
                -verbose => 1,
            });
        }
    );

    GetOptions(
        \%options,
        'workdir=s',
        'help'
    );

    return %options;
}

=head2 read_stdin

If STDIN is connected to a pipe or something, this slurps it and uses it as the
list of selected repos. See 
L<@SELECTED_REPOS in App::Multigit|App::Multigit/@SELECTED_REPOS>.

=cut

sub read_stdin {
    if (-p STDIN) {
        no warnings 'once';
        chomp(@App::Multigit::SELECTED_REPOS = <STDIN>);
    }
}

# installs symbol $ref into package $package as symbol name $name.
sub _install_symbol {
    my ($ref, $package, $name) = @_;

    no strict 'refs';
    *{ $package . '::' . $name } = $ref;
}

1;

=head1 AUTHOR

Alastair McGowan-Douglas, C<< <altreus at perl.org> >>

=head1 BUGS

Please report bugs on the github repository L<https://github.com/Altreus/App-Multigit>.

=head1 LICENSE

Copyright 2015 Alastair McGowan-Douglas.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
