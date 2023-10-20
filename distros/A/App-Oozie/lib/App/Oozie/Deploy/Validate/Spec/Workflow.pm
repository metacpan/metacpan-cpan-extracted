package App::Oozie::Deploy::Validate::Spec::Workflow;
$App::Oozie::Deploy::Validate::Spec::Workflow::VERSION = '0.010';
use 5.014;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use File::Basename;
use Moo;
use MooX::Options;
use Types::Standard qw( CodeRef );

my @JOB_TYPES_NEEDING_QUEUE = qw(
    fs
    hive
    java
    shell
    spark
    sqoop
    sub-workflow
);

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
);

has queue_conf_key_name => (
    is      => 'rw',
    default => sub { 'mapreduce.job.queuename' },
);

has file => (
    is       => 'rw',
    required => 1,
);

has file_size => (
    is      => 'ro',
    default => sub {
        my $file = shift->file;
        my $wf_size = (stat $file )[7] || die "$file either has zero size or I've failed to locate it";
        $wf_size;
    }
);

has max_wf_xml_length => (
    is       => 'rw',
    required => 1,
);

has max_node_name_len => (
    is       => 'rw',
    required => 1,
);

has email_validator => (
    is       => 'rw',
    required => 1,
    isa      => CodeRef,
);

has spec_queue_is_missing_message => (
    is      => 'rw',
    default => sub {
        <<'NO_QUEUE_MSG';
The action configuration property "%s" is not
defined for these action(s):

%s

You don't have to add it to each individually;
you can also add a global block which adds it to all
of your action nodes at once. Example:

    [% PROCESS workflow_global_xml_start %]
      <property>
        <name>mapreduce.job.queuename</name>
        <value> PUT YOUR QUEUE NAME HERE </value>
      </property>
    [% PROCESS workflow_global_xml_end %]

The [% ... %] tags are probably already in your
workflow.xml.

NO_QUEUE_MSG
    },
);

sub verify {
    my $self   = shift;
    my $xml_in = shift;

    my $file              = $self->file;
    my $wf_size           = $self->file_size;
    my $max_wf_xml_length = $self->max_wf_xml_length;
    my $max_node_name_len = $self->max_node_name_len;

    my($validation_errors, $total_errors);
    if ( $wf_size > $max_wf_xml_length ) {
        my $msg = sprintf <<'ETOOFAT', basename( $file ), $wf_size, $max_wf_xml_length;
Your %s has a size above the limit ( %s > %s )
please either modify it to reduce the size as
your job will fail anyway if you push it as-is.
ETOOFAT
        $self->logger->warn( $msg );
        $validation_errors++;
        $total_errors++;
    }
        # check any action contains root.default or root.mapred queue conf (spark,hive or shell)
        
	my $FH;
	my $validation_queue_check = 0;
        open $FH, '<', $file or die "Cannot open $file";
        while(my $String = <$FH>)
        {
          if($String =~ /(root.default)$/ || $String =~ /(root.mapred)$/ )
            {
              $self->logger->error( "FIXME !!! queue configuration parameter in workflow.xml is set to default or mapred; you are not allowed to deploy workflows in root.mapred or root.default queue." );
               $validation_errors++;
               $total_errors++;

            }
          if($String=~ /(mapreduce.job.queuename)/ || $String =~ /(spark.yarn.queue)/ )
            {
              $validation_queue_check++;
            }
        }
        if ( !$validation_queue_check )
            {
                $self->logger->error( "FIXME !!! queue configuration parameter in workflow.xml is not mentioned..Please set queue parameter either using --conf spark.yarn.queue or mapreduce.job.queuename. you are not allowed to deploy workflows in root.mapred or root.default queue." );
                $validation_errors++;
                $total_errors++;
            }

    my $prop        = $xml_in->{parameters} && $xml_in->{parameters}{property}
                        ? $xml_in->{parameters}{property}
                        : undef
                    ;
    my $global_prop = $xml_in->{global}
                        && $xml_in->{global}{configuration}
                        && $xml_in->{global}{configuration}{property}
                        ? $xml_in->{global}{configuration}{property}
                        : undef
                    ;

    $self->logger->info( "XML key validation for $file" );

    # check some values in the XML files
    # in workflow.xml, check errorEmailTo, various params, and display a warning

    my @contact_mail = map { $_->{value} } grep { $_->{name} eq 'errorEmailTo' } @$prop;

     # check if global conf parameter contains mapred or default queue configuration
        my @queue_array = map { $_->{value} } grep { $_->{name} =~ 'queuename' } @$global_prop;
        foreach my $queue_value (@queue_array) {
             if ($queue_value  =~ 'default' || $queue_value =~ 'mapred' ) {
              $self->logger->error( "FIXME !!! mapreduce.job.queuename parameter in workflow.xml is set to default or mapred; you are not allowed to deploy workflows in root.mapred or root.default queue" );
              $validation_errors++;
              $total_errors++;
          }
       }

    if ( ! @contact_mail ) {
        $self->logger->warn( "FIXME !!! no errorEmailTo parameter in workflow.xml; you will not get error emails" );
        $validation_errors++;
        $total_errors++;
    }
    else {
        my $validator = $self->email_validator;
        if ( ! $validator->( $self, @contact_mail ) ) {
            $self->logger->warn( sprintf "errorEmailTo=`%s` is invalid", @contact_mail );
            $validation_errors++;
            $total_errors++;
        }
    }

    if ( my $action = $xml_in->{action} ) {
        foreach my $name ( keys %{ $action } ) {
            my $len = length $name;
            next if $len <= $max_node_name_len;

            # See  https://issues.apache.org/jira/browse/OOZIE-2168
            my $msg = <<"LONG_ACTION_NAME";
FIXME !!! The action name is longer than $max_node_name_len characters (it is $len characters to be precise)

    $name

The restriction to $max_node_name_len characters is a hardcoded limit in the
Oozie Java code (and its MySQL metastore).

Plese rename it as your job will fail eventually at run time.

LONG_ACTION_NAME
            $self->logger->warn( $msg );
            $validation_errors++;
            $total_errors++;
        }
        my($action_validation_errors,
           $action_total_errors
        ) = $self->verify_queue_name( $action, $global_prop );
        $validation_errors += $action_validation_errors;
        $total_errors      += $action_total_errors;
    }

    return $validation_errors // 0, $total_errors // 0;
}

sub verify_queue_name {
    my($self, $action, $global_prop) = @_;

    my $logger = $self->logger;
    $logger->info( sprintf 'Verifying %s', $self->queue_conf_key_name );

    # check if workflow has defined queuname globally
    my $needs_verification =   ! $global_prop
                            || ! exists $global_prop->{ $self->queue_conf_key_name }
    ;

    if ( ! $needs_verification ) {
        $logger->info( sprintf 'There is a global setting for %s', $self->queue_conf_key_name );
        return 0, 0;
    }

    $logger->info(
        sprintf 'There is no global setting for "%s" defined in your workflow. The individual actions will now be verified instead.',
                $self->queue_conf_key_name
    );

    my($validation_errors, $total_errors);

    # mapreduce.job.queuename is not defined globally
    # check if action has queuename property defined or not
    my @offenders;

    if ( exists $action->{name} ) {
        # There are only single actions (XML::Simple issue)
        $action = { $action->{name} => $action };
    }

    foreach my $action_name (keys %{ $action } ) {
        my $action = $action->{$action_name};
        foreach my $job_type (
            grep { exists $action->{ $_ } }
                @JOB_TYPES_NEEDING_QUEUE
        ) {
            my $a_prop =  $action->{ $job_type }{configuration}
                            && $action->{ $job_type }{configuration}{property}
                        ? $action->{ $job_type }{configuration}{property}
                        : undef
                        ;
            if (
                ( ! $a_prop || ! exists $a_prop->{ $self->queue_conf_key_name } )
                &&
                ( ! exists $a_prop->{name} || $a_prop->{name} ne $self->queue_conf_key_name )
            ) {
                push @offenders, $action_name;
            }
            last;
        }
    }

    if ( @offenders ) {
        my $flat_list = sprintf "\t- %s\n",
                            join "\n\t- ",
                                    sort { lc $a cmp lc $b }
                                        @offenders;

        my $varname = $self->queue_conf_key_name;
        my $msg     = sprintf $self->spec_queue_is_missing_message,
                                $varname,
                                $flat_list,
                    ;

        $self->logger->warn( $msg );
        $validation_errors = $total_errors = @offenders;
    }

    return $validation_errors // 0, $total_errors // 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Validate::Spec::Workflow

=head1 VERSION

version 0.010

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 NAME

App::Oozie::Deploy::Validate::Spec::Workflow - Part of the Oozie Workflow validator kit.

=head1 Methods

=head2 file

=head2 file_size

=head2 max_node_name_len

=head2 max_wf_xml_length

=head2 queue_conf_key_name

=head2 spec_queue_is_missing_message

=head2 verify

=head2 verify_queue_name

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
