package Catalyst::Plugin::CheckFileUploadTypes;

# ABSTRACT: Check uploaded files are expected and of the correct type

use Data::Printer;

use File::MMagic;
use Moose;
use namespace::autoclean;
with 'Catalyst::ClassData';

use MRO::Compat;

sub setup {
    my $c = shift;
    return $c->maybe::next::method(@_);
}


sub dispatch {
    my $c = shift;
    use Data::Dumper;

    # If we don't have any uploads, there's nothing more to do:
    if (!keys %{ $c->req->uploads }) {
        $c->maybe::next::method(@_);
        return 1;
    }

    # If the action is a Catalyst::Action::REST action, then we want to
    # attempt to find the _method suffixed action that it will forward to
    # (e.g. index() -> index_POST()) and if we do, look at the attributes
    # for that instead - as e.g. an index_GET() isn't going to expect uploads
    # but the index_POST() may well do.
    my $action = $c->action;
    if (ref $action eq 'Catalyst::Action::REST') {
        my $rest_method = $action->name . '_' . $c->req->method;
        my $controller = $c->component( $action->class );
        if (my $rest_action = $controller->action_for($rest_method)) {
            $action = $rest_action;
        }
    }
    
    my $mm = File::MMagic->new;

    my $expects_uploads = $action->attributes->{ExpectUploads};

    my %ok_type;
    for my $type (
        map { split /[\s,]/ } @{ $action->attributes->{ExpectUploads} }
    ) {
        $ok_type{$type}++;
    }

    if (!$expects_uploads) {
        # No uploads expected...
        $c->log->error("Uploads present, but not expected by action");
        $c->response->status(400);
        $c->response->body("File upload not expected");
        return;
    } else {
        # Alright, we do expect uploads; do we care *what*?
        if (defined $expects_uploads->[0]) {
            # alright, we need to check the types match.
            # For every file, determine its type, then for each allowed type,
            # see if it's a match (and end if so)
            upload:
            for my $upload (values %{ $c->req->uploads }) {
                my $upload_type = $mm->checktype_filehandle($upload->fh);
                # File::MMagic will haveread from the filehandle, seek it back
                # to the start so we don't confuse things that expect to just
                # read from it
                seek($upload->fh, 0, 0);
                $c->log->debug(
                    sprintf "Determined type %s for %s",
                    $upload_type, $upload->filename,
                );
                if ($ok_type{$upload_type}) {
                        next upload;
                } else {
                    $c->log->warn(
                        sprintf "Upload %s with unexpected type %s rejected",
                        $upload->filename,
                        $upload_type,
                    );
                    # FIXME we probably want to make rejections more configurable,
                    # maybe ability to provide coderef to trigger on reject?
                    $c->res->status(400);
                    $c->res->body("Unsupported file content type uploaded");
                    return;
                }
            }

        }
    }

    # If we get to here, then we've seen no problems - we've either
    # short-circuited early because there *weren't* any uploads, or
    # we've confirmed that the action expects uploads, and if it
    # specified what types, we're happy that the upload(s) are of
    # the right type.
    $c->maybe::next::method(@_);

}

=head1 NAME

Catalyst::Plugin::CheckFileUploadTypes - check file uploads are expected and right types

=head1 SYNOPSIS

  use Catalyst qw(CheckFileUploadTypes);

  # Actions can declare that they expect to receive file uploads:
  sub upload_file : Local ExpectUploads { ... }

  # They can also specify that any uploaded files must be of expected types
  # (determined from file content by File::MMagic, not what the client said)
  sub upload_file : Local ExpectUploads(image/jpeg image/png) { ... }

=head1 DESCRIPTION

This plugin allows Catalyst apps to easily accept and validate file uploads.

If the action a request is about to be handed to does not declare that it
expects file uploads, by setting a C<ExpectUploads> attribute, and the HTTP
request contains one or more file uploads, the request will be rejected.

The action can also specify the type(s) of files it expects to receive,
and the request will be rejected if an uploaded file is of a different
type (as determined by L<File::MMagic> from the file's content, not trusting
the file extension or what the client says it is).  This avoids uploading
executable files / scripts etc to an action which expects image uploads,
for instance.


=head1 AUTHOR

David Precious (BIGPRESH), C<< <davidp@preshweb.co.uk> >>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2023 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
