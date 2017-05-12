#!perl

use strict;
use warnings;
use App::CPANTS::Lint;
use Getopt::Long qw/:config gnu_compat/;
use Pod::Usage;

GetOptions(\my %opts, qw(
  help|? man verbose dump yaml json colour|color save|to_file dir=s metrics_path=s@
));

pod2usage(1) if $opts{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{man};

my $dist = shift @ARGV;
pod2usage(-exitstatus => 0, -verbose => 0) unless $dist;

my $app = App::CPANTS::Lint->new(%opts);

my $res = $app->lint($dist);

$app->output_report;

__END__

=encoding utf-8

=head1 NAME

cpants_lint.pl - commandline frontend to Module::CPANTS::Analyse

=head1 SYNOPSIS

    cpants_lint.pl path/to/Foo-Dist-1.42.tgz

    Options:
        --help              brief help message
        --man               full documentation
        --verbose           print more info during run
        --colour, --color   pretty output

        --dump              dump result using Data::Dumper
        --yaml              dump result as YAML
        --json              dump result as JSON

        --save              write report (or dump) to a file
        --dir               directory to save a report to
        --metrics_path      search path for extra metrics modules


=head1 DESCRIPTION

C<cpants_lint.pl> checks the B<Kwalitee> of a CPAN distribution. More exact, it checks how a given tarball will be rated on C<http://cpants.perl.org>, without needing to upload it first.

For more information on Kwalitee, and the whole of CPANTS, see C<http://cpants.perl.org> and / or C<Module::CPANTS::Analyse>.

=head1 OPTIONS

=head2 --help 

Print a brief help message.

=head2 --man

Print manpage.

=head2 --verbose

Print some informative messages while analysing a distribution.

=head2 --colour, --color

Like C<< --verbose >>, but prettier. You need to install L<Term::ANSIColor> (and L<Win32::Console::ANSI> for Win32) to enable this option.

=head2 --dump

Dump the result using Data::Dumper (instead of displaying a report text).

=head2 --yaml

Dump the result as YAML.

=head2 --json

Dump the result as JSON.

=head3 --save

Output the result into a file instead of STDOUT.

The name of the file will be F<Foo-Dist.txt> (well, the extension depends on the dump format and can be C<.dmp>, C<.yml> or C<.json>)

=head3 --dir

Directory to dump a file to. Defaults to the current working directory.

=head3 --metrics_path

Search path for extra metrics modules

=head1 AUTHOR

L<Thomas Klausner|https://metacpan.org/author/domm>

L<Kenichi Ishigaki|https://metacpan.org/author/ishigaki>

=head1 COPYRIGHT AND LICENSE

Copyright © 2003–2006, 2009 L<Thomas Klausner|https://metacpan.org/author/domm>

Copyright © 2014 L<Kenichi Ishigaki|https://metacpan.org/author/ishigaki>

You may use and distribute this module according to the same terms
that Perl is distributed under.
