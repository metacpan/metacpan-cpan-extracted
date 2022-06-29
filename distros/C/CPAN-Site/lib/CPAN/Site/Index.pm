# Copyrights 1998,2005-2022 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution CPAN::Site.
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package CPAN::Site::Index;
use vars '$VERSION';
$VERSION = '1.17';

use base 'Exporter';

use warnings;
use strict;

our @EXPORT_OK = qw/cpan_index cpan_mirror/;
our $VERSION;  # required in test-env

use Log::Report     'cpan-site', syntax => 'SHORT';

use version;
use File::Find      qw/find/;
use File::Copy      qw/copy/;
use File::Basename  qw/basename dirname/;
use HTTP::Date      qw/time2str/;
use File::Spec::Functions qw/catfile catdir splitdir/;
use LWP::UserAgent  ();
use Archive::Tar    ();
use Archive::Zip    qw(:ERROR_CODES :CONSTANTS);
use CPAN::Checksums qw(updatedir);  # horrible function name
use IO::Zlib        ();

my $tar_gz      = qr/ \.tar\.gz$ | \.tar\.Z$ | \.tgz$/xi;
my $zip         = qr/ \.zip$ /xi;
my $cpan_update = 0.04; # days between reload of full CPAN index
my $ua;

sub safe_copy($$);
sub cpan_index($@);
sub register($$$);
sub package_inventory($$;$);
sub package_on_usual_location($);
sub inspect_archive;
sub inspect_tar_archive($$);
sub inspect_zip_archive($$);
sub collect_package_details($$$);
sub update_global_cpan($$);
sub load_file($$);
sub merge_global_cpan($$$);
sub create_details($$$$$);
sub calculate_checksums($$);
sub read_details($);
sub remove_expired_details($$$);
sub mkdirhier(@);
sub cpan_mirror($$$@);

sub safe_copy($$)
{   my ($from, $to) = @_;
    trace "copy $from to $to";
    copy $from, $to
        or fault __x"cannot copy {from} to {to}", from => $from, to => $to;
}

sub cpan_index($@)
{   my ($mycpan, $globalcpan, %opts) = @_;
    my $lazy     = $opts{lazy};
    my $fallback = $opts{fallback};
    my $undefs   = exists $opts{undefs} ? $opts{undefs} : 1;

    unless($ua)
    {   $ua = LWP::UserAgent->new;
        $ua->env_proxy if $opts{env_proxy};
    }

    -d $mycpan
        or error __x"archive top '{dir}' is not a directory"
             , dir => $mycpan;

    my $program     = basename $0;
    $VERSION      ||= 'undef';   # test env at home
    trace "$program version $VERSION";

    my $global      = catdir $mycpan, 'global';
    my $mods        = catdir $mycpan, 'modules';
    my $authors     = catdir $mycpan, 'authors';
    mkdirhier $global, $mods, $authors;

    my $globdetails = update_global_cpan $mycpan, $globalcpan;

    # Create mailrc and modlist

    safe_copy catfile($global, '01mailrc.txt.gz')
            , catfile($authors, '01mailrc.txt.gz');

    safe_copy catfile($global, '03modlist.data.gz')
            , catfile($mods, '03modlist.data.gz');

    # Create packages details

    my $details     = catfile $mods, '02packages.details.txt.gz';
    my $newlist     = catfile $mods, '02packages.details.tmp.gz';
    my $newer;

    my $reuse_dists = {};
    if($lazy && -f $details)
    {   $reuse_dists = read_details $details;
        $newer       = -M $details;
        remove_expired_details $mycpan, $reuse_dists, $newer;
    }

    my ($mypkgs, $distdirs)
      = package_inventory $mycpan, $reuse_dists, $newer;

    merge_global_cpan $mycpan, $mypkgs, $globdetails
        if $fallback;

    create_details $details, $newlist, $mypkgs, $lazy, $undefs;

    if(-f $details)
    {   trace "backup old details file to $details.bak";
        safe_copy $details, "$details.bak";
    }

    if(-f $newlist)
    {   trace "promoting $newlist to current";
        rename $newlist, $details
            or error __x"cannot rename '{from}' in '{to}'"
                 , from => $newlist, to => $details;
    }

    calculate_checksums $distdirs, catdir($mycpan, 'authors', 'id');
}

#
# Package Inventory
#

# global variables for testing purposes (sorry)
our ($topdir, $findpkgs, %finddirs, $olddists, $index_age);

sub register($$$)
{   my ($package, $this_version, $dist) = @_;

    # warn "register $package, " . (defined $this_version ? $this_version : 'undef');

    if(ref $this_version)
    {   eval { $this_version = version->parse($this_version) };
        if($@)
        {   alert __x"error when creating version object for {pkg}: {err}"
               , pkg => $package, err => $@;
            return;
        }
    }
      
    my $registered_version = exists $findpkgs->{$package} ? $findpkgs->{$package}[0] : undef;
    $this_version =~ s/^v// if $this_version;

    return if defined $registered_version
           && $registered_version > $this_version;

    $findpkgs->{$package} = [ $this_version, $dist ];
}

sub package_inventory($$;$)
{   (my $mycpan, $olddists, $index_age) = @_;   #!!! see "my"
    $topdir   = catdir $mycpan, 'authors', 'id';
    mkdirhier $topdir;

    $findpkgs = {};
    trace "creating inventory from $topdir";

    find {wanted => \&inspect_archive, no_chdir => 1}, $topdir;
    ($findpkgs, \%finddirs);
}

sub package_on_usual_location($)
{   my $file  = shift;
    my ($top, $subdir, @rest) = splitdir $file;
    defined $subdir or return 0;

       !@rest             # path is at top-level of distro
    || $subdir eq 'lib';  # inside lib
}

sub inspect_archive
{   my $fn = $File::Find::name;
    return unless -f $fn && ($fn =~ $tar_gz || $fn =~ $zip);

    (my $dist = $fn) =~ s!^\Q$topdir\E[\\/]!!;

    if(defined $index_age && -M $fn > $index_age)
    {
        unless(exists $olddists->{$dist})
        {   trace "not the latest: $dist";
            return;
        }

        trace "latest older than index: $dist";
        foreach (@{$olddists->{$dist}})
        {   my ($pkg, $version) = @$_;
            register $pkg, $version, $dist;
        }
        return;
    }

    trace "inspecting archive $fn";
    $finddirs{$File::Find::dir}++;

    return inspect_tar_archive $dist, $fn
        if $fn =~ $tar_gz;

    return inspect_zip_archive $dist, $fn
        if $fn =~ $zip;
}

sub inspect_tar_archive($$)
{   my ($dist, $fn) = @_;

    my $arch =  Archive::Tar->new;
    $arch->read($fn, 1)
        or error __x"no files in tar archive '{fn}': {err}"
             , fn => $fn, err => $arch->error;

    foreach my $file ($arch->get_files)
    {   my $fn = $file->full_path;
        $file->is_file && $fn =~ m/\.pm$/i && package_on_usual_location $fn
            or next;
        collect_package_details $fn, $dist, $file->get_content_by_ref;
    }
}

sub inspect_zip_archive($$)
{   my ($dist, $fn) = @_;

    my $arch =  Archive::Zip->new;
    $arch->read($fn)==AZ_OK
        or error __x"no files in zip archive '{fn}': {err}"
             , fn => $fn, err => $arch->error;

    foreach my $member ($arch->membersMatching( qr/\.pm$/i ))
    {   my $fn = $member->fileName;
        $member->isTextFile && package_on_usual_location $fn
            or next;
        my ($contents, $status) = $member->contents;
        $status==AZ_OK
            or error "error in zip file {fn}: {err}"
               , fn => $fn, err => $status;
        collect_package_details $fn, $dist, \$contents;
    }
}

sub collect_package_details($$$)
{   my ($fn, $dist) = (shift, shift);
    my @lines  = split /\r?\n/, ${shift()};
    my $in_pod = 0;
    my $package;
    local $VERSION = undef;  # may get destroyed by eval

    while(@lines)
    {   local $_ = shift @lines;
        last if m/^__(?:END|DATA)__$/;

        $in_pod = ($1 ne 'cut') if m/^=(\w+)/;
        next if $in_pod || m/^\s*#/;

        $_ .= shift @lines
            while @lines && m/package|use|VERSION/ && !m/[;{]/;

        if( m/^\s* package \s* ((?:\w+\:\:)*\w+) (?:\s+ (\S*))? \s* [;{]/x )
        {   my ($thispkg, $v) = ($1, $2);
            my $thisversion;
            if($v)
            {   $thisversion = eval {qv($v)};
                alert __x"illegal version for {pkg}, found '{version}': {err}"
                   , pkg => $thispkg, version => $v, err => $@  if $@;
            }

            # second package in file?
            register $package, $VERSION, $dist
                if defined $package;

            ($package, $VERSION) = ($thispkg, $thisversion);
            trace "pkg $package from $fn";
        }

        if( m/^\s* \$ ${package}::VERSION \s* = \s* ["']?(\w+?)["']? \s* ;/x )
        {   $VERSION = $1;
        }

        if( !$VERSION && m/^ (?:use\s+version\s*;\s*)?
            (?:our)? \s* \$ ((?: \w+\:\:)*) VERSION \s* \= (.*)/x )
        {   defined $2 or next;
            my ($ns, $vers) = ($1, $2);

            # some versions of CPAN.pm do contain lines like "$VERSION =~ ..."
            # which also need to be processed.
            eval "\$VERSION =$vers";
            if(defined $VERSION)
            {   ($package = $ns) =~ s/\:\:$//
                    if length $ns;
                trace "pkg $package version $VERSION";
            }
        }
    }

    $VERSION = $VERSION->numify if ref $VERSION;
    register $package, $VERSION, $dist
        if defined $package;
}

sub update_global_cpan($$)
{   my ($mycpan, $globalcpan) = @_;

    my $global = catdir $mycpan, 'global';
    my ($mailrc, $globdetails, $modlist) = 
       map { catfile $global, $_ }
         qw/01mailrc.txt.gz 02packages.details.txt.gz 03modlist.data.gz/;

    return $globdetails
       if -f $globdetails && -f $globdetails && -f $modlist
       && -M $globdetails < $cpan_update;

    info "(re)loading global CPAN files";

    mkdirhier $global;
    load_file "$globalcpan/authors/01mailrc.txt.gz",   $mailrc;
    load_file "$globalcpan/modules/02packages.details.txt.gz", $globdetails;
    load_file "$globalcpan/modules/03modlist.data.gz", $modlist;
    $globdetails;
}

sub load_file($$)
{   my ($from, $to) = @_;
    my $response = $ua->get($from, ':content_file' => $to);
    return if $response->is_success;

    unlink $to;
    error __x"failed to get {uri} for {to}: {err}"
      , uri => $from, to => $to, err => $response->status_line;
}

sub merge_global_cpan($$$)
{   my ($mycpan, $pkgs, $globdetails) = @_;

    trace "merge packages with CPAN core list in $globdetails";
    my $cpan_pkgs = read_details $globdetails;

    while(my ($cpandist, $cpanpkgs) = each %$cpan_pkgs)
    {   foreach (@$cpanpkgs)
        {  my ($pkg, $version) = @$_;
           next if exists $pkgs->{$pkg};
           $pkgs->{$pkg} = [$version, $cpandist];
        }
    }
}

sub create_details($$$$$)
{  my ($details, $filename, $pkgs, $lazy, $undefs) = @_;

   trace "creating package details in $filename";
   my $fh = IO::Zlib->new($filename, 'wb')
      or fault __x"generating gzipped {fn}", fn => $filename;

   my $lines = keys %$pkgs;
   my $date  = time2str time;
   my $how   = $lazy ? "lazy" : "full";

   info "produced list of $lines packages $how";

   my $program     = basename $0;
   my $module      = __PACKAGE__;
   $fh->print (<<__HEADER);
File:         02packages.details.txt
URL:          file://$details
Description:  Packages listed in CPAN and local repository
Columns:      package name, version, path
Intended-For: private CPAN
Line-Count:   $lines
Written-By:   $program with $module $CPAN::Site::Index::VERSION ($how)
Last-Updated: $date

__HEADER

   foreach my $pkg (sort { lc($a) cmp lc($b) } keys %$pkgs)
   {  my ($version, $path) = @{$pkgs->{$pkg}};

      $version = 'undef'
          if !defined $version || $version eq '';

      next
          if $version eq 'undef' && !$undefs;

      $path    =~ s,\\,/,g;
      $fh->printf("%-30s\t%s\t%s\n", $pkg, $version, $path);
   }
}

sub calculate_checksums($$)
{   my $dirs = shift;
    my $root = shift;
    trace "updating checksums";

    foreach my $dir (keys %$dirs)
    {   trace "summing $dir";
        updatedir($dir, $root)
            or warning 'failed calculating checksums in {dir}', dir => $dir;
    }
}

sub read_details($)
{   my $fn = shift;
    -f $fn or return {};
    trace "collecting all details from $fn";

    my $fh    = IO::Zlib->new($fn, 'rb')
       or fault __x"cannot read from {fn}", fn => $fn;

    my $line;   # skip header, search first blank
    do { $line = $fh->getline } until $line =~ m/^\s*$/;

    my $time_last_update = (stat $fn)[9];
    my %dists;

    while(my $line = $fh->getline)
    {   chomp $line;
        my ($pkg, $version, $dist) = split ' ', $line, 3;

        unless($dist)
        {   warning "$fn error line=\n  $line";
            next;
        }

        push @{$dists{$dist}}, [$pkg, $version];
    }

    \%dists;
}

sub remove_expired_details($$$)
{   my ($mycpan, $dists, $newer) = @_;
    trace "extracting only existing local distributions";

    my $authors = catdir $mycpan, 'authors', 'id';
    foreach my $dist (keys %$dists)
    {   my $fn = catfile $authors, $dist;
        if(! -f $fn)
        {   # removed local or a global dist
            delete $dists->{$dist};
        }
        elsif(-M $fn < $newer)
        {   trace "dist $dist file updated, reindexing";
            delete $dists->{$dist};
        }
    }
}

sub mkdirhier(@)
{   foreach my $dir (@_)
    {   next if -d $dir;
        mkdirhier dirname $dir;

        mkdir $dir, 0755
            or fault __x"cannot create directory {dir}", dir => $dir;

        trace "created $dir";
    }
    1;
}

sub cpan_mirror($$$@)
{   my ($mycpan, $globalcpan, $mods, %opts) = @_;
    @$mods or return;
    my %need = map { ($_ => 1) } @$mods;
    my $auth = catdir $mycpan, 'authors', 'id';

    unless($ua)
    {   $ua = LWP::UserAgent->new;
        $ua->env_proxy if $opts{env_proxy};
    }

    my $globdetails
             = update_global_cpan $mycpan, $globalcpan;

    my $fh   = IO::Zlib->new($globdetails, 'rb')
        or fault __x"cannot read from {fn}", fn => $globdetails;

    while(my $line = $fh->getline)   # skip header, search first blank
    {   last if $line =~ m/^\s*$/;
    }

    $ua ||= LWP::UserAgent->new;
    while(my $line = $fh->getline)
    {   my ($pkg, $version, $dist) = split ' ', $line;
        delete $need{$pkg} or next;

        my $to = catfile $auth, split m#/#, $dist;
        if(-f $to)
        {   trace __x"package {pkg} present in distribution {dist}"
              , pkg => $pkg, dist => $dist;
            next;
        }

        my $source   = "$globalcpan/authors/id/$dist";
        mkdirhier dirname $to;
        my $response = $ua->get($source, ':content_file' => $to);
        unless($response->is_success)
        {   unlink $to;
            error __x"failed to get {uri} for {to}: {err}"
              , uri => $source, to => $to, err => $response->status_line;
        }

        info __x"got {pkg} in {dist}", pkg => $pkg, dist => $dist;
    }

    warning __x"package {pkg} does not exist", pkg => $_
        for sort keys %need;
}

1;
