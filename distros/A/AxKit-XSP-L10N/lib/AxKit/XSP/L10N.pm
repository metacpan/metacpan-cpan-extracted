# $Id: /local/CPAN/AxKit-XSP-L10N/lib/AxKit/XSP/L10N.pm 1402 2008-03-08T20:28:41.664717Z claco  $
package AxKit::XSP::L10N;
use strict;
use warnings;
use vars qw($VERSION $NS @EXPORT_TAGLIB);
use base 'Apache::AxKit::Language::XSP::TaglibHelper';
use base 'Locale::Maketext';
use Apache;

$VERSION = '0.05000';
$NS = 'http://today.icantfocus.com/CPAN/AxKit/XSP/L10N';

@EXPORT_TAGLIB = (
    'translate($value;$base,$lang,@param)'
);

sub translate {
    my ($value, $base, $lang, $params) = @_;
    my $lh = _get_handle($base, $lang);

    $base ||= '';
    $lang ||= '';

    AxKit::Debug(5, "[L10N] value=$value,base=$base,lang=$lang");

    if ($lh) {
        AxKit::Debug(5, "[L10N] loaded language handle " . ref $lh);

        return _to_utf8($lh->maketext($value, @{$params}));
    } else {
        return $value;
    };
};

sub _get_handle {
    my ($base, $lang) = @_;
    my $r = Apache->request;
    my $module = $base || $r->dir_config('AxL10NBase') || __PACKAGE__;

    $base ||= '';

    AxKit::Debug(5, "[L10N] base=$module");

    eval "require $module";

    if (!$@) {
        return $module->get_handle($lang);
    } else {
        AxKit::Debug(5, "[L10N] $@");

        return undef;
    };
};

sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) {
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

1;
__END__

=head1 NAME

AxKit::XSP::L10N - String localization (L10N) taglib for AxKit

=head1 SYNOPSIS

Add this taglib to AxKit in your http.conf or .htaccess:

    AxAddXSPTaglib AxKit::XSP::L10N

and set your base L10N module path:

    PerlSetVar  AxL10NBase  MyPackage::L10N

Add the namespace to your XSP file and use the tags:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:l10n="http://today.icantfocus.com/CPAN/AxKit/XSP/L10N"
    >

    <l10n:translate value="Please select a state from the list below"/>

=head1 DESCRIPTION

This tag library provides an interface to localiize string values
within XSP pages using C<Locale::Maketext>.

=head1 TAG HIERARCHY

    <l10n:translate base="" lang="en|fr|..." value="" param="">
        <l10n:base></l10n:base>
        <l10n:lang></l10n:lang>
        <l10n:value></l10n:value>
        <l10n:param></l10n:param>
    </l10n:translate>

=head1 TAG REFERENCE

=head2 <l10n:translate>

Translates a given string value to the language of the users browser,
or to the language specified in the C<lang> attribute.

The C<translate> tag has three options:

=over

=item base

If you need to use different sets of localization modules within the same
page or sets of pages and C<AxL10NBase> is too strict, you can specify
the base module name to be loaded for each call to translate:

    PerlSetVar AxL10NBase MyModule::L10N;

    <l10n:translate value="Submit" lang="en"/>
        # uses MyModule::L10N::en

    <l10n:translate base="OtherModule::L10N" lang="en"/>
        # uses OtherModule::L10N::en

If no C<base> or C<AxL10NBase> are specified, or the given C<base> or
C<AxL10NBase> can't be loaded, the supplied C<value> will be returned.

=item lang

This specifies the target language to localize the string to.
It can be specified as either an attribute, or as a child tag.

    <l10n:translate lang="fr"></l10n:translate>

If no C<lang> is supplied, C<Locale::Maketext> will attempt to guess
the best language. Since this is running under AxKit/mod_perl, it
should find the language specified in the C<Accept-Language> header
of the users browser.

=item value

This is the string to be localized. It can be specified as either an
attribute, or as a child tag.

    <l10n:translate>English</l10n:translate>

Make sure to read the section on "AUTO LEXICONS" in C<Locale::Maketext>
for more information on the various methods and actions performed when no
entry can be found for C<value> or no suitable language modules can be found.

=item param

These are values parameters to be used in C<Locale::Maketext>s
"BRACKET NOTATION". This is similiar to using parametera in C<sprinf>.

    <l10n:translate>
        <l10n:value>You have [_1] items marked in [_2] folders.</l10n:value>
        <l10n:param>23</l10n:param>
        <l10n:param>5</l10n:param>
    </l10n:translate>

It can be specified as either an attribute, or as a child tag.
B<Note>, when using C<param> as an attribute, it can only be specified once.
If you need to pass more than one attribute, pass them in as child tags
instead.

See C<Locale::Maketext> for more information on the use of parameters.

=back

=head1 CONFIGURATION

The following configuration variables are available:

=head2 AxL10NBase

This sets the name of the base localization module to use.
See C<Locale::Maketext> for more information how to construct the base
localization module and specific language module lexicons.

    AxL10NBase  MyPackage::L10N

=head1 SEE ALSO

L<Locale::Maketext>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
