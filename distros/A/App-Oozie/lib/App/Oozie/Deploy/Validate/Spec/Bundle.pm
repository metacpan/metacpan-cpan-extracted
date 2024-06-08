package App::Oozie::Deploy::Validate::Spec::Bundle;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use Moo;
use MooX::Options;
use List::MoreUtils qw( uniq );
use App::Oozie::Types::Common qw( IsFile );

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
);

sub verify {
    my $self   = shift;
    my $xml_in = shift;

    my($validation_errors, $total_errors);
    my $looper;
    $looper = sub  {
        my $hash = shift;
        my $cb   = shift;
        foreach my $key ( keys %{ $hash } ) {
            $cb->( $hash, $key );
            my $value = $hash->{ $key };
            $looper->( $value, $cb ) if ref $value eq 'HASH';
        }
        return;
    };

    my @non_utc_tz;
    $looper->(
        $xml_in,
        sub {
            my($h, $key) = @_;
            return if $key ne 'timezone' || uc( $h->{$key} ) eq 'UTC';
            push @non_utc_tz, $h->{$key};
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

    return $validation_errors // 0, $total_errors // 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Validate::Spec::Bundle

=head1 VERSION

version 0.017

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 NAME

App::Oozie::Deploy::Validate::Spec::Bundle - Part of the Oozie Workflow validator kit.

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
