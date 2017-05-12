# vim: set ts=4 sw=4 tw=78 et si ft=perl:
package App::MakeEPUB;

use warnings;
use strict;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Carp;
use File::Basename;
use File::Find;
use File::Path qw(make_path);
use HTML::TreeBuilder;

use version; our $VERSION = qv('0.3.1');

my %guidetitle = (
    cover   => 'Cover',
);

my %embed = (
    'container.xml' => q(<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
 <rootfiles>
  <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
 </rootfiles>
</container>
),
    'content.opf'   => q(<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid" version="2.0">

 <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:opf="http://www.idpf.org/2007/opf">
%%METADATA%%
 </metadata>

 <manifest>
%%MANIFEST%%
 </manifest>

 <spine toc="ncx">
%%SPINE%%
 </spine>

%%GUIDE%%
</package>),
    'toc.ncx'       => q(<?xml version="1.0"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">

 <head>
%%TOCNCXHEAD%%
 </head>

 <docTitle>
%%TOCNCXDOCTITLE%%
 </docTitle>

 <navMap>
%%TOCNCXNAVMAP%%
 </navMap>

</ncx>),
);

sub new {
    my ($self, $args) = @_;
    my $type = ref($self) || $self;

    $self = bless {}, $type;
    $self->{path} = {};
    #
    $self->{nav_l2} = {
        '_tag'  => 'span',
        'class' => 'h2',
    };

    $self->_init($args)                 if (defined $args);

    return $self;
} # new()

sub add_metadata {
    my ($self, $opt) = @_;
    my %data = ();
    $data{metadata}->{identifier}   = $opt->{identifier};
    $data{metadata}->{language}     = $opt->{language};
    $data{metadata}->{title}        = $opt->{title};
    $data{metadata}->{creator}      = $opt->{creator}   if $opt->{creator};
    $data{metadata}->{publisher}    = $opt->{publisher} if $opt->{publisher};
    $data{metadata}->{rights}       = $opt->{rights}    if $opt->{rights};
    $data{guide}->{cover}           = $opt->{cover}     if $opt->{cover};
    $data{tocncx}->{uid}            = $opt->{identifier};
    $data{tocncx}->{depth}          = $opt->{tocdepth};
    $data{tocncx}->{totalPageCount} = 0;
    $data{tocncx}->{maxPageNumber}  = 0;
    $self->{data} = \%data;
    return %data;
} # add_metadata()

sub write_epub {
    my ($self,$outname) = @_;
    my $paths  = $self->{path_ids};
    my $epub   = Archive::Zip->new();
    my $m;

    $m = $epub->addString('application/epub+zip', 'mimetype');

    $m = $epub->addString($embed{'container.xml'}, 'META-INF/container.xml');

    $m = $epub->addString($self->_substitute_template($embed{'content.opf'}),
        'content.opf');

    $m = $epub->addString($self->_substitute_template($embed{'toc.ncx'}),
        'toc.ncx');

    foreach my $path (keys %$paths) {
        next if 'toc.ncx' eq $path;
        $m = $epub->addFile($self->{epubdir} . '/' . $path, $path);
    }

    unless ($outname) {
        $outname = $self->{epubdir} . '.epub';
    }
    unless (AZ_OK == $epub->writeToFileNamed($outname)) {
        die "could not write to $self->{epubdir}.epub: $!";
    }
} # write_epub()

sub _generate_guide {
    my ($self) = @_;
    my $data = $self->{data};
    my @guide = ();
    if (my $g = $data->{guide}) {
        push @guide, q( <guide>);
        foreach my $type (keys %$g) {
            push @guide,
                 qq(   <reference type="$type" title="$guidetitle{$type}")
               . qq( href="$g->{$type}" />);
        }
        push @guide ,q( </guide>);
    }
    return join "\n", @guide;
} # _generate_guide()

sub _generate_manifest {
    my ($self) = @_;
    my $c_opf = $self->{path}->{'content.opf'};
    my $paths = $self->{path_ids};
    my @manifest = ();
    my $type;
    foreach my $path (keys %$paths) {
        my $id = $paths->{$path};
        next if $path eq 'mimetype';
        next if $path eq 'META-INF/container.xml';
        next if $path eq $c_opf;
        if ($path =~ /\.html$/i) {
            $type = 'application/xhtml+xml';
        }
        elsif ($path =~ /\.png$/i) {
            $type = 'image/png';
        }
        elsif ($path =~ /\.jpe?g$/i) {
            $type = 'image/jpeg';
        }
        elsif ($path =~ /toc\.ncx$/i) {
            $type = 'application/x-dtbncx+xml';
            $id   = 'ncx';
        }
        elsif ($path =~ /\.css$/i) {
            $type = 'text/css';
        }
        else {
            die "Don't know type media-type for '$path'!";
        }
        push @manifest, qq(  <item id="$id" href="$path" media-type="$type" />);
    }
    return join "\n", @manifest;
} # _generate_manifest()

sub _generate_metadata {
    my ($self) = @_;
    my @metadata = ();
    my $md = $self->{data}->{metadata};
    push(@metadata
        ,qq(  <dc:identifier id="uid">$md->{identifier}</dc:identifier>)
        ,  "  <dc:language>$md->{language}</dc:language>"
        ,  "  <dc:title>$md->{title}</dc:title>");
    push(@metadata
        , "  <dc:creator>$md->{creator}</dc:creator>") if ($md->{creator});
    push(@metadata
        , "  <dc:publisher>$md->{publisher}</dc:publisher>"
        )                                              if ($md->{publisher});
    push(@metadata
        , "  <dc:rights>$md->{rights}</dc:rights>"
        )                                              if ($md->{rights});
    return join "\n", @metadata;
} # _generate_metadata()

sub _generate_spine {
    my ($self) = @_;
    my $sp     = $self->{spine_order};
    my $paths  = $self->{path_ids};
    my @spine  = ();
    foreach my $path (@$sp) {
        my $id = $paths->{$path};
        push @spine, qq(  <itemref idref="$id" />);
    }
    return join "\n", @spine;
} # _generate_spine()

sub _generate_tocncx_head {
    my ($self) = @_;
    my $data   = $self->{data}->{tocncx};
    my @head   = ();
    foreach my $key (keys %$data) {
        push @head, qq(  <meta name="dtb:$key" content="$data->{$key}"/>);
    }
    return join "\n", @head;
} # _generate_tocncx_head()

sub _generate_tocncx_navMap {
    my ($self) = @_;
    my $epubdir     = $self->{epubdir};
    my $spine_paths = $self->{spine_order};
    my $tocdepth    = $self->{data}->{tocncx}->{depth};
    my @navMap      = ();
    my $id          = 1;
    foreach my $sp (@$spine_paths) {
        my $navPoint;
        ($id, $navPoint) =  $self->_generate_tocncx_navPoint($sp,
                                                             $tocdepth,
                                                             $id);
        push @navMap, $navPoint;
    }
    return join "\n", @navMap;
} # _generate_tocncx_navMap()

sub _generate_tocncx_navPoint {
    my ($self, $path, $depth, $id) = @_;
    my $epubdir = $self->{epubdir};

    die "Can't do tocdepth > 1 at the moment." if (2 < $depth);
    my $tree = HTML::TreeBuilder->new();

    $tree->parse_file("$epubdir/$path");

    my $tt = $tree->look_down('_tag' => 'title');
    my $title = $tt->as_text();
    my $extra = '';
    my $l1id  = $id;
    my $args  = { };
    my $cnt;
    
    if (2 == $depth) {
        my @l2s = $tree->look_down(%{$self->{nav_l2}});
        my $nps = [];

        foreach my $l2 (@l2s) {
            my $text = $l2->as_text();
            if (my $a = $l2->look_down('_tag' => 'a', 'id' => qr//)) {
                my $id   = $a->attr('id');
                push @$nps, [ $path, $id, $text ];
            }
        }
        $args->{counter} = $id + 1;
        $args->{array}   = $nps;
        $args->{indent}  = '    ';
        $extra = _tocncf_navPoints_from_array($args);
        $cnt   = $args->{counter};
    }
    else {
        $cnt   = $id + 1;
    }

    $args->{counter} = $id;
    $args->{array}   = [ [ $path, '', $title, $extra ], ];
    $args->{indent}  = '  ';

    my $navPoints = _tocncf_navPoints_from_array($args);

    return ($cnt, $navPoints);
} # _generate_tocncx_navPoint()

sub _init {
    my ($self, $args) = @_;

    die "need argument 'epubdir'"       unless (defined $args->{epubdir});
    $self->{epubdir} = $args->{epubdir};
    $self->{epubdir} =~ s|/$||;
    $self->{spine_order} = $args->{spine_order};
    if ($args->{level2}) {
        #
        # $args->{level2} comes as 'attr1:val1,attr2:val2,...' and goes into
        # $self->{nav_l2} as { attr1 => val1, attr2 => val2, ... }
        #
        my @attrs = split(/,/, $args->{level2});
        my %nav_l2 = map { my @p = split(/:/, $_, 2); $p[0] => $p[1] } @attrs;
        $self->{nav_l2} = \%nav_l2;
    }

    $self->_scan_directory();
    $self->_spine_order();
    $self->{path}->{'content.opf'} = 'content.opf';
} # _init()

sub _scan_directory {
    my ($self)   = @_;
    my $startdir = $self->{epubdir};
    my $id = 1;
    my $dirs = {};
    my $have_toc_ncx = 0;
    my $adddir = sub {
        if (m|^$startdir/(.+)$| && -f $_) {
            my $path = $1;
            $dirs->{$path} = "id$id";
            $id++;
            if ($path =~ m|(.*/)?toc\.ncx$|) {
                $have_toc_ncx = 1;
            }
        }
    };
    find( {wanted => $adddir, no_chdir => 1 },$startdir);
    unless ($have_toc_ncx) {
        $dirs->{'toc.ncx'} = 'ncx';
    }
    $self->{path_ids} = $dirs;
    return %$dirs;
} # _scan_directory()

sub _spine_order {
    my ($self) = @_;
    my $paths = $self->{path_ids};
    my $order = $self->{spine_order};
    my %o2p = ();
    my @spo = ();
    foreach my $path (keys %$paths) {
        next unless $path =~ /^(.+)\.html/i;
        my $si = $1;
        $si =~ s|^.+/([^/]+)$|$1|;
        $o2p{$si} = $path;
    }
    if ($order) {
        @spo = map { $o2p{$_} } split /,/, $order;
    }
    else {
        @spo = map { $o2p{$_} } sort keys %o2p;
    }
    $self->{spine_order} = \@spo;
    return @spo;
} # _spine_order()

sub _substitute_template {
    my ($self,$tmpl,$data) = @_;
    my $out = "";

    unless (exists $self->{substitutes}) {
        my $s = {};
        $s->{'%%GUIDE%%'}          = $self->_generate_guide(),
        $s->{'%%MANIFEST%%'}       = $self->_generate_manifest(),
        $s->{'%%METADATA%%'}       = $self->_generate_metadata(),
        $s->{'%%SPINE%%'}          = $self->_generate_spine(),
        $s->{'%%TOCNCXDOCTITLE%%'} = '<text>'
                                     . $self->{data}->{metadata}->{title}
                                     . '</text>',
        $s->{'%%TOCNCXHEAD%%'}     = $self->_generate_tocncx_head(),
        $s->{'%%TOCNCXNAVMAP%%'}   = $self->_generate_tocncx_navMap(),
        $self->{substitutes} = $s;
    }
    my $substitutes = $self->{substitutes};

    my $replace = sub {
        my ($pattern) = @_;
        return $substitutes->{$pattern} ? $substitutes->{$pattern} : '';
    };

    my @lines = split /\n/, $tmpl;
    foreach (@lines) {
        s/(%%[^%]+%%)/$replace->($1)/e;
        $out .=  $_ . "\n";
    }
    return $out;
} # _substitute_template()

# Functions not bound to an object.
# ---------------------------------

# _tocncf_navPoints_from_array( {
#     counter => $cnt,
#     array   => $array,
#     indent  => "  ",
#     } )
#
# Returns a string containing <navPoint> entries for the <navMap> in toc.ncf
# from the given array. The first id is named "navPoint-$cnt" and the first
# playOrder "$cnt". $cnt is updated to the next number after the last
# playOrder.
#
# The array should be of the form [ [ $fname, $anchor, $text, $extra ], ... ],
# where $fname is the name of the file, $anchor the id of an html anchor
# (<a id="$anchor" ...>) and $text the text belonging to the anchor. The
# fourth field ($extra) is optional and can be used for next level navPoints.
#
sub _tocncf_navPoints_from_array {
    my ($args) = @_;
    my @anchors = @{$args->{array}};
    my $indent = $args->{indent} || "";

    my $np = sub {
        my $count = $args->{counter}++;
        my $href  = ($_[0]->[1]) ? $_[0]->[0] . "#" . $_[0]->[1] : $_[0]->[0];
        my $label = $_[0]->[2];
        my $extra = $_[0]->[3] || '';
        return << "EONAVPOINT";
$indent<navPoint id="navpoint-$count" playOrder="$count">
$indent  <navLabel><text>$label</text></navLabel>
$indent  <content src="$href" />
$extra$indent</navPoint>
EONAVPOINT
    };

    my $navPoints = join("", map { $np->($_) } @anchors);
} # _tocncf_navPoints_from_array()

1; # Magic true value required at end of module
__END__

=head1 NAME

App::MakeEPUB - Create an EPUB ebook

=head1 VERSION

This document describes App::MakeEPUB version 0.0.1

=head1 SYNOPSIS

    use App::MakeEPUB;

    my $epub = App::MakeEPUB->new( { epubdir => $epubdir } );

    $epub->add_metadata( { identifier => $identifier,
                           language   => $language,
                           title      => $title,
                           creator    => $creator,
                           publisher  => $publisher,
                           rights     => $rights,
                           cover      => $cover, } );

    $epub->write_epub();

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

This library is used by the script make-epub to create an ebook in EPUB
format.

=head1 INTERFACE 

=head2 new()

    my $epub = App::MakeEPUB->new( {
        epubdir     => $epubdir,
        level2      => $level2,
        spine_order => $spine_order,
    } );

Create an App::MakeEPUB object;

The named argument I<epubdir> is the path to the directory containing the
files for the ebook.

The named argument I<spine_order> takes a string containing the names of the
XHTML files in spine order as a comma separated list. If it is missing the
names are sorted by alphabet.

The named argument I<level2> takes a string containing instructions for
HTML::Element->look_down() on how to find the text and id for the level 2
navPoints in the file I<toc.ncf>. It takes a string like
'attr1:val1,attr2:val2,...' and translates it into

  HTML::Element->look_down( { attr1 =>  val1, attr2 => val2, ... } );

The content for the navPoint is taken from the first C<< <a> >> tag inside
each HTML::Element found by I<look_down()> and containing an attribute I<id>.
The text for the navPoint is taken from the whole text inside each
HTML::Element found.

If the argument I<level2> is missing, '_tag:span,class:h2' is taken. This
will take the navPoints from all spans looking roughly like

  <span class="h2"><a id="navid">some text</a></span>

and translates them to something like

  <navPoint id="navpoint-id" playOrder="order">
    <navLabel><text>some text</text></navLabel>
    <content src="filename#navid" />
  </navPoint>

=head2 add_metadata()

    $epub->add_metadata( { identifier => $identifier,
                           language   => $language,
                           title      => $title,
                           creator    => $creator,
                           publisher  => $publisher,
                           rights     => $rights,
                           cover      => $cover, } );

Add Metadata to the EPUB. 

The following keys are accepted:

=over 4

=item identifier, language, title, creator, publisher, rights

These go into the C<< <metadata> >> section of the I<content.opf> as
C<< <dc:identifier...> >>, C<< <dc:language...> >> and so on.

=item cover

This goes into die C<< <metadata> >> section of the I<content.opf> as
C<< <reference type="cover" ...> >>.

=back

=head2 write_epub()

    $epub->write_epub();
    $epub->write_epub($filename);

This method writes the epub.

If a filename is given it writes the file under that name. Otherwise the name
will be built from the name of the directory containing the files given in
argument C<epubdir> to I<new()> with the suffix C<.epub> added.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
App::MakeEPUB requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-makeepub@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mathias Weidner  C<< <mamawe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Mathias Weidner C<< <mamawe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

