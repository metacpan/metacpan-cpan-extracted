package CXC::Astro::Regions::CIAO::Variant;

# ABSTRACT: Generate CIAO Region classes

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.03';

use Module::Runtime 'module_notional_filename';
use Ref::Util qw( is_arrayref );


use Package::Variant
  importing => [ 'Moo', 'MooX::StrictConstructor' ],
  subs      => [qw( has extends around with )];

use constant PREFIX => __PACKAGE__ =~ s/[^:]+$//r;

sub _croak {
    require Carp;
    goto \&Carp::croak;
}


sub make_variant_package_name ( $, $package, % ) {
    return PREFIX . ucfirst( $package );
}


sub make_variant ( $, $, $region, %args ) {

    my $params = $args{params} // [];
    $region = $args{name} // $region;

    extends $args{extends}->@* if $args{extends} && $args{extends}->@*;

    my @private = qw( label );

    for my $arg ( $params->@* ) {
        my %has = ( is => 'ro', required => 1, $arg->%* );
        my ( $name ) = delete @has{ 'name', @private };
        has $name => %has;
    }

    install render => sub ( $self ) {
        return sprintf( '%s(%s)', $region, join( q{,}, params( $self, $params ) ) );
    };

    around $args{around}->@* if $args{around} && $args{around}->@*;
    with $args{with}->@*     if $args{with}   && $args{with}->@*;

}

sub params ( $self, $params ) {
    my @output;

    for my $param ( $params->@* ) {

        my $name   = $param->{name};
        my @values = ( $self->$name );
        next if !defined $values[0];

        while ( @values ) {
            my $value = shift @values;
            if ( is_arrayref( $value ) ) {
                unshift @values, $value->@*;
                next;
            }
            push @output, $value;
        }
    }

    return @output;
}


1;

#
# This file is part of CXC-Astro-Regions
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Astro::Regions::CIAO::Variant - Generate CIAO Region classes

=head1 VERSION

version 0.03

=for Pod::Coverage make_variant
make_variant_package_name
params
props

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-astro-regions@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Astro-Regions>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-astro-regions

and may be cloned from

  https://gitlab.com/djerius/cxc-astro-regions.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Astro::Regions|CXC::Astro::Regions>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
