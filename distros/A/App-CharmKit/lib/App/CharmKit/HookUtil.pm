package App::CharmKit::HookUtil;
$App::CharmKit::HookUtil::VERSION = '2.07';
# ABSTRACT: Additional helper hook routines

use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';
use Rex::Commands::Run;
use FindBin;
use Module::Runtime qw(use_module);
use base "Exporter::Tiny";

our @EXPORT = qw(config resource unit status plugin);


sub config($key) {
    return run "config-get $key";
}


sub resource($key) {
    return run "resource-get $key";
}


sub unit($key) {
    return run "unit-get $key";
}



sub status ($level = "active", $msg = "Ready") {
    return run "status-set $level $msg";
}


sub plugin($name) {
    return use_module("$name");
}


1;

__END__

=pod

=head1 NAME

App::CharmKit::HookUtil - Additional helper hook routines

=over

=item config($key)

This queries the charms config

=item resource($key)

Pulls the resource bound to $key

=item unit($key)

Queries the Juju unit for a specific value

C<unit 'public-address';>

This above code would pull the public-address of the unit in the context of the
running charm

=item status($level, $msg)

Sets the charm's current status of execution

=item plugin($name)

Load a plugin

=back

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
