package App::perlminlint; sub MY () {__PACKAGE__}
# -*- coding: utf-8 -*-
use 5.009;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.23';

use Carp;
use autodie;

sub CFGFILE () {'.perlminlint.yml'}

use App::perlminlint::Object -as_base,
  [fields => qw/no_stderr
		help
		verbose
		dryrun

		no_auto_libdir

		_plugins
		_lib_list _lib_dict
		_perl_opts
	       /];

require lib;
require File::Basename;

use Module::Pluggable require => 1, sub_name => '_plugins';


sub usage {
  (my MY $app) = @_;
  die <<END;
Usage: @{[$app->basename($0)]} [opts..] YOUR_SCRIPT

Options:
-v --verbose
-n --dryrun
-w -c -wc    (just ignored)

Pass-through Options:
-IDIR
-Mmodule
-mmodule
-dDEBUG
END
}

sub run {
  my ($pack, $argv) = @_;

  my MY $app = $pack->new($pack->parse_argv
			  ($argv, {h => 'help'
				   # Just to ignore -w -c -wc
				   , w => '', c => '', wc => ''
				   , v => 'verbose'
				   , n => 'dryrun'
				 }
			   , qr{^-[ImMd]}, my $perl_opts = []
			 ));

  # -IDIR, -mmod, -MMod
  push @{$app->{_perl_opts}}, @$perl_opts;

  if ($app->{help} or not @$argv) {
    $app->usage;
  }

  $app->find_and_load_config_from(@$argv);

  if ($app->{no_stderr}) {
    close STDERR;
    open STDERR, '>&STDOUT';
  }

  $app->add_lib_to_inc_for(@$argv) if not $app->{no_auto_libdir};

  my @res = $app->lint(@$argv);
  if (@res) {
    print join("\n", @res), "\n" unless @res == 1 and ($res[0] // '') eq '';
  } else {
    print "OK\n";
  }
}

sub after_new {
  (my MY $self) = @_;
  foreach my $lib (@INC) {
    $self->{_lib_dict}{$lib}++;
  }
}

sub upward_first_file_from (&@) {
  my ($code, $lookfor, $startFn) = @_;
  my @dirs = MY->splitdir(MY->rel2abs($startFn));
  pop @dirs;
  local $_;
  while (@dirs) {
    -e (my $fn = MY->catdir(@dirs, $lookfor))
      or next;
    $code->($_ = $fn)
      and last;
  } continue {
    pop @dirs;
  }
}

sub add_lib_to_inc_for {
  (my MY $self, my $fn) = @_;

  upward_first_file_from {
    my ($libdir) = @_;
    if (-d $libdir) {
      if (not $self->{_lib_dict}{$libdir}) {
	import lib $libdir;
	push @{$self->{_lib_list}}, $libdir;
      }
      1;
    }
  } lib => $fn;
}

sub find_and_load_config_from {
  (my MY $self, my $fn) = @_;
  upward_first_file_from {
    $self->load_config($_);
  } CFGFILE, $fn;
}

sub load_config {
  (my MY $self, my $fn) = @_;
  if ($self->{verbose}) {
    print STDERR "# loading config: $fn\n";
  }

  eval {require YAML::Tiny};
  if ($@) {
    die "Can't load '$fn'. Please install YAML::Tiny\n";
  }

  my $yaml = YAML::Tiny->read($fn);
  if (not $yaml->[0] and ref $yaml->[0] eq 'HASH') {
    die "Invalid data in $fn. Only HASH is allowed\n";
  }

  $self->configure($yaml->[0]);
}

sub lint {
  (my MY $self, my $fn) = @_;

  my @fallback;
  foreach my $plugin ($self->plugins) {

    if (my $obj = $self->apply_to($plugin, handle_match => $fn)) {
      #
      my @res = $obj->handle_test($fn)
	or next;

      return @res;

    } elsif ($plugin->is_generic) {

      push @fallback, $plugin;
    }
  }

  unless (@fallback) {
    die "Don't know how to lint $fn\n";
  }

  foreach my $plugin (@fallback) {

    my @res = $self->apply_to($plugin, handle_test => $fn)
	or next;

    return @res;
  }

  return "";
}

sub apply_to {
  (my MY $self, my ($plugin, $method, @args)) = @_;

  $plugin->new(app => $self)->$method(@args);
}

sub plugins {
  (my MY $self) = @_;
  my $plugins = $self->{_plugins}
    //= [sort {$b->priority <=> $a->priority} $self->_plugins];
  wantarray ? @$plugins : $plugins;
}

sub run_perl {
  my MY $self = shift;
  my @opts;
  push @opts, lexpand($self->{_perl_opts});
  push @opts, map {"-I$_"} lexpand($self->{_lib_list});
  if ($self->{verbose} || $self->{dryrun}) {
    print STDERR join(" ", "#", $^X, @opts, @_), "\n";
  }
  if ($self->{dryrun}) {
    return;
  }
  system($^X, @opts, @_) == 0
    or exit $? >> 8;
}

sub read_file {
  (my MY $self, my $fn) = @_;
  open my $fh, '<', $fn;
  local $/;
  scalar <$fh>;
}

sub basename {
  shift; File::Basename::basename(@_);
}

sub dirname {
  shift; File::Basename::dirname(@_);
}

sub rootname {
  shift;
  my $fn = shift;
  $fn =~ s/\.\w+$//;
  join "", $fn, @_;
}

sub lexpand {
  if (not defined $_[0]) {
    wantarray ? () : 0;
  } elsif (not ref $_[0]) {
    $_[0]
  } else {
    @{$_[0]};
  }
}

sub inc_opt {
  my ($app, $file, $modname) = @_;
  (my $no_pm = $file) =~ s/\.\w+$//;
  my @filepath = $app->splitdir($app->rel2abs($no_pm));
  my @modpath = grep {$_ ne ''} split "::", $modname;
  my @popped;
  while (@modpath and @filepath and $modpath[-1] eq $filepath[-1]) {
    unshift @popped, pop @modpath;
    pop @filepath;
  }
  if (@modpath) {
    die "Can't find library root directory of $modname in file $file\n@modpath\n";
  }
  '-I' . $app->catdir(@filepath);
}

sub read_shbang_opts {
  (my MY $app, my $fn) = @_;

  my @opts;

  my $body = $app->read_file($fn);

  my (@shbang) = $app->parse_shbang($body);

  if (grep {$_ eq "-T"} @shbang) {
    push @opts, "-T";
  }

  @opts;
}

sub parse_shbang {
  my MY $app = shift;
  my ($shbang) = $_[0] =~ m{^(\#![^\n]+)}
    or return;
  split " ", $shbang;
}

# XXX: Real new and options...

sub parse_argv {
  my ($pack, $list, $alias, $special_re, $special_list) = @_;
  my @opts;
  while (@$list) {
    if ($special_re and $list->[0] =~ $special_re) {
      push @$special_list, $list->[0]
    } elsif (my ($k, $v) = $list->[0] =~ /^--?(\w[-\w]*)(?:=(.*))?/) {
      $k =~ s/-/_/g;
      my $opt = $alias->{$k} // $k;
      next if $opt eq ''; # To drop compat-only option.
      push @opts, $opt => ($v // 1);
    } else {
      last;
    }
  } continue {
    shift @$list;
  }
  @opts;
}

sub parse_perl_opts {
  (my MY $self, my $list) = @_;

  my @opts;
  while (@$list and defined $list->[0]
	 and $list->[0] =~ m{^-[ImMd]}) {
    push @opts, shift @$list;
  }

  @opts;
}

1; # End of App::perlminlint

__END__

=head1 NAME

App::perlminlint - minimalistic lint for perl

=head1 SYNOPSIS

    % perlminlint  myscript.pl
    #  => This tests "perl -wc myscript.pl"

    % perlminlint  MyModule.pm
    #  => This tests "perl -MMyModule -we0"

    % perlminlint  MyInnerModule.pm
    #  => This tests "perl -I.. -MMyApp::MyInnerModule -we0"

    % perlminlint  cpanfile
    #  => This tests Module::CPANfile->load

=head1 DESCRIPTION

Perl has had long support for L<compile only mode|perlrun/-c>,
but it is not so trivial to use this mode to check scripts
so that to integrate automatic check into editors like Emacs and Vim.
Because most real-world perl scripts consist of many other modules,
and to load them correctly, you must give correct search path for perl
as L<-I$DIR|perlrun/-I> and/or L<-Mlib=$DIR|lib>.
Also, to test modules, "perl -M$MOD -e0" is better than "perl -wc".

C<perlminlint> wraps all such details so that you can just run C<perlminlint $yourfile> to test your script.


=head1 SEE ALSO

L<Module::Pluggable>

=head1 COPYRIGHT

Copyright 2014- KOBAYASHI, Hiroaki
