package App::Followme::TextData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::FileData);
use App::Followme::FIO;
use App::Followme::Web;

our $VERSION = "2.03";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            extension => 'md',
            text_pkg => 'Text::Markdown',
            text_method => 'markdown',
           );
}

#----------------------------------------------------------------------
# Convert content block markup to html

sub fetch_as_html {
    my ($self, $content_block) = @_;

    my $method = $self->{text_method};
    return $self->{text}->$method($content_block);
}

1;
__END__
=encoding utf-8

=head1 NAME

App::Followme::TextData - Convert text files to html

=head1 SYNOPSIS

    use FIO;
    my $data = App::Followme::TextData->new();
    my $page = fio_read_page('new_file.md');
    my $html = $data_fetch_as_html($page);

=head1 DESCRIPTION

This module contains the methods that build metadata values from a text
file.  The text file is optionally preceded by a section containing Yaml
formatted data.

=head1 METHODS

All data are accessed through the build method.

=over 4

=item my %data = $obj->build($name, $filename);

Build a variable's value. The first argument is the name of the variable. The
second argument is the name of the file the metadata is being computed for. If
it is undefined, the filename stored in the object is used.

=back

=head1 VARIABLES

The text metadata class can evaluate the following variables. When passing
a name to the build method, the sigil should not be used.

=over 4

=item $body

All the contents of the file, minus the title if there is one. Text is
called on the file's content to generate html before being stored in the body
variable.

=item $description

A one line sentence description of the content.

=item $title

The title of the page is derived from contents of the top header tag, if one is
at the front of the file content, or the filename, if it is not.


=back

=head1 CONFIGURATION

The following parameters are used from the configuration:

=over 4

=item extension

The extension of files that are converted to web pages. The default value
is md.

=item text_pkg

The name of the package which converts text to html. The default value 
is 'Text::Markdown'.

=item text_method

The name of the method that does the conversion. The default value is 'markdown'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
