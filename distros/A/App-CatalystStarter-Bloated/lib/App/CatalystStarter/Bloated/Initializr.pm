package # hide from pause
    App::CatalystStarter::Bloated::Initializr;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.9.3');

use File::ShareDir qw/module_file/;
use Archive::Zip;
use File::Basename;
use Mojo::DOM;
use Log::Log4perl qw/:easy/;

my $az;
my $logger = get_logger;
## nice to have this in top
sub l{
    $logger
}
sub _require_az {
    confess "az object not initialized" unless defined $az and $az->isa("Archive::Zip");
}
sub _set_logger {
    $logger = shift;
}

## Top level functions
sub deploy {

    _initialize();

    _require_az;

    my $dir = shift;

    _setup_index();
    _move_images();
    _move_css_js_fonts();

    $az->extractTree( "initializr", $dir );
    l->info( "HTML5: template unzipped to catalyst root" );

}
sub _initialize_from_cache {
    l->debug("Getting template from cache");
    _set_az_from_cache();
}
sub _initalize_over_http {
    l->debug("Getting template from initializr.com" );
}
sub _initialize {
    _initialize_from_cache;
    l->debug("HTML5: Template loaded");
}

## High level functions:


## parse index.html:
## 1) substitute content for [% content %]
## 2) store it again with new name wrapper.tt2
##    - index.html should not be in zip afterwards
## 3) fix any local links to img, css or js, should point to:
## 4) /static/images, css and js
sub _setup_index {

    _require_az;

    my $dom = _index_dom();

    ## insert content template var
    {
        my $div = $dom->find( 'body > div[class="container"]' )->first;
        if ( !$div ) {
            croak "container tag not found in html template - cannot continue";
        }
        $div->content( "[% content %]" );
        l->debug( "HTML5: Wrapper content template var inserted" );
    }

    ## insert jumbotron, might aswell since the template has it
    {
        my $div = $dom->find
            ( 'body > div[class="jumbotron"] > div[class="container"]' )->first;
        if ( !$div ) {
            croak "container tag not found in html template - cannot continue";
        }

        my $p = $div->parent;

        $p->prepend( "\n[% IF jumbotron %]" .
                         "[% # put a h1 and one or more p in here %]\n    "
                     );

        my $h1 = $div->find( 'h1' )->first;
        $h1->content( '[% jumbotron.header %]' );
        my $ps = $div->find( 'p' );

        my $pa = $ps->first;

        $pa->content( '[% jumbotron.body %]' );

        my $i;
        $div->children->each
            ( sub {

                  if ( ++$i > 2 ) {
                      $_[0]->remove;
                  }

              });



        $p->append( "\n[% END %]\n" );
        l->debug( "HTML5: Wrapper jumbotron template var inserted" );
    }

    ## fix any relative links to img/ or css/ or js/ to now point to static/
    $dom->find("*")->each(
        sub {
            my($element,$i) = @_;

            my %h = %$element;

            while ( my($key,$val) = each %h ) {

                # print "# '$key'='$val' ";

                if ( $val =~ m{(?:\./)?img/} ) {
                    (my $new_val = $val) =~
                        s{(?:\./)?img/(.*)}{[% c.uri_for(QUOTEHERE/static/images/$1QUOTEHERE) %]};
                    $element->attr($key => $new_val);
                    # print "=> '$new_val'";
                }
                elsif ( $val =~ m{(?:\./)?(css|js)/} ) {
                    my $d = $1;
                    (my $new_val = $val) =~
                        s{(?:\./)?$d/(.*)}{[% c.uri_for(QUOTEHERE/static/$d/$1QUOTEHERE) %]};
                    $element->attr($key => $new_val);
                    # print "=> '$new_val'";
                }

                # print "\n";

            }

        });
    l->debug("HTML5: references to img/ css/ js/ and fonts/ changed to static/*");

    (my $new_index_content = "$dom") =~ s/QUOTEHERE/"/g;

    ## this won't be handled because it's not an html element
    ## attribute, and we're not parsing javascript (yet?)
    $new_index_content =~ s{\Qdocument.write('<script src="js/vendor/jquery-1.10.1.min.js">}
                           {document.write('<script src="[% c.uri_for("/static/js/vendor/jquery-1.10.1.min.js") %]">};

    ## replace it into the zip
    my $index_member = _safely_search_one_member( qr/index\.html$/ );
    my $index_name = $index_member->fileName;
    my($f,$d) = fileparse( $index_name );
    $az->contents( $index_member, $new_index_content );

    $index_member->fileName( $d."wrapper.tt2" );
    l->debug("HTML5: index.html changed to wrapper.tt2" );

}
sub _move_images {

    _require_az;

    ## change dir name from img/* to static/images/*

    my @img_members = $az->membersMatching(qr(/img/));

    if (not @img_members) {
        carp "did not find any img/ files in zip, this does not feel right";
        return;
    }

    for my $m (@img_members) {
        (my $new_name = $m->fileName) =~ s|/img/|/static/images/|;
        $m->fileName( $new_name );
    }

    l->debug(sprintf "HTML5: %d image(s) moved from img/ to images/",
         scalar(@img_members) );

}
sub _move_css_js_fonts {

    _require_az;

    ## change dir name from img/* to static/images/*

    my @static_members = $az->membersMatching(qr(/(?:css|js|fonts)/));

    if (not @static_members) {
        carp "did not find any js/ or css/ files in zip, that cannot be right";
        return;
    }

    for my $m (@static_members) {
        (my $new_name = $m->fileName) =~ s{/(css|js|fonts)/}{/static/$1/};
        $m->fileName( $new_name );
    }

    l->debug(sprintf "HTML5: %d css, js or fonts files moved to static/*",
         scalar(@static_members) );

}

## Low level functions:
sub _az {
    return $az;
}
sub _set_az_from_cache {

    my $zip_file = module_file( __PACKAGE__, "initializr-verekia-4.0.zip" );
    return $az //= Archive::Zip->new( $zip_file );

}
sub _safely_search_one_member {

    my ($qr,$allowed_to_live_when_doesnt_match) = @_;

    _require_az;

    my @m;

    if ( ref $qr eq "Regexp" ) {
        @m = $az->membersMatching({ regex => $qr });
    }
    else {
        @m = ($az->memberNamed( $qr ));
    }

    if ( @m != 1 and not $allowed_to_live_when_doesnt_match or @m > 1 ) {
        croak "Found 0 or more than one zip member match for '$qr'";
    }

    return $m[0];

}
sub _zip_content {

    my( $qr, $new_content ) = @_;

    _require_az;

    my $member = _safely_search_one_member($qr) or return;

    if ( $new_content ) {
        return $az->contents( $member, $new_content );
    }
    else {
        return $az->contents( $member );
    }
}
sub _index_dom {

    _require_az;

    my $h = _zip_content( qr/index\.html$/ );
    my $dom = Mojo::DOM->new( $h );

    return $dom;

}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

App::CatalystStarter::Bloated::Initializr - Setup a html5 template
from initializr.com in your catalyst project


=head1 VERSION

This document describes App::CatalystStarter::Bloated::Initializr version 0.9.3

=head1 SYNOPSIS

    # Don't use this module. catalyst-fatstart.pl uses this for magic.

=head1 DESCRIPTION

This module offers the following functionality:

=over

=item Offer a cached zip download from initializr.com with a given set of options

=item Download a new zip file from initializr.com.

If this fails, offer to provide the cached version bundled with this
module instead

=item Process the zipped file, correct paths to images, css and js

Adaptes it to fit to a catalyst setup with /root/static/images etc.

=item Inserts [% content %] to make it work as a wrapper

Inspects the HTML and locates what content should be substituted with this tag

=item Future versions will allow custom downloads from initializr.com

Ie choosing what content to include

=back

All modifications is done in the zip file which is then written to disk.

=head1 INTERFACE

=head2 deploy($directory)

Processes zip and extracts it at given dir.

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

App::CatalystStarter::Bloated::Initializr requires no configuration files or environment variables.


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
C<bug-bug-app-catalyststarter::bloated::initializr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

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
