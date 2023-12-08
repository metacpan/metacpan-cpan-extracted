package App::Oozie::Deploy::Validate::Spec::Coordinator;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.016'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use Moo;
use MooX::Options;
use List::MoreUtils qw( uniq );
use App::Oozie::Types::Common qw( IsFile );
use App::Oozie::Constants qw( EMPTY_STRING );

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
    App::Oozie::Role::Validate::XML
);

sub verify {
    my $self   = shift;
    my $xml_in = shift;

    my($validation_errors, $total_errors);
    my $looper;

    $looper = sub  {
        my $hash = shift;
        my $non_utc = shift;
        my $wrong_parameters = shift;
        foreach my $key ( keys %{ $hash } ) {
            $non_utc->( $hash, $key );
            $wrong_parameters->( $hash, $key );
            my $value = $hash->{ $key };
            $looper->( $value, $non_utc, $wrong_parameters ) if ref $value eq 'HASH';
        }
        return;
    };

    my @non_utc_tz;
    my @restricted_properties;
    my @restricted_keys = qw/startTime endTime/;
    my %blacklist;
    @blacklist{@restricted_keys} = ();
    $looper->(
        $xml_in,
        sub {
            my($h, $key) = @_;
            return if $key ne 'timezone' || uc( $h->{$key} ) eq 'UTC';
            push @non_utc_tz, $h->{$key};
            return;
        },
        sub {
            my($h, $key) = @_;
            return if $key ne 'property';

            $self->validate_xml_property(
                \$validation_errors,
                \$total_errors,
                $h->{property},
            );

            for my $property ( @{ $h->{property} } ) {
              my $property_name = defined($property->{name})? $property->{name} : EMPTY_STRING;
              #if ($property_name eq 'startDate' || $property_name eq 'endDate') {
              if (exists $blacklist{$property_name}) {
                 push @restricted_properties, $h->{$key};
              }
            }
            return;
        }
    );

    if ( @non_utc_tz ) {
        my $msg = sprintf "\nThere are non-UTC time zone definitions in your coordinator: '%s'\n"
                         ."Which can result with off by one errors leading to fetching the wrong\n"
                         ."   month if you are doing/relying on further date operations like this.\n"
                         ."In that case you will need UTC in your time zone setting (where applicable).\n"
                         ,
                        join(q{', '}, uniq @non_utc_tz);
        $self->logger->warn( $msg );
    }

    if ( @restricted_properties ) {
        my $msg = sprintf "\nYou have declared restricted properties (startTime and/or endTime) in your coodinator.\n"
                         ."Please don't set up these properties, the oozie tools will handle them.\n"
                         ."If you have a good reason to set them, please contact #bigdata.\n"
                         ,
                        join(q{', '}, uniq @non_utc_tz);
        $self->logger->error( $msg );
        $validation_errors++;
    }

    return $validation_errors // 0, $total_errors // 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Validate::Spec::Coordinator

=head1 VERSION

version 0.016

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 NAME

App::Oozie::Deploy::Validate::Spec::Coordinator - Part of the Oozie Workflow validator kit.

=head1 Methods

=head2 verify

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
