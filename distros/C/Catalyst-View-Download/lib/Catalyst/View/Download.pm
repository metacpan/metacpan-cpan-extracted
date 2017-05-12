package Catalyst::View::Download;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

=head1 NAME

Catalyst::View::Download

=head1 VERSION

0.09

=cut

our $VERSION = '0.09';
$VERSION = eval $VERSION;

__PACKAGE__->config(
    'stash_key'    => 'download',
    'default'      => 'text/plain',
    'content_type' => {
        'text/csv' => {
            'outfile_ext' => 'csv',
            'module'      => '+Download::CSV',
        },
        'text/html' => {
            'outfile_ext' => 'html',
            'module'      => '+Download::HTML',
        },
        'text/plain' => {
            'outfile_ext' => 'txt',
            'module'      => '+Download::Plain',
        },
        'text/xml' => {
            'outfile_ext' => 'xml',
            'module'      => '+Download::XML',
        },
    },
);

sub process {
    my $self = shift;
    my ($c) = @_;

    my $content = $self->render( $c, $c->stash->{template}, $c->stash );

    $c->response->body($content);
}

sub render {
    my $self = shift;
    my ( $c, $template, $args ) = @_;
    my $content;

    my $content_type =
        $args->{ $self->config->{'stash_key'} }
        || $c->response->header('Content-Type')
        || $self->config->{'default'};

    my $options = $self->config->{'content_type'}{$content_type}
        || return $c->response->body;

    my $module = $options->{'module'} || return $c->response->body;
    if ( $module =~ /^\+(.*)$/ ) {
        my $part = $1;

        # First try a package in the app
        $module = $c->config->{'name'} . '::View::' . $part;
        my $file = $module . '.pm';
        $file =~ s{::}{/}g;
        eval { CORE::require($file) };

        if( $@ ) {
            # Next try a module under Catalyst::View::
            $module = 'Catalyst::View::' . $part;
            my $file = $module . '.pm';
            $file =~ s{::}{/}g;
            eval { CORE::require($file) };

            # All attempts failed, so return body
            return $c->response->body if( $@ );
        }
    } else {
        Catalyst::Utils::ensure_class_loaded($module);
    }

    $c->response->header( 'Content-Type' => $content_type );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
        . (
            $c->stash->{'outfile_name'} ? $c->stash->{'outfile_name'} . '.' . $options->{'outfile_ext'}
            : $c->action . '.' . $options->{'outfile_ext'}
        )
    );

    my $view = $module->new();

    return $view->render( @_ );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    # Use the helper
    > script/create.pl view Download Download

    # or just add your own...
    # lib/MyApp/View/Download.pm
    package MyApp::View::Download;
    use Moose;
    use namespace::autoclean;

    extends 'Catalyst::View::Download';

    1;

    # lib/MyApp/Controller/SomeController.pm
    sub example_action : Local {
        my ($self, $c, $content_type) = @_;

        my $data = [
            ['00','01','02','03'],
            ['10','11','12','13'],
            ['20','21','22','23'],
            ['30','31','32','33']
        ];

        if( $content_type ) {
            # For this example we are only using csv, html and plain.
            # xml is also available and you can add any of your own
            # modules under your MyApp::View::Download:: namespace.
            $content_type = 'plain' unless
                scalar(
                    grep { $content_type eq $_ }
                    qw(csv html plain)
                );

            # Set the response header content type
            $c->res->header('Content-Type' => 'text/' . $content_type);

            # OR set the content type in the stash variable 'download'
            # to process it. (Note: this is configurable)
            $c->stash->{'download'} = 'text/' . $content_type;

            # This is here just so I can do some quick data formatting
            # for this example.
            my $format = {
                'html' => sub {
                    return  "<!DOCTYPE html><html><head><title>Data</title></head><body>"
                            . join( "<br>", map { join( " ", @$_ ) } @$data )
                            . "</body></html>";
                },
                'plain' => sub {
                    return  join( "\n", map { join( " ", @$_ ) } @$data );
                },
                'csv' => sub { return $data; }
            };

            # Store the data in the appropriate stash key.
            # 'csv' for csv, 'html' for html, etc.
            $c->stash->{$content_type} = $format->{$content_type}();

            # You can optionally set the outfile_name or the current action name
            # will be used
            $c->stash->{'outfile_name'} = 'filename';

            # Use the Download View
            $c->detach('MyApp::View::Download');
        }

        # In this example if a content type isn't specified a page is then displayed
        $c->res->body('Display page as normal.');
    }

=head1 DESCRIPTION

A view module to help in the convenience of downloading data into many
supportable formats.

=head1 SUBROUTINES

=head2 process

This method will be called by Catalyst if it is asked to forward to a component
without a specified action.

=head2 render

Allows others to use this view for much more fine-grained content generation.

=head1 CONFIG

=over

=item stash_key

Determines the key in the stash this view will look for when attempting to
retrieve the type of format to process. If this key isn't found it will search
for a Content-Type header for the format. Further if neither are found a
default format will be applied.

    $c->view('MyApp::View::Download')->config->{'stash_key'} = 'content_type';

=item default

Determines which Content-Type to use by default. Default: 'text/plain'

    $c->view('MyApp::View::Download')->config('default' => 'text/plain');

=item content_type

A hash ref of hash refs. Each key in content_type is Content-Type that is
handled by this view.

    $c->view('MyApp::View::Download')->config->{'content_type'}{'text/csv'} = {
        outfile_ext => 'csv',
        module      => 'My::Module'
    };

The Content-Type key refers to it's own hash of parameters to determine the
actions thie view should take for that Content-Type.

'outfile_ext' - The extenstion of the file that will downloaded.

'module' - The name of the module that will handle data output. If there is
a plus symbol '+' at the beginning of the module name, this will indicate that
the module is either a MyApp::View module or a Catalyst::View module and
the appropriate namespace will be added to the beginning of the module name.

    # Module Loaded: Catalyst::View::Download::CSV
    $c->view('MyApp::View::Download')
        ->config
        ->{'content_type'}{'text/csv'}{'module'} = '+Download::CSV';

    # Module Loaded: My::Module::CSV
    $c->view('MyApp::View::Download')
        ->config
        ->{'content_type'}{'text/csv'}{'module'} = 'My::Module::CSV';

=back

=head1 Content-Type Module Requirements

Any module set as 'the' module for a certain Content-Type needs to have a
subroutine named 'render' that returns the content to output with the
following parameters handled.

=over

=item $c

The catalyst $c variable

=item $template

In case a template file is needed for the module. This view will pass
$c->stash->{template} as this value.

=item $args

A list of arguments the module will use to process the data into content.
This view will pass $c->stash as this value.

=back

=head1 INCLUDED CONTENT TYPES

=head2 text/csv

Catalyst::View::Download has the following default configuration for this
Content-Type.

    $c->view('MyApp::View::Download')->config->{'content_type'}{'text/csv'} = {
        outfile_ext => 'csv',
        module      => '+Download::CSV'
    };

See L<Catalyst::View::Download::CSV> for more details.

=head2 text/html

Catalyst::View::Download has the following default configuration for this
Content-Type.

    $c->view('MyApp::View::Download')->config->{'content_type'}{'text/html'} = {
        outfile_ext => 'html',
        module      => '+Download::HTML'
    };

See L<Catalyst::View::Download::HTML> for more details.

=head2 text/plain

Catalyst::View::Download has the following default configuration for this
Content-Type.

    $c->view('MyApp::View::Download')->config->{'default'} = 'text/plain';

    $c->view('MyApp::View::Download')->config->{'content_type'}{'text/plain'} = {
        outfile_ext => 'txt',
        module      => '+Download::Plain'
    };

See L<Catalyst::View::Download::Plain> for more details.

=head2 text/xml

Catalyst::View::Download has the following default configuration for this
Content-Type.

    $c->view('MyApp::View::Download')->config->{'content_type'}{'text/xml'} = {
        outfile_ext => 'xml',
        module      => '+Download::XML'
    };

See L<Catalyst::View::Download::XML> for more details.

=head1 BUGS

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>

=head1 AUTHOR

Travis Chase, C<< <gaudeon at cpan dot org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to following people for their constructive comments and help:

=over

=item J. Shirley

=item Jonathan Rockway

=item Jon Schutz

=item Kevin Frost

=item Michele Beltrame

=item Dave Lambley

=back

=head1 LICENSE

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
