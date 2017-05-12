package Catmandu::Importer::MWTemplates;
use v5.14;

use namespace::clean;
use Catmandu::Sane;
use Furl;
use Moo;

our $VERSION = '0.01';

with 'Catmandu::Importer';

has site => (
    is => 'ro',
    coerce => sub {
        my ($site) = @_;
        if ($site =~ /^[a-z]+([_-][a-z])*$/) {
            $site =~ s/-/_/g;
            $site = "http://$site.wikipedia.org/";
        }
        return $site;
    }
);

has page => (
    is => 'ro'
);

has template => (
    is => 'ro'
);

has wikilinks => (
    is => 'ro',
    default => sub { 1 }
);

has tempname => (
    is => 'ro',
    default => sub { 'TEMPLATE' }
);


sub generator {
    my ($self) = @_;
    
    sub {
        state $templates = $self->_extract;
        return unless $templates and @$templates;
        return shift @$templates;
    }
}

sub _extract {
    my ($self) = @_;
    my $text = "";

    if ($self->site) {
        my $client = Furl->new;
        if (defined $self->page) {
            my $page = $self->page;
            my $url = $self->site . "wiki/$page?action=raw";
            my $res = $client->get($url);
            if ($res->is_success) {
                $text = $res->decoded_content;
            } else {
                die "failed to get $url";
            }
        } else {
            # TODO: read pages from input unless page is set
        }
    } else {
        my $fh = $self->fh;
        $text = do { local $/; <$fh> };
    }

    # TODO: add PAGE if page input mode set

    $self->_extract_template($text);
}

# Parse arguments of one template call
sub _template () {
    my ($self, $result, $name, $parameters) = @_;

    # {{foo bar}} calls Template:Foo_bar with upper case F.
    # Might not work for non-ASCII characters.
    $name = ucfirst($name);
    $name =~ s/ /_/g;

    my $template = { };

    if  (defined ($parameters)) {
        my ($field, $value);
        my $argc = 0;
        $parameters =~ s/^\|\s*(.*?)\s*$/$1/;
        foreach my $arg (split(/\s*\|\s*/, $parameters)) {
            $argc++;
            if ($arg =~ /^([^=]*?)\s*=\s*(.*)$/) {
                $field = $1;
                $value = $2;
            } else {
                $field = $argc;
                $value = $arg;
            }

            if (!$self->wikilinks) {
                $value =~ s/\[\[([^\]]*?)(\$!([^\]]*))?\]\]/$2 ? $3 : $1/eg;
            } elsif ($self->wikilinks == 2) {
                $value =~ s/\[\[([^\]]*?)(\$!([^\]]*))?\]\]/$1/eg;
            } else {
                $value =~ s/\[\[([^\]]*?)(\$!([^\]]*))?\]\]/$2 ? "[[$1|$3]]" : "[[$1]]"/eg;
            }

            $template->{$field} = $value; 
        }
    }

    if (!defined $self->template) {
        $template->{$self->tempname} = $name;
        push @$result, $template;
    } elsif ($self->template eq $name) {
        push @$result, $template;
    }

    return "\@($name)";
}

sub _extract_template {
    my ($self, $text) = @_;

    # Perform various substitutions to get rid of troublesome wiki markup.
    # In its place, leave $something

    # silently drop HTML comments
    $text =~ s/&lt;!--.*?--&gt;//g;

    # ignore nowiki, non-greedy match, leave $nowiki
    $text =~ s/&lt;nowiki&gt;.*?&lt;\/nowiki&gt;/\$nowiki/g;

    # ignore math, non-greedy match, leave $math
    $text =~ s/&lt;math&gt;.*?&lt;\/math&gt;/\$math/g;

    # wiki link with alternative text, leave $!
    # multiple passes handle image thumbnails
    for (my $i = 0; $i < 5; $i++) {
        $text =~ s/(\[\[[^\]\|{}]*)\|([^\]{}]*\]\])/$1\$!$2/g;
    }

    # These are not real template calls, leave $pagename
    $text =~ s/{{(CURRENT(DAY|DOW|MONTH|TIME(STAMP)?|VERSION|WEEK|YEAR)(ABBREV|NAME(GEN)?)?|(ARTICLE|NAME|SUBJECT|TALK)SPACE|NUMBEROF(ADMINS|ARTICLES|FILES|PAGES|USERS)(:R)?|(ARTICLE|BASE|FULL|SUB|SUBJECT|TALK)?PAGENAMEE?|REVISIONID|SCRIPTPATH|SERVER(NAME)?|SITENAME)}}/\$$1/g;

    # template parameter value with default, leave $!
    $text =~ s/{{{([^\|{}]*)\|([^{}]*)}}}/\$($1\$!$2)/g;

    # template parameter values, leave $parameter
    $text =~ s/{{{([^{}]*)}}}/\$($1)/g;

    # template bang escape, leave $!
    $text =~ s/{{!}}/\$!/g;

    my $result = [];
    my $tempname = $self->tempname;

    # multiple passes handle nested template calls
    for (my $i = 0; $i < 5; $i++) {
        $text =~ s/{{\s*([^\|{}]*?)\s*(\|[^{}]*)?}}/&_template($self,$result,$1,$2)/eg;
    }

    return $result;
}

1;
__END__

=encoding utf8

=head1 NAME

Catmandu::Importer::MWTemplates - extract MediaWiki template data

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Importer-MWTemplates.png)](https://travis-ci.org/LibreCat/Catmandu-Importer-MWTemplates)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-Importer-MWTemplates/badge.png)](https://coveralls.io/r/LibreCat/Catmandu-Importer-MWTemplates)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-Importer-MWTemplates.png)](http://cpants.cpanauthors.org/dist/Catmandu-Importer-MWTemplates)

=end markdown

=head1 DESCRIPTION


=head1 SYNOPSIS

Command line client C<catmandu>:

    catmandu convert MWTemplates --file example.wiki 
    catmandu convert MWTemplates --site en --page Feminis
    catmandu convert MWTemplates --site de --page Feminism --template Literatur
    
=head1 DESCRIPTION

This L<Catmandu::Importer> extracts L<MediaWiki
Templates|http://www.mediawiki.org/wiki/Help:Templates> from wiki pages.

=head1 CONFIGURATION

=over

=item site

The MediaWiki site to get data from. This must either be a base URL such as
L<http://en.wikipedia.org/> or a Wikipedia name tag, such as C<en>. If no site
is specified, the input is read from C<file> or standard input as wiki markup.

=item page

A wiki page to get data from.

=item template

A template to extract data for. If not specified, all templates will be
extracted with the template name if field C<TEMPLATE>.

=item tempname

The field to store template name in. Set to C<TEMPLATE> by default.

=item wikilinks

Keep wikilinks if set to 1 (default). If disabled (0), links will be
transformed to plain text. If set to 0, links will be transformed to their link
target.

=back

=head1 METHODS

See L<Catmandu::Importer> for general importer methods.

=head1 SEE ALSO

L<Catmandu::Wikidata>

The core parsing method is based on a script originally created by Erich
Zachte: L<http://meta.wikimedia.org/wiki/User:LA2/Extraktor>

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
