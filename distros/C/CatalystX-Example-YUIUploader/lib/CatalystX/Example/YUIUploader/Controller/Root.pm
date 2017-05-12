package CatalystX::Example::YUIUploader::Controller::Root;

use strict;
use warnings;

use base qw/Catalyst::Controller/;

use Data::UUID;
use MIME::Types;
my $types = MIME::Types->new(only_complete => 1);

__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ($self, $catalyst) = @_;

    $catalyst->detach(qw/advanced/);
}

sub simple : Local {
    my ($self, $catalyst) = @_;

    $catalyst->stash->{template} = "simple.tt.html";
}

sub advanced : Local {
    my ($self, $catalyst) = @_;

    $catalyst->stash->{template} = "advanced.tt.html";
}

sub upload : Local {
    my ($self, $catalyst) = @_;

    my @uploads;
    for my $field ($catalyst->request->upload) {
    for my $upload ($catalyst->request->upload($field)) {
        my $uuid = Data::UUID->new->create_str;
        my $type;
        $type = $types->mimeTypeOf($upload->type);
        $type ||= $types->mimeTypeOf($upload->filename);
        my $localfile = $uuid;
        if ($type) {
            $localfile .= "." . ($type->extensions)[0];
        }
        my $localfile_file = $catalyst->path_to(qw/root static/)->file(qw/upload/, $localfile);
        my $localfile_uri = $catalyst->uri_for(qw/static upload/, $localfile);

        $localfile_file->parent->mkpath unless -d $localfile_file->parent;
        $upload->link_to($localfile_file);

        push @uploads, {
            uuid => $uuid,
            type => "$type",
            uri => "$localfile_uri",
        };
    }
    }

    $catalyst->stash->{json}->{uploads} = \@uploads,;
    $catalyst->forward("View::JSON");
}

sub end : ActionClass('RenderView') {
}

1;
