package App::MechaCPAN::Install;

use v5.14;

use Carp;
use Config;
use Cwd qw/cwd/;
use JSON::PP qw//;
use File::Spec qw//;
use File::Path qw//;
use CPAN::Meta qw//;
use CPAN::Meta::Prereqs qw//;
use Module::CoreList;
use ExtUtils::MakeMaker qw//;
use App::MechaCPAN qw/:go/;

our @args = (
  'skip-tests!',
  'skip-tests-for:s@',
  'smart-tests!',
  'install-man!',
  'source=s%',
  'only-sources!',
  'update!',
  'stop-on-error!',
);

our $dest_lib;

# Constants
my $COMPLETE = 'COMPLETE';
my $FAILED   = 'FAILED';

sub go
{
  my $class = shift;
  my $opts  = shift;
  my $src   = shift // '.';
  my @srcs  = @_;

  my $orig_dir = cwd;
  my $dest_dir = &dest_dir;

  local $dest_lib = "$dest_dir/lib/perl5";

  my @targets = ( $src, @srcs );
  my %src_names;
  my @deps;

  if ( ref $opts->{source} ne 'HASH' && ref $opts->{source} ne 'CODE' )
  {
    $opts->{source} = {};
  }

  if ( ref $opts->{'skip-tests-for'} ne 'ARRAY' )
  {
    $opts->{'skip-tests-for'} = [];
  }
  $opts->{'skip-tests-for'}
    = { map { $_ => 1 } @{ $opts->{'skip-tests-for'} } };

  my $unsafe_inc
    = exists $ENV{PERL_USE_UNSAFE_INC} ? $ENV{PERL_USE_UNSAFE_INC} : 1;

  # trick AutoInstall
  local $ENV{PERL5_CPAN_IS_RUNNING}     = $$;
  local $ENV{PERL5_CPANPLUS_IS_RUNNING} = $$;

  local $ENV{PERL_MM_USE_DEFAULT} = 1;
  local $ENV{PERL_USE_UNSAFE_INC} = $unsafe_inc;

  local $ENV{PERL_MM_OPT} = "INSTALL_BASE=$dest_dir";
  local $ENV{PERL_MB_OPT} = "--install_base $dest_dir";

  local $ENV{PERL5LIB} = "$dest_lib";

  # skip man page generation
  if ( !$opts->{'install-man'} )
  {
    $ENV{PERL_MM_OPT}
      .= " " . join( " ", "INSTALLMAN1DIR=none", "INSTALLMAN3DIR=none" );
    $ENV{PERL_MB_OPT} .= " " . join(
      " ",                            "--config installman1dir=",
      "--config installsiteman1dir=", "--config installman3dir=",
      "--config installsiteman3dir="
    );
  }

  #if ( $self->{pure_perl} )
  #{
  #  $ENV{PERL_MM_OPT} .= " PUREPERL_ONLY=1";
  #  $ENV{PERL_MB_OPT} .= " --pureperl-only";
  #}

  my $cache = { opts => $opts };

  # Prepopulate all of the sources as targets
  foreach my $source_key ( keys %{ $opts->{source} } )
  {
    my $source = $opts->{source}->{$source_key};

    # If there is no source to translate to, continue
    if ( !defined $source )
    {
      _create_target( $source_key, $cache );
      next;
    }

    # If we can find a target, reuse it, otherwise create a new one
    my $target = _find_target( $source, $cache );
    if ( defined $target )
    {
      _alias_target( $target, $source_key, $cache );
    }
    else
    {
      $target = _create_target( $source_key, $cache );
      _alias_target( $target, $source, $cache );
    }
  }

  my @full_states = (
    'Resolving'     => \&_resolve,
    'Configuring'   => \&_meta,
    'Configuring'   => \&_config_prereq,
    'Configuring'   => \&_configure,
    'Configuring'   => \&_mymeta,
    'Prerequisites' => \&_prereq,
    'Prerequisites' => \&_test_prereq,
    'Prerequisites' => \&_prereq_verify,
    'Building'      => \&_build,
    'Testing'       => \&_test,
    'Installing'    => \&_install,
    'Installed'     => \&_write_meta,
  );

  my @states     = grep { ref $_ eq 'CODE' } @full_states;
  my @state_desc = grep { ref $_ ne 'CODE' } @full_states;

  foreach my $target (@targets)
  {
    $target = _create_target( $target, $cache );
    $target->{update} = $opts->{update} // 1;
  }

TARGET:
  while ( my $target = shift @targets )
  {
    $target = _create_target( $target, $cache );

    if ( $target->{state} eq $COMPLETE || $target->{state} eq $FAILED )
    {
      next;
    }

    chdir $orig_dir;
    chdir $target->{dir}
      if exists $target->{dir};

    my $line = _target_line( $target, $state_desc[ $target->{state} ] );
    info( $target->{key}, $line );
    my $method = $states[ $target->{state} ];

    {
      local $@;
      my $succ = eval { unshift @targets, $method->( $target, $cache ); 1; };
      my $err = $@;

      if ( !$succ )
      {
        my $line = sprintf(
          '%-13s %s', 'Error',
          "Could not install " . _name_target($target)
        );

        error( $target->{key}, $line );

        _failed($target);

        if ( $opts->{'stop-on-error'} )
        {
          croak $err;
        }

        next TARGET;
      }
    }

    $target->{state}++
      if $target->{state} ne $COMPLETE;

    if ( $target->{state} eq scalar @states )
    {
      _complete($target);
      $target->{was_installed} = 1;
      success( $target->{key}, $line );
    }
  }

  chdir $orig_dir;

  my %attempted = map  { $_->{name} => $_ } values %{ $cache->{targets} };
  my @failed    = grep { $_->{state} eq $FAILED } values %attempted;
  my @installed = grep { $_->{was_installed} } values %attempted;

  success "\tsuccess", "Installed " . scalar @installed . " modules";

  if ( @failed > 0 )
  {
    logmsg "Failed modules: " . join( ", ", @failed );
    die "Failed to install " . scalar @failed . " modules\n";
  }

  return 0;
}

sub _resolve
{
  my $target = shift;
  my $cache  = shift;

  # Verify we need to install it
  return
    if !_should_install($target);

  my $src_name = $target->{src_name};

  $target->{src_name} = _source_translate( $src_name, $cache->{opts} );

  # fetch
  my $src_tgz = _get_targz($target);

  return
    if !_should_install($target);

  my $src_dir = inflate_archive($src_tgz);

  my @files = glob( $src_dir . '/*' );
  if ( @files == 1 )
  {
    $src_dir = $files[0];
  }

  @{$target}{qw/src_tgz dir was_installed/} = ( $src_tgz, $src_dir, 0 );
  return $target;
}

sub _meta
{
  my $target = shift;
  my $cache  = shift;

  $target->{meta} = _load_meta( $target, $cache, 0 );
  return $target;
}

sub _config_prereq
{
  my $target = shift;
  my $cache  = shift;

  my $meta = $target->{meta};

  return $target
    if !defined $meta;

  my @config_deps = _phase_prereq( $target, $cache, 'configure' );

  $target->{configure_prereq} = [@config_deps];

  return @config_deps, $target;
}

sub _configure
{
  my $target = shift;
  my $cache  = shift;
  my $meta   = $target->{meta};

  state $mb_deps = { map { $_ => 1 }
      qw/version ExtUtils-ParseXS ExtUtils-Install ExtUtilsManifest/ };

  # meta may not be defined, so wrap it in an eval
  my $is_mb_dep = eval { exists $mb_deps->{ $meta->name } };
  my $maker;

  if ( -e 'Build.PL' && !$is_mb_dep )
  {
    run( $^X, 'Build.PL' );
    my $configured = -e -f 'Build';
    croak 'Unable to configure Buid.PL for ' . $target->{src_name}
      unless $configured;
    $maker = 'mb';
  }

  if ( !defined $maker && -e 'Makefile.PL' )
  {
    run( $^X, 'Makefile.PL' );
    my $configured = -e 'Makefile';
    croak 'Unable to configure Makefile.PL for ' . $target->{src_name}
      unless $configured;
    $maker = 'mm';
  }

  croak 'Unable to configure ' . $target->{src_name}
    if !defined $maker;

  $target->{maker} = $maker;
  return $target;
}

sub _mymeta
{
  my $target = shift;
  my $cache  = shift;

  my $new_meta = _load_meta( $target, $cache, 1 );
  $target->{meta} = $new_meta
    if defined $new_meta;

  $target->{name} = $target->{meta}->name;
  $target->{name} =~ s[-][::]xmsg;

  return $target;
}

sub _prereq
{
  my $target = shift;
  my $cache  = shift;

  my $meta = $target->{meta};

  my @deps = map { _phase_prereq( $target, $cache, $_ ) } qw/runtime build/;

  $target->{prereq} = [@deps];

  return @deps, $target;
}

sub _test_prereq
{
  my $target = shift;
  my $cache  = shift;

  my $meta = $target->{meta};
  my $opts = $cache->{opts};

  my $skip_tests = $opts->{'skip-tests'};
  if ( !$skip_tests )
  {
    my $skips = $opts->{'skip-tests-for'};
    $skip_tests = exists $skips->{ $target->{src_name} };

    if ( !$skip_tests && defined $target->{modules} )
    {
      foreach my $module ( %{ $target->{modules} } )
      {
        if ( $skips->{$module} )
        {
          $skip_tests = 1;
          last;
        }
      }
    }

    if ( !$skip_tests && $opts->{'smart-tests'} )
    {
      $skip_tests = _target_prereqs_were_installed( $target, $cache );
    }
  }

  $target->{skip_tests} = $skip_tests;

  my @deps;

  if ( !$skip_tests )
  {
    @deps = map { _phase_prereq( $target, $cache, $_ ) } qw/test/;
    push @{ $target->{prereq} }, @deps;
  }

  return @deps, $target;
}

sub _prereq_verify
{
  my $target = shift;
  my $cache  = shift;

  my @deps = _target_prereqs( $target, $cache );
  my @incomplete_deps = grep { $_->{state} ne $COMPLETE } @deps;

  if ( @incomplete_deps > 0 )
  {
    my $line = 'Unmet dependencies for: ' . $target->{src_name};
    error $target->{key}, $line;
    logmsg "Missing requirements: "
      . join( ", ", map { $_->{src_name} } @incomplete_deps );
    croak 'Error with prerequisites';
  }

  return $target;
}

sub _build
{
  my $target = shift;
  my $cache  = shift;

  local $ENV{PERL_MM_USE_DEFAULT}    = 0;
  local $ENV{NONINTERACTIVE_TESTING} = 0;
  state $make = $Config{make};

  my $opts = $cache->{opts};

  if ( $target->{maker} eq 'mb' )
  {
    run( $^X, './Build' );
    return $target;
  }

  if ( $target->{maker} eq 'mm' )
  {
    run($make);
    return $target;
  }

  croak 'Unable to determine how to install ' . $target->{meta}->name;
}

sub _test
{
  my $target = shift;
  my $cache  = shift;

  local $ENV{PERL_MM_USE_DEFAULT}    = 0;
  local $ENV{NONINTERACTIVE_TESTING} = 0;
  state $make = $Config{make};

  my $opts = $cache->{opts};

  if ( $target->{skip_tests} )
  {
    return $target;
  }

  if ( $target->{maker} eq 'mb' )
  {
    run( $^X, './Build', 'test' );
    return $target;
  }

  if ( $target->{maker} eq 'mm' )
  {
    run( $make, 'test' );
    return $target;
  }

  croak 'Unable to determine how to install ' . $target->{meta}->name;
}

sub _install
{
  my $target = shift;
  my $cache  = shift;

  local $ENV{PERL_MM_USE_DEFAULT}    = 0;
  local $ENV{NONINTERACTIVE_TESTING} = 0;
  state $make = $Config{make};

  my $opts = $cache->{opts};

  if ( $target->{maker} eq 'mb' )
  {
    run( $^X, './Build', 'install' );
    return $target;
  }

  if ( $target->{maker} eq 'mm' )
  {
    run( $make, 'install' );
    return $target;
  }

  croak 'Unable to determine how to install ' . $target->{meta}->name;
}

sub _write_meta
{
  my $target = shift;
  my $cache  = shift;

  state $arch_dir = "$Config{archname}/.meta/";

  if ( $target->{is_cpan} )
  {
    my $dir = "$dest_lib/$arch_dir/" . $target->{distvname};
    File::Path::mkpath( $dir, 0, 0777 );
    $target->{meta}->save("$dir/MYMETA.json");

    my $install = {
      name     => $target->{name},
      target   => $target->{src_name},
      version  => $target->{meta}->version,
      dist     => $target->{distvname},
      pathname => $target->{pathname},
      provides => $target->{meta}->provides,
    };

    open my $fh, ">", "$dir/install.json";
    print $fh JSON::PP::encode_json($install);
  }
  return;
}

my $full_pause_re = qr[
  (?: authors/id/ )
  (   \w / \w\w )
  /
  ( \w{2,} )
  /
  ( [^/]+ )
]xms;
my $pause_re = qr[
  ^

  (?: authors/id/ )?
  (?: \w / \w\w /)?

  ( \w{2,} )
  /
  ( .+ )

  $
]xms;

sub _escape
{
  my $str = shift;
  $str =~ s/ ([^A-Za-z0-9\-\._~]) / sprintf("%%%02X", ord($1)) /xmsge;
  return $str;
}

my $ident_re = qr/^ \p{ID_Start} (?: :: | \p{ID_Continue} )* $/xms;

sub _src_normalize
{
  my $target = shift;

  if ( ref $target eq '' )
  {
    if ( $target =~ m{^ ([^/]+) @ (.*) $}xms )
    {
      $target = [ $1, "==$2" ];
    }
    else
    {
      $target = [ split /[~]/xms, $target, 2 ];
    }
  }

  if ( ref $target eq 'ARRAY' )
  {
    $target = {
      src_name   => $target->[0],
      constraint => $target->[1],
    };
  }

  return {
    src_name   => $target->{src_name},
    constraint => $target->{constraint},
  };
}

sub _find_target
{
  my $target = shift;
  my $cache  = shift;

  my $src      = _src_normalize($target);
  my $src_name = $src->{src_name};

  return $cache->{targets}->{$src_name};
}

sub _alias_target
{
  my $target = shift;
  my $alias  = shift;
  my $cache  = shift;

  my $target = _find_target( $target, $cache );

  if ( $alias =~ $ident_re )
  {
    $target->{modules}->{$alias} = {
      inital_version => _get_mod_ver($alias),
    };
  }

  $cache->{targets}->{$alias} = $target;
  return;
}

sub _create_target
{
  my $target = shift;
  my $cache  = shift;

  my $src = _src_normalize($target);
  my $cached_target = _find_target( $target, $cache );

  if ( !defined $cached_target )
  {
    my $src_name = $src->{src_name};

    $cached_target = { %$src, state => 0 };
    $cache->{targets}->{$src_name} = $cached_target;
    $cached_target->{key} = $src_name;
  }

  if ( $cached_target->{state} eq $COMPLETE
    && $src->{constraint} ne $cached_target->{constraint} )
  {
    $cached_target->{constraint} = $src->{constraint};
    $cached_target->{state}      = 0;
    delete $cached_target->{version};
  }

  for my $altkey (qw/distvname name module/)
  {
    my $altname = $cached_target->{$altkey};
    if ( defined $altname )
    {
      if ( !exists $cache->{targets}->{$altname} )
      {
        _alias_target( $cached_target, $altname, $cache );
      }
    }
  }

  if ( $src->{src_name} =~ $ident_re )
  {
    $cached_target->{module} = $src->{src_name};
  }

  return $cached_target;
}

sub _target_prereqs
{
  my $target = shift;
  my $cache  = shift;

  return
    map { _find_target $_, $cache }
    ( @{ $target->{prereq} }, @{ $target->{configure_prereq} } );
}

sub _target_prereqs_were_installed
{
  my $target = shift;
  my $cache  = shift;

  foreach my $prereq ( _target_prereqs( $target, $cache ) )
  {
    _target_prereqs_were_installed( $prereq, $cache );

    if ( !$prereq->{prereqs_was_installed} || !$prereq->{was_installed} )
    {
      return $target->{prereqs_was_installed} = 0;
    }
  }

  return $target->{prereqs_was_installed} = 1;
}

sub _search_metacpan
{
  my $src        = shift;
  my $constraint = shift;

  state %seen;

  return $seen{$src}->{$constraint}
    if exists $seen{$src}->{$constraint};

  # TODO mirrors
  my $dnld = 'https://fastapi.metacpan.org/download_url/' . _escape($src);
  if ( defined $constraint )
  {
    $dnld .= '?version=' . _escape($constraint);
  }

  my $json_info = '';
  fetch_file( $dnld => \$json_info );

  my $result = JSON::PP::decode_json($json_info);
  $seen{$src}->{$constraint} = $result;

  return $result;
}

sub _get_targz
{
  my $target = shift;

  my $src = $target->{src_name};

  if ( -e -f $src )
  {
    return $src;
  }

  my $url;

  # git
  if ( $src =~ git_re )
  {
    my $min_git_ver = min_git_ver;
    croak "System has git version < $min_git_ver, cannot retrieve git URL"
      unless has_updated_git;

    croak "System does not have git, cannot retrieve git URL"
      unless has_git;

    my ( $git_url, $commit ) = $src =~ git_extract_re;
    my ($descr) = $git_url =~ m{ ([^/]*) $}xms;

    my $dir  = humane_tmpdir($descr);
    my $fh   = humane_tmpfile($descr);
    my $file = $fh->filename;

    run( 'git', 'clone', '--bare', $git_url, $dir );
    run(
      $fh, 'git', 'archive', '--format=tar.gz', "--remote=$dir",
      $commit || 'master'
    );
    close $fh;
    return $fh;
  }

  # URL
  if ( $src =~ url_re )
  {
    $url = $src;
  }

  # PAUSE
  if ( $src =~ $pause_re )
  {
    my $author  = $1;
    my $package = $2;
    $url = join(
      '/',
      'https://cpan.metacpan.org/authors/id',
      substr( $author, 0, 1 ),
      substr( $author, 0, 2 ),
      $author,
      $package,
    );

    $target->{is_cpan} = 1;
  }

  # Module Name
  if ( !defined $url )
  {
    my $json_data = _search_metacpan( $src, $target->{constraint} );

    $url = $json_data->{download_url};

    $target->{is_cpan} = 1;
    $target->{version} = version->parse( $json_data->{version} );
  }

  if ( defined $url )
  {
    # if it's pause like, parse out the distibution's version name
    if ( $url =~ $full_pause_re )
    {
      my $package = $3;
      $target->{pathname} = "$1/$2/$3";
      $package =~ s/ (.*) [.] ( tar[.](gz|z|bz2) | zip | tgz) $/$1/xmsi;
      $target->{distvname} = $package;
    }

    return fetch_file($url);
  }

  croak "Cannot find $src\n";
}

sub _get_mod_ver
{
  my $module = shift;
  return $]
    if $module eq 'perl';
  local $@;
  my $ver = eval {
    my $file = _installed_file_for_module($module);
    MM->parse_version($file);
  };

  if ( !defined $ver )
  {
    $ver = $Module::CoreList::version{$]}{$module};
  }

  return $ver;
}

sub _load_meta
{
  my $target = shift;
  my $cache  = shift;
  my $my     = shift;

  my $prefix = $my ? 'MYMETA' : 'META';

  my $meta;

  foreach my $file ( "$prefix.json", "$prefix.yml" )
  {
    $meta = eval { CPAN::Meta->load_file($file) };
    last
      if defined $meta;
  }

  return $meta;
}

sub _phase_prereq
{
  my $target = shift;
  my $cache  = shift;
  my $phase  = shift;

  my $prereqs = $target->{meta}->effective_prereqs;
  my @result;

  my $requirements = $prereqs->requirements_for( $phase, "requires" );
  my $reqs = $requirements->as_string_hash;
  for my $module ( sort keys %$reqs )
  {
    my $is_core;

    if ( exists $Module::CoreList::version{$]}{$module} )
    {
      my $version = $Module::CoreList::version{$]}{$module};
      $is_core = $requirements->accepts_module( $module, $version );
    }

    push @result, [ $module, $reqs->{$module} ]
      if $module ne 'perl' && !$is_core;
  }

  return @result;
}

sub _installed_file_for_module
{
  my $prereq = shift;
  my $file   = "$prereq.pm";
  $file =~ s{::}{/}g;

  state $archname = $Config{archname};
  state $perlver  = $Config{version};

  for my $dir (
    "$dest_lib/$archname",
    "$dest_lib",
    )
  {
    my $tmp = File::Spec->catfile( $dir, $file );
    return $tmp
      if -r $tmp;
  }
}

sub _should_install
{
  my $target = shift;

  return 1
    unless defined $target->{module};

  my $module = $target->{module};
  my $ver    = _get_mod_ver($module);

  $target->{installed_version} = $ver;

  return 1
    if !defined $ver;

  my $msg = 'Up to date';

  $msg = 'Installed'
    if $target->{was_installed};

  if ( !$target->{update} )
  {
    my $constraint = $target->{constraint};
    my $prereq     = CPAN::Meta::Prereqs->new(
      { runtime => { requires => { $module => $constraint // 0 } } } );
    my $req = $prereq->requirements_for( 'runtime', 'requires' );

    if ( $req->accepts_module( $module, $ver ) )
    {
      success(
        $target->{key},
        _target_line( $target, $msg )
      );
      _complete($target);
      return;
    }
  }

  if ( defined $target->{version} && $target->{version} eq $ver )
  {
    success(
      $target->{key},
      _target_line( $target, $msg )
    );
    _complete($target);
    return;
  }

  return 1;
}

sub _source_translate
{
  my $src_name = shift;
  my $opts     = shift;
  my $sources  = $opts->{source};

  my $new_src;

  if ( ref $sources eq 'HASH' )
  {
    $new_src = $sources->{$src_name};
  }

  if ( ref $sources eq 'CODE' )
  {
    $new_src = $sources->($src_name);
  }

  if ( $opts->{'only-sources'} && !defined $new_src )
  {
    if ( exists $Module::CoreList::version{$]}{$src_name} )
    {
      return $src_name;
    }

    croak "Unable to locate $src_name from the sources list\n";
  }

  return defined $new_src ? $new_src : $src_name;
}

sub _complete
{
  my $target = shift;
  $target->{state} = $COMPLETE;

  # If we are marking complete because the installed version is the Core
  # version, mark that it "was_installed"
  if ( exists $target->{installed_version} && !$target->{was_installed} )
  {
    my $module = $target->{module};
    my $ver    = $target->{installed_version};

    $target->{was_installed} = 1
      if $ver eq $Module::CoreList::version{$]}{$module};
  }

  if ( exists $target->{inital_version}
    && !defined $target->{inital_version} )
  {
    # If the module was initally not installed but now is, we probbaly
    # installed it by another package name, so mark it as was_installed
    $target->{was_installed} = 1
      if defined _get_mod_ver( $target->{module} );
  }

  return;
}

sub _failed
{
  my $target = shift;
  $target->{state} = $FAILED;
  return;
}

sub _name_target
{
  my $target = shift;
  return $target->{name} || $target->{module} || $target->{src_name};
}

sub _target_line
{
  my $target = shift;
  my $status = shift;

  my $line = sprintf( '%-13s %s', $status, _name_target($target) );

  return $line;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::MechaCPAN::Install - Mechanize the installation of CPAN modules.

=head1 SYNOPSIS

  # Install Catalyst into local/
  user@host:~$ mechacpan install Catalyst

=head1 DESCRIPTION

  user@host:~$ mechacpan install Catalyst

The C<install> command is used for installing specific modules. All modules are installed into the C<local/> directory.
It can accept module names in various formats. This includes:

                                         # Install from:
  foo-bar.tar.gz                         # * an archive
  foo::bar                               # * a CPAN module
  foo::bar@1.0                           # * a specific module version
  foo::bar~<1.0                          # * a module with version < 1.0
  BAZ/foo-bar.tar.gz                     # * a PAUSE URL
  B/BA/BAZ/foo-bar.tar.gz                # * a PAUSE URL
  https://example.com/foo-bar.zip        # * a URL
  https://example.com/foo-bar.git        # * a git repo
  https://example.com/foo-bar.git@master # * a git branch

L<MetaCPAN|https://metacpan.org> is used to search for modules by name.

=head2 Methods

=head3 go( \%opts, @srcs )

There is only a single public function that should be called. This will install the modules listed in C<@srcs> using the options in C<\%opts>. The options available are listed in the L<arguments|/Arguments> section below.

  # Example of calling go
  App::MecahCPAN::Install->go({}, 'Try::Tiny');

=head2 Arguments

=head3 skip-tests

=head3 skip-tests-for

By default the tests of each module will be ran. If you do not want to run tests when installing modules, use this option. Alternatively, you can use C<skip-tests-for> to specify module names that will skip the tests for that module.

  # Examples of --skip-tests
  mechacpan install Try::Tiny --skip-tests
  mechacpan install Catalyst --skip-tests-for=Moose

=head3 smart-tests

An alternative to skipping all tests is to try and be clever about which tests to run and which to skip. The smart-tests option will skip tests for any package that it considers pristine. It defines pristine modules as modules that only depend on modules that are either Core or other pristine modules that have been installed during the current run. This means that on a fresh install, no tests will be ran, whereas installing new modules will cause tests to be ran to make sure there are no issues.

This isn't a fool-proof system, tests are an important part of making sure that all modules installed play well. This option is most useful with L<App::MechaCPAN::Deploy> and a C<cpanfile.snapshot> since the versions of packages listed in the snapshot file have been likely tested together so they are unlikely to have problems that would be revealed by running tests.

=head3 install-man

By default, man pages are not installed. Use this option to install the man pages.

=head3 source

Add a source translation to the installation. This can be used to translate a module name into another form, like using an exact version of a module or pull another module from its git repo. This can be repeated multiple times for multiple translations.

  # Examples of --source
  mechacpan install Catalyst --source Try::Tiny=ETHER/Try-Tiny-0.24
  mechacpan install Catalyst --source Catalyst=git://git.shadowcat.co.uk/catagits/Catalyst-Runtime.git

=head3 only-sources

Do not use modules not listed in the source list. This means if you do not specify every module and every prerequisite in the source list, then it will not be installed. This doesn't sound very useful since you would be potentially listing hundreds of modules. However, this feature is mostly used in conjuncture with L<App::MechaCPAN::Deploy> so that the modules listed in the C<cpanfile.snapshot> are the only module versions used.

=head3 update

If an older version of a given module is installed, a newer version will be installed. This is on by default.

Because to update is the default, the more useful option is false, or C<--no-update> from the command line. This will only install modules, not update modules to a newer version.

B<Note> this option I<ONLY> affects CPAN modules listed by package name, prerequisites and modules given not by package name are not affected by this option.

=head3 stop-on-error

If an error is encountered while processing an install, the default is to continue processing any module that isn't affected. Using this option will stop processing after the first error and not continue.

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=over

=item L<App::cpanminus>

=item L<CPAN>

=back

=cut
