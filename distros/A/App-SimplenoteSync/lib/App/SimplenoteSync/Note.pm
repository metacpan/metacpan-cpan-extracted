package App::SimplenoteSync::Note;
{
  $App::SimplenoteSync::Note::VERSION = '0.2.0';
}

# ABSTRACT: stores notes in plain files,

use v5.10;
use Moose;
use MooseX::Types::Path::Class;
use Try::Tiny;
use namespace::autoclean;

extends 'WebService::Simplenote::Note';

use Method::Signatures;

has '+title' => (trigger => \&_title_to_filename,);

has file => (
    is        => 'rw',
    isa       => 'Path::Class::File',
    coerce    => 1,
    traits    => ['NotSerialised'],
    trigger   => \&_has_markdown_ext,
    predicate => 'has_file',
);

has file_extension => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['NotSerialised'],
    default => sub {
        {
            default  => 'txt',
            markdown => 'mkdn',
        };
    },
);

has notes_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    traits   => ['NotSerialised'],
    required => 1,
    default  => sub {
        my $self = shift;
        if ($self->has_file) {
            return $self->file->dir;
        } else {
            return Path::Class::Dir->new($ENV{HOME}, 'Notes');
        }
    },
);

has ignored => (
    is      => 'rw',
    isa     => 'Bool',
    traits  => ['NotSerialised'],
    default => 0,
);

# set the markdown systemtag if the file has a markdown extension
method _has_markdown_ext(@_) {
    my $ext = $self->file_extension->{markdown};

    if ($self->file =~ m/\.$ext$/ && !$self->is_markdown) {
        $self->set_markdown;
    }

    return 1;
}

# Convert note's title into file
method _title_to_filename(Str $title, Str $old_title?) {

    # don't change if already set
    if (defined $self->file) {
        return;
    }

    # TODO trim
    my $file = $title;

    # non-word to underscore
    $file =~ s/\W/_/g;
    $file .= '.';

    if (grep '/markdown/', @{$self->systemtags}) {
        $file .= $self->file_extension->{markdown};
        $self->logger->debug('Note is markdown');
    } else {
        $file .= $self->file_extension->{default};
        $self->logger->debug('Note is plain text');
    }

    $self->file($self->notes_dir->file($file));

    return 1;
}

method load_content {
    my $content;

    try {
        $content = $self->file->slurp(iomode => '<:utf8');
    }
    catch {
        $self->logger->error("Failed to read file: $_");
        return;
    };

    $self->content($content);
    return 1;
}

method save_content {
    try {
        my $fh = $self->file->open('w');

        # data from simplenote should always be utf8
        $fh->binmode(':utf8');
        $fh->print($self->content);
    }
    catch {
        $self->logger->error("Failed to write content to file: $_");
        return;
    };

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=for :stopwords Ioan Rogers Fletcher T. Penney github

=head1 NAME

App::SimplenoteSync::Note - stores notes in plain files,

=head1 VERSION

version 0.2.0

=head1 AUTHORS

=over 4

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Fletcher T. Penney <owner@fletcherpenney.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Ioan Rogers.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/App-SimplenoteSync/issues>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/App-SimplenoteSync>
and may be cloned from L<git://github.com/ioanrogers/App-SimplenoteSync.git>

=cut

