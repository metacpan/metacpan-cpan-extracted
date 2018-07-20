package BioSAILs::Command::version;

use v5.10;
use strict;
use warnings FATAL => 'all';
use MooseX::App::Command;
use namespace::autoclean;

use BioX::Workflow::Command;
use HPC::Runner::Command;
use BioSAILs::Command;
use MooseX::App::Plugin::Version::Command;

command_short_description 'Get the versions of BioX::Workflow::Command, HPC::Runner::Command, BioSAILs, and perl';
command_long_description 'Get the versions of BioX::Workflow::Command, HPC::Runner::Command, BioSAILs, and perl.' .
    ' Please be sure to include this information in any tickets.';

sub execute {
    my $self = shift;

    my $biox = BioX::Workflow::Command->new();
    my $hpc = HPC::Runner::Command->new();
    my $biosails = BioSAILs::Command->new();

#    my $moosex = MooseX::App::Plugin::Version::Command->new();

    my $envelope;
    $envelope = $self->perl_version($biosails);
    $envelope->print;

    $envelope = $self->version($biosails, 'BioSAILs');
    $envelope->print;
    $envelope = $self->version($biox, 'BioX-Workflow-Command');
    $envelope->print;
    $envelope = $self->version($hpc, 'HPC-Runner-Command');
    $envelope->print;
}

sub perl_version {
    my $self = shift;
    my $app = shift;

    my $message_class = $app->meta->app_messageclass;
    my $version = sprintf("%vd", $^V);

    my @parts = ($message_class->new({
        header => 'Perl Version',
        body   => MooseX::App::Utils::format_text($version)
    }));
    return MooseX::App::Message::Envelope->new(@parts);
}

sub version {
    my ($self, $app, $name) = @_;

    my $version = '';
    $version .= $name . ' ' . $app->VERSION . "\n";

    my $message_class = $app->meta->app_messageclass;

    my @parts = ($message_class->new({
        header => $name . ' Version',
        body   => MooseX::App::Utils::format_text($version)
    }));

    return MooseX::App::Message::Envelope->new(@parts);
}

__PACKAGE__->meta->make_immutable;

1;
