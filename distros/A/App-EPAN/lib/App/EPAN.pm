package App::EPAN;

use 5.012;
{ our $VERSION = '0.002' }
use warnings;
use English qw( -no_match_vars );
use version;
use autodie;
use Getopt::Long qw< :config gnu_getopt >;
use Pod::Usage qw< pod2usage >;
use Dist::Metadata ();
use Path::Class qw< file dir >;
use Cwd qw< cwd >;
use File::Find::Rule ();
use Compress::Zlib   ();
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use Moo;
use IPC::Run   ();
use File::Copy ();
use File::Which qw< which >;

has configuration => (
   is        => 'rw',
   lazy      => 1,
   predicate => 'has_config',
   clearer   => 'clear_config',
   default   => sub { {} },
);
has action     => (is => 'rw',);
has last_index => (is => 'rw',);

sub run {
   my $package = shift;
   my $self    = $package->new();
   $self->get_options(@_);

   my $action = $self->action();
   pod2usage(-verbose => 99, -sections => 'USAGE') unless defined $action;
   if (my $method = $self->can("action_$action")) {
      $self->$method();
   }
   else {
      FATAL "action '$action' is not supported\n";
      $self->action_list_actions;
      exit 1;
   }
   return;
} ## end sub run

sub get_options {
   my $self = shift;
   my $action =
     (scalar(@_) && length($_[0]) && (substr($_[0], 0, 1) ne '-'))
     ? shift(@_)
     : 'list-actions';
   $action =~ s{-}{_}gmxs;
   local @ARGV = @_;
   $self->action($action);
   my %config = ();
   GetOptions(
      \%config,
      qw(
        mailrc|m|1=s
        output|packages-details|o|2=s
        modlist|modlist-data|l|3=s
        target|t=s
        test|T!
        author|a=s
        usage! help! man! version!
        )
   ) or pod2usage(-verbose => 99, -sections => 'USAGE');
   our $VERSION ||= 'whateva';
   pod2usage(message => "$0 $VERSION", -verbose => 99, -sections => ' ')
     if $config{version};
   pod2usage(-verbose => 99, -sections => 'USAGE') if $config{usage};
   pod2usage(-verbose => 99, -sections => 'USAGE|EXAMPLES|OPTIONS')
     if $config{help};
   pod2usage(-verbose => 2) if $config{man};
   $self->configuration(
      {
         cmdline_config => \%config,
         config         => \%config,
         args           => [@ARGV],
      }
   );
   return;
} ## end sub get_options

sub args {
   return @{$_[0]->configuration()->{args}};
}

sub config {
   my $self = shift;
   return @{$self->configuration()->{config}}{@_} if wantarray();
   return $self->configuration()->{config}{shift @_};
}

sub target_dir {
   my $self = shift;
   return dir($self->config('target') // 'epan');
}

sub execute_tests {
   my $self = shift;
   return $self->config('test');
}

sub action_index { return shift->_do_index }

{
   no strict 'refs';
   *{action_idx} = \&action_index;
}

sub _save {
   my ($self, $name, $contents, $config_key, $output) = @_;

   if (defined(my $confout = $self->config($config_key))) {
      $output =
          !length($confout) ? undef
        : $confout eq '-'   ? \*STDOUT
        :                     file($confout);
   } ## end if (defined(my $confout...))
   if (defined $output) {
      INFO "saving output to $output";
      $self->_save2($output,
         scalar(ref($contents) ? $contents->() : $contents));
   }
   else {
      INFO "empty filename for $name file, skipping";
   }
} ## end sub _save

sub _do_index {
   my ($self, $basedir) = @_;
   $basedir //= $self->target_dir;
   LOGDIE "path '$basedir' does not exist (wrong -t option?)"
      unless -d $basedir;

   $self->_save(
      '01mailrc',    # name
      '',            # contents
      'mailrc',      # configuration key to look output file
      $basedir->file(qw< authors 01mailrc.txt.gz >)    # default
   );

   $self->_save(
      '02packages.details',    # name
      sub {                    # where to get data from. Call is avoided if
                               # no file on output
         INFO "getting contributions for regenerated index...";
         $self->_index_for($basedir);
      },
      'output',                # configuration key to look output file
      $basedir->file(qw< modules 02packages.details.txt.gz >)    # default
   );

   $self->_save(
      '03modlist.data',                                          # name
      <<'END_OF_03_MODLIST_DATA',
File:        03modlist.data
Description: These are the data that are published in the module
        list, but they may be more recent than the latest posted
        modulelist. Over time we'll make sure that these data
        can be used to print the whole part two of the
        modulelist. Currently this is not the case.
Modcount:    0
Written-By:  PAUSE version 1.005
Date:        Sun, 28 Jul 2013 07:41:15 GMT

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
   my $result = {};
   my $primary = "modid";
   for (@$CPAN::Modulelist::data){
      my %hash;
      @hash{@$CPAN::Modulelist::cols} = @$_;
      $result->{$hash{$primary}} = \%hash;
   }
   return $result;
}
$CPAN::Modulelist::cols = [ ];
$CPAN::Modulelist::data = [ ];
END_OF_03_MODLIST_DATA
      'modlist',    # configuration key to look output file
      $basedir->file(qw< modules 03modlist.data.gz >)    # default
   );
} ## end sub _do_index

sub _save2 {
   my ($self, $path, $contents) = @_;
   my ($fh, $is_gz);
   if (ref($path) eq 'GLOB') {
      $fh    = $path;
      $is_gz = 0;
   }
   else {
      $path->dir()->mkpath() unless -d $path->dir()->stringify();
      $fh    = $path->open('>');
      $is_gz = $path->stringify() =~ m{\.gz$}mxs;
   }

   if ($is_gz) {
      my $gz = Compress::Zlib::gzopen($fh, 'wb');
      $gz->gzwrite($contents);
      $gz->gzclose();
   }
   else {
      binmode $fh;
      print {$fh} $contents;
   }
   return;
} ## end sub _save2

sub _index_for {
   my ($self, $path) = @_;
   $path //= $self->target_dir;
   my @index = $self->_index_body_for($path);
   our $VERSION ||= 'whateva';
   my $header = <<"END_OF_HEADER";
File:         02packages.details.txt
URL:          http://cpan.perl.org/modules/02packages.details.txt.gz
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   epan $VERSION
Line-Count:   ${ \ scalar @index }
Last-Updated: ${ \ scalar localtime() }
END_OF_HEADER
   return join "\n", $header, @index, '';
} ## end sub _index_for

sub _collect_index_for {
   my ($self, $path) = @_;
   $path //= $self->target_dir;
   $path = dir($path);
   LOGDIE "path '$path' does not exist (wrong -t option?)" unless -d $path;

   my $idpath = $path->subdir(qw< authors id >);
   my %data_for;
   for my $file (File::Find::Rule->extras({follow => 1})->file()
      ->in($idpath->stringify()))
   {
      INFO "indexing $file";
      my $index_path =
        file($file)->relative($idpath)->as_foreign('Unix')->stringify();
      my $dm = Dist::Metadata->new(file => $file);
      my $version_for = $dm->package_versions();

      $data_for{distro}{$index_path} = $version_for;
      (my $bare_index_path = $index_path) =~
        s{^(.)/(\1.)/(\2.*?)/}{$3/}mxs;
      $data_for{bare_distro}{$bare_index_path} = $version_for;

      my %_localdata_for;
      my $score = 0;
      my $previous;
      while (my ($module, $version) = each %$version_for) {
         my $print_version = $version // 'undef';
         DEBUG "data for $module: [$print_version] [$index_path]";
         $_localdata_for{$module} = {
            version => $version,
            distro  => $index_path,
            _file   => $file,
         };
         next if $score != 0;
         next unless exists($data_for{module}{$module});
         $previous = $data_for{module}{$module};
         DEBUG 'some previous version exists';
         if (! defined $version) {
            $score = -1 if defined($previous->{version});
         }
         elsif (defined $previous->{version}) {
            my $tv = version->parse($version);
            my $pv = version->parse($previous->{version});
            $score = $tv <=> $pv;
         }
         DEBUG "score: $score";
      } ## end while (my ($module, $version...))

      DEBUG "FINAL SCORE $score";

      if ($score < 0) { # didn't win against something already in
         DEBUG "marking $file as obsolete";
         $data_for{obsolete}{$file} = 1;
         next;
      }

      DEBUG "getting $file data as winner (for the moment)";
      if ($previous) {
         my $oip = $previous->{distro};
         DEBUG "marking $oip as obsolete";
         $data_for{obsolete}{$previous->{_file}} = 1;
         delete $data_for{module}{$_}
           for keys %{$data_for{distro}{$oip}};
      }
      # copy stuff over to the "official" data for modules
      $data_for{module}{$_} = $_localdata_for{$_} for keys %_localdata_for;
   } ## end for my $file (File::Find::Rule...)
   $self->last_index(\%data_for);
   return %data_for if wantarray();
   return \%data_for;
} ## end sub _collect_index_for

sub _index_body_for {
   my ($self, $path) = @_;
   $path //= $self->target_dir;

   my $data_for        = $self->_collect_index_for($path);
   my $module_data_for = $data_for->{module};
   my @retval;
   for my $module (sort keys %{$module_data_for}) {
      my $md         = $module_data_for->{$module};
      my $version    = $md->{version} || 'undef';
      my $index_path = $md->{distro};
      my $fw         = 38 - length $version;
      $fw = length $module if $fw < length $module;
      push @retval, sprintf "%-${fw}s %s  %s", $module, $version,
        $index_path;
   } ## end for my $module (sort keys...)
   return @retval if wantarray();
   return \@retval;
} ## end sub _index_body_for

sub action_create {
   my ($self) = @_;

   my $target = $self->target_dir;
   LOGDIE "target directory $target exists, use update instead"
     if -d $target;
   $target->mkpath();

   return $self->action_update;
} ## end sub action_create

sub action_update {
   my ($self) = @_;

   my $target = $self->target_dir;
   $target->mkpath() unless -d $target;

   my $dists   = $target->stringify();
   my $local   = $target->subdir('local')->stringify();
   my @command = (
      qw< cpanm --reinstall --quiet --self-contained >,
      ($self->execute_tests ? () : '--notest'),
      '--local-lib-contained' => $local,
      '--save-dists'          => $dists,
      $self->args(),
   );

   my ($out, $err);
   {
      local $SIG{TERM} = sub {
         WARN "cpanm: received TERM signal, ignoring";
      };
      INFO "calling @command";
      IPC::Run::run \@command, \undef, \*STDOUT, \*STDERR
        or LOGDIE "cpanm: $? ($err)";
   }

   INFO 'onboarding completed, indexing...';
   $self->_do_index($target);
   my $data_for = $self->last_index();

   INFO 'saving distlist';
   my @distros = $self->last_distlist();
   $self->_save2($target->file('distlist.txt'), join "\n", @distros, '');

   INFO 'saving modlist';
   my @modules = $self->last_modlist();
   $self->_save2($target->file('modlist.txt'), join "\n", @modules, '');

   my $file = $target->file('install.sh');
   if (!-e $file) {
      $self->_save2($file, <<'END_OF_INSTALL');
#!/bin/bash
ME=$(readlink -f "$0")
MYDIR=$(dirname "$ME")

TARGET="$MYDIR/local"
[ $# -gt 0 ] && TARGET=$1

if [ -n "$TARGET" ]; then
   "$MYDIR/cpanm" --mirror "file://$MYDIR" --mirror-only \
      -L "$TARGET" \
      $(<"$MYDIR/modlist.txt")
else
   "$MYDIR/cpanm" --mirror "file://$MYDIR" --mirror-only \
      $(<"$MYDIR/modlist.txt")
fi
END_OF_INSTALL
      chmod 0777 & ~umask(), $file->stringify();
   } ## end if (!-e $file)

   $file = $target->file('cpanm');
   if (!-e $file) {
      my $cpanm = which('cpanm');
      File::Copy::copy($cpanm, $file->stringify());
      chmod 0777 & ~umask(), $file->stringify();
   }
} ## end sub action_update

{
   no strict 'subs';
   *action_install = \&action_update;
   *action_add     = \&action_update;
}

sub action_inject {
   my ($self) = @_;

   my $target = $self->target_dir;
   $target->mkpath() unless -d $target;

   my $author = $self->config('author') // $ENV{EPAN_AUTHOR} // 'LOCAL';
   my $first = substr $author, 0, 1;
   my $first_two = substr $author, 0, 2;
   my $repo = $target->subdir(qw< authors id >, $first, $first_two, $author);
   $repo->mkpath;
   $repo = $repo->stringify;

   File::Copy::copy($_, $repo) for $self->args;

   INFO 'onboarding completed, indexing...';
   $self->_do_index($target);

   return;
}

sub _list_obsoletes {
   my ($self) = @_;
   my $basedir = $self->target_dir;
   my $data_for = $self->_collect_index_for($basedir);
   return sort {$a cmp $b} keys %{$data_for->{obsolete}};
}

sub action_list_obsoletes {
   my ($self) = @_;
   say for $self->_list_obsoletes;
   return;
}

sub action_purge_obsoletes {
   my ($self) = @_;
   for my $file ($self->_list_obsoletes) {
      INFO "removing $file";
      unlink $file;
   }
   return;
}

sub action_list_actions {
   my $self = shift;
   no strict 'refs';
   say 'Available actions:';
   say for
     sort {$a cmp $b}
     map {s/^action_/- /; s/_/-/g; $_ }
     grep {/^action_/ && $self->can($_)}
     keys %{ref($self)."::"};
   return;
}

sub last_distlist {
   my ($self) = @_;
   return keys %{$self->last_index()->{bare_distro}};
}

sub last_modlist {
   my ($self) = @_;
   my @retval =
     map { (sort keys %$_)[0] }
     values %{$self->last_index()->{bare_distro}};
} ## end sub last_modlist

1;
__END__
