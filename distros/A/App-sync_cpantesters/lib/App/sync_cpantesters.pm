use 5.010;
use warnings;
use strict;

package App::sync_cpantesters;
BEGIN {
  $App::sync_cpantesters::VERSION = '1.111470';
}

# ABSTRACT: Sync CPAN testers failure reports to local directories
use open qw(:utf8);
use Class::Trigger;
use File::Find;
use File::Path;
use HTML::FormatText;
use HTML::TreeBuilder;
use LWP::UserAgent::ProgressBar;
use Web::Scraper;
use Class::Accessor::Lite
  new => 1,
  rw  => [qw(uri author base_dir verbose ignore)];

sub log {
    my ($self, $message, @values) = @_;
    1 while chomp $message;
    $self->verbose && printf "$message\n", @values;
}

sub get {
    my ($self, $url) = @_;
    my $response = LWP::UserAgent::ProgressBar->new->get_with_progress($url);
    $response->is_success or die "couldn't get $url\n";
    $response->content;
}

sub run {
    my $self     = shift;
    my $base_dir = $self->base_dir;
    die "need --basedir\n" unless defined $base_dir;
    die "can't have both --uri and --author\n"
      if defined($self->uri) && defined $self->author;
    $self->uri(sprintf 'http://cpantesters.perl.org/author/%s.html',
        $self->author)
      if defined $self->author;
    die "need --uri or --author\n" unless defined $self->uri;

    # make base_dir absolute
    $base_dir =~ s/~/$ENV{HOME}/ge;
    my $scraper = scraper {
        process '//div[contains(@class, "off")][.//td[@class="FAIL"]]',
          'dist[]' => scraper {
            process '//h2/a[@name]',            name     => '@name';
            process '//tr/td[@class="FAIL"]/a', 'fail[]' => '@href';
          };
    };
    $self->log('Downloading %s...', $self->uri);
    my $html = $self->get($self->uri);
    $self->log('Scraping information...');
    my $result = $scraper->scrape(\$html);
    $self->log('Creating directory %s...', $base_dir);
    mkpath($base_dir);
    my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 50);
    my %report;    # lookup hash to see which files and dirs should be there
    $self->log('Start iterating through results...');
    my @dist = @{ $result->{dist} || [] };

    if ($self->ignore) {
        my $ignore = $self->ignore;
        @dist = grep { $_->{name} !~ /$ignore/o } @dist;
    }
    __PACKAGE__->call_trigger('dist.filter', \@dist);
    for my $dist (@dist) {
        ref $dist eq 'HASH' or die 'expected a HASH reference';
        $self->log('Processing results for %s...', $dist->{name});
        unless (exists $dist->{fail}) {
            $self->log('No failures, skipping.');
            next;
        }
        ref $dist->{fail} eq 'ARRAY'
          or die "expected 'fail' to be an ARRAY reference";
        (my $dir = $dist->{name}) =~ s/\s+/-/g;
        $dir = sprintf '%s/%s', $base_dir, $dir;
        $self->log('Creating directory %s...', $dir);
        mkpath($dir);
        $report{dir}{$dir}++;
        for my $fail (@{ $dist->{fail} || [] }) {
            (my $id = $fail) =~ s!.*/!!;
            $self->log('Failure id %s', $id);
            my $filename = "$dir/$id";
            if (-e $filename) {
                $self->log('File %s exists, skipping.', $filename);
                $report{file}{$filename}++;
                next;
            }
            $self->log('Downloading %s...', $fail);
            my $content = $self->get($fail);
            open my $fh, '>', $filename
              or die "can't open $filename for writing: $!\n";
            print $fh $formatter->format(
                HTML::TreeBuilder->new_from_content($content));
            close $fh or die "can't close $filename: $!\n";
            $report{file}{$filename}++;
        }
    }
    $self->log('Deleting files other than the current failure reports...');
    find(
        sub {
            if (-d) {
                return if /^\.+$/;
                return if $report{dir}{$File::Find::name};
                $self->log('Deleting directory %s', $File::Find::name);
                rmtree($File::Find::name);
                $File::Find::prune = 1;
            } elsif (-f) {
                return if $report{file}{$File::Find::name};
                $self->log('Deleting file %s', $File::Find::name);
                unlink $File::Find::name;
            }
        },
        $base_dir
    );
}
1;


__END__
=pod

=for stopwords uri dir

=for test_synopsis 1;
__END__

=head1 NAME

App::sync_cpantesters - Sync CPAN testers failure reports to local directories

=head1 VERSION

version 1.111470

=head1 SYNOPSIS

    $ sync_cpantesters -a MARCEL -d ~/dev/cpan-testers

=head1 DESCRIPTION

CPAN testers provide a valuable service. The reports are available
on the Web - for example, for CPAN ID C<MARCEL>, the reports are at
L<http://cpantesters.perl.org/author/MARCEL.html>. I don't like to
read them in the browser and click on each individual failure report.
I also don't look at the success reports. I'd rather download the
failure reports and read them in my favorite editor, vim. I want to
be able to run this program repeatedly and only download new failure
reports, as well as delete old ones that no longer appear in the
master list - probably because a new version of the distribution in
question was uploaded.

If you are in the same position, then this program might be for you.

You need to pass a base directory using the C<--dir> options. For
each distribution for which there are failure reports, a directory
is created. Each failure report is stored in a file within that
subdirectory. The HTML is converted to plain text. For example, at one
point in time, I ran the program using:

    sync_cpantesters -a MARCEL -d reports

and the directory structure created looked like this:

    reports/Aspect-0.12/449224
    reports/Attribute-Memoize-0.01/39824
    reports/Attribute-Memoize-0.01/71010
    reports/Attribute-Overload-0.04/700557
    reports/Attribute-TieClasses-0.03/700575
    reports/Attribute-Util-1.02/455076
    reports/Attribute-Util-1.02/475237
    reports/Attribute-Util-1.02/477578
    reports/Attribute-Util-1.02/485231
    reports/Attribute-Util-1.02/489218
    ...

=head1 METHODS

=head2 author

The CPAN ID for which you want to download CPAN testers results. In my
case, this id is C<MARCEL>.

You have to use exactly one of C<author()> or C<uri()>.

=head2 uri

The URI from which to download the CPAN testers
results. It needs to be in the same format as, say,
L<http://cpantesters.perl.org/author/MARCEL.html>. You might want to
use this option if you've already downloaded the relevant file; in
this case, use a C<file://> URI.

You have to use exactly one of C<author()> or C<uri()>.

=head2 dir

The directory you want to download the reports to. Mandatory argument;
does tilde expansion during C<run()>.

=head2 ignore

If this argument is given, then, during C<run()>, every distribution
whose name matches this regular expression is ignored. You might use
this when you have deprecated distributions that you don't care about
anymore, but the reports are still there.

=head2 verbose

Be more verbose.

=head2 run

The main method, which is called by the C<sync_cpantesters> program.
Call this after you've set the relevant accessors described above.

You can add a trigger to this class to filter distributions after they
have been scraped from the web page and before the individual reports
are being downloaded. See L</TRIGGERS> below.

=head2 get

Takes a URL, downloads and returns the contents. A progress bar is
displayed during the download.

=head2 log

Takes arguments like C<sprintf> and prints them only if C<verbose()>
is true. The string will have exactly one newline character at the
end.

=head1 TRIGGERS

This class supports a trigger in the style of L<Class::Trigger>.

=over 4

=item dist.filter

This trigger is called after the data has been scraped from the web
page but before the individual testing reports are being downloaded.
The trigger is given an array reference to the distributions; each
element is a hash that contains the distribution name as well as a
list of the failure reports.

For example, suppose you keep the currently maintained distributions
in a directory and the deprecated ones, the ones you won't support
anymore, in another directory. Then you might want to download only
those reports for distributions you maintain. Use something like this:

    use App::sync_cpantesters;
    App::sync_cpantesters->add_trigger(
        'dist.filter' => sub {
            my ($class, $dist) = @_;
            @$dist = grep { -d "$ENV{HOME}/code/$_->{name}" } @$dist;
        }
    );
    App::sync_cpantesters->new(
        author   => 'MARCEL',
        base_dir => '~/dev/cpan-testers',
        verbose  => 1,
    )->run;

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=App-sync_cpantesters>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/App-sync_cpantesters/>.

The development version lives at L<http://github.com/hanekomu/App-sync_cpantesters>
and may be cloned from L<git://github.com/hanekomu/App-sync_cpantesters.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

