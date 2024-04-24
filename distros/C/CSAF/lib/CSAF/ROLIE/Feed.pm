package CSAF::ROLIE::Feed;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;


use CSAF::Util qw(file_write file_read parse_datetime tracking_id_to_well_filename);
use CSAF::ROLIE::Entries;
use CSAF::Options::ROLIE;

use Cpanel::JSON::XS;
use File::Basename;
use File::Find;
use File::Spec::Functions qw(catfile);
use Time::Piece;

use constant TRUE  => !!1;
use constant FALSE => !!0;

my $CSAF_SCHEMAS = {'2.0' => 'https://docs.oasis-open.org/csaf/csaf/v2.0/csaf_json_schema.json'};

has options => (
    isa   => sub { Carp::croak q{Not "CSAF::Options::ROLIE" object} unless ref($_[0]) eq 'CSAF::Options::ROLIE' },
    is    => 'lazy',
    build => 1,
);

sub _build_options { CSAF::Options::ROLIE->new }

# ROLIE feed properties
has id    => (is => 'rw');
has title => (is => 'rw');
has link  => (is => 'rw');

has category => (
    is      => 'lazy',
    default => sub { [{scheme => 'urn:ietf:params:rolie:category:information-type', term => 'csaf'}] }
);

has updated => (is => 'rw', required => 1, default => sub { Time::Piece->new }, coerce => \&parse_datetime);


sub init {

    my $self = shift;

    $self->id($self->options->feed_id)       unless $self->id;
    $self->title($self->options->feed_title) unless $self->title;
    $self->link($self->options->feed_link)   unless $self->link;

}

sub entry {
    my $self = shift;
    $self->{entry} ||= CSAF::ROLIE::Entries->new(@_);
}

sub import_entry_from_file {

    my ($self, $feed_path) = @_;

    Carp::croak 'ROLIE feed not found' unless -e $feed_path;

    my $json = eval { Cpanel::JSON::XS->new->decode(file_read($feed_path)) };

    Carp::croak "Failed to parse the ROLIE feed: $@" if ($@);
    Carp::croak 'Invalid ROLIE feed' unless defined $json->{feed};

    foreach my $entry (@{$json->{feed}->{entry}}) {
        $self->entry->item(%{$entry});
    }

}


sub add_entry {

    my ($self, $csaf, $options) = @_;

    $options //= {};

    Carp::croak 'Not CSAF object' unless (ref($csaf) eq 'CSAF');

    my $id        = $csaf->document->tracking->id;
    my $title     = $csaf->document->title;
    my $published = $csaf->document->tracking->initial_release_date;
    my $updated   = $csaf->document->tracking->current_release_date;

    my $csaf_year = $csaf->document->tracking->initial_release_date->year;
    my $csaf_url  = join('/', $self->options->base_url, $csaf_year, tracking_id_to_well_filename($id));

    my $format  = {schema => $CSAF_SCHEMAS->{$csaf->document->csaf_version}, version => $csaf->document->csaf_version};
    my $content = {type   => 'application/json', src => $csaf_url};
    my $link    = [{href => $csaf_url, rel => 'self'}];
    my $summary = undef;

    $csaf->document->notes->each(sub {
        my $note = shift;
        $summary = $note->text if ($note->category eq 'summary');
    });

    # TODO  Add the check of the existence of integrity and signature files

    if (defined $options->{integrity}) {

        my $integrity = $options->{integrity};

        push @{$link}, {href => "$csaf_url.sha256", ref => 'hash'}
            if (defined $integrity->{sha256} && $integrity->{sha256});

        push @{$link}, {href => "$csaf_url.sha512", ref => 'hash'}
            if (defined $integrity->{sha512} && $integrity->{sha512});

    }

    push @{$link}, {href => "$csaf_url.asc", ref => 'signature'}
        if (defined $options->{signature} && $options->{signature});

    my $is_updated = 0;

    $self->entry->each(sub {

        my ($item) = @_;

        if ($item->id eq $id) {

            if ($item->updated < $updated) {

                $item->updated($updated);
                $item->title($title);
                $item->summary($summary);

            }

            $is_updated = 1;
            return;

        }

    });

    unless ($is_updated) {
        my $entry = {
            id        => $id,
            title     => $title,
            published => $published,
            updated   => $updated,
            format    => $format,
            link      => $link,
            summary   => $summary,
            content   => $content
        };
        $self->entry->item(%{$entry});
    }

    $self->updated(Time::Piece->new);

    return $self;

}

sub from_file {

    my ($class, $feed_path) = @_;

    Carp::croak 'ROLIE feed not found' unless -e $feed_path;

    my $json = eval { Cpanel::JSON::XS->new->decode(file_read($feed_path)) };

    Carp::croak "Failed to parse the ROLIE feed: $@" if ($@);
    Carp::croak 'Invalid ROLIE feed' unless defined $json->{feed};

    my $feed = $class->new(
        id      => $json->{feed}->{id},
        title   => $json->{feed}->{title},
        link    => $json->{feed}->{link},
        updated => $json->{feed}->{updated}
    );

    $feed->options->configure(feed_directory => dirname($feed_path), feed_filename => basename($feed_path));

    foreach my $entry (@{$json->{feed}->{entry}}) {
        $feed->entry->item(%{$entry});
    }

    return $feed;

}

sub render {

    my $self = shift;

    $self->init;

    my $json = Cpanel::JSON::XS->new->utf8->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed
        ->stringify_infnan->escape_slash(0)->allow_dupkeys->pretty;

    my @sorted_entries = sort { $b->updated->epoch <=> $a->updated->epoch } @{$self->entry->to_array};
    $self->entry->items(\@sorted_entries);

    return $json->encode($self);

}

sub write {

    my ($self, $path) = @_;

    $path //= $self->options->feed_filename;

    file_write($path, $self->render);
    return 1;

}

sub from_csaf_directory {

    my ($self, $path) = @_;

    $path //= $self->options->csaf_directory;

    Carp::croak 'Directory not found' unless -e -d $path;

    my @files = ();

    my $wanted = sub {
        push @files, $File::Find::name if !-d $File::Find::name && $File::Find::name =~ /\.json$/;
    };

    find {wanted => $wanted, no_chdir => 1}, $path;

    foreach my $file (@files) {

        my $parser = CSAF::Parser->new(file => $file);
        my $csaf   = eval { $parser->parse };

        next unless $csaf;

        my $id        = $csaf->document->tracking->id;
        my $tlp_label = $csaf->document->distribution->tlp->label;

        if ($tlp_label eq $self->options->tlp_label) {
            $self->add_entry(
                $csaf,
                {
                    integrity => {sha256 => (-e "$file.sha256"), sha512 => (-e "$file.sha512")},
                    signature => (-e "$file.asc")
                }
            );
        }

    }

    return $self;

}

sub TO_JSON {

    my $self = shift;

    my $json = {
        feed => {
            id       => $self->id,
            title    => $self->title,
            link     => $self->link,
            category => $self->category,
            updated  => $self->updated,
            entry    => $self->entry
        }
    };

    return $json;

}

1;


__END__

=encoding utf-8

=head1 NAME

CSAF::ROLIE::Feed - Build ROLIE (Resource-Oriented Lightweight Information Exchange) feed

=head1 SYNOPSIS

    use CSAF::ROLIE::Feed;

    my $rolie = CSAF::ROLIE::Feed->new;

    $rolie->options->configure(
        feed_id    => 'acme-csaf-feed-tlp-white',
        feed_title => 'ACME Security Advisory CSAF feed (TLP:WHITE)'
        base_url   => 'https://security.acme.tld/advisories/csaf'
    );

    # Add CSAF document entry
    $rolie->add_entry($csaf);

    if ($rolie->write) {
        say "ROLIE feed created";
    }



=head1 DESCRIPTION

L<CSAF::ROLIE::Feed> build a ROLIE (Resource-Oriented Lightweight Information Exchange)
feed using the CSAF documents.

L<https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html>

The Resource Oriented Lightweight Information Exchange (ROLIE) is standard (RFC-8322)
for exchanging security automation information between two machines, or between
a machine and a human operator.

L<https://tools.ietf.org/html/rfc8322>


=head2 ATTRIBUTES

=over

=item id

Feed ID

=item title

Feed title

=item link

=item category

Feed category

=item entry

Feed entries

=item updated

Feed last update

=back


=head2 METHODS

=over

=item $rolie->options

Change the default options for L<CSAF::Options::ROLIE> configurator.

    $rolie->options->configure(
        feed_title => 'ACME Security Advisory CSAF feed (TLP:WHITE)'
        base_url   => 'https://security.acme.tld/advisories/csaf'
    );

=item $rolie->add_entry ( $csaf, [ $options ])

Add a L<CSAF> document to the ROLIE feed and provide a C<$options> hash to
include the integrity and signature files.

    $rolie->add_entry($csaf, {
        integrity => {
            sha256 => 0,
            sha512 => 1
        },
        signature => 1 
    });

=item $rolie->from_csaf_directory ( [$path] )

Create ROLIE feed from the provided CSAF directory in C<$path>. If C<$path> is
not specified, the name will be taken from the C<csaf_directory> option in L<CSAF::Options::ROLIE>.

    $rolie->from_csaf_directory('/var/www/html/advisories/csaf');
    $rolie->write;

=item $rolie->from_file ( $path )

Import ROLIE feed from the provided file.

=item $rolie->import_entry_from_file ( $path )

Import only the entries from provided ROLIE feed file.

=item $rolie->render

Render a ROLIE feed in JSON.

    $rolie->render;

=item $rolie->write ( [$path] )

Render and write a ROLIE feed. If C<$path> is not specified, the name will be taken
from the C<feed_filename> option in L<CSAF::Options::ROLIE> (default C<csaf-feed-tlp-white.json>).

    $rolie->write('acme-csaf-feed-tlp-white.json');

=item $rolie->TO_JSON



=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
