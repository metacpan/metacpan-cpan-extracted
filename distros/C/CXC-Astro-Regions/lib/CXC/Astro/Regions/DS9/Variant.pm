package CXC::Astro::Regions::DS9::Variant;

# ABSTRACT: Generate DS9 Region classes

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.02';

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
    my $props  = $args{props}  // [];
    $region = $args{name} // $region;

    extends $args{extends}->@* if $args{extends} && $args{extends}->@*;

    # if a region has a text *parameter*, don't add a text *property*
    my $has_text_param;

    my @private = qw( label format render );

    for my $arg ( $params->@* ) {
        my %has = ( is => 'ro', required => 1, $arg->%* );
        my ( $name ) = delete @has{ 'name', @private };
        has $name => %has;
        $has_text_param = !!1 if $name eq 'text';
    }

    for my $arg ( $props->@* ) {
        my %has = ( is => 'ro', required => 0, $arg->%* );
        my ( $name ) = delete @has{ 'name', @private };
        next if $has_text_param && $name eq 'text';
        has $name => %has;
    }

    install render => sub ( $self ) {
        my @output;
        push @output, q{#} if $args{comment};
        push @output, ( $self->include ? q{} : q{-} ) . $region;
        push @output, params( $self, $params );
        my @props = props( $self, $props, has_text_param => $has_text_param );

        push @output, q{#}, @props if @props;

        return join q{ }, @output;
    };

    around $args{around}->@* if $args{around} && $args{around}->@*;
    with $args{with}->@*     if $args{with}   && $args{with}->@*;

}

sub params ( $self, $params ) {
    my @output;

    for my $param ( $params->@* ) {

        # if the caller doesn't want this rendered, don't
        next if !( $param->{render} // !!1 );

        my $name   = $param->{name};
        my @values = ( $self->$name );
        next if !defined $values[0];

        if ( defined( my $format = $param->{format} ) ) {
            push @output, $format->( 'param', $name, \@values );
            next;
        }

        my @param_values;

        while ( @values ) {
            my $value = shift @values;
            if ( is_arrayref( $value ) ) {
                unshift @values, $value->@*;
                next;
            }
            push @param_values, $value;
        }

        if ( @param_values == 1 && defined( my $label = $param->{label} ) ) {
            push @output, $label . q{=} . $param_values[0];
        }
        else {
            push @output, @param_values;
        }
    }

    return @output;
}

sub props ( $self, $props, %args ) {

    my @output;

    for my $prop ( $props->@* ) {

        # if the caller doesn't want this rendered, don't
        next if !( $prop->{render} // !!1 );

        my $name = $prop->{name};

        next if $name eq 'include';    # this results in a prefix to the
                                       # start of the region spec

        next if $name eq 'text' && $args{has_text_param};

        my $label  = exists $prop->{label} ? $prop->{label} : $name;
        my @values = ( grep defined, $self->$name );
        next unless @values;

        if ( defined( my $format = $prop->{format} ) ) {
            push @output, $format->( 'prop', $label, \@values );
            next;
        }

        my @prop_values;

        while ( @values ) {
            my $value = shift @values;
            if ( is_arrayref( $value ) ) {
                unshift @values, $value->@*;
                next;
            }
            push @prop_values, $value;
        }

        if ( @prop_values ) {

            if ( !defined $label ) {
                push @output, @prop_values;
            }
            elsif ( @prop_values == 1 ) {
                push @output, $label . q{=} . $prop_values[0];
            }
            else {
                push @output, "$label=" if defined $label;
                push @output, @prop_values;
            }
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

CXC::Astro::Regions::DS9::Variant - Generate DS9 Region classes

=head1 VERSION

version 0.02

=head1 INTERNALS

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
