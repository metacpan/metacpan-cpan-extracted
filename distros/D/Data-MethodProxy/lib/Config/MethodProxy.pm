package Config::MethodProxy;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.05';

=encoding utf8

=head1 NAME

Config::MethodProxy - A backwards compatibility shim for Data::MethodProxy.

=head1 DESCRIPTION

This module's distribution has been renamed to C<Data-MethodProxy> and this
module itself has been turned into a shell of a shim over L<Data::MethodProxy>.

Use L<Data::MethodProxy> directly, not this module.

This module will be removed once a reasonable amount of time has passed and
any reverse dependencies have gone away or deamed ignorable.

=cut

use Data::MethodProxy;
use Exporter qw( import );

our @EXPORT = qw(
    apply_method_proxies
);

our @EXPORT_OK = qw(
    apply_method_proxies
    is_method_proxy
    call_method_proxy
);

our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

my $mproxy = Data::MethodProxy->new();

=head1 FUNCTIONS

Only the L</apply_method_proxies> function is exported by default.

=head2 apply_method_proxies

This calls L<Data::MethodProxy/render>.

=cut

sub apply_method_proxies {
    my ($data) = @_;
    local $Carp::Internal{ (__PACKAGE__) } = 1;
    return $mproxy->render( $data );
}

=head2 is_method_proxy

This calls L<Data::MethodProxy/is_valid>.

=cut

sub is_method_proxy {
    my ($proxy) = @_;
    return $mproxy->is_valid( $proxy );
}

=head2 call_method_proxy

This calls L<Data::MethodProxy/call>.

=cut

sub call_method_proxy {
    my ($proxy) = @_;
    local $Carp::Internal{ (__PACKAGE__) } = 1;
    return $mproxy->call( $proxy );
}

1;
__END__

=head1 SUPPORT

See L<Data::MethodProxy/SUPPORT>.

=head1 AUTHORS

See L<Data::MethodProxy/AUTHORS>.

=head1 LICENSE

See L<Data::MethodProxy/LICENSE>.

=cut

