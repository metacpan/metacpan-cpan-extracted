package App::Oozie::Role::Validate::XML;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.020'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw( EMPTY_STRING );
use Moo::Role;

sub validate_xml_property {
    my $self                  = shift;
    my $validation_errors_ref = shift;
    my $total_errors_ref      = shift;
    my $prop                  = shift || return;
    my $type                  = shift || EMPTY_STRING;

    my $logger  = $self->logger;
    my $verbose = $self->verbose;

    $type = "$type " if $type;

    for my $param ( @{ $prop } ) {
        my($name, $value) = @{ $param }{ qw/
            name   value
        / };

        if ( $verbose ) {
            $logger->debug(
                sprintf 'Validating property `%s`: `%s`',
                            $name,
                            $value // '[undef]',
            );
        }

        # A special case in global template injection
        if ( $name eq 'do.not.remove' ) {
            $logger->debug(
                sprintf 'Skipping special property `%s`',
                            $name,
            ) if $verbose;
            next;
        }

        my $msg;

        if ( $value ) {
            # Check the possible free form XML problem.
            $value =~ s{ \A \s+     }{}xmsg;
            $value =~ s{    \s+  \z }{}xmsg;

            if ( $value ) {
                if ( $verbose ) {
                    $logger->debug(
                        sprintf 'The property `%s` has a value',
                                    $name,
                    );
                }
                next;
            }
            else {
                if ( $verbose ) {
                    $logger->debug(
                        sprintf 'The property `%s` was set to empty data',
                                    $name,
                    );
                }
            }

            $msg = 'The XML %sproperty `%s` does not have a value (set to spaces), which might cause something to fail!';
        }
        else {
            $msg = 'The XML %sproperty `%s` does not have a value, which might cause something to fail!';
        }

        # empty
        $logger->warn( sprintf $msg, $type, $name );

        # TODO:
        # Only report but don't take action for now.
        # Needs more testing before this part can be enabled.
        # ${ validation_errors_ref }++;
        # ${ total_errors_ref }++;
    }

    return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Role::Validate::XML

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Moo::Role;
    with 'App::Oozie::Role::Validate::XML';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie validators.

=head1 NAME

App::Oozie::Role::Validate::XML - Internal role for validators.

=head1 Methods

=head2 validate_xml_property

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
