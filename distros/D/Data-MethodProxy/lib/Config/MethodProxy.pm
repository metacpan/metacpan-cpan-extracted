package Config::MethodProxy;

$Config::MethodProxy::VERSION = '0.03';

=head1 NAME

Config::MethodProxy - A backwards compatibility shim for Data::MethodProxy.

=head1 DESCRIPTION

This module's distribution has been renamed to C<Data-MethodProxy> and this
module itself has been turned into a shell of a shim over L<Data::MethodProxy>.

Use L<Data::MethodProxy> directly, not this module.

This module will be removed once a reasonable amount of time has passed and
any reverse dependencies have gone away or deamed ignorable.

=cut

use strict;
use warnings;

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

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

