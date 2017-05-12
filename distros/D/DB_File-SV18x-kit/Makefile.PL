#!/usr/bin/perl -w

=comment sketch

"Where is your db 1.85 library that we should link to? (Please specify
the correct directory below PORT/)"

Where is your DB_File distribution (specify either a directory or the
DB_File-x.xx.tar.gz file)

build_alternative_db185();

build_alternative_DB_File();

=comment build_alternative_db185

Patch Makefile, patch db.h, add db-survive, compile

=comment build_alternative_DB_File

DB_File.pm->SV185.pm, DB_File.xs->SV185.xs, typemap, testscripts.

=cut

use ExtUtils::MakeMaker;
use Config;
use DirHandle ();
use FileHandle ();
use File::Basename qw(dirname);
use File::Path qw(mkpath rmtree);
use Cwd;
use File::Copy qw(cp);
use strict;
use vars qw(%THIS $TERM);

eval 'use Term::ReadLine' ;
$THIS{HAS_TRL} = ! $@;
print "ReadLine support ", $THIS{HAS_TRL} ? "" : "not ", "enabled\n" ;

my $have_config;
for my $d (qw( . .. )) {
  for my $v (qw(1.85 1.86)) {
    my $f = "$d/config.db_file_$v";
    next unless -f $f;
    $have_config++;
    print "Reading config file $f\n";
    my $fh = FileHandle->new($f) or die "Couldn't open $f: $!";
    local($/) = "\n";
    while (<$fh>) {
      next if / ^ \s* ( \# | $ ) /x;
      my($k,$v) = /(\S+?)\s*=\s*(\S+)/;
      $THIS{$k} = $v;
    }
    last;
  }
}
unless ($have_config) {
  print qq{No config file (e.g. config.db_file_1.85) found,
trying to guess defaults
};
}

$TERM = Term::ReadLine->new('DB_File::SV18x install') if $THIS{HAS_TRL};
{
  local *F;
  open F, "SV18x.pm" or die "Couldn't find SV18x.pm: $!";
  local $/;
  my($version) = <F> =~ /VERSION=\"(\d+\.\d+)\"/;
  close F;
  $THIS{VERSION} = $version; # will be appended to Paul's without the dot
}

if ($THIS{DB_SRC} && -d $THIS{DB_SRC}) {
  if ($THIS{DB_SRC} =~ m|/db\.(\d\.\d+)/|) {
    $THIS{DB_VERSION} = $1;
  }
} else {
  my @v = $THIS{DB_VERSION} if exists $THIS{DB_VERSION};
  @v = qw(1.85 1.86) unless @v;
  for my $v (@v) {
    if ( -d "../db.$v") {
      my $dh;
      if ($dh = DirHandle->new("../db.$v/PORT")) {
	my @ports = grep /^\w/, $dh->read;
	my $default = bestmatch("$Config{osname}.$Config{osvers}", @ports);
	$THIS{DB_SRC} = "../db.$v/PORT/$default";
	$THIS{DB_VERSION} = $v;
	last;
      }
    }
  }
}

print qq{

Which historic berkeley db version do you want to build? Note that
currently only 1.85 and 1.86 are supported!
};
$THIS{DB_VERSION} = _prompt("DB_VERSION?", $THIS{DB_VERSION});

print qq{

Where is your db $THIS{DB_VERSION} library that we should link to? (Please specify
the correct directory below PORT/)
};
$THIS{DB_SRC} = _prompt("DB_SRC?", $THIS{DB_SRC});
unless ($THIS{DB_SRC} && -d $THIS{DB_SRC}) {
  die "Couldn't find directory $THIS{DB_SRC}";
}
{
  my $v = $THIS{DB_VERSION};
  $v =~ s/\W//g;
  $THIS{DB_VERSION_SYM} = $v;
}
print qq{
Shall I build a new libdb_sv$THIS{DB_VERSION_SYM} for you?
};

$THIS{MAKE_DB_LIB} = _prompt("MAKE_DB_LIB?",$THIS{MAKE_DB_LIB}||"yes");
$THIS{DB_LIB} = "$THIS{DB_SRC}/libdb_sv$THIS{DB_VERSION_SYM}$Config{lib_ext}";
unless ($THIS{MAKE_DB_LIB} =~ /^y/i || -f $THIS{DB_LIB}) {
  die "Can't proceed without a valid $THIS{DB_LIB}";
}

unless (exists $THIS{DB_FILE_PMQS} && -d $THIS{DB_FILE_PMQS}) {
  my $dh;
  if ($dh = DirHandle->new("..")) {
    my @dotdot = sort grep { -d "../$_" } grep /^DB_File-\d/, $dh->read;
    $THIS{DB_FILE_PMQS} = "../$dotdot[-1]" || "";
  }
}
print qq{

The DB_File::SV18x extension builds its source code by extracting the
code from the DB_File distribution. It needs DB_File.pm, DB_File.xs,
typemap, and the testfiles.

Where is the (hopefully fairly recent) DB_File extension
by Paul Marquess? Note, that the extension should already
be un-tarred.
};
$THIS{DB_FILE_PMQS} = _prompt("DB_FILE_PMQS?", $THIS{DB_FILE_PMQS});

write_config(\%THIS) unless $have_config;

get_pmqs(\%THIS);

build_alternative_db(\%THIS);

WriteMakefile(
	      NAME     => "DB_File::SV$THIS{DB_VERSION_SYM}",
	      DISTNAME => "DB_File-SV18x-kit",
	      LIBS     => ["-L$THIS{DB_SRC} -ldb_sv$THIS{DB_VERSION_SYM}"],
	      INC      => "-I$THIS{DB_SRC} -I$THIS{DB_SRC}/include",
	      VERSION  => "$THIS{MANGLED_VERSION}",
	      DEFINE   => "-DDB_SURVIVAL_KIT",
	      XSPROTOARG => '-noprototypes',
	      'dist'   => {
			   COMPRESS => 'gzip --best',
			   SUFFIX   => 'gz',
			   VERSION  => "$THIS{VERSION}",
			  },    
	      'clean'  => {FILES => 'SV18[56].?? typemap t/db-*.t'},
	     );

sub get_pmqs {
  my($this) = @_;
  for my $file (qw(DB_File.pm DB_File.xs typemap t/db-btree.t
		   t/db-hash.t t/db-recno.t)) {
    my $abs = MM->catfile($this->{DB_FILE_PMQS},$file);
    unless (-f $abs){
      warn "Couldn't find $abs. Continuing is DANGEROUS";
      return;
    }
  }
  grok_db_file_pm($this);
  grok_db_file_xs($this);
  grok_typemap($this);
  for my $file (qw(t/db-btree.t t/db-hash.t t/db-recno.t)) {
    grok_test($file,$this);
  }
}

sub grok_db_file_xs {
  my($this) = @_;
  my($in) = MM->catfile($this->{DB_FILE_PMQS},"DB_File.xs");
  my($vsym) = $this->{DB_VERSION_SYM};
  my($out) = "SV$vsym.xs";
  open IN, $in or die "Couldn't open $in: $!";
  unlink "$out.bak";
  rename $out, "$out.bak";
  open SV, ">$out" or die "Couldn't open >$out\: $!";
  my $in_comment = 1;
  my $in_XS = 0;
  while (<IN>) {
    s/DB_File_type/DB_File__SV$vsym\_type/;
    if ($in_comment) {
      $in_comment = 0 if m|\*/|;
    } elsif (/DB_File\s+db/ && ! $in_XS) {
      s/DB_File\b/DB_File__SV$vsym/g;
    } elsif (/typedef|static|RETVAL| db /) {
      s/DB_File\b/DB_File__SV$vsym/g;
    } elsif (s/__getBerkeleyDBInfo.*//) {
    } else {
      if (/^MODULE/) {
	$in_XS = 1;
      }
      s/DB_File\b/DB_File::SV$vsym/g;
    }
    print SV $_;
  }
  close IN;
  close SV;
}

sub grok_test {
  my($file,$this) = @_;
  my($in) = MM->catfile($this->{DB_FILE_PMQS},$file);
  my($vsym) = $this->{DB_VERSION_SYM};
  my($out) = $file;
  open IN, $in or die "Couldn't open $in: $!";
  unlink "$out.bak";
  rename $out, "$out.bak";
  open SV, ">$out" or die "Couldn't open >$out\: $!";
  my $re = q{((?:package|use|new|tie|croak|qw|\@)
	      [\s\"\(^/~=\',x%hgk]*DB_File)(\b[^:]|::[A-RT-Z]\w+)};
  while (<IN>) {
    my $shadow = $_;
    $shadow =~ s/\#.*//;
    ### s/^BEGIN/sub not_needed_BEGIN$./; # Originally I thought:
    ### relevant only for perl's own tests; this seems not so
    1 while s{ $re
	     }{$1::SV$vsym$2}xo;
    s/::/::SV$vsym\::/ if /\$db185mode\s+=/; # test in db-btree.t
    print SV $_;
    if ($shadow =~ /\b__END__\b/) {
      last;
    }
  }
  close IN;
  close SV;
}

sub grok_db_file_pm {
  my($this) = @_;
  my($in) = MM->catfile($this->{DB_FILE_PMQS},"DB_File.pm");
  my($vsym) = $this->{DB_VERSION_SYM};
  my($out) = "SV$vsym.pm";
  open IN, $in or die "Couldn't open $in: $!";
  unlink "$out.bak";
  rename $out, "$out.bak";
  open SV, ">$out" or die "Couldn't open >$out\: $!";
  my $re = q{((?:package|bootstrap|new|croak|load|qw|\@)
	      [\s\"\(]*DB_File)(\b[^:]|::[A-RT-Z]\w+)};
  while (<IN>) {
    my $shadow = $_;
    $shadow =~ s/\#.*//;
    1 while s{ $re
	     }{$1::SV$vsym$2}xo;
    if (/\$VERSION\s*=\s*[\"\']*(\d+\.\d+)/) {
      my $pauls = $1;
      my $mine = $this->{VERSION};
      $mine =~ s/\D//g;
      $THIS{MANGLED_VERSION} = "$pauls$mine";
      $_ = qq{\$VERSION = "$THIS{MANGLED_VERSION}"; \$db_version = "1";\n};
    }
    print SV $_;
    if ($shadow =~ /\b__END__\b/) {
      last;
    }
  }
  close IN;
  close SV;
}

sub grok_typemap {
  my($this) = @_;
  my($in) = MM->catfile($this->{DB_FILE_PMQS},"typemap");
  my($vsym) = $this->{DB_VERSION_SYM};
  my($out) = "typemap";
  open IN, $in or die "Couldn't open $in: $!";
  unlink "$out.bak";
  rename $out, "$out.bak";
  open SV, ">$out" or die "Couldn't open >$out\: $!";
  while (<IN>) {
    s{^DB_File}{DB_File::SV$vsym};
    print SV $_;
  }
  close IN;
  close SV;
}

sub build_alternative_db {
  my($this) = @_;
  my $dep = "";
  my $all = "";
  if ($this->{MAKE_DB_LIB} =~ /^\s*y/i){
    $dep = " Makefile".
	" $this->{DB_SRC}/include/db-survive-$this->{DB_VERSION_SYM}.h".
	    " $this->{DB_SRC}/Makefile.$this->{DB_VERSION_SYM}".
		" $this->{DB_SRC}/include/db.h";
    $all = "all :: $this->{DB_LIB}\n\n";
  }
  my($args) = join " ", %$this;
  my $postamble = qq{
    package MY;
    sub top_targets {
      my \$self = shift;
      my \$string = \$self->MM::top_targets;
      return "$all\$string";
    }
    sub postamble {
      "
\#all
$all

\#libdb
$this->{DB_LIB}:$dep
	(cd $this->{DB_SRC} && \\\$(MAKE) clean && \\\\
		\\\$(MAKE) -f Makefile.$this->{DB_VERSION_SYM})

\#db-survive-xxx.h
db-survive-$this->{DB_VERSION_SYM}.h: db-survive.perl
	\\\$(PERL) db-survive.perl $this->{DB_VERSION_SYM}

$this->{DB_SRC}/include/db-survive-$this->{DB_VERSION_SYM}.h: db-survive-$this->{DB_VERSION_SYM}.h
	\\\$(MKPATH) $this->{DB_SRC}/include
	\\\$(CP) db-survive-$this->{DB_VERSION_SYM}.h \\\$@

$this->{DB_SRC}/include/db.h: grok.dbh.perl Makefile
	\\\$(MKPATH) $this->{DB_SRC}/include
	\\\$(PERL) grok.dbh.perl DB_H \\\$@ $args

$this->{DB_SRC}/Makefile.$this->{DB_VERSION_SYM}: grok.dbmakefile.perl Makefile
	\\\$(PERL) grok.dbmakefile.perl MAKEFILE_DB \\\$@ $args
";
    }
  };
  eval $postamble;
}

sub _prompt {
  my ($prompt, $default) = @_ ;

  if ($THIS{HAS_TRL}) {
    my($ret) = split " ", $TERM->readline($prompt." ", $default) ;
    $ret = $default if $ret eq "";
    $ret;
  } else { 
    prompt(@_);
  }
}

sub bestmatch {
  my($this,@choice) = @_;
  my($L,$C);
  $L = 0; $C = "";
  for my $choice (@choice) {
    for (my $l=1; $l<length($this); $l++) {
      if (
	  $l > $L &&
	  substr(lc $this,0,$l) eq substr(lc $choice,0,$l)
	 ) {
	$L = $l;
	$C = $choice;
      }
    }
  }
  $C;
}

sub write_config {
  my $h = shift;
  my $file = "config.db_file_" . $h->{DB_VERSION};
  if (-f $file) {
    warn "Config file $file exists, won't overwrite\n";
    return;
  }
  open F, ">$file" or die "Couldn't write $file: $!";
  while (my($k,$v) = each %$h) {
    print F "$k = $v\n";
  }
  close F;
}
