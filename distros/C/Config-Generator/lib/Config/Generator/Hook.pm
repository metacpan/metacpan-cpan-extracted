#+##############################################################################
#                                                                              #
# File: Config/Generator/Hook.pm                                               #
#                                                                              #
# Description: Config::Generator hook support                                  #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Hook;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Log qw(log_debug);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate_pos :types);

#
# global variables
#

our(%_Registered);

#
# register a hook in a category
#

my @register_hook_options = (
    { type => SCALAR, regex => qr/^(check|generate)$/ },
    { type => CODEREF },
);

sub register_hook ($$) {
    my($category, $hook) = validate_pos(@_, @register_hook_options);

    push(@{ $_Registered{$category} }, $hook);
}

#
# run all the hooks in a category
#

my @run_hooks_options = (
    $register_hook_options[0],
);

sub run_hooks ($) {
    my($category) = validate_pos(@_, @run_hooks_options);

    log_debug("running the %s hooks...", $category);
    foreach my $hook (@{ $_Registered{$category} }) {
        $hook->();
    }
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(register_hook run_hooks));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::Hook - Config::Generator hook support

=head1 DESCRIPTION

This module eases the manipulation of the hooks (i.e. code references) that
are used internally by the B<yacg> command.

The C<check> hooks are executed (in module dependency order) after the high
level configuration has been read (and partially validated) but before it has
been used. These hooks usually perform additional validation (not performed by
the schema based validation) and set default values.

The C<generate> hooks are executed after the final high level configuration
validation. These hooks usually generate files, mainly with the help of the
L<Config::Generator::File> module.

Here is what the B<yacg> command does, in order:

=over

=item 1. read and partially validate the configuration

=item 2. run the C<check> hooks

=item 3. perform the final configuration validation

=item 4. run the C<generate> hooks

=item 5. cleanup (e.g. handle the "manifest" file)

=back

Note: module dependencies are handled by Perl when it loads them so the hooks
will be executed in the correct order: the C<check> hook of a given module
will be executed after the C<check> hooks of all the modules it depends on.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item register_hook(C<check>|C<generate>, CODE)

register the given C<check> or C<generate> hook

=item run_hooks(C<check>|C<generate>)

run all the previously registered C<check> or C<generate> hooks

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
