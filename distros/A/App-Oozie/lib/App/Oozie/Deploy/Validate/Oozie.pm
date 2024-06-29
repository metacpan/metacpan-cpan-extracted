package App::Oozie::Deploy::Validate::Oozie;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.020'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Types::Common qw( IsExecutable );
use IPC::Cmd ();
use Moo;
use MooX::Options;
use Types::Standard qw( Num );

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
);

has oozie_cli => (
    is       => 'rw',
    isa      => IsExecutable,
    required => 1,
);

has oozie_uri => (
    is       => 'rw',
    required => 1,
);

sub validate {
    my $self = shift;
    my $oozie_xmlfile = shift || die 'No xml specified!';

    if ( ! -e $oozie_xmlfile ) {
        die "Not a file: $oozie_xmlfile";
    }

    my($validation_errors, $total_errors);

    $self->logger->info(
        sprintf 'Oozie validate for %s',
                $oozie_xmlfile,
    );

    my $oozie_uri = $self->oozie_uri;
    my $command   = [
        $self->oozie_cli,
        validate => $oozie_xmlfile,
    ];

    my($ok, $err, $full_buf, $stdout_buff, $stderr_buff);
    EXEC_VALIDATE: {
        # At least Oozie v4.1 does not seem to support an `-oozie` parameter
        # In the validate sub command args, hence the need to set the env var.
        #
        local $ENV{OOZIE_URL} = $oozie_uri if $oozie_uri;
        if ( $self->verbose && $oozie_uri ) {
            $self->logger->debug(
                sprintf 'Overriding the env var OOZIE_URL for validation only: %s',
                        $oozie_uri,
            );
        }
        ( $ok, $err, $full_buf, $stdout_buff, $stderr_buff ) = IPC::Cmd::run(
            command => $command,
            verbose => $self->verbose,
            timeout => $self->timeout,
        );
    }

    if ( !$ok ) {
        $validation_errors++;
        $total_errors++;
        my $msg = join "\n", @{
                   $stderr_buff
                || $stdout_buff
                || ["Timed out (can happen is the local host is overloaded)? Unknown error from @{$command}"]
                };
        $self->logger->error( $msg );
    }

    return $validation_errors // 0, $total_errors // 0;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Validate::Oozie

=head1 VERSION

version 0.020

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 NAME

App::Oozie::Deploy::Validate::Oozie - Part of the Oozie Workflow validator kit.

=head1 Methods

=head2 oozie_uri

=head2 validate

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
