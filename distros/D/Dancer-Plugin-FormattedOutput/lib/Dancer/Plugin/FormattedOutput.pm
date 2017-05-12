package Dancer::Plugin::FormattedOutput;

use warnings;
use strict;
use Dancer ':syntax';
use Dancer::Plugin;
use feature 'switch';

=head1 NAME

Dancer::Plugin::FormattedOutput - Provide output in a variety of formats

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use constant {
    # Formats
    JSON_FT  => "json",
    XML_FT   => "xml",
    YAML_FT  => "yaml",
    TEXT_FT  => "text",
    HTML_FT  => "html",

    # Content Types
    JSONP_CT => "text/javascript",
    JSON_CT  => "application/json",
    XML_CT   => 'text/xml',
    YAML_CT  => 'application/yaml',
    TEXT_CT  => "text/plain",
};

=head1 SYNOPSIS

Similar in functionality to the standard Dancer serialisation routines,
this module provides functions for serialising output to a variety of formats.
Where it differs from the default Dancer functionality is that it:

=over

=item Correctly sets the content type

=item Allows html as a format using templates

=item Allows per-call configuration of default format

=item Works with jsonp

=back

    use Dancer::Plugin::FormattedOutput;

    get '/some/route' => sub {
        my $data = get_data();
        format "template" => $data;
    };

    get '/some/other/route' => sub {
        my $data = get_data();
        format $data;
    };
    ...

=head1 EXPORT

The function "format" is automatically exported.

=head1 SUBROUTINES/METHODS

=head2 format

This function is exported in the calling namespace, and it manages
the formatting of data into the various available formats.

It can be called as:

  format($data)

  format("template_name" => $data);

  format($data, "default_format");

  format("template_name", $data, "default_format");

=cut

register format_output => sub {
    my ($data, $template, $format, $callback, $default_format);
    if (@_ == 1) {
        $data = shift;
    } elsif (@_ == 2 && ! ref $_[0]) {
        ($template, $data) = @_;
    } elsif (@_ == 2 && ! ref $_[1]) {
        ($data, $default_format) = @_;
    } elsif (@_ == 3) {
        ($template, $data, $default_format) = @_;
    } else {
        die "Wrong number of arguments to format: got @_";
    }

    $format = params->{ plugin_setting->{"format_parameter"} || "format" };
    $callback = params->{ plugin_setting->{"callback_parameter"} || "callback" };
    $default_format = $default_format || plugin_setting->{default_format} || JSON_FT;
    $format = $format || $default_format;

    given($format) {
        when(/^\.?json$/i) {
            return return_json($data, $callback);
        }
        when(/^\.?xml$/i) {
            return return_xml($data);
        }
        when(/^\.?ya?ml$/i) {
            return return_yaml($data);
        }
        when(/^\.?html?$/i) {
            return template $template, $data;
        }
        when(/^\.?te?xt$/i) {
            return return_text($data);
        }
        default {
            die "Could not handle format: $format";
        }
    }
};

=head2 return_json 

The formatter for json. It appends the callback if any,
and sets the content type to application/json or 
text/javascript as appropriate

=cut

sub return_json {
    my ($data, $callback) = @_;
    my $ret = $callback ? "$callback(" : '';
    $ret .= to_json($data);
    $ret .= ");" if $callback;
    content_type($callback ? JSONP_CT : JSON_CT);
    return $ret;
}

=head2 return_xml 

The formatter for xml. It sets the content type, and does a 
basic transformation to xml.

=cut

sub return_xml {
    my $data = shift;
    content_type(XML_CT);
    return to_xml($data);
}

=head2 return_yaml 

The formatter for yaml. It sets the content type and does a 
basic transformation to yaml.

=cut

sub return_yaml {
    my $data = shift;
    content_type(YAML_CT);
    to_yaml($data);
}

=head2 return_text 

The formatter for text. It sets the content type, and, 
if the data is a hashref and has a key named "text", returns
the value of that key. Otherwise it returns a Data::Dumper
version of the data.

=cut

sub return_text {
    my $data = shift;
    content_type(TEXT_CT);
    if (ref $data eq 'HASH' and $data->{text}) {
        return $data->{text};
    } else {
        return to_dumper($data);
    }
}

register_plugin;

=head1 AUTHOR

Alex Kalderimis, C<< <alex kalderimis at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-formattedoutput at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-FormattedOutput>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::FormattedOutput


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-FormattedOutput>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-FormattedOutput>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-FormattedOutput>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-FormattedOutput/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alex Kalderimis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dancer::Plugin::FormattedOutput
