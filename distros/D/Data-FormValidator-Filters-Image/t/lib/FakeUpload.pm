package FakeUpload;

use strict;
use warnings;
use CGI;
use HTTP::Request::Common;
use IO::Scalar;
use base qw(Exporter);

our @EXPORT_OK = qw(
    fake_upload
);

sub fake_upload {
    my @content = @_;

    # Create the HTTP request object
    my $post = POST '/dummy_location',
        Content_type => 'form-data',
        Content => \@content;

    # Extract the relevant bits of info from the HTTP request, so we can make
    # CGI.pm think that we're in the middle of handling a file upload
    my $content_type   = $post->header('content_type');
    my $content_length = $post->header('content_length');
    my $content_buffer = $post->content();

    # Fake our ENV/STDIN, to trick CGI.pm
    my %fake_env = (
        REQUEST_METHOD  => 'POST',
        CONTENT_TYPE    => $content_type,
        CONTENT_LENGTH  => $content_length,
        HTTP_USER_AGENT => 'Test 1.0',
    );
    my $fake_stdin = IO::Scalar->new(\$content_buffer);

    local %ENV   = (%ENV, %fake_env);
    local *STDIN = \*$fake_stdin;

    # Create/return a new CGI object, which slurps in the data from our fake
    # upload.
    CGI::_reset_globals();
    return CGI->new();
}

1;

=head1 NAME

FakeUpload - Helper method to do a fake upload

=head1 SYNOPSIS

  use FakeUpload qw(fake_upload);

  my $cgi = fake_upload(
    image => [$filename],
  );

=head1 DESCRIPTION

C<FakeUpload> makes a C<fake_upload()> method available for export, which does
a fake upload of form data.

=head1 METHODS

=over

=item B<fake_upload(@content)>

Does a fake upload of the given C<@content>, returning a C<CGI> object back to
the caller.  The upload is faked as a multipeart/form-data upload, and the
provided C<@content> is passed through directly to
C<HTTP::Request::Common::POST()>; please refer to L<HTTP::Request::Common> for
more information on the format/structure of the C<@content> argument.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2009 Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<HTTP::Request::Common>.

=cut
