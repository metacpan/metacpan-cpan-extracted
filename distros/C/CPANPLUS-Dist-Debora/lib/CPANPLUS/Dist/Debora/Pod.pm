package CPANPLUS::Dist::Debora::Pod;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.008';

use parent qw(Pod::Simple);

use Pod::Simple;
use Pod::Simple::Search;

sub find {
    my ($class, $module_name, @dirs) = @_;

    my $pod;

    my $podfile = Pod::Simple::Search->new->inc(0)->find($module_name, @dirs);
    if ($podfile) {
        $pod = CPANPLUS::Dist::Debora::Pod->new;
        $pod->parse_file($podfile);
    }

    return $pod;
}

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{buf}  = q{};
    $self->{text} = q{};

    return $self;
}

sub text {
    my $self = shift;

    return $self->{text};
}

sub title {
    my $self = shift;

    return $self->section(q{1}, qr{NAME}xmsi);
}

sub summary {
    my $self = shift;

    my $summary = $self->title;
    if ($summary) {
        if ($summary =~ m{\h+ - \h+ (.*)}xms) {
            $summary = $1;
        }
    }

    return $summary;
}

sub description {
    my $self = shift;

    my $length = 500;

    my @headings
        = (qr{DESCRIPTION}xmsi, qr{INTRODUCTION}xmsi, qr{SYNOPSIS}xmsi);

    my $description;
    SECTION:
    for my $heading (@headings) {
        my $section = $self->section(q{1}, $heading);
        next SECTION if !$section;

        $description = q{};

        # Remove subheadings.
        $section =~ s{^ =head\d \h (\V+) \v+}{}xmsg;

        # Add the first paragraphs to the description.
        PARAGRAPH:
        for my $paragraph (split qr{\v\v+}xms, $section) {
            if ($description) {
                $description .= "\n\n";
            }
            $description .= $paragraph;
            last PARAGRAPH if length $description > $length;
        }

        # Remove the last sentence if the sentence ends with ":".
        $description =~ s{[.] [^.]* : \z}{.}xms;

        # Remove the last sentence if the sentence contains the word "below".
        $description =~ s{[.] [^.]+ \b (?:below) \b [^.]* [.] \z}{.}xms;

        last SECTION if $description;
    }

    return $description;
}

sub _copyrights_from_text {
    my ($self, $text) = @_;

    my $COPYRIGHT = qr{Copyright (?:\h+ (?:[(]c[)] | ©))?}xmsi;
    my $YEAR      = qr{\d+ (?: \s* [-,] \s* \d+)*}xms;
    my $HOLDER    = qr{[^\v]+}xms;

    my $COPYRIGHT_NOTICE = qr{
        $COPYRIGHT
        \s+
        ($YEAR) [-,]?
        \s+
        ($HOLDER)
    }xms;

    my $MARKS = qr{[.,;!?:]}xms;

    my $AUTHOR_REFERENCE = qr{
        \b (?:above | aforementioned ) \b
        | "AUTHORS?"
    }xmsi;

    # Put a newline before any copyright notice so that we can find
    # consecutive copyright notices.
    $text =~ s{($COPYRIGHT \s+ $YEAR)}{\n$1}xmsg;

    # Remove some phrases.
    my @phrases = (
        qr{\b by \b}xmsi,        # "by"
        qr{[(] [^)]* [)]}xms,    # text in parens
        qr{(?:All | Some) \h+ rights \h+ reserved \V*}xmsi,
        qr{This [\h\w]* \h+ is \h+ free \h+ software \V*}xmsi,
        qr{This [\h\w]* \h+ is \h+ made \h+ available \V*}xmsi,
        qr{License [\h\w]* \h+ granted \V*}xmsi,
        qr{Licensed \h+ under \V*}xmsi,
        qr{Same \h+ license \V*}xmsi,
        qr{You \h+ (?:may | should) \V*}xmsi,
        qr{[^.,;:]+ \h+ is \h+ (?:distributed | released) \V*}xmsi,
        qr{<? \S+@\S+[.]\S+ >?}xms,    # email addresses
        qr{https?://[^\h]+}xms,        # URLs
    );

    for my $phrase (@phrases) {
        $text =~ s{$MARKS* \h* $phrase}{}xmsg;
    }

    my %unique_copyrights;
    COPYRIGHT_NOTICE:
    while ($text =~ m{$COPYRIGHT_NOTICE}xmsg) {
        my $year   = $1;
        my $holder = $2;

        $year =~ s{\h* -+ \h*}{-}xmsg;    # Remove spaces from hyphens.
        $year =~ s{,(\S)}{, $1}xmsg;      # Put a space after commas.
        $year =~ s{\s+}{ }xmsg;           # Squeeze spaces.

        $holder =~ s{\s+ \z}{}xms;        # Remove trailing spaces.
        $holder =~ s{\s+}{ }xmsg;         # Squeeze spaces.
        $holder =~ s{$MARKS+ \z}{}xms;    # Remove trailing punctuation marks.

        next COPYRIGHT_NOTICE if $holder =~ $AUTHOR_REFERENCE;

        $unique_copyrights{"$year $holder"}
            = {year => $year, holder => $holder};
    }

    my @copyrights
        = sort { $a->{year} cmp $b->{year} } values %unique_copyrights;

    return \@copyrights;
}

sub copyrights {
    my $self = shift;

    my $COPYRIGHT_HEADINGS = qr{
        (?: LICEN[CS]E | LICENSING | COPYRIGHT | LEGAL ) \b [^\v]*
    }xmsi;

    my @copyrights;

    my $section = $self->section(qr{\d}xms, $COPYRIGHT_HEADINGS);
    if ($section) {
        push @copyrights, @{$self->_copyrights_from_text($section)};
    }

    return \@copyrights;
}

sub section {
    my ($self, $level, $title) = @_;

    my $section;
    if ($self->{text} =~ m{^ =head($level) \h $title \v+ (.*)}xms) {
        my $n = $1;
        $section = $2;
        $section =~ s{\v* ^ =head$n \h .*}{}xms;    # Remove other sections.
        $section =~ s{\v+ \z}{}xms;                 # Remove trailing newlines.
    }

    return $section;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

sub _handle_element_start {
    my ($self, $name, $attrs) = @_;

    my %do_clear = map { $_ => 1 } qw(
        head1
        head2
        head3
        head4
        item-text
        Para
        Verbatim
    );

    if ($name eq 'item-bullet') {
        $self->{buf} = q{ * };
    }
    elsif ($name eq 'item-number') {
        $self->{buf} = q{ } . $attrs->{number} . q{. };
    }
    elsif ($do_clear{$name}) {
        $self->{buf} = q{};
    }

    return;
}

sub _handle_element_end {
    my ($self, $name) = @_;

    my %do_output = map { $_ => 1 } qw(
        head1
        head2
        head3
        head4
        item-bullet
        item-number
        item-text
        Para
        Verbatim
    );

    my %do_newline = map { $_ => 1 } qw(
        head1
        head2
        head3
        head4
        Para
        Verbatim
    );

    if ($name =~ m{^ head\d}xms) {
        $self->{text} .= "=$name ";
    }

    if ($do_output{$name}) {
        $self->{text} .= $self->{buf};
        $self->{text} .= "\n";
        if ($do_newline{$name}) {
            $self->{text} .= "\n";
        }
        $self->{buf} = q{};
    }

    return;
}

sub _handle_text {
    my ($self, $text) = @_;

    # Pod::Simple provides nbsp and shy since Perl 5.24.
    ## no critic (Variables::ProhibitPackageVars)
    if (defined $Pod::Simple::nbsp) {
        $text =~ s{$Pod::Simple::nbsp}{ }xmsg;
    }
    if (defined $Pod::Simple::shy) {
        $text =~ s{$Pod::Simple::shy}{}xmsg;
    }
    $self->{buf} .= $text;

    return;
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Pod - Parse Pod documents

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::Pod;

  $pod = CPANPLUS::Dist::Debora::Pod->find($module_name, @dirs);

  $pod_text    = $pod->text;
  $summary     = $pod->summary;
  $description = $pod->description;

=head1 DESCRIPTION

This L<Pod::Simple> subclass finds and parses files in Perl's Pod markup
language.  Information that is not relevant for extracting descriptions and
license information is ignored.

=head1 SUBROUTINES/METHODS

=head2 find

  my $pod = CPANPLUS::Dist::Debora::Pod->find($module_name, @dirs);

Takes a module name and a list of directories to search for Pod files.
Returns a Pod object or the undefined value.

=head2 new

  my $pod = CPANPLUS::Dist::Debora::Pod->new;

Creates a new object.

=head2 parse_file

  $pod->parse_file($name);

Parses the specified Pod file.

=head2 text

  my $pod_text = $pod->text;

Returns the Pod document, which is simplified for the purpose of finding
descriptions and license information.

Use L<Software::LicenseUtils> to guess the license.

  my @licenses = Software::LicenseUtils->guess_license_from_pod($pod_text);

=head2 title

  my $title = $pod->title;

Returns the Pod document's title or the undefined value.

If the Pod document contains the section below, "Hoo::Boy::Wowza - Stuff wow
yeah!" will be returned.

  =head1 NAME

  Hoo::Boy::Wowza - Stuff wow yeah!

=head2 summary

  my $summary = $pod->summary;

Returns the Pod document's one-line description or the undefined value.

If the Pod document contains the section below, "Stuff wow yeah!" will be
returned.

  =head1 NAME

  Hoo::Boy::Wowza - Stuff wow yeah!

=head2 description

  my $description = $pod->description;

Returns the first paragraphs of the Pod document's description or the
undefined value.

=head2 copyrights

  for my $copyright (@{$pod->copyrights}) {
      my $year   = $copyright->{year};
      my $holder = $copyright->{holder};
  }

Returns the copyright years and holders.

=head2 section

  my $pod_text = $pod->section($level, $title);

Searches for a section with the specified title on the specified level.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the modules L<Pod::Simple> and L<Pod::Simple::Search>, which are
distributed with Perl.

=head1 INCOMPATIBILITIES

None.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

None known.

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
