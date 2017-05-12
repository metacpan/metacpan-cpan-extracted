#!perl
package CPAN::Search::Lite::Extract;
use strict;
use warnings;
use Archive::Zip;
use Archive::Tar;
use File::Temp qw(tempfile);
use File::Basename;
use File::Path;
use File::Spec::Functions qw(splitdir catfile catdir splitpath canonpath);
use YAML qw(LoadFile);
use File::Copy;
use Pod::Select;
use Perl::Tidy;
use File::Find;
use CPAN::Search::Lite::Util qw(has_data);
use Safe;
our $VERSION = 0.77;

my $ext = qr/\.(tar\.gz|tar\.Z|tgz|zip)$/;
my $DEBUG = 1;
my $setup;

sub new {
    my ($class, %args) = @_;
    foreach (qw(CPAN pod_root) ) {
        die "Must supply a '$_' argument" unless $args{$_};
    }

    $setup = $args{setup};
    my $index = $args{index};
    my %info;
    foreach my $table (qw(dists mods auths)) {
        my $obj = $index->{$table};
        die "Please supply a CPAN::Search::Lite::Index::$table object"
            unless ($obj and ref($obj) eq "CPAN::Search::Lite::Index::$table");
        $info{$table} = $obj->{info};
    }    
    my $state = $args{state};
    unless ($setup) {
        die "Please supply a CPAN::Search::Lite::State object"
            unless ($state and ref($state) eq 'CPAN::Search::Lite::State');
    }
    if ($args{pod_only} and $args{split_pod}) {
        die qq{Please specify only one of "split_pod" or "pod_only"};
    }

    my $self = {pod_root => $args{pod_root},
		CPAN => $args{CPAN},
                props => {},
                %info,
                state => $state,
                pod_only => $args{pod_only},
                split_pod => $args{split_pod},
		dist_docs => {},
            };
    bless $self, $class;
}

sub extract {
  my $self = shift;
  my $props = $self->{props};
  my $dists = $self->{dists};
  my $mods = $self->{mods};
  my $CPAN = $self->{CPAN};
  my $pod_root = $self->{pod_root};
  my $pod_only = $self->{pod_only};
  my $split_pod = $self->{split_pod};
  my $pat = qr!^[^/]+/change|^[^/]+/install|^[^/]+/Makefile.PL$|\.pod$|\.pm$!i;
  my @dist_names = ();
  if ($setup) {
    @dist_names = keys %$dists;
  }
  else {
    my $dist_obj = $self->{state}->{obj}->{dists};
    for my $type (qw(insert update)) {
      my $data = $dist_obj->{$type};
      next unless has_data($data);
      push @dist_names, keys %{$data};
    }
  }
  foreach my $dist (@dist_names) {
    my $docs;
    my $values = $dists->{$dist};
    my $version = $values->{version};
    my $cpanid = $values->{cpanid};
    my $filename = $values->{filename};
    unless ($filename and $version and $cpanid) {
      warn "No distribution/version/cpanid info for $dist";
      next;
    }
    my ($archive, @files);
    my $download = $self->download($cpanid, $filename);
    
    my $fulldist = catfile $CPAN, $download;
    unless (-f $fulldist) {
      print qq{"$fulldist" not present - skipping ...\n};
      next;
    }
    print "Extracting files within $download ...\n";
    
    my $cs = catfile dirname($fulldist), 'CHECKSUMS';
    if (-f $cs) {
      my $cksum = $self->load_cs($cs);
      my $md5;
      my $basename = basename($filename, qr{\..*});
      if ($cksum and ($md5 = $cksum->{$basename}->{md5})) {
        $dists->{$dist}->{md5} = $md5;
      }
    }
    
    (my $yaml = $fulldist) =~ s/$ext/.meta/;
    if (-f $yaml) {
      eval {$props->{$dist} = LoadFile($yaml);};
      warn $@ if $@;
    }
    if ($props->{$dist} and $props->{$dist}->{requires}) {
      $dists->{$dist}->{requires} = $props->{$dist}->{requires};
    }
    if ($props->{$dist} and $props->{$dist}->{abstract}) {
      $dists->{$dist}->{description} = $props->{$dist}->{abstract};
    }
    
    my $dist_root = catdir $pod_root, $dist;
    $docs->{dist_root} = $dist_root;
    if (-d $dist_root) {
      rmtree($dist_root, $DEBUG, 1) or do {
        warn "Cannot rmtree $dist_root: $!";
        next;
      };
    }
    mkpath($dist_root, $DEBUG, 0755) or do {
      warn "Cannot mkdir $dist_root: $!";
      next;
    };
    
    (my $cpan_readme = $fulldist) =~ s/$ext/.readme/;
    if (-f $cpan_readme) {
      my $readme = catfile $dist_root, 'README';
      copy($cpan_readme, $readme) or do {
        warn "Cannot copy $cpan_readme to $readme: $!";
        next;
      };
      my $contains_pod;
      open(my $fh, $readme) or do {
        warn "Cannot open $cpan_readme: $!";
        next;
      };
      while (<$fh>) {
        if (/^=head1/) {
          $contains_pod = 1;
          last;
        }
      }
      close $fh;
      if ($contains_pod) {
        rename ($readme, $readme . '.pod') or do {
          warn "Cannot rename $readme: $!";
          next;
        };
        $docs->{files}->{'README.pod'} = {name => "$dist README"};
      }
      else {
        $docs->{files}->{'README'} = {name => "$dist README"};
        }
      $dists->{$dist}->{readme} = 1;
    }
    
    if (-f $yaml) {
      my $meta = catfile $dist_root, 'META.yml';
      copy($yaml, $meta) or do {
        warn "Cannot copy $yaml to $meta: $!";
        next;
      };
      $dists->{$dist}->{meta} = 1;
      $docs->{files}->{'META.yml'} = {name => "$dist META"};
    }
    
    my $is_zip = ($filename =~ /\.zip$/);
    if ($is_zip) {
      $archive = Archive::Zip->new($fulldist) or do {
        warn "Cannot open $fulldist: $!";
        next;
      };
      @files = grep {m!$pat!} $archive->memberNames() or do { 
        warn "Cannot list files for $fulldist: $!";
        next;
      };
    }
    else {
      $archive = Archive::Tar->new($fulldist, 1) or do {
        warn "Cannot open $fulldist: $!";
        next;
      };
      @files = grep {m!$pat!} $archive->list_files() or do { 
        warn "Cannot list files for $fulldist: $!";
        next;
      };
    }
    
    my $ignore;
    push @{$ignore->{directory}}, qw(t blib);
    if (defined $props->{$dist}) {
      foreach my $key (qw(no_index ignore)) {
        foreach my $type(qw(directory file package)) {
          my $value = $props->{$dist}->{$key}->{$type};
          next unless (defined $value and ref($value) eq 'ARRAY');
          push @{$ignore->{$type}}, @$value;
        }
      }
    }
    my $ignore_pat = join '|', @{$ignore->{directory}};
    @files = grep {not m!\Q$dist\E[^/]*/($ignore_pat)/!} @files;
    my $entry = $ignore->{file};
    if ($entry and ref($entry) eq 'ARRAY') {
      $ignore_pat = join '|', @$entry;
      @files = grep {not m!\Q$dist\E[^/]*/($ignore_pat)$!} @files;
    }
    my %ignore_packs = ();
    $entry = $ignore->{package};
    if (defined $entry and ref($entry) eq 'ARRAY') {
      %ignore_packs = map {$_ => 1} @$entry;
    }
    
    unless ($files[0] =~ /\Q$dist/) {
      warn "Strange unpacked directory structure for $dist";
      # next;
    }
    
    foreach my $file (@files) {
      print "Extracting $file ...\n";
      my $provides;
      if ($props->{$dist} and $props->{$dist}->{provides}) {
        $provides = $props->{$dist}->{provides};
      }
      my $content = ($is_zip ? 
                     $archive->contents($file) : 
                     $archive->get_content($file) ) or do {
                       warn "Cannot get content of $file: $!";
                       next;
                     };
      $content =~ s!\r!!g;
      if ($file =~ /Makefile.PL$/ 
	  and not has_data($dists->{$dist}->{requires})) {
	my $prereqs = $self->parse_MakefilePL($content);
	next unless ($prereqs  and has_data($prereqs));
	$dists->{$dist}->{requires} = $prereqs;
	next;
      }
      my $is_pod = ($file =~ /\.(pod|pm)$/);
      my $has_pod = ($is_pod and $content =~ /^=head/m);
      next if ($pod_only and $is_pod and not $has_pod);
      my ($module, $description);
      if ($has_pod) {
        ($module, $description) = $self->abstract($content);
      }
      else {
        $module = $self->package_name($content);
      }
      
      next if ($module and $ignore_packs{$module});
      if ($provides and $file =~ /\.pm$/) {
        next unless ($provides->{$module} 
                     and $file =~ /$provides->{$module}->{file}/);
      }
      
      my $rel_root;
      if ($module and $dists->{$dist}->{modules}->{$module}) {
        my @dirs = split /::/, $module;
        pop @dirs if @dirs >= 1;
        $rel_root = catdir(@dirs);
      }
      my $abs_root = $rel_root ?
          catdir $dist_root, $rel_root : $dist_root;
      unless (-d $abs_root) {
        mkpath($abs_root, $DEBUG, 0755) or do {
          warn "Cannot mkdir $abs_root: $!";
          next;
        };
      }
      
      my $doc = basename($file);
      if ($doc =~ /change/i and $doc !~ /\.pm$/) {
        $doc = $is_pod ? 'Changes.pod' : 'Changes';
        $description = "$dist Changes";
        $docs->{files}->{$doc} = {name => $description};
        $dists->{$dist}->{changes} = 1;
      }
      if ($doc =~ /install/i and $doc !~ /\.pm$/) {
        $doc = $is_pod ? 'INSTALL.pod' : 'INSTALL';
        $description = "$dist INSTALL";
          $docs->{files}->{$doc} = {name => $description};
        $dists->{$dist}->{install} = 1;
      }
      my $rel_file = $rel_root ?
        catfile $rel_root, $doc : $doc; 
      my $abs_file = catfile $abs_root, $doc;
      if ($pod_only and $is_pod) {
        my ($tmpfh, $tmpfn) = tempfile(UNLINK => 1) or do {
          warn "Cannot create tempfile: $!";
          next;
        };
        print $tmpfh $content;
        seek($tmpfh,0,1);
        my $parser = Pod::Select->new();
        $parser->parse_from_file($tmpfn, $abs_file);
        close $tmpfh;
      }
      else {
        open(my $fh, '>', $abs_file) or do {
          warn "Cannot write to $abs_file: $!";
          next;
        };
        print $fh $content;
        close $fh;
        }
      if ($is_pod) {
        my $name;
        if ($module) {
          $name = $module;
        }
        else {
          ($name = $doc) =~ s/\.(pm|pod)$//;
        }
        my $desc = $description || "$name documentation";
        $docs->{files}->{$rel_file} = {name => $name, 
                                       desc => $desc};
      }
      if ($is_pod and $module) {
        if ($dists->{$dist}->{modules}->{$module}) {
          $mods->{$module}->{description} = $description
                    if ($description and !$mods->{$module}->{description});
          $mods->{$module}->{doc} = 1 if $has_pod;
          $mods->{$module}->{src} = 1 unless $pod_only;
        }
        unless ($dists->{$dist}->{description} or ! $description) {
          (my $trial_dist = $module) =~ s/::/-/g;
                  if ($trial_dist eq $dist) {
                    $dists->{$dist}->{description} = $description;
                  }
          else {
            foreach my $key ( qw(abstract_from version_from) ) {
              next unless (my $key_file = $props->{$key});
              if ($key_file =~ /\Q$rel_file/) {
                $dists->{$dist}->{description} = $description;
                last;
              }
            }
          }
        }
      }
    }
    $self->{dist_docs}->{$dist} = $docs;
  }
  $self->cleanup() unless $setup;
  return 1;
}

sub parse_MakefilePL {
  my ($self, $content) = @_;
  my $p = $1 if $content =~ m/PREREQ_PM.*?=>.*?\{(.*?)\}/s;
  return unless $p;
  # get rid of lines which are only comments
  $p = join "\n", grep { $_ !~ /^\s*#/ } split "\n", $p;
  # get rid of empty lines
  $p = join "\n", grep { $_ !~ /^\s*$/ } split "\n", $p;

  my $prereqs;
  if ($p =~ /=>/ or $p =~ /,/) {
    my $code = "{no strict; \$prereqs = { $p\n}}";
    eval $code;
    if ($@) {
      print "$@\n";
      return;
    }
  }
  return $prereqs;
}

sub cleanup {
    my $self = shift;
    my $dist_obj = $self->{state}->{obj}->{'CPAN::Search::Lite::State::dists'};
    my $data = $dist_obj->{delete};
    return unless has_data($data);
    my $dists = $self->{dists};
    my $pod_root = $self->{pod_root};
    my $html_root = $self->{html_root};
    foreach my $dist (keys %$data) {
        next unless defined $dist;
        my $values = $dists->{$dist};
        my $cpanid = $values->{cpanid};
        my $filename = $values->{filename};
        my $download = $self->download($cpanid, $filename);
        my $pod_dir = catdir $pod_root, $dist;
        my $html_dir = catdir $html_root, $dist;
        foreach my $dir ($pod_dir, $html_dir) {
            if (-d $dir) {
                rmtree($dir, $DEBUG, 1) or do {
                    warn "Cannot rmtree $dir: $!";
                    next;
                };
            }
        }
    }
    return 1;
}

sub abstract {
    my ($self, $content) = @_;
    my @lines = split /\n/, $content;
    my ($description, $module);
    my $inpod = 0;
    foreach (@lines) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if !$inpod;
        chomp;
        next unless /^\s*(\S+)\s+--?\s+(.*?)\s*$/;
        $module = $1;
        $description = $2;
        last;
    }
    
    my $has_mod = ($module and $module =~ /\w/);
    my $has_desc = ($description and $description =~ /\w/);
    $module =~ s/-/::/g if $has_mod;
    if ($has_mod and $has_desc) {
        return ($module, $description);
    }
    elsif ($has_mod) {
        return ($module, undef);
    }
    else {
        return;
    }
}

sub package_name {
    my ($self, $content) = @_;
    my @lines = split /\n/, $content;
    my $module;
    foreach (@lines) {
        if (/^package\s+(\S+)\s*;/) {
            return $1;
        }
    }
    return;
}

sub download {
    my ($self, $cpanid, $dist_file) = @_;
    (my $fullid = $cpanid) =~ s!^(\w)(\w)(.*)!$1/$1$2/$1$2$3!;
    my $download = catfile 'authors/id', $fullid, $dist_file;
    return $download;
}

# routine to verify the CHECKSUMS for a file
# adapted from the MD5 check of CPAN.pm
sub load_cs {
    my ($self, $cs) = @_;
    my ($cksum, $fh);
    unless (open $fh, $cs) {
        warn "Could not open $cs: $!";
        return;
    }
    local($/);
    my $eval = <$fh>;
    $eval =~ s/\015?\012/\n/g;
    close $fh;
    my $comp = Safe->new();
    $cksum = $comp->reval($eval);
    if ($@) {
        warn $@;
        return;
    }
    return $cksum;
}

1;

__END__

=head1 NAME

CPAN::Search::Lite::Extract - extract files from CPAN distributions

=head1 DESCRIPTION

This module extracts the pod sections from various files in a
CPAN distribution, and places them in the location specified by
C<pod_root> in the main configuration file, underneath a
subdirectory denoting the distribution's name. Additionally,
it copies to this subdirectory the F<README> and F<META.yml>
files of the distribution, if they exist. Information on the
prerequisites of the package, as well as the abstract, if not
known at this point and if available, is extracted from
F<META.yml> and stored for future use.

It is assumed here that a local CPAN mirror exists; the C<no_mirror>
configuration option will cause this extraction to be skipped.

=head1 SEE ALSO

L<CPAN::Search::Lite::Index>

=cut

