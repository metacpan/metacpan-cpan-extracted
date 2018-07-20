use strict;
use warnings;
package BioSAILs::Command::get_help;

use MooseX::App::Command;
use MooseX::App::Plugin::Version::Command;
use namespace::autoclean;

command_short_description 'A few helper urls';

sub execute {
    my $self = shift;
    my $envelope;
    my $biosails = BioSAILs::Command->new();

    #General
    $envelope = $self->render_message(
        $biosails,
        'General Help',
        "Please see the website at :\nhttp://biosails.abudhabi.nyu.edu/\n" .
            "From the website you can view workflows, ask for help from the forums, and view the complete documentation."
    );
    $envelope->print;

    #    There is a JIRA issue open to get the ajaxy urls on the website to reference actual things
    #    #Find Workflows
    #    $envelope =  $self->render_message(
    #        $biosails,
    #        'In House Workflows',
    #        "In house workflows are available at:\n".
    #        'https://biosails.abudhabi.nyu.edu/biosails/index.php/templates/'
    #    );
    #    $envelope->print;
    #
    #    #Documentation
    #    $envelope =  $self->render_message(
    #        $biosails,
    #        'Documentation',
    #        "Please see the complete documentation at:\n".
    #        'https://biosails.abudhabi.nyu.edu/biosails/index.php/templates/'
    #    );
    #    $envelope->print;

    # Documentation
    $envelope = $self->render_message(
        $biosails,
        'Raise Issues',
        "If you think you have found a bug, or would like to request additional functionality, please request it over on github\n".
            "https://github.com/biosails/BioSAILs-Command"
    );
    $envelope->print;
}

sub render_message {
    my $self = shift;
    my $app = shift;
    my $title = shift;
    my $message = shift;

    my $message_class = $app->meta->app_messageclass;

    my @parts = ($message_class->new({
        header => $title,
        body   => MooseX::App::Utils::format_text($message)
    }));

    return MooseX::App::Message::Envelope->new(@parts);

}

__PACKAGE__->meta->make_immutable;

1;
