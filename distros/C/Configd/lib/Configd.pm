package Configd;
$Configd::VERSION = '0.005';
#ABSTRACT: Give software without a conf.d one anyway.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use File::Basename qw{basename};
use Module::Load   ();

use Configd::Unit();


sub languages {
    my %seen;
    foreach my $dir (@INC) {
        my $path = "$dir/Configd/Language";
        opendir( my $dh, $path ) or next;
        foreach my $file ( readdir($dh) ) {
            next unless $file =~ m/\A(\w+)[.]pm\z/;
            $seen{$1} = 1;
        }
        closedir $dh;
    }

    return sort keys %seen;
}


sub language {
    my ( $class, $name, %opts ) = @_;

    die "Which language?\n" unless defined $name && length $name;

    # It becomes part of a module name, so it has to be a name and not a path.
    die "'$name' is not a language name\n" unless $name =~ m/\A\w+\z/;

    my $module = "Configd::Language::$name";
    eval { Module::Load::load($module); 1 } or do {
        my @known = $class->languages();
        die "No language '$name'. This installation knows: " . join( ', ', @known ) . "\n";
    };

    return $module->new(%opts);
}


sub build {
    my ( $class, $name, %opts ) = @_;

    my $language = $class->language( $name, %opts );

    my @changed;
    foreach my $file ( $language->files() ) {
        push @changed, $file->{path} if $language->write($file);
    }

    return @changed;
}


sub adopt {
    my ( $class, $name, %opts ) = @_;

    my $language = $class->language( $name, %opts );
    my @adopted  = $language->adopt();
    my $unit     = Configd::Unit->new( language => $language, %opts );

    return {
        adopted  => \@adopted,
        dropins  => [ $unit->install() ],
        services => [ $language->services() ],
    };
}


sub release {
    my ( $class, $name, %opts ) = @_;

    my $language = $class->language( $name, %opts );
    my $unit     = Configd::Unit->new( language => $language, %opts );

    return {
        dropins  => [ $unit->uninstall() ],
        released => [ $language->release() ],
        services => [ $language->services() ],
    };
}


sub status {
    my ( $class, $name, %opts ) = @_;

    my $language = $class->language( $name, %opts );
    my $unit     = Configd::Unit->new( language => $language, %opts );

    my @files;
    foreach my $file ( $language->files() ) {
        my @fragments = $language->fragments($file);
        push @files, {
            path      => $file->{path},
            adopted   => ( scalar grep { basename($_) eq '00-original' } @fragments ) ? 1 : 0,
            fragments => [ map { basename($_) } @fragments ],
        };
    }

    return {
        language => $language->name(),
        files    => \@files,
        units    => [ $language->units() ],
        wrapped  => $unit->installed(),
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd - Give software without a conf.d one anyway.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Configd();

    my @known = Configd->languages();
    my $postfix = Configd->language('postfix');

    Configd->adopt('postfix');    # take the files over, wrap the service
    Configd->build('postfix');    # regenerate, which the unit does for you
    Configd->release('postfix');  # give them back

=head1 DESCRIPTION

Postfix keeps its configuration in F</etc/postfix/main.cf> and offers
C<postconf -e> to change it.  That is fine for a person at a terminal and wrong
for anything automated, because C<postconf -e> B<sets> a parameter -- there is no
way to B<add> to one.

Provisioning a second domain onto a mail server that already hosts one is enough
to hit it:

    postconf -e "mydestination = first.example.com"     # the first domain
    postconf -e "mydestination = second.example.com"    # the second

The second run does not add the second domain.  It replaces the first, and mail
for C<first.example.com> quietly stops being delivered locally.  Nothing errors,
nothing logs, and the two provisioning runs had no way to know about each other.

Software that ships a C<conf.d> does not have this problem: each thing drops in a
file and the daemon reads them all.  Plenty of software does not ship one.

=head2 What this does

C<configd adopt postfix> gives it one anyway:

=over 4

=item * F</etc/postfix/main.cf> becomes B<generated output>.

=item * F</etc/postfix/main.cf.d/> appears beside it, holding fragments in
main.cf's own syntax.

=item * Whatever was in main.cf becomes C<main.cf.d/00-original>, so the
distribution's defaults and anything the administrator had done keep winning
wherever nothing later has an opinion.

=item * A systemd drop-in regenerates the file every time the service starts or
reloads, so what the daemon reads is always what the fragments say.

=back

Two domains can then each write their own file and both get what they asked for:

    mydestination = $myhostname, localhost, first.example.com, second.example.com

=head2 Which settings merge, and which do not

This is the whole design decision, and it is per setting.

Most are B<values>: two fragments setting C<myhostname> disagree, and the later
one wins.  Some are B<lists>: two fragments each naming a domain in
C<mydestination> both meant it, and joining them is the only answer that does not
lose one.  A language says which is which by overriding C<accumulates>.

L<Configd::Language::postfix> deliberately does B<not> accumulate
C<smtpd_recipient_restrictions> and its relatives, even though they are lists.
They are I<ordered> lists where the order is the meaning, and joining two end to
end produces something that parses and that neither fragment asked for -- a
C<permit_> landing ahead of a check that was supposed to run first is an open
relay.  Two fragments disagreeing about a restriction list is something a person
should look at.

=head2 Caveats

B<Comments are not carried into the generated file.>  A comment is anchored to
the setting below it, and once several fragments have had their say there may be
no such setting any more -- reproducing the distribution's paragraph above a
value that has since been replaced tells the reader something untrue.  They stay
in the fragment they were written in, and C<00-original> keeps every one the file
arrived with.

B<Editing the generated file works until the next restart.>  That is deliberate:
long enough to test something, short enough that nobody comes to rely on it.  The
header on the file says so.

=head2 Requirements

Core perl 5.34 or newer, and nothing else.  Deliberately: this runs from
C<ExecStartPre>, so it stands between a service and starting, and it has to work
on whatever perl the guest already has rather than one somebody installed first.
Ubuntu 24.04 ships 5.38 and 22.04 ships 5.34.

L<Configd::Language> is where the design is written down and what you subclass
to teach it a new format.  Read the part about checking for a native C<conf.d>
first: this is for software that has none, and using it where a real mechanism
exists trades a working feature for a moving part.

=head1 NAME

Configd - give software without a conf.d one anyway.

=head1 CLASS METHODS

=head2 languages()

The languages this installation knows about, by name.

Found by looking through C<@INC> rather than by keeping a list, so a language
dropped in by a site -- or by a distribution that ships one -- is found without
anything here being edited.

=head2 language($name, %opts)

One language, loaded and instantiated. C<%opts> reaches its constructor, which
is how C<root> gets there.

Dies naming what is available when there is no such language, because the
alternative is a typo looking exactly like a language that does not handle the
file you expected.

=head2 build($name, %opts)

Regenerate every file a language manages, returning the paths that changed.

This is what the systemd drop-in runs, so it does exactly this and nothing else:
no C<systemctl>, which would deadlock against the start it is part of, and no
adopting, because a service starting is not the time to be taking files over.

=head2 adopt($name, %opts)

Take a language's files over and wrap its service: move each file into its own
fragment directory as C<00-original>, generate it, and install the drop-in.

Returns a hashref of what happened, which is what the command line prints.  Its
C<services> is what to restart, which is not always what the drop-in went on --
see L<Configd::Language/services()>.

Safe to run again: a file already adopted is regenerated rather than adopted a
second time, and re-adopting is the one thing that would duplicate every setting
in it.

Reloading systemd and restarting the service are the caller's, so that a caller
building an image rather than configuring a running machine can skip them.

=head2 release($name, %opts)

Give a language's files back: restore each C<00-original> and remove the
drop-in.

The fragment directories are left alone. They are somebody's configuration, and
throwing them away on the way out means a release followed by an adopt loses
everything that was ever added.

=head2 status($name, %opts)

What a language is doing right now: its files, whether each is adopted, how many
fragments it has, and whether the drop-in is in place.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd::Language>, L<Configd::Unit>, L<Configd::Language::postfix>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
