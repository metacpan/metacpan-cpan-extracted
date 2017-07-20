package CPAN::Mirror::Tiny;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.20';

use CPAN::Meta;
use CPAN::Mirror::Tiny::Archive;
use CPAN::Mirror::Tiny::Tempdir;
use CPAN::Mirror::Tiny::Util 'safe_system';
use Capture::Tiny ();
use Cwd ();
use Digest::MD5 ();
use File::Basename ();
use File::Copy ();
use File::Copy::Recursive ();
use File::Path ();
use File::Spec::Unix;
use File::Spec;
use File::Temp ();
use File::Which ();
use HTTP::Tinyish;
use JSON ();
use Parse::LocalDistribution;
use Parse::PMFile;

my $JSON = JSON->new->canonical(1)->utf8(1);
my $CACHE_VERSION = 1;

sub new {
    my ($class, %option) = @_;
    my $base = $option{base} || $ENV{PERL_CPAN_MIRROR_TINY_BASE} or die "Missing base directory argument";
    my $tempdir = $option{tempdir} || File::Temp::tempdir(CLEANUP => 1);
    File::Path::mkpath($base) unless -d $base;
    $base = Cwd::abs_path($base);
    my $archive = CPAN::Mirror::Tiny::Archive->new;
    my $http = HTTP::Tinyish->new;
    my $self = bless {
        base => $base,
        archive => $archive,
        http => $http,
        tempdir => $tempdir,
    }, $class;
    $self->init_tools;
}

sub init_tools {
    my $self = shift;
    for my $cmd (qw(git tar gzip)) {
        $self->{$cmd} = File::Which::which($cmd)
            or die "Couldn't find $cmd; CPAN::Mirror::Tiny needs it";
    }
    $self;
}

sub archive { shift->{archive} }
sub http { shift->{http} }

sub extract {
    my ($self, $path) = @_;
    my $method = $path =~ /\.zip$/ ? "unzip" : "untar";
    $self->archive->$method($path);
}

sub base {
    my $self = shift;
    return $self->{base} unless @_;
    File::Spec->catdir($self->{base}, @_);
}

sub tempdir { CPAN::Mirror::Tiny::Tempdir->new(shift->{tempdir}) }
sub pushd_tempdir { CPAN::Mirror::Tiny::Tempdir->pushd(shift->{tempdir}) }

sub _author_dir {
    my ($self, $author) = @_;
    my ($a2, $a1) = $author =~ /^((.).)/;
    $self->base("authors", "id", $a1, $a2, $author);
}

sub _locate_tarball {
    my ($self, $file, $author) = @_;
    my $dir = $self->_author_dir($author);
    File::Path::mkpath($dir) unless -d $dir;
    my $basename = File::Basename::basename($file);
    my $dest = File::Spec->catfile($dir, $basename);
    File::Copy::move($file, $dest);
    return -f $dest ? $dest : undef;
}

sub inject {
    my ($self, $url, $option) = @_;

    my $maybe_git = sub {
        my $url = shift;
        scalar($url =~ m{\A https?:// (?:github\.com|bitbucket.org) / [^/]+ / [^/]+ \z}x);
    };

    if ($url =~ s{^file://}{} or -e $url) {
        $self->inject_local($url, $option);
    } elsif ($url =~ /(?:^git|\.git(?:@(.+))?$)/ or $maybe_git->($url)) {
        $self->inject_git($url, $option);
    } elsif ($url =~ /^cpan:(.+)/) {
        $self->inject_cpan($1, $option);
    } elsif ($url =~ /^https?:/) {
        $self->inject_http($url, $option);
    } else {
        die "Unknown url $url\n";
    }
}

sub _encode {
    my $str = shift;
    $str =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    $str;
}

sub _cpan_url {
    my ($self, $module, $version) = @_;
    my $url = "https://fastapi.metacpan.org/v1/download_url/$module";
    $url .= "?version=" . _encode("== $version") if $version;
    my $res = $self->http->get($url);
    return (undef, "$res->{status} $res->{reason}, $url") unless $res->{success};
    my $hash = eval { $JSON->decode($res->{content}) };
    if ($@) {
        return (undef, $@);
    } else {
        return ($hash->{download_url}, undef);
    }
}

sub inject_local {
    my ($self, $arg) = (shift, shift);
    if (-f $arg) {
        return $self->inject_local_file($arg, @_);
    } elsif (-d $arg) {
        return $self->inject_local_directory($arg, @_);
    } else {
        die "$arg is neither file nor directory";
    }
}

sub inject_local_file {
    my ($self, $file, $option) = @_;
    die "'$file' is not a file" unless -f $file;
    die "'$file' must be tarball or zipball" if $file !~ /(?:\.tgz|\.tar\.gz|\.tar\.bz2|\.zip)$/;
    $file = Cwd::abs_path($file);
    my $guard = $self->pushd_tempdir;
    my $dir = $self->extract($file);
    return $self->inject_local_directory($dir, $option);
}

sub inject_local_directory {
    my ($self, $dir, $option) = @_;
    my $metafile = File::Spec->catfile($dir, "META.json");
    die "Missing META.json in $dir" unless -f $metafile;
    my $meta = CPAN::Meta->load_file($metafile);
    my $distvname = sprintf "%s-%s", $meta->name, $meta->version;
    $dir = Cwd::abs_path($dir);
    my $guard = $self->pushd_tempdir;
    File::Path::rmtree($distvname) if -d $distvname;
    File::Copy::Recursive::dircopy($dir, $distvname) or die;
    my ($out, $err, $exit) = safe_system [$self->{tar}, "czf", "$distvname.tar.gz", $distvname];
    die "Failed to create tarball: $err" unless $exit == 0;
    my $author = ($option ||= {})->{author} || "VENDOR";
    return $self->_locate_tarball("$distvname.tar.gz", $author);
}

sub inject_http {
    my ($self, $url, $option) = @_;
    if ($url !~ /(?:\.tgz|\.tar\.gz|\.tar\.bz2|\.zip)$/) {
        die "URL must be tarball or zipball\n";
    }
    my $basename = File::Basename::basename($url);
    my $tempdir = $self->tempdir;
    my $file = File::Spec->catfile($tempdir->as_string, $basename);
    my $res = $self->http->mirror($url => $file);
    if ($res->{success}) {
        my $author = ($option ||= {})->{author};
        if (!$author) {
            if ($url =~ m{/authors/id/./../([^/]+)/}) {
                $author = $1;
                return $self->_locate_tarball($file, $author);
            } else {
                $author = "VENDOR";
            }
        }
        return $self->inject_local_file($file, {author => $author});
    } else {
        die "Couldn't get $url: $res->{status} $res->{reason}";
    }
}

sub inject_cpan {
    my ($self, $package, $option) = @_;
    $package =~ s/^cpan://;
    my $version = $option->{version};
    if ($package =~ s/@(.+)$//) {
        $version ||= $1;
    }
    my ($url, $err) = $self->_cpan_url($package, $version);
    die $err if $err;
    $self->inject_http($url, $option);
}

sub inject_git {
    my ($self, $url, $option) = @_;

    my $ref = ($option ||= {})->{ref};
    if ($url =~ /(.*)\@(.*)$/) {
        # take care of git@github.com:skaji/repo@tag, http://user:pass@example.com/foo@tag
        my ($leading, $remove) = ($1, $2);
        my ($out, $err, $exit) = safe_system [$self->{git}, "ls-remote", $leading];
        if ($exit == 0) {
            $ref = $remove;
            $url =~ s/\@$remove$//;
        }
    }

    my $guard = $self->pushd_tempdir;
    my (undef, $err, $exit) = safe_system [$self->{git}, "clone", $url, "."];
    die "Couldn't git clone $url: $err" unless $exit == 0;
    if ($ref) {
        my (undef, $err, $exit) = safe_system [$self->{git}, "checkout", $ref];
        die "Couldn't git checkout $ref: $err" unless $exit == 0;
    }
    my $metafile = "META.json";
    die "Couldn't find $metafile in $url" unless -f $metafile;
    my $meta = CPAN::Meta->load_file($metafile);
    my ($rev) = safe_system [$self->{git}, "rev-parse", "--short", "HEAD"];
    chomp $rev;
    my $distvname = sprintf "%s-%s-%s", $meta->name, $meta->version, $rev;
    (undef, $err, $exit) = safe_system(
        [$self->{git}, "archive", "--format=tar", "--prefix=$distvname/", "HEAD"],
        "|",
        [$self->{gzip}],
        ">",
        ["$distvname.tar.gz"],
    );
    if ($exit == 0 && -f "$distvname.tar.gz") {
        my $author = ($option || +{})->{author} || "VENDOR";
        return $self->_locate_tarball("$distvname.tar.gz", $author);
    } else {
        die "Couldn't archive $url: $err";
    }
}

sub _cached {
    my ($self, $path, $sub) = @_;
    return unless -f $path;
    my $cache_dir = $self->base("modules", ".cache");
    File::Path::mkpath($cache_dir) unless -d $cache_dir;

    my $md5 = Digest::MD5->new;
    $md5->addfile(do { open my $fh, "<", $path or die; $fh });
    my $cache_file = File::Spec->catfile($cache_dir, $md5->hexdigest . ".json");

    if (-f $cache_file) {
        my $content = do { open my $fh, "<", $cache_file or die; local $/; <$fh> };
        my $cache = $JSON->decode($content);
        if ( ($cache->{version} || 0) == $CACHE_VERSION ) {
            return $cache->{payload};
        } else {
            unlink $cache_file;
        }
    }
    my $result = $sub->();
    if ($result) {
        open my $fh, ">", $cache_file or die;
        my $content = {version => $CACHE_VERSION, payload => $result};
        print {$fh} $JSON->encode($content), "\n";
        close $fh;
    }
    $result;
}

sub extract_provides {
    my ($self, $path) = @_;
    $path = Cwd::abs_path($path);
    $self->_cached($path, sub { $self->_extract_provides($path) });
}

sub _extract_provides {
    my ($self, $path) = @_;
    my $gurad = $self->pushd_tempdir;
    my $dir = $self->extract($path) or return;
    my $parser = Parse::LocalDistribution->new({ALLOW_DEV_VERSION => 1});
    $parser->parse($dir) || +{};
}

sub index_path {
    my ($self, %option) = @_;
    my $file = $self->base("modules", "02packages.details.txt");
    $option{compress} ? "$file.gz" : $file;
}

sub index {
    my ($self, %option) = @_;
    my $base = $self->base("authors", "id");
    return unless -d $base;

    my @dist;
    my $wanted = sub {
        return unless -f;
        return unless /(?:\.tgz|\.tar\.gz|\.tar\.bz2|\.zip)$/;
        my $path = $_;
        push @dist, {
            path => $path,
            mtime => (stat $path)[9],
            relative => File::Spec::Unix->abs2rel($path, $base),
        };
    };
    File::Find::find({wanted => $wanted, no_chdir => 1}, $base);

    my %packages;
    for my $i (0..$#dist) {
        my $dist = $dist[$i];
        if ($option{show_progress}) {
            warn sprintf "%d/%d examining %s\n",
                $i+1, scalar @dist, $dist->{relative};
        }
        my $provides = $self->extract_provides($dist->{path});
        $self->_update_packages(\%packages, $provides, $dist->{relative}, $dist->{mtime});
    }

    my @line;
    for my $package (sort { lc $a cmp lc $b } keys %packages) {
        my $path    = $packages{$package}[1];
        my $version = $packages{$package}[0];
        $version = 'undef' unless defined $version;
        push @line, sprintf "%-36s %-8s %s\n", $package, $version, $path;
    }
    join '', @line;
}

sub write_index {
    my ($self, %option) = @_;
    my $file = $self->index_path;
    my $dir  = File::Basename::dirname($file);
    File::Path::mkpath($dir) unless -d $dir;
    open my $fh, ">", "$file.tmp" or die "Couldn't open $file: $!";
    printf {$fh} "Written-By: %s %s\n\n", ref $self, $self->VERSION;
    print {$fh} $self->index(%option);
    close $fh;
    if ($option{compress}) {
        my (undef, $err, $exit) = safe_system(
            [$self->{gzip}, "--stdout", "--no-name", "$file.tmp"],
            ">",
            ["$file.gz.tmp"],
        );
        if ($exit == 0) {
            rename "$file.gz.tmp", "$file.gz"
                or die "Couldn't rename $file.gz.tmp to $file.gz: $!";
            unlink "$file.tmp";
            return "$file.gz";
        } else {
            unlink $_ for "$file.tmp", "$file.gz.tmp";
            return;
        }
    } else {
        rename "$file.tmp", $file or die "Couldn't rename $file.tmp to $file: $!";
        return $file;
    }
}

# Copy from WorePAN: https://github.com/charsbar/worepan/blob/master/lib/WorePAN.pm
# Copyright (C) 2012 by Kenichi Ishigaki.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
sub _update_packages {
  my ($self, $packages, $info, $path, $mtime) = @_;

  for my $module (sort keys %$info) {
    next unless exists $info->{$module}{version};
    my $new_version = $info->{$module}{version};
    if (!$packages->{$module}) { # shortcut
      $packages->{$module} = [$new_version, $path, $mtime];
      next;
    }
    my $ok = 0;
    my $cur_version = $packages->{$module}[0];
    if (Parse::PMFile->_vgt($new_version, $cur_version)) {
      $ok++;
    }
    elsif (Parse::PMFile->_vgt($cur_version, $new_version)) {
      # lower VERSION number
    }
    else {
      no warnings; # numeric/version
      if (
        $new_version eq 'undef' or $new_version == 0 or
        Parse::PMFile->_vcmp($new_version, $cur_version) == 0
      ) {
        if ($mtime >= $packages->{$module}[2]) {
          $ok++; # dist is newer
        }
      }
    }
    if ($ok) {
      $packages->{$module} = [$new_version, $path, $mtime];
    }
  }
}

1;
__END__

=encoding utf-8

=for stopwords DarkPAN OrePAN2 tempdir commitish

=head1 NAME

CPAN::Mirror::Tiny - create partial CPAN mirror (a.k.a. DarkPAN)

=head1 SYNOPSIS

  use CPAN::Mirror::Tiny;

  my $cpan = CPAN::Mirror::Tiny->new(base => "./darkpan");

  $cpan->inject("https://cpan.metacpan.org/authors/id/S/SK/SKAJI/App-cpm-0.112.tar.gz");
  $cpan->inject("https://github.com/skaji/Carl.git");
  $cpan->write_index(compress => 1);

  # $ find darkpan -type f
  # darkpan/authors/id/S/SK/SKAJI/App-cpm-0.112.tar.gz
  # darkpan/authors/id/V/VE/VENDOR/Carl-0.01-ff194fe.tar.gz
  # darkpan/modules/02packages.details.txt.gz

=head1 DESCRIPTION

CPAN::Mirror::Tiny helps you create partial CPAN mirror (also known as DarkPAN).

There is also a command line interface L<cpan-mirror-tiny> for CPAN::Mirror::Tiny.

=head1 WHY NEW?

Yes, we already have great CPAN modules which create CPAN mirror.

L<CPAN::Mini>, L<OrePAN2>, L<WorePAN> ...

I want to use such modules in CPAN clients.
Actually I used OrePAN2 in L<Carl|https://github.com/skaji/Carl>,
which can install modules in github.com or any servers.

Then minimal dependency and no dependency on XS modules is critical.
Unfortunately existing CPAN mirror modules depend on XS modules.

This is why I made CPAN::Mirror::Tiny.

=head1 METHODS

=head2 new

  my $cpan = CPAN::Mirror::Tiny->new(%option)

Constructor. C< %option > may be:

=over 4

=item * base

Base directory for cpan mirror. If C<$ENV{PERL_CPAN_MIRROR_TINY_BASE}> is set, it will be used.
This is required.

=item * tempdir

Temp directory. Default C<< File::Temp::tempdir(CLEANUP => 1) >>.

=back

=head2 inject

  # automatically guess $source
  $cpan->inject($source, \%option)

  # or explicitly call inject_* method
  $cpan->inject_local('/path/to//Your-Module-0.01.tar.gz'', {author => 'YOU'});
  $cpan->inject_local_file('/path/to//Your-Module-0.01.tar.gz'', {author => 'YOU'});
  $cpan->inject_local_directory('/path/to/cpan/dir', {author => 'YOU'});

  $cpan->inject_http('http://example.com/Hoge-0.01.tar.gz', {author => 'YOU'});

  $cpan->inject_git('git://github.com/skaji/Carl.git', {author => 'SKAJI'});

  $cpan->inject_cpan('Plack', {version => '1.0039'});

Inject C< $source > to our cpan mirror directory. C< $source > is one of

=over 4

=item * local tar.gz path / directory

  $cpan->inject('/path/to/Module.tar.gz', { author => "SKAJI" });
  $cpan->inject('/path/to/dir',           { author => "SKAJI" });

=item * http url of tar.gz

  $cpan->inject('http://example.com/Module.tar.gz', { author => "DUMMY" });

=item * git url (with optional ref)

  $cpan->inject('git://github.com/skaji/Carl.git', { author => "SKAJI", ref => '0.114' });

=item * cpan module

  $cpan->inject('cpan:Plack', {version => '1.0039'});

=back

As seeing from the above examples, you can specify C<author> in C<\%option>.
If you omit C<author>, default C<VENDOR> is used.

B<CAUTION>: Currently, the distribution name for git repository is something like
C<S/SK/SKAJI/Carl-0.01-9188c0e.tar.gz>,
where C<0.01> is the version and C<9188c0e> is C<git rev-parse --short HEAD>.

=head2 index

  my $index_string = $cpan->index

Get the index (a.k.a. 02packages.details.txt) of our cpan mirror.

=head2 write_index

  $cpan->write_index( compress => bool )

Write the index to C< $base/modules/02packages.details.txt >
or C< base/modules/02packages.details.txt.gz >.

=head1 TIPS

=head2 How can I install modules in my DarkPAN with cpanm / cpm?

L<cpanm> is an awesome CPAN clients. If you want to install modules
in your DarkPAN with cpanm, there are 2 ways.

First way:

  cpanm --cascade-search \
    --mirror-index /path/to/darkpan/modules/02packages.details.txt \
    --mirror /path/to/darkpan \
    --mirror http://www.cpan.org \
    Your::Module

Second way:

  cpanm --mirror-only \
    --mirror /path/to/darkpan \
    --mirror http://www.cpan.org \
    Your::Module

If you use L<cpm>, then:

  cpm install -r 02packages,file:///path/to/drakpan -r metadb Your::Module

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
