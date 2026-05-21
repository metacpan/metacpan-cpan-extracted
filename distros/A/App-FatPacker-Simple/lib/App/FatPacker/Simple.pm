package App::FatPacker::Simple v1.0.0;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use App::FatPacker;
use Config;
use Cwd ();
use Distribution::Metadata;
use File::Basename ();
use File::Find ();
use File::Spec;
use File::Spec::Unix;
use Getopt::Long ();
use Perl::Strip;
use Pod::Usage ();

our $IGNORE_FILE = [
    qr/\.pod$/,
    qr/\.packlist$/,
    qr/MYMETA\.json$/,
    qr/install\.json$/,
];

our $TRIAL = 0;

sub new ($class, @argv) {
    bless { @argv }, $class;
}

sub parse_options ($self, @argv) {
    my $parser = Getopt::Long::Parser->new(
        config => [qw(no_auto_abbrev no_ignore_case)],
    );
    $parser->getoptionsfromarray(
        \@argv,
        "d|dir=s"       => \(my $dir = 'lib,fatlib,local,extlib'),
        "e|exclude=s"   => \(my $exclude),
        "h|help"        => sub (@) { $self->show_help; exit 1 },
        "o|output=s"    => \(my $output),
        "q|quiet"       => \(my $quiet),
        "s|strict"      => \(my $strict),
        "v|version"     => sub (@) { printf "%s %s\n", __PACKAGE__, __PACKAGE__->VERSION; exit },
        "color!"        => \(my $color = 1),
        "shebang=s"     => \(my $custom_shebang),
        "exclude-strip=s@" => \(my $exclude_strip),
        "no-strip|no-perl-strip" => \(my $no_perl_strip),
        "cache=s"       => \(my $cache),
    ) or exit 1;
    $self->{script}     = shift @argv or do { warn "Missing script.\n"; $self->show_help; exit 1 };
    $self->{dir}        = $self->build_dir($dir);
    $self->{output}     = $output;
    $self->{quiet}      = $quiet;
    $self->{strict}     = $strict;
    $self->{color}      = $color;
    $self->{custom_shebang} = $custom_shebang;
    $self->{exclude_strip}  = [map { qr/$_/ } ($exclude_strip || [])->@*];
    $self->{exclude}    = [];
    if (!$no_perl_strip) {
        $self->{perl_strip} = Perl::Strip->new($cache ? (cache => $cache) : ());
    }
    if ($exclude) {
        for my $e (split /,/, $exclude) {
            my $dist = Distribution::Metadata->new_from_module(
                $e, inc => $self->{dir},
            );
            if (my $files = $dist->files) {
                push $self->{exclude}->@*, $files->@*;
            } else {
                $self->warning("Missing $e in $dir");
            }
        }
    }
    $self;
}

sub show_help ($self) {
    open my $fh, '>', \my $out;
    Pod::Usage::pod2usage
        exitval => 'noexit',
        input => $0,
        output => $fh,
        sections => 'SYNOPSIS|COMMANDS|OPTIONS|EXAMPLES',
        verbose => 99,
    ;
    $out =~ s/^[ ]{4,6}/  /mg;
    $out =~ s/\n$//;
    print $out;
}

sub warning ($self, $msg) {
    chomp $msg;
    my $color = $self->{color}
              ? sub ($text) { "\e[31m$text\e[m", "\n" }
              : sub ($text) { "$text\n" };
    if ($self->{strict}) {
        die $color->("=> ERROR $msg");
    } elsif (!$self->{quiet}) {
        warn $color->("=> WARN $msg");
    }
}

sub debug ($self, $msg) {
    chomp $msg;
    if (!$self->{quiet}) {
        warn "-> $msg\n";
    }
}

sub output_filename ($self) {
    return $self->{output} if $self->{output};

    my $script = File::Basename::basename $self->{script};
    my ($suffix, @other) = reverse split /\./, $script;
    if (!@other) {
        "$script.fatpack";
    } else {
        unshift @other, "fatpack";
        join ".", reverse(@other), $suffix;
    }
}

sub run ($self) {
    my $fatpacked = $self->fatpack_file($self->{script});
    my $output_filename = $self->output_filename;
    open my $fh, ">", $output_filename
        or die "Cannot open '$output_filename': $!\n";
    print {$fh} $fatpacked;
    close $fh;
    my $mode = (stat $self->{script})[2];
    chmod $mode, $output_filename;
    $self->debug("Successfully created $output_filename");
}

# In order not to depend on App::FatPacker internals,
# we use only App::FatPacker::fatpack_code method.
sub fatpack_file ($self, $file) {
    my ($shebang, $script) = $self->load_main_script($file);
    $shebang = $self->{custom_shebang} if $self->{custom_shebang};
    my %files;
    $self->collect_files($_, \%files) for $self->{dir}->@*;
    my $fatpacker = App::FatPacker->new;
    return join "\n", $shebang, $fatpacker->fatpack_code(\%files), $script;
}

# almost copy from App::FatPacker::load_main_script
sub load_main_script ($self, $file) {
    open my $fh, "<", $file or die "Cannot open '$file': $!\n";
    my @lines = <$fh>;
    my @shebang;
    if (@lines && index($lines[0], '#!') == 0) {
        while (1) {
            push @shebang, shift @lines;
            last if $shebang[-1] =~ m{^\#\!.*perl};
        }
    }
    ((join "", @shebang), (join "", @lines));
}

sub load_file ($self, $absolute, $relative, $original) {

    my $content = do {
        open my $fh, "<", $absolute or die "Cannot open '$absolute': $!\n";
        local $/; <$fh>;
    };

    if ($self->{perl_strip} and !grep { $original =~ $_ } $self->{exclude_strip}->@*) {
        $self->debug("fatpack $relative (with perl-strip)");
        return $self->{perl_strip}->strip($content);
    } else {
        $self->debug("fatpack $relative (without perl-strip)");
        return $content;
    }
}

sub collect_files ($self, $dir, $files) {

    my $absolute_dir = Cwd::abs_path($dir);
    # When $dir is not an archlib,
    # and we are about to search $dir/archlib, skip it!
    # because $dir/archlib itself will be searched another time.
    my $skip_dir = File::Spec->catdir($absolute_dir, $Config{archname});
    $skip_dir = qr/\Q$skip_dir\E/;

    my $find = sub (@) {
        return unless -f $_;
        for my $ignore ($IGNORE_FILE->@*) {
            $_ =~ $ignore and return;
        }
        my $original = $_;
        my $absolute = Cwd::abs_path($original);
        return if $absolute =~ $skip_dir;
        my $relative = File::Spec::Unix->abs2rel($absolute, $absolute_dir);
        for my $exclude ($self->{exclude}->@*) {
            if ($absolute eq $exclude) {
                $self->debug("exclude $relative");
                return;
            }
        }
        if (!/\.(?:pm|ix|al|pl)$/) {
            $self->warning("skip non perl module file $relative");
            return;
        }
        $files->{$relative} = $self->load_file($absolute, $relative, $original);
    };
    File::Find::find({wanted => $find, no_chdir => 1}, $dir);
}

sub build_dir ($self, $dir_string) {
    my @dir;
    for my $d (grep -d, split /,/, $dir_string) {
        my $try = File::Spec->catdir($d, "lib/perl5");
        if (-d $try) {
            push @dir, $try, File::Spec->catdir($try, $Config{archname});
        } else {
            push @dir, $d, File::Spec->catdir($d, $Config{archname});
        }
    }
    return [ grep -d, @dir ];
}

1;
__END__

=for stopwords fatpack fatpacks fatpacked deps

=encoding utf-8

=head1 NAME

App::FatPacker::Simple - only fatpack a script

=head1 SYNOPSIS

  $ fatpack-simple script.pl

=head1 DESCRIPTION

App::FatPacker::Simple or its frontend C<fatpack-simple> helps you
fatpack a script when B<YOU> understand the whole dependencies of it.

For tutorial, please look at L<App::FatPacker::Simple::Tutorial>.

=head1 MOTIVATION

App::FatPacker::Simple is an alternative for L<App::FatPacker>'s
C<fatpack file> command.
Let me explain why I wrote this module.

L<App::FatPacker> brings more portability to Perl, that is totally awesome.

As far as I understand, App::FatPacker does 3 things:

=over 4

=item (a) trace dependencies for a script

=item (b) collects dependencies to C<fatlib> directory

=item (c) fatpack the script with modules in C<fatlib>

=back

As for (a), I have often encountered problems. For example,
modules that I don't want to trace trace,
conversely, modules that I DO want to trace do not trace.
Moreover a core module has changed interfaces or has been bug-fixed recently,
so we have to fatpack that module with new version, etc.
So I think if you author intend to fatpack a script,
B<YOU> need to understand the whole dependencies of it.

As for (b), to locate modules in a directory, why don't you use
C<carton> or C<cpanm>?

So the rest is (c) to fatpack a script with modules in directories,
on which App::FatPacker::Simple concentrates.

That is, App::FatPacker::Simple only fatpacks a script with features:

=over 4

=item * automatically perl-strip modules

=item * has option to exclude some modules

=back

=head1 SEE ALSO

L<App::FatPacker>

L<App::depak>

L<Perl::Strip>

=head1 ARTIFACT ATTESTATIONS

GitHub Artifact Attestations are generated for release tarballs uploaded to
CPAN. If you care about provenance for the uploaded tarballs, see:

L<https://github.com/skaji/App-FatPacker-Simple/attestations>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
