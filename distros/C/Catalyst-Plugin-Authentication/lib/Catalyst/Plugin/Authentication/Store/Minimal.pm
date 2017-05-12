package Catalyst::Plugin::Authentication::Store::Minimal;

use strict;
use warnings;
use MRO::Compat;

use Catalyst::Authentication::Store::Minimal ();

## backwards compatibility
sub setup {
    my $c = shift;

    ### If a user does 'use Catalyst qw/Authentication::Store::Minimal/'
    ### he will be proxied on to this setup routine (and only then --
    ### non plugins should NOT have their setup routine invoked!)
    ### Beware what we pass to the 'new' routine; it wants
    ### a config has with a top level key 'users'. New style
    ### configs do not have this, and split by realms. If we
    ### blindly pass this to new, we will 1) overwrite what we
    ### already passed and 2) make ->userhash undefined, which
    ### leads to:
    ###  Can't use an undefined value as a HASH reference at
    ###  lib/Catalyst/Authentication/Store/Minimal.pm line 38.
    ###
    ### So only do this compatibility call if:
    ### 1) we have a {users} config directive
    ###
    ### Ideally we could also check for:
    ### 2) we don't already have a ->userhash
    ### however, that's an attribute of an object we can't
    ### access =/ --kane

    my $cfg = $c->config->{'Plugin::Authentication'}->{users}
                ? $c->config->{'Plugin::Authentication'}
                : undef;

    $c->default_auth_store( Catalyst::Authentication::Store::Minimal->new( $cfg, $c ) ) if $cfg;

    $c->next::method(@_);
}

foreach my $method (qw/ get_user user_supports find_user from_session /) {
    no strict 'refs';
    *{$method} = sub { __PACKAGE__->default_auth_store->$method( @_ ) };
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::Minimal - Compatibility shim

=head1 DESCRIPTION

THIS IS A COMPATIBILITY SHIM.  It allows old configurations of Catalyst
Authentication to work without code changes.  

B<DO NOT USE IT IN ANY NEW CODE!>

Please see L<Catalyst::Authentication::Store::Minimal> for more information.

=head1 METHODS

=over

=item find_user

=item from_session

=item get_user

=item setup

=item user_supports

=back

=cut
