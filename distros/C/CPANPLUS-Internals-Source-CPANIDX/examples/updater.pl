use strict;
use warnings;
use Term::UI;
use Term::ReadLine;
use ExtUtils::Installed;
use File::Spec;
use File::Spec::Unix;
use File::Fetch;
use IO::Zlib;
use version;
use Module::Load::Conditional qw[check_install];
use CPANPLUS::Internals::Constants;
use CPANPLUS::Backend;

$ENV{PERL_MM_USE_DEFAULT} = 1; # despite verbose setting
$ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';

my %installed;
my %cpan;
my $conf = CPANPLUS::Configure->new();
my $hosts = $conf->get_conf( 'hosts' );

foreach my $module ( _all_installed() ) {
  my $href = check_install( module => $module );
  next unless $href;
  $installed{ $module } = defined $href->{version} ? $href->{version} : 'undef';
}

my $loc = fetch_indexes('.',$hosts) or die;
populate_cpan( $loc );
my %seen;
foreach my $module ( sort keys %installed ) {
  # Eliminate core modules
  if ( supplied_with_core( $module ) and !$cpan{ $module } ) { 
    delete $installed{ $module };
    next;
  }
  if ( !$cpan{ $module } ) {
    delete $installed{ $module };
    next;
  }
  if ( $seen{ $cpan{ $module }->[1] } ) {
    delete $installed{ $module };
    next;
  }
  $seen{ $cpan{ $module }->[1] }++;
  unless ( _vcmp( $cpan{ $module }->[0], $installed{ $module} ) > 0 ) {
    delete $installed{ $module };
    next;
  }
}

# Further eliminate choices.

my $term = Term::ReadLine->new('brand');

foreach my $module ( sort keys %installed ) {
  delete $installed{ $module }
    unless $term->ask_yn(
               prompt => "Update module '$module' ?",
               default => 'y',
  );
}

$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANIDX' );
$conf->set_conf( 'prereqs' => 1 );
$conf->set_conf( dist_type => 'CPANPLUS::Dist::YACSmoke' )
  if check_install( module => 'CPANPLUS::Dist::YACSmoke' );
my $cb = CPANPLUS::Backend->new($conf);
foreach my $mod ( sort keys %installed ) {
  my $module = $cb->module_tree($mod);
  next unless $module;
  $module->install();
}
exit 0;

sub supplied_with_core {
  my $name = shift;
  my $ver = shift || $];
  require Module::CoreList;
  return $Module::CoreList::version{ 0+$ver }->{ $name };
}

sub _vcmp {
  my ($x, $y) = @_;
  s/_//g foreach $x, $y;
  return version->parse($x) <=> version->parse($y);
}

sub populate_cpan {
  my $pfile = shift;
  my $fh = IO::Zlib->new( $pfile, "rb" ) or die "$!\n";
  my %dists;

  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my ($module,$version,$package_path) = split ' ', $_;
    $cpan{ $module } = [ $version, $package_path ];
  }
  return 1;
}

sub fetch_indexes {
  my ($location,$mirrors) = @_;
  foreach my $mirror ( @$mirrors ) {
    my $url = $mirror->{scheme} . '://' . 
      File::Spec::Unix->catdir( $mirror->{host}, $mirror->{path}, 'modules', '02packages.details.txt.gz' );
    my $ff = File::Fetch->new( uri => $url );
    my $stat = $ff->fetch( to => $location );
    next unless $stat;
    print "Downloaded '$url' to '$stat'\n";
    return $stat;
  }
  return;
}

sub _all_installed {
    ### File::Find uses follow_skip => 1 by default, which doesn't die
    ### on duplicates, unless they are directories or symlinks.
    ### Ticket #29796 shows this code dying on Alien::WxWidgets,
    ### which uses symlinks.
    ### File::Find doc says to use follow_skip => 2 to ignore duplicates
    ### so this will stop it from dying.
    my %find_args = ( follow_skip => 2 );

    ### File::Find uses lstat, which quietly becomes stat on win32
    ### it then uses -l _ which is not allowed by the statbuffer because
    ### you did a stat, not an lstat (duh!). so don't tell win32 to
    ### follow symlinks, as that will break badly
    $find_args{'follow_fast'} = 1 unless ON_WIN32;

    ### never use the @INC hooks to find installed versions of
    ### modules -- they're just there in case they're not on the
    ### perl install, but the user shouldn't trust them for *other*
    ### modules!
    ### XXX CPANPLUS::inc is now obsolete, remove the calls
    #local @INC = CPANPLUS::inc->original_inc;

    my %seen; my @rv;
    for my $dir (@INC ) {
        next if $dir eq '.';

        ### not a directory after all
        ### may be coderef or some such
        next unless -d $dir;

        ### make sure to clean up the directories just in case,
        ### as we're making assumptions about the length
        ### This solves rt.cpan issue #19738

        ### John M. notes: On VMS cannonpath can not currently handle
        ### the $dir values that are in UNIX format.
        $dir = File::Spec->canonpath( $dir ) unless ON_VMS;

        ### have to use F::S::Unix on VMS, or things will break
        my $file_spec = ON_VMS ? 'File::Spec::Unix' : 'File::Spec';

        ### XXX in some cases File::Find can actually die!
        ### so be safe and wrap it in an eval.
        eval { File::Find::find(
            {   %find_args,
                wanted      => sub {

                    return unless /\.pm$/i;
                    my $mod = $File::Find::name;

                    ### make sure it's in Unix format, as it
                    ### may be in VMS format on VMS;
                    $mod = VMS::Filespec::unixify( $mod ) if ON_VMS;

                    $mod = substr($mod, length($dir) + 1, -3);
                    $mod = join '::', $file_spec->splitdir($mod);

                    return if $seen{$mod}++;

                    push @rv, $mod;
                },
            }, $dir
        ) };

    }

    return @rv;
}
