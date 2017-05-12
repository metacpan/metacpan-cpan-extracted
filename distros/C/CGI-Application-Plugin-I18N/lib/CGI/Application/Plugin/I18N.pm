package CGI::Application::Plugin::I18N;


=head1 NAME

CGI::Application::Plugin::I18N - I18N and L10N methods for CGI::App

=head1 SYNOPSIS

Nothing is exported by default. You can specify a list of individual methods or
use one of the groups :std, :max or :min.

    use CGI::Application::Plugin::I18N qw( :std );

Within your setup, cgiapp_init, cgiapp_prerun or specific runmode routine add
the line

    $self->i18n_config();

Or

    $self->i18n_config( %options );

%options are the same as for Locale::Maketext::Simple. If none are passed the
following default are used:-

    %DEFAULT_OPTIONS = (
        Path        => "$RealBin/I18N",
        Style       => 'gettext',
        Export      => '_maketext',
        Decode      => 1,
        Encoding    => '',
    );

$RealBin being the folder from which the executed cgi script is running.
B<Note that Export must remain as _maketext for this module to function
properly!>

For instance if you wanted to use maketext style markup in your lexicons you
would use the line:-

    $self->i18n_config( Style => 'maketext' );

Then use the I<localtext> method to localize text:-

    print $self->localtext( 'Hello World!' );

=head1 DESCRIPTION

This module is a wrapper around C<Locale::Maketext::Simple> by Audrey Tang.
It extends the C<CGI::Application> object with variour methods to control the
localization of text. A L</FAQ> is provided with the aim to fill in the gaps.

=head1 Methods

=head2 i18n_config

Runs the initial configuration of C<Locale::Maketext::Simple> and runs it's
import within your calling objects namespace (Your CGI::App class)

=head2 localtext_langs

Sets the current language for localtext output. Usage:-

    $self->localtext_langs( LIST );

LIST must consist of valid language tags as defined in RFC3066. See
C<I18N::LangTags> for more details.
If LIST is ommited then the method will attempt to figure out the users locale
using C<I18N::LangTags::Detect>.

This method will also return the list of language tags as an array reference.

    my $langtags = $self->localtext_langs( LIST );
    print @$langtags;

=head2 localtext_lang

This method returns the currently selected language. This is the tag that was
actually available for use, after searching through the localtext_langs list.
This is the name of the module used in your MyAPP::I18N::XXX namespace (where
XXX is the name of the lexicon used)

    my $lexicon = $self->localtext_lang;

=head2 localtext_lang_tag

This method returns the RFC3066 language tag for the currently selected
language. This differs from the above method which would most likely return
I<en_us> for American English, whereas this method would return I<en-us>.

    my $langtag = $self->localtext_lang_tag;

=head2 localtext

This is the method that actually does the work.

    print $self->localtext( 'Hello World!' );

=head2 loc

You can choose to import a shorter method called C<loc> that works the same way
as C<localtext>. You need to specify this when you use the module:-

    use CGI::Application::Plugin::I18N qw( loc );
    print $self->loc( 'Hello World!' );

=head2 Export groups

:max exports:-

    i18n_config localtext_langs localtext_lang localtext_lang_tag localtext loc

:std exports:-

    i18n_config localtext_langs localtext_lang localtext_lang_tag localtext

:min exports:-

    i18n_config localtext

=head1 FAQ

=head2 How does it all work?

I kept a blog on how I put this module together and all the material I looked
through in order to understand internationalization.
L<http://perl.bristolbath.org/blog/lyle/2008/12/giving-cgiapplication-internationalization-i18n.html>

=head2 What is a Lexicon?

Think of it as a kind of hash. Where the text you use (usually english) has a
corrosponding value in the local language. So the 'Hello world' under a German
lexicon would have the value 'Hallo welt'.

=head2 Is there some sort of guide?

Yes I've written one. L<CGI::Application::Plugin::I18N::Guide>
See Guide.pod which is part of this distribution. It'll walk you through what
you need to know, and how to make your lexicons.

=head1 Thanks to:-

L<Catalyst::Plugin::I18N> - The module this one was heavily based on

L<Locale::Maketext::Simple> - Making it possible

L<Locate::Maketext> - Doing all the hard work

L<CGI::Application> - Providing the framework

And all others I haven't yet mentioned.

=head1 Come join the bestest Perl group in the World!

Bristol and Bath Perl moungers is renound for being the friendliest Perl group
in the world. You don't have to be from the UK to join, everyone is welcome on
the list:-
L<http://perl.bristolbath.org>

=head1 AUTHOR

Lyle Hopkins ;)

=cut



use strict;
use warnings;
use Carp;

use FindBin qw($RealBin);

use I18N::LangTags ();
use I18N::LangTags::Detect;

require Locale::Maketext::Simple;

use vars qw ( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $RealBin %DEFAULT_OPTIONS );

require Exporter;
@ISA = qw(Exporter);

@EXPORT = ();

@EXPORT_OK = qw(
    i18n_config
    localtext_langs
    localtext_lang
    localtext_lang_tag
    localtext
    loc
);

%EXPORT_TAGS = (
    all => [ qw(i18n_config localtext_langs localtext_lang localtext_lang_tag localtext loc) ],
    std => [ qw(i18n_config localtext_langs localtext_lang localtext_lang_tag localtext) ],
    min => [ qw(i18n_config localtext) ],
);

$VERSION = '0.03';

%DEFAULT_OPTIONS = (
    Path        => "$RealBin/I18N",
    Style       => 'gettext',
    Export      => '_maketext',
    Decode      => 1,
    Encoding    => '', # When set to locale, .po and .mo files that include a Content-Type cause the software to die?
);


sub i18n_config {

    my $self = shift;
    my $class = ref $self || $self;
    
    local %DEFAULT_OPTIONS = %DEFAULT_OPTIONS;
    if ( @_ ) {
        my %newoptions = @_;
        my @valid_options = ("Class","Style","Export","Subclass","Decode","Encoding","Path");
        foreach my $key (keys %newoptions) {
            unless (grep (/^$key$/, @valid_options)) {
                croak( "Invalid option: $key" );
            }#unless
        }#foreach
        %DEFAULT_OPTIONS = (%DEFAULT_OPTIONS, %newoptions);
    }#if

    my $evalcode = qq~
        package $class;
        Locale::Maketext::Simple->import( \%CGI\::Application\::Plugin\::I18N\::DEFAULT_OPTIONS );
    ~;
    eval $evalcode;

    if ( $@ ) {
        croak( qq~Couldn't initialize i18n, error "$@", code "$evalcode"~ );
    }#if
    
}#sub


sub localtext_langs {
    my $self = shift;
    my @langs = @_;
    if (@langs) {
        $self->{__I18N_LANGS} = \@langs;
    }#if
    else {
        ### Get CGI query object
        my $q = $self->query();
        $self->{__I18N_LANGS} = [
            I18N::LangTags::implicate_supers(
                I18N::LangTags::Detect->http_accept_langs(
                    $q->http('Accept-Language')
                )
            ),
            'i-default'
        ] unless $self->{__I18N_LANGS};
    }#else
    no strict 'refs';
    &{ ref($self) . '::_maketext_lang' }( @{ $self->{__I18N_LANGS} } );
    return $self->{__I18N_LANGS};
}#sub


sub localtext_lang {
    my $self = shift;
    my $class = ref $self || $self;

    my $lang = ref "$class\::I18N"->get_handle( @{ $self->localtext_langs } );
    $lang =~ s/.*:://;

    return $lang;
}#sub


sub localtext_lang_tag {
    my $self = shift;
    my $class = ref $self || $self;

    return "$class\::I18N"->get_handle( @{ $self->localtext_langs } )->language_tag;
}#sub


sub localtext {
    my $self = shift;
    $self->localtext_langs unless $self->{__I18N_LANGS};
    no strict 'refs';
    return &{ ref($self) . '::_maketext' }( $_[0], @{ $_[1] } ) if ( ref $_[1] eq 'ARRAY' );
    return &{ ref($self) . '::_maketext' }(@_);
}#sub

sub loc {
    &localtext;
}#sub



1;
