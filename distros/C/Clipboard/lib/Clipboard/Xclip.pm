package Clipboard::Xclip;
$Clipboard::Xclip::VERSION = '0.28';
use strict;
use warnings;

use File::Spec ();

sub copy {
    my $self = shift;
    my ($input) = @_;
    return $self->copy_to_selection($self->favorite_selection, $input);
}

sub copy_to_all_selections {
    my $self = shift;
    my ($input) = @_;
    foreach my $sel ($self->all_selections) {
        $self->copy_to_selection($sel, $input);
    }
    return;
}

sub copy_to_selection {
    my $self = shift;
    my ($selection, $input) = @_;
    my $cmd = '|xclip -i -selection '. $selection;
    my $r = open my $exe, $cmd or die "Couldn't run `$cmd`: $!\n";
    binmode $exe, ':encoding(UTF-8)';
    print {$exe} $input;
    close $exe or die "Error closing `$cmd`: $!";

    return;
}
sub paste {
    my $self = shift;
    for ($self->all_selections) {
        my $data = $self->paste_from_selection($_);
        return $data if length $data;
    }
    return undef;
}
sub paste_from_selection {
    my $self = shift;
    my ($selection) = @_;
    my $cmd = "xclip -o -selection $selection|";
    open my $exe, $cmd or die "Couldn't run `$cmd`: $!\n";
    my $result = join '', <$exe>;
    close $exe or die "Error closing `$cmd`: $!";
    return $result;
}
# This ordering isn't officially verified, but so far seems to work the best:
sub all_selections { qw(primary buffer clipboard secondary) }
sub favorite_selection { my $self = shift; ($self->all_selections)[0] }

sub xclip_available {
    # close STDERR
    open my $olderr, '>&', \*STDERR;
    close STDERR;
    open STDERR, '>', File::Spec->devnull;

    my $open_retval = open my $just_checking, 'xclip -o|';

    # restore STDERR
    close STDERR;
    open STDERR, '>&', $olderr;
    close $olderr;

    return $open_retval;
}

{
  xclip_available() or warn <<'EPIGRAPH';

Can't find the 'xclip' script.  Clipboard.pm's X support depends on it.

Here's the project homepage: http://sourceforge.net/projects/xclip/

EPIGRAPH
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.28

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Clipboard>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Clipboard>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Clipboard>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Clipboard>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Clipboard>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Clipboard>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-clipboard at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Clipboard>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Clipboard>

  git clone git://github.com/shlomif/Clipboard.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Clipboard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ryan King <rking@panoptic.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
