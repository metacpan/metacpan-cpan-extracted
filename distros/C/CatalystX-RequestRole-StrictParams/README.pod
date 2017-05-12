package CatalystX::RequestRole::StrictParams;
use Moose::Role;
use Carp qw/croak/;

=head1 NAME

CatalystX::RequestRole::StrictParams - Insist users specify HTTP method for form parameters

=head1 DESCRIPTION

Insist users specify HTTP method for form parameters

=head1 SYNOPSIS

    package MyApp;

    use base 'Catalyst';
    use Catalyst;
    use CatalystX::RoleApplicator;

    __PACKAGE__->apply_request_class_roles('CatalystX::RequestRole::StrictParams');

=head1 EXPLANATION

Perl wrappers around the CGI protocol frequently make it too easy to write
exploitable code by conflating C<GET> and C<POST> parameters. Implementers
instead should be considering whether a given request is retrieving (I<GET>)
or modifying (I<POST>) data.

This role removes access to C<params>, C<parameters> and C<param> from
Catalyst request objects, forcing users to use C<body_parameters> and
C<query_parameters> instead.

=head1 WARNING

L<Cross-site Scripting|https://en.wikipedia.org/wiki/Cross-site_scripting>
vulnerabilities are easy to introduce, and often subtle. While using this
module reduces the threat surface a little, it in no way provides general
protection from all (or maybe even most) attacks.

=cut

# See: perldoc Carp
our @CARP_NOT;

# Methods we're intending to knock out
our @targets = qw/param parameters params/;

for my $target (@targets) {
    before $target => sub {
        my $self = shift;

        # Catalyst::Engine may call this as part of setup, and we want to
        # let it... We'll check for that by seeing if we can find
        # Catalyst::Engine in the callstack. We're as likely to find
        # Class::MOP::Method::Wrapped first, which we ignore.

        # Search the callers for the first class that isn't
        # Class::MOP::Method::Wrapped
        my $stack = 0;
        my @caller = caller( $stack++ );
        @caller = caller( $stack++ ) while
            $caller[0] eq 'Class::MOP::Method::Wrapped';
        my $package = $caller[0];

        # Don't allow the call unless the caller is Catalyst::Engine, which
        # implies this is happening at request preparation state.
        if (! $package->isa('Catalyst::Engine') ) {
            local @CARP_NOT = qw/Class::MOP::Method::Wrapped/;
            croak
                "'$target' encourages insecure code; please use either " .
                "body_parameters or query_parameters instead. For more " .
                "details: perldoc CatalystX::RequestRole::StrictParams";
        }
    };
}

=head1 SPONSORED BY

Initial development sponsored by NET-A-PORTER
L<http://www.net-a-porter.com/>, through their generous open-source support.

=head1 AUTHOR

Peter Sergeant - C<pete@clueball.com>

=cut

1;
