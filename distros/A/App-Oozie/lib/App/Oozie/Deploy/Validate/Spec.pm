package App::Oozie::Deploy::Validate::Spec;
$App::Oozie::Deploy::Validate::Spec::VERSION = '0.006';
use 5.010;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Deploy::Validate::Oozie;
use App::Oozie::Deploy::Validate::DAG::Workflow;
use App::Oozie::Deploy::Validate::Spec::Coordinator;
use App::Oozie::Deploy::Validate::Spec::Workflow;
use App::Oozie::Types::Common qw( IsExecutable );
use App::Oozie::Deploy::Validate::Spec::Bundle;
use App::Oozie::Types::Common;
use App::Oozie::XML;
use File::Basename;
use File::Find::Rule;
use File::Path;
use File::Spec;
use Moo;
use MooX::Options;
use Text::Trim      qw( trim );
use Types::Standard qw( Num CodeRef );

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
);

has local_path => (
    is       => 'rw',
    required => 1,
);

has max_wf_xml_length => (
    is       => 'rw',
    required => 1,
);

has max_node_name_len => (
    is       => 'rw',
    required => 1,
);

has oozie_cli => (
    is      => 'rw',
    isa     => IsExecutable,
    required => 1,
);

has oozie_client_jar => (
    is       => 'rw',
    required => 1,
);

has oozie_uri => (
    is      => 'rw',
    required => 1,
);

has email_validator => (
    is => 'rw',
    required => 1,
    isa => CodeRef,
);

has spec_queue_is_missing_message => (
    is => 'rw',
);

sub maybe_parse_xml {
    my $self     = shift;
    my $xml_file = shift;
    my $dest     = $self->local_path;

    my $relative_file_name = File::Spec->abs2rel( $xml_file, $dest );

    my @lines = do {
        open my $FH, '<', $xml_file or die "Failed to read $xml_file: $!";
        my @rv = <$FH>;
        close $FH;
        @rv;
    };

    for my $bogus ( grep { m{ (?:ARRAY|HASH)[(]0x[a-fA-F0-9]+[)] }xms } @lines ) {
        $self->logger->warn(
            "=> [$relative_file_name] There seems to be a template error around: ",
            trim( $bogus ),
        );
    }

    my %default_rv = (
        relative_file_name => $relative_file_name,
    );

    my ($xml_in, $localname);
    eval {
        my $xml = App::Oozie::XML->new(
                        data             => join('', @lines),
                        oozie_client_jar => $self->oozie_client_jar,
                        verbose          => $self->verbose,
                    );
        $localname = $xml->localname;
        $xml_in    = $xml->data;
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        return {
            %default_rv,
            error => $eval_error,
        };
    };

    return {
        %default_rv,
        localname => $localname,
        xml_in    => $xml_in,
    };
}

sub local_xml_files {
    my $self = shift;
    my $dest = $self->local_path;
    File::Find::Rule
            ->file
            ->maxdepth( 1       )
            ->name(     '*.xml' )
            ->in(       $dest   )
    ;
}

sub verify {
    my $self    = shift;
    my $dest    = $self->local_path;
    my $verbose = $self->verbose;
    my $logger  = $self->logger;

    my $ov = App::Oozie::Deploy::Validate::Oozie->new(
                map { $_ => $self->$_ }
                    qw(
                        oozie_cli
                        oozie_uri
                        timeout
                        verbose
                    )
            );

    my $validation_errors = 0;
    my $total_errors = 0;

    my @xml_files = $self->local_xml_files;

    $logger->info('Validating xml files within workflow directory.');

    for my $xml_file ( @xml_files ) {
        # Possible improvements
        #
        #  i) let the XML parser filter snippet documents
        # ii) or even validate the basic syntax for such documents
        #        and skip Oozie schema checks (which will fail)
        #
        if (index($xml_file, "common_datasets.xml") != -1) {
            next;
        }
        my $oozie_cli_validation = 1;

        my $parsed             = $self->maybe_parse_xml( $xml_file );
        my $relative_file_name = $parsed->{relative_file_name};

        if ( my $error = $parsed->{error} ) {
            $logger->fatal("We can't validate $relative_file_name since parsing failed: ", $error );
            $validation_errors++;
            $total_errors++;
            next; #we don't even have valid XML file at this point, so just skip it
        };

        my($xml_in, $localname) = @{ $parsed }{qw/ xml_in localname /};

        if( $localname eq "workflow-app" ) {
            $logger->info("$relative_file_name identified as workflow-app.");
            eval {
                my ($wf_validation_errors,
                    $wf_total_errors,
                ) = App::Oozie::Deploy::Validate::Spec::Workflow->new(
                        file => $xml_file,
                        ( map { $_ => $self->$_ } qw(
                            email_validator
                            max_node_name_len
                            max_wf_xml_length
                            spec_queue_is_missing_message
                            verbose
                        ) ),
                    )->verify( $xml_in );

                $validation_errors += $wf_validation_errors;
                $total_errors      += $wf_total_errors;

                # check the DAG is OK
                my $dag = App::Oozie::Deploy::Validate::DAG::Workflow->new;
                my @dag_errors = $dag->validate( $xml_file );

                if ( @dag_errors ) {
                    $validation_errors += @dag_errors;
                    $total_errors      += @dag_errors;

                    my $warn_tmpl = 'DAG validation failed: %s';
                    for my $tuple ( @dag_errors ) {
                        my($error, $meaning) = @{ $tuple };
                        $self->logger->warn( sprintf $warn_tmpl, $error   );
                        $self->logger->warn( sprintf $warn_tmpl, $meaning );
                    }
                }

                1;
            } or do {
                $logger->warn(
                    sprintf "Unable to validate `%s` as workflow-app. Please consider fixing the error: %s",
                                $relative_file_name,
                                $@,
                );
                next;
            };
        } elsif( $localname eq "coordinator-app" ) {
            $logger->info("$relative_file_name identified as coordinator-app.");
            eval {
                my ($coord_validation_errors,
                    $coord_total_errors,
                ) = App::Oozie::Deploy::Validate::Spec::Coordinator->new(
                    verbose => $verbose,
                )->verify( $xml_in );

                $validation_errors += $coord_validation_errors;
                $total_errors      += $coord_total_errors;

                1;
            } or do {
                $logger->warn(
                    sprintf "Unable to validate `%s` as coordinator-app. Please consider fixing error: %s",
                                $relative_file_name,
                                $@,
                );
                next;
            };
        } elsif( $localname eq "bundle-app" ) {
            $logger->info("$relative_file_name identified as bundle-app.");
            eval {
                my ($bundle_validation_errors,
                    $bundle_total_errors,
                ) = App::Oozie::Deploy::Validate::Spec::Bundle->new(
                    verbose => $verbose,
                )->verify( $xml_in );

                $validation_errors += $bundle_validation_errors;
                $total_errors      += $bundle_total_errors;

                1;
            } or do {
                $logger->warn(
                    sprintf "Unable to validate `%s` as bundle-app. Please consider fixing error: %s",
                                $relative_file_name,
                                $@,
                );
                next;
            };
        } else { # we can't identify it and validate, so just yield a warning
            $oozie_cli_validation = 0;
            $logger->fatal(
                sprintf "We can't validate `%s` since it doesn't look like either workflow-app, coordinator-app or bundle-app.",
                            $relative_file_name,
            );
            $validation_errors++;
            $total_errors++;
        }

        if($oozie_cli_validation) {
            my($ooz_validation_errors, $ooz_total_errors) = $ov->validate( $xml_file );
            $validation_errors += $ooz_validation_errors;
            $total_errors      += $ooz_total_errors;
        }
    }

    return $validation_errors, $total_errors;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Validate::Spec

=head1 VERSION

version 0.006

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 NAME

App::Oozie::Deploy::Validate::Spec - Part of the Oozie Workflow validator kit.

=head1 Methods

=head2 local_path

=head2 local_xml_files

=head2 max_node_name_len

=head2 max_wf_xml_length

=head2 maybe_parse_xml

=head2 oozie_client_jar

=head2 oozie_uri

=head2 spec_queue_is_missing_message

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
