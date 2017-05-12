package Catalyst::Controller::DirectoryDispatch;
# ABSTRACT: Simple directory listing with built in url dispatching
$Catalyst::Controller::DirectoryDispatch::VERSION = '1.03';
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use JSON;
use Try::Tiny;
use namespace::autoclean;

__PACKAGE__->config(
    'default'   => 'application/json',
    'stash_key' => 'response',
    'map'       => {
        'application/x-www-form-urlencoded' => 'JSON',
        'application/json'                  => 'JSON',
    }
);

has 'root' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/',
);

has 'full_paths' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'filter' => (
    is      => 'ro',
    isa     => 'RegexpRef',
);

has 'data_root' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'data',
);

sub setup :Chained('specify.in.subclass.config') :CaptureArgs(0) :PathPart('specify.in.subclass.config') {}

sub list :Chained('setup') :PathPart('') :Args {
    my ( $self, $c, @dirpath ) = @_;

    my $path = join '/', @dirpath;
    $path = "/$path" if ($path);
    my $full_path = $self->root . $path;

    my @files = ();
    try {
        opendir (my $dir, $full_path) or die;
        @files = readdir $dir;
        closedir $dir;
    } catch {
        $c->stash->{response} = {
            "error"   => "Failed to open directory '$full_path'",
            "success" => JSON::false,
        };
        $c->detach('serialize');
    };

    my $regexp = $self->filter;
    @files = grep { !/$regexp/ } @files if ($regexp);

    @files = map { "$path/$_" } @files if ($self->full_paths);

    my $files_ref = $self->process_files( $c, \@files );

    $c->stash(
        response => {
            $self->data_root => $files_ref,
            success          => JSON::true,
        }
    );
}

sub process_files {
    my ( $self, $c, $files ) = @_;

    return $files;
}

sub end :Private {
    my ( $self, $c ) = @_;

    $c->res->status(200);
    $c->forward('serialize');
}

sub serialize :ActionClass('Serialize') {}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Controller::DirectoryDispatch - Simple directory listing with built in url dispatching

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    package MyApp::Controller::Browser::Example;
    use Moose;
    BEGIN { extends 'Catalyst::Controller::DirectoryDispatch' }

    __PACKAGE__->config(
        action => { setup => { Chained => '/browser/base', PathPart => 'mydir' } },
        root     => '/home/andy',
        filter     => qr{^\.|.conf$},
        data_root  => 'data',
        full_paths => 1,
    );

=head1 DESCRIPTION

Provides a simple configuration based controller for listing local system directories and dispatching them as URLs.

=head2 Example Usage

If you created the controller at http://localhost/mydir and set root to '/home/user1' then browsing to the controller might give the following output:

    {
        "success":true,
        "data":[
            "file1",
            "file2",
            "dir1",
            "dir2"
        ],
    }

You could then point your browser to http://localhost/mydir/dir1 to get a directory listing of the folder '/home/user1/dir1' and so on...

=head2 Changing Views

The default view for DirectoryDispatch serializes the file list as JSON but it's easy to change it to whatever view you'd like.

    __PACKAGE__->config(
        'default'   => 'text/html',
        'map'       => {
            'text/html' => [ 'View', 'TT' ],
        }
    );

Then in your template...

    [% FOREACH node IN response.data %]
    [% node %]
    [% END %]

=head2 Post Processing

If you need to process the files in anyway before they're passed to the view you can override process_files in your controller.

    sub process_files {
        my ($self, $c, $files) = @_;

        foreach my $file ( @$files ) {
            # Modify $file
        }

        return $files;
    }

This is the last thing that happens before the list of files are passed on to the view. $files is sent in as an ArrayRef[Str] but you
are free to return any thing you want as long as the serializer you're using can handle it.

=head1 CONFIGURATION

=head2 root

    is: ro, isa: Str

The folder that will be listed when accessing the controller (default '/').

=head2 filter

    is: ro, isa: RegexpRef

A regular expression that will remove matching files or folders from the directory listing (default: undef).

=head2 data_root

    is: ro, isa: Str

The name of the key inside $c->stash->{response} where the directory listing will be stored (default: data).

=head2 full_paths

    is: ro, isa: Bool

Returns full paths for the directory listing rather than just the names (default: 0).

=head1 THANKS

The design for this module was heavly influenced by the fantastic L<Catalyst::Controller::DBIC::API>.

=head1 AUTHOR

Andy Gorman <agorman@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Andy Gorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
