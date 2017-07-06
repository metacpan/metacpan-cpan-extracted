package Dancer2::Plugin::Locale;

use strict;
use warnings;

use Dancer2::Plugin;
$Dancer2::Plugin::Locale::VERSION = '0.07';

package Dancer2::Plugin::Locale::Obj;
use Locales 0.33 unicode => 1;
use Locale::Maketext::Utils;
use base 'Locale::Maketext::Utils';
our %Lexicon;

package Dancer2::Plugin::Locale;

use File::Spec;

# use Tie::Hash::ReadonlyStack;

plugin_keywords 'locale';

sub locale {
    my $dsl = shift;

    if (@_) {
        return Dancer2::Plugin::Locale::Obj->get_handle( grep( { defined } (@_) ), 'en' );    # multiton already via Locale::Maketext::Utils
    }

    my $app = $dsl->app;

    # TODO 2: request locale via browser/HTP req after session and before default?
    return Dancer2::Plugin::Locale::Obj->get_handle( grep( { defined } ( eval { $app->session->read('locale') }, $dsl->config->{default_locale} ) ), 'en' );    # multiton already via Locale::Maketext::Utils
}

sub BUILD {
    my $dsl = shift;

    my @available_locales = ('en');

    # read locale/ dir for available locales (via config also? likley YAGNI/overly comlicated-why?)
    my $locale_dir = File::Spec->catdir( $dsl->app->config->{'appdir'}, 'locale' );                                                                             # configurable? nah, why?
    if ( -d $locale_dir ) {
        if ( opendir my $dh, $locale_dir ) {
            while ( my $file = readdir($dh) ) {
                next if $file !~ m/\.json$/;
                next if $file eq 'en.json';
                $file =~ s/\.json//;
                if ( Locales::normalize_tag($file) ne $file ) {
                    warn "Skipping un-normalized locale named lexicon ($file.json) …\n";                                                                      # just no apparent need to complicate things by trying to deal with this
                    next;
                }

                if ( !-f "$locale_dir/$file.json" ) {
                    warn "Skipping non-file lexicon ($file.json) …\n";
                    next;
                }

                push @available_locales, $file;
            }
            closedir($dh);
        }
        else {
            die "Could not read locale directory ($locale_dir): $!\n";
        }
    }
    no strict 'refs';          ## no critic
    no warnings 'redefine';    ## no critic
    *Locale::Maketext::Utils::list_available_locales = sub {
        return ( sort @available_locales );
    };

    # create classes that Locale::Maketext uses
    for my $tag (@available_locales) {
        my $file = File::Spec->catfile( $locale_dir, "$tag.json" );

        # TODO 1: for en (and its alias) empty value means key *is* value …

        # TODO 1: support tieing to CDB_File hash (e.g. if -f locale_cdb/$tag.cdb) so as not to load all the data into memory (see use_external_lex_cache)?

        # TODO 2: POD app w/ charset !utf8 == ick
        eval "package Dancer2::Plugin::Locale::Obj::$tag;use base 'Dancer2::Plugin::Locale::Obj';our \$Encoding='utf8';our \%Lexicon;package Dancer2::Plugin::Locale;";    ## no critic

        no strict 'refs';                                                                                                                                                  ## no critic
                                                                                                                                                                           #
        my $hr = $tag eq 'en' && !-e $file ? {} : ( _from_json_file($file) || {} );
        %{"Dancer2::Plugin::Locale::Obj::$tag\::Lexicon"} = %{$hr};

        # TODO 1: instead: tie %{"Dancer2::Plugin::Locale::$tag\::Lexicon"}, 'Tie::Hash::ReadonlyStack', _from_json_file($file);
    }

    # TODO 2: Is there a better way to add template keyword?
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                $_[0]->{locale} = sub { $dsl->locale(@_) };
            },
        )
    );
}

sub _from_json_file {
    my ($file) = @_;
    open( my $fh, '<', $file ) or die "Could not read “$file”: $!";
    use Dancer2::Serializer::JSON;
    my $ref = {};
    eval {
        $ref = Dancer2::Serializer::JSON::from_json(
            do { local $/; <$fh> }
        );
    };
    if ($@) {

        warn "Ignoring lexicon, $file, since it containes invalid JSON:\n\t$@";
    }
    return $ref;
}

# TODO 2: localization tips
# TODO 2: extractor/checker tool

1;

__END__

=encoding utf8

=head1 NAME

Dancer2::Plugin::Locale - Localize your Dancer2 application

=head1 VERSION

This document describes Dancer2::Plugin::Locale version 0.07

=head1 SYNOPSIS

In your app:

    use Dancer2;
    use Dancer2::Plugin::Locale;

    …
        locale->maketext('You are [numf,_1] of [numf,_2].', 42, 99);
    …

and from template

    <div id="req_msg">[% locale.maketext('You have [quant,_1,request,requests].', req_count) %]</div>

=head1 DESCRIPTION

Adds a C<locale> keyword for your code and templates.

=head1 INTERFACE 

=head2 locale

A lazy façade to get a locale handle suitable to the request. The locale object is a CLDR aware maketext format object.

It will be based on the session’s locale value if possible, then a configured default if possible, then 'en'.

=head2 The object, in more detail

The object is L<Locale::Maketext::Utils> based.

L<Locale::Maketext::Utils> extends L<Locale::Maketext> a number of ways including:

=over 4

=item * It shifts toward CLDR based functionality which means you no longer have to create locale specific variants of code in each locale’s class.

=item * Because of that and other utils it has, creating and dealing with the locale subclasses classes is much easier.

=item * The object is a multiton (AKA an argument based singleton):  L<Locale::Maketext::Utils/"Argument based singleton">

=item * Adds a number of helpful methods: L<Locale::Maketext::Utils/METHODS>

=item * More sane fallback and lookup failure hooks: L<Locale::Maketext::Utils/"Automatically _AUTO'd Failure Handling with hooks">

=item * Adds a very handy set of bracket notation methods (CLDR when possible)  L</"Bracket Notation">

=back

=head3 Available Locales

The locales available are determined by the lexicon files found in the appdir’s C<locale/> directory.

The name of each file must be a normalized version (See Locales::normalize_tag() in L<Locales>) of an L<acceptable ISO tag|Locales/"Supported_Locale_Criteria">. and end in with the extension C<.json>.

Tip: To make them available to your UI you could simply symlink C<…/locale/> to C<…/public/locale>.

=head3 Lexicon

A lexicon is a simple key/value hash  where the key is the phrase and the value is the translation.

For example,in pseudo code:

    # source phrase => target phrase
    'Hello World' => 'Bonjour Monde'

Each locale will have a lexicon hash in a file as desrcibed in L</"Available Locales">.

The hash must be written in JSON format and be utf8 encoded.

Don’t be afraid of non-ASCII characters, just put them in the file as the character and it will work fine (if it doesn’t then it can help you track down bugs faster, win win!).

    "I ♥︎ Dancer2!" : "私は♥︎ダンサー2"

=head3 Bracket Notation

Bracket notation is described a bit more at L<Locale::Maketext/BRACKET NOTATION> but is essentially a format to allow you to notate–within left and right square brackets, hence the name–dynamic portions of a phrase.

For example, include a non-translatable ever-changing name:

    locale->maketext('Your email address, [_1], has been unsubscribed.', $email)

or a number formatted according to the object’s locale’s CLDR data:

    locale->maketext('You are user [numf,_1] of [numf,_2].', $place, $count)

The bracket notation improvements over the core L<Locale::Maketext> can be categoraized as follows:

=over 4

=item * L<improved core Locale::Maketext bracket notation methods|http://search.cpan.org/perldoc?Locale::Maketext::Utils#Improved_Bracket_Notation>

=item * L<additional bracket notation methods|http://search.cpan.org/perldoc?Locale::Maketext::Utils#Additional_bracket_notation_methods>

=item * L<output() bracket notation methods|http://search.cpan.org/perldoc?Locale::Maketext::Utils#output()>

=back

=head2 Misc Info

=head3 Only load the lexicon data you need!

… TODO, sorry I needed to get this on CPAN for a consumer but will finish it ASAP …

=head4 per app/route loading/unloading of specific lexicon

… TODO, sorry I needed to get this on CPAN for a consumer but will finish it ASAP …

=head4 only load the keys you use

=head3 Localization Principles

… TODO, sorry I needed to get this on CPAN for a consumer but will finish it ASAP …

=head3 Extracting and Vetting phrases from your app

… TODO, sorry I needed to get this on CPAN for a consumer but will finish it ASAP …

=head2 TODOs

TODO items in the POD obviously, will list more if there are any left after the next version.

=head1 DIAGNOSTICS

=head2 Errors

If the C<locale/> directory exists but can not be opened:

C<<Could not read locale directory (%s): $!>>

=head2 Warnings

If you have a mis-named file in your C<locale/> directory:

C<<Skipping un-normalized locale named lexicon (%s.json) …>>

If you have a properly named lexicon that is not a file in your C<locale/> directory:

C<<Skipping non-file lexicon (%s.json) …>>

If you have a lexicon that can’t be loaded (e.g. broken JSON):

C<<Ignoring lexicon, %s, since it containes invalid JSON:\n\t$@>>

=head1 CONFIGURATION AND ENVIRONMENT

The default locale is “en”, you can change it via Dancer2 configuration like so:

    plugins:
      Locales:
        default_locale: ja

=head1 DEPENDENCIES

L<Dancer2::Plugin>

L<Locale::Maketext::Utils>

L<Locales>

L<File::Spec>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Dancer2-Plugin-Locale/issues>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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
