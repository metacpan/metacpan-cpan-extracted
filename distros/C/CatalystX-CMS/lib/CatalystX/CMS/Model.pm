package CatalystX::CMS::Model;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Model::File );
use MRO::Compat;
use mro 'c3';
use Carp;
use Data::Dump qw( dump );
use Path::Class;

our $VERSION = '0.011';

my $DEBUG = 0;

__PACKAGE__->config(
    object_class => 'CatalystX::CMS::Page',
    file_ext     => '.tt',
);

__PACKAGE__->mk_accessors(qw( file_ext ));

=head1 NAME

CatalystX::CMS::Model - manage template file paths

=head1 SYNOPSIS

 package MyCMS::Model::CMS;
 use strict;
 use base qw( CatalystX::CMS::Model );
 1;

=head1 DESCRIPTION

CatalystX::CMS::Model is a subclass of CatalystX::CRUD::Model::File. Be sure
to read that documentation.

=head1 METHODS

Only new or overridden methods are documented here.

=head2 Xsetup

Sets inc_path() based on the main application C<cms> config I<root> values.

=cut

sub Xsetup {
    my ( $self, $c ) = @_;
    $self->_make_inc($c);
    $self->{use_basename_fallback} = 1
        if $c->config->{cms}->{use_basename_fallback};
    $self->next::method($c);
    if ( $c->debug ) {
        my $t = Text::SimpleTable->new(74);
        $t->row("$_") for @{ $self->inc_path };
        $c->log->debug( "CMS Model inc path:\n" . $t->draw . "\n" );
    }
    return $self;
}

sub _make_inc {
    my ( $self, $c ) = @_;
    my $conf = $c->config->{cms}->{root};

    # inc path is composite array of all paths, rw followed by r
    my @r  = @{ $conf->{r} };
    my @rw = @{ $conf->{rw} };
    $self->{__make_copy}->{"$_"}++ for @r;
    $self->{inc_path} = [ @rw, @r ];
}

=head2 fetch( file => I<path/file> )

Overrides base method to additionally set I<cms_root> and I<ext>
in the returned CatalystX::CMS::Page object.

=cut

sub fetch {
    my $self = shift;
    my $page = $self->new_object(
        ext => $self->file_ext,
        url => '/' . $self->context->req->path,
        @_,
    );
    return $self->find_page_in_inc($page);
}

=head2 find_page_in_inc( I<cmspage> [, I<extra_paths>] )

Called by fetch(). Locates I<cmspage> in the filesystem
if it exists, setting type and flavour flags and calling the read() method
on I<cmspage> if found.

Returns I<cmspage>.

=cut

sub find_page_in_inc {
    my $self           = shift;
    my $page           = shift or croak "page required";
    my @extra_paths    = @_;
    my $delegate_class = $page->delegate_class;
    my $c              = $self->context;
    my $type 
        = $page->type
        || $c->req->params->{'cxcms-type'}
        || $c->config->{cms}->{default_type}
        || 'html';
    my $flav 
        = $page->flavour
        || $c->req->params->{'cxcms-flavour'}
        || $c->config->{cms}->{default_flavour}
        || 'default';

    my $ext = $self->file_ext;

    # look through inc_path
DIR: for my $dir ( @{ $self->inc_path }, @extra_paths ) {

        my $flavoured = Path::Class::dir( $dir, $type, $flav );
        my $plain = Path::Class::dir($dir);

        $DEBUG and warn "inc_path flavoured: $flavoured";

    SUBDIR: for my $subdir ( $flavoured, $plain ) {
            $c->log->debug("looking in $subdir for $page") if $c->debug;

            my $test = $delegate_class->new( $subdir, $page );

            if ( -s $test ) {
                $c->log->debug("Found cms file: $test") if $c->debug;
                $page->{delegate} = $test;
                $page->{cms_root} = $dir;
                $page->{type}     = $type;
                $page->{flavour}  = $flav;
                $page->{copy}     = exists $self->{__make_copy}->{"$dir"};
                $page->read;

                #$c->log->debug( Data::Dump::dump($page) ) if $c->debug;

                last DIR;
            }

        }
    }

    # allow for (e.g.) CXCRUD templates, which we want to
    # edit but which are stored in @INC
    # This logic mirrors what is done in
    # CatalystX::CRUD::YUI::View->process
    my $basename = $page->delegate->basename;
    $basename =~ s/$ext$//;
    if (   $self->{use_basename_fallback}
        && !-s $page->delegate
        && $basename !~ m/^(body|wrapper|header|footer)$/
        && !$self->{__no_recurse} )
    {

        $DEBUG and warn dump $page;

        $c->log->debug("$page does not exist -- trying $basename")
            if $c->debug;

        $self->{__no_recurse} = 1;
        $page = $self->fetch( file => $basename );
        delete $self->{__no_recurse};

        #$page->{delegate}->{dir} = Path::Class::dir( $crud_base, 'crud' );
        $page->{copy} = 1;    # make a local copy to edit
    }

    # make sure delegate() has absolute path
    # while page is relative to inc_path.
    if ( $page->dir eq '.' or !$page->dir->is_absolute ) {

        $c->log->debug("No absolute path for $page") if $c->debug;

        $page->{delegate} = $delegate_class->new(
            path => Path::Class::file(
                $c->config->{cms}->{root}->{rw}->[0],
                $type, $flav, $page
            )
        );
        $page->{type}    = $type;
        $page->{flavour} = $flav;
    }

    # calculate url if it is empty
    if ( !$page->url ) {
        $page->calc_url;
    }

    $DEBUG and carp dump $page;
    $c->log->debug( "returning Model page: " . dump($page) ) if $c->debug;

    return $page;
}

=head2 make_query

Returns a CODE ref according to CatalystX::CRUD::Model::File API
to skip all C<.svn> dirs and files not ending with file_ext().

=cut

sub make_query {
    my ($self) = @_;
    my $ext = quotemeta( $self->file_ext );
    return sub {
        my ( $root, $dir, $file ) = @_;

        #warn $file;
        return 0 if $dir  =~ m/\.svn/;
        return 0 if $file =~ m/\.svn/;

        #warn "$ext : considering $file";
        return 0 unless $file =~ m/$ext$/;

        #warn " >>>>>>> match on $file";
        return 1;
    };
}

=head2 search

Overrides default method to call fetch() on each page.

=cut

sub search {
    my $self = shift;
    my $filter_sub = shift || $self->make_query;
    my @objects;
    for my $root ( @{ $self->inc_path } ) {
        my $files = $self->_find( $filter_sub, $root );
        for my $f ( sort keys %$files ) {
            my $page = $self->fetch( file => $f, url => '' );    # calc url
            push @objects, $page;
        }
    }
    return \@objects;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


