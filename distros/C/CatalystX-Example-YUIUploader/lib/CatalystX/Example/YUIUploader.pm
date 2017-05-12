package CatalystX::Example::YUIUploader;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.02';

__PACKAGE__->config(
    name => 'CatalystX::Example::YUIUploader',
    static => {
        dirs => [ qw/static/ ],
    },
    default_view => 'View::TT',
    'View::TT' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to(qw/root tt/),
        ],
        CATALYST_VAR => "catalyst",
    },
);

__PACKAGE__->setup;

=head1 NAME

CatalystX::Example::YUIUploader - A YUI Uploader example for Catalyst

=head1 SYNOPSIS

    script/catalystx_example_yuiuploader_server.pl
    # Nothing much to do, this is just an example application

=head1 DESCRIPTION

This is a very basic Catalyst application that shows off the YUI (experimental) uploader.
Launch the server by running:

    ./script/catalystx_example_yuiuploader_server.pl

And browse to L<http://localhost:3000> (or whatever you've set the port to) to play with the uploader.

NOTE: Currently, under Firefox 2 in Linux, the logging text in the flash window seems to be white on white. The text doesn't show up, but uploading works fine.

=head1 SEE ALSO

L<http://developer.yahoo.com/yui/uploader/>, L<Catalyst>,

=head1 AUTHOR

Robert Krimen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
