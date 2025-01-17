use v5.16; # from dependencies, so go for it.
package CPAN::Mini::Inject;

use strict;
use warnings;

use CPAN::Checksums 2.13;
use CPAN::Mini;
use CPAN::Mini::Inject::Config;
use Carp;
use Compress::Zlib;
use File::Basename;
use File::Copy;
use File::Path qw( make_path );
use File::Spec;
use File::Spec::Functions;
use LWP::Simple;
use Dist::Metadata ();

BEGIN {
  use version 0.9915;
  use # hide from PAUSE
  	CPAN::Meta::Converter;

  # This is here because the CPAN::Meta package has not been updated
  # since 2016 and it's unlikely that they'd accept a patch for this.
  # see https://github.com/briandfoy/cpan-mini-inject/issues/11
  # and https://github.com/Perl-Toolchain-Gang/CPAN-Meta#138
  package CPAN::Meta::Converter;

  no warnings qw(redefine);

  # lifted from CPAN::Meta::Converter
  # https://fastapi.metacpan.org/source/DAGOLDEN/CPAN-Meta-2.150010/lib/CPAN/Meta/Converter.pm
  sub _clean_version {
    my ($element) = @_;
    return 0 if ! defined $element;

    $element =~ s{^\s*}{};
    $element =~ s{\s*$}{};
    $element =~ s{^\.}{0.};

    return 0 if ! length $element;
    return 0 if ( $element eq 'undef' || $element eq '<undef>' );
    my $v = eval { version->parse($element) };
    # XXX check defined $v and not just $v because version objects leak memory
    # in boolean context -- dagolden, 2012-02-03
    if ( defined $v ) {
    return _is_qv($v) ? $v->stringify : $element;
    }
    else {
    return 0;
    }
  }
}

=encoding utf8

=head1 NAME

CPAN::Mini::Inject - Inject modules into a CPAN::Mini mirror.

=cut

our $VERSION = '1.007';
our @ISA     = qw( CPAN::Mini );

=head1 SYNOPSIS

If you're not going to customize the way CPAN::Mini::Inject works you
probably want to look at the L<mcpani> command instead.

    use CPAN::Mini::Inject;

    $mcpi=CPAN::Mini::Inject->new;
    $mcpi->parsecfg('t/.mcpani/config');

    $mcpi->add(
      module   => 'CPAN::Mini::Inject',
    authorid => 'SSORICHE',
    version  => ' 0.01',
    file     => 'mymodules/CPAN-Mini-Inject-0.01.tar.gz'
  );

    $mcpi->writelist;
    $mcpi->update_mirror;
    $mcpi->inject;

=head1 DESCRIPTION

CPAN::Mini::Inject uses CPAN::Mini to build or update a I<local> CPAN mirror
from a I<remote> one.  It adds two extra features:

1. an additional I<repository> of distribution files and related information
(author and module versions), separate from the local and remote mirrors, to
which you can add your own distribution files.

2. the ability to I<inject> the distribution files from your I<repository>
into a I<local> CPAN mirror.

=head1 METHODS

Each method in CPAN::Mini::Inject returns a CPAN::Mini::Inject object which
allows method chaining. For example:

    my $mcpi=CPAN::Mini::Inject->new;
    $mcpi->parsecfg
         ->update_mirror
         ->inject;

A C<CPAN::Mini::Inject> ISA L<CPAN::Mini>. Refer to the
L<documentation|CPAN::Mini> for that module for details of the interface
C<CPAN::Mini::Inject> inherits from it.

=over 4

=item C<new>

Create a new CPAN::Mini::Inject object.

=cut

sub new {
  my( $class, %args ) = @_;
  my %defaults = (
    config_class => $class->default_config_class,
  );
  my %allowed = map {
    $_, 1
  } qw(config_class);

  my %filtered =
    map { ($_, $args{$_}) }
    grep { exists $allowed{$_} }
    keys %args;


  my %obj = ( %defaults, %filtered );
  return bless \%obj, $class;
}

=item C<< config_class( [CLASS] ) >>

Returns the name of the class used to handle the configuration. Also
see C<default_config_class>.

=cut

sub config_class {
  my $self = shift;
  if ( @_ ) { $self->{config_class} = shift }
  $self->{config_class};
}

=item C<< config( [HASHREF] ) >>

With a hashref argument, sets the config data.

Returns the current configuration hash.

=cut

sub config {
  my $self = shift;
  if ( @_ ) { $self->{config} = shift }
  $self->{config};
}

=item C<< default_config_class >>

=cut

sub default_config_class {
  'CPAN::Mini::Inject::Config'
}

=item C<< loadcfg( [FILENAME] ) >>


This is a bridge to CPAN::Mini::Inject::Config's loadconfig. It sets the
filename for the configuration, or uses one of the defaults.

=cut

sub loadcfg {
  my $self = shift;

  unless ( $self->{config} ) {
    $self->{config} = $self->config_class->new;
  }

  $self->{cfgfile} = $self->{config}->load_config( @_ );

  return $self;
}

=item C<< parsecfg() >>

This is a bridge to CPAN::Mini::Inject::Config's parseconfig.

=cut

sub parsecfg {
  my $self = shift;

  unless ( $self->{config} ) {
    $self->config( $self->config_class->new );
  }

  $self->config->parse_config( @_ );

  return $self;
}

=item C<< site( [SITE] ) >>

With an argument, set the site to use to contact CPAN. Returns the
site setting, or, if the site has not be set (or was set to undef),
returns the empty string.

=cut

sub site {
  no warnings;
  my $self = shift;

  if ( @_ ) { $self->{site} = shift }

  $self->{site} // '';
}

=item C<testremote>

Test each site listed in the remote parameter of the config file by
performing a get on each site in order for authors/01mailrc.txt.gz.
The first site to respond successfully is set as the instance variable
site.

 print "$mcpi->{site}\n"; # ftp://ftp.cpan.org/pub/CPAN

C<testremote> accepts an optional parameter to enable verbose mode.

=cut

sub testremote {
  my $self    = shift;
  my $verbose = shift;

  $self->site( undef ) if $self->site;

  $ENV{FTP_PASSIVE} = 1 if ( $self->config->get( 'passive' ) );

  for my $site ( split( /\s+/, $self->config->get( 'remote' ) ) ) {

    $site .= '/' unless ( $site =~ m/\/$/ );

    print "Testing site: $site\n" if ( $verbose );

    if ( get( $site . 'authors/01mailrc.txt.gz' ) ) {
      $self->site( $site );

      print "\n$site selected.\n" if ( $verbose );
      last;
    }
  }

  croak "Unable to connect to any remote site" unless $self->site;

  return $self;
}

=item C<update_mirror>

This is a subclass of CPAN::Mini.

=cut

sub update_mirror {
  my $self    = shift;
  my %options = @_;

  croak 'Can not write to local: ' . $self->config->get( 'local' )
   unless ( -w $self->config->get( 'local' ) );

  $ENV{FTP_PASSIVE} = 1 if $self->config->get( 'passive' );

  $options{local}        ||= $self->config->get( 'local' );
  $options{trace}        ||= 0;
  $options{skip_perl}    ||= $self->config->get( 'perl' ) || 1;
  $options{skip_cleanup} ||= $self->config->get( 'skip_cleanup' ) || 0;

  # module_filters, log_level, and force
  my @extra = grep { defined $self->config->get($_) } qw(module_filters log_level force);

  $options{$_} = $self->config->get($_) for @extra;

  $self->testremote( $options{trace} )
   unless ( $self->site || $options{remote} );
  $options{remote} ||= $self->site;

  $options{dirmode} ||= oct( $self->config->get( 'dirmode' )
     || sprintf( '0%o', 0777 & ~umask ) );

  CPAN::Mini->update_mirror( %options );
}

=item C<add>

Add a new distribution to the repository. The C<add> method copies the
distribution file into the repository with the same structure as a
CPAN site. For example, F<CPAN-Mini-Inject-0.01.tar.gz> with author
C<SSORICHE> is copied to F<MYCPAN/authors/id/S/SS/SSORICHE>. add
creates the required directory structure below the repository.

Packages found in the distribution will be added to the module list
(for example both C<CPAN::Mini::Inject> and
C<CPAN::Mini::Inject::Config> will be added to the
F<modules/02packages.details.txt.gz> file).

Packages will be looked for in the C<provides> key of the META file if
present, otherwise the files in the dist will be searched. See
L<Dist::Metadata> for more information.

=over 4

=item * module

(optional) The package name of the module to add. The distribution
file will be searched for modules but you can specify the main one
explicitly.

=item * authorid

(required) The CPAN ID of the module's author. Since this isn't
actually CPAN, the ID does not need to exist on CPAN. Typically, this
ID uses C<[A-Z]> and is three to ten letters. This is not enforced,
but other CPAN tools may not like other sorts of names.

=item * version

(optional) The module's version number. If you don't specify this.
C<add> will try to extract it from the distribution.

=item * file

(required) The path to the distribution file.

=back

  $mcpani->add(
    module   => 'Module::Name',
  authorid => 'SOMEAUTHOR',
  version  => 0.01,
  file     => './Module-Name-0.01.tar.gz'
  );

=cut

sub add {
  my $self    = shift;
  my %options = @_;

  my $optionchk
   = _optionchk( \%options, qw/authorid file/ );

  croak "Required option not specified: $optionchk" if $optionchk;
  croak "No repository configured"
   unless ( $self->config->get( 'repository' ) );
  croak "Can not write to repository: "
   . $self->config->get( 'repository' )
   unless ( -w $self->config->get( 'repository' ) );

  croak "Can not read module file: $options{file}"
   unless -r $options{file};

  # attempt to guess module and version
  my $distmeta = Dist::Metadata->new( file => $options{file} );

  my $packages = $distmeta->package_versions;
  # include passed in module and version (prefer the declared version)
  if ( $options{module} and $options{version} ) {
    $packages->{ $options{module} } ||= $options{version};
  }

  # if no packages were found we need explicit options
  if ( !keys %$packages ) {
    $optionchk
     = _optionchk( \%options, qw/module version/ );

    croak "Required option not specified and no modules were found: $optionchk"
     if $optionchk;
  }

  my $modulefile = basename( $options{file} );
  $self->readlist unless exists( $self->{modulelist} );

  $options{authorid} = uc( $options{authorid} );
  $self->{authdir} = $self->_authordir( $options{authorid},
    $self->config->get( 'repository' ) );

  my $target
   = $self->config->get( 'repository' )
   . '/authors/id/'
   . $self->{authdir} . '/'
   . basename( $options{file} );

  copy( $options{file}, dirname( $target ) )
   or croak "Copy failed: $!";

  $self->_updperms( $target );

  {
    my $mods = join('|', keys %$packages);
    # remove old versions from the list
    @{ $self->{modulelist} }
     = grep { $_ !~ m/\A($mods)\s+/ } @{ $self->{modulelist} };
  }

  # make data available afterwards (since method returns $self)
  push @{ $self->{added_modules} ||= [] },
    { file => $modulefile, authorid => $options{authorid}, modules => $packages };

  push(
    @{ $self->{modulelist} },
    map {
      _fmtmodule(
        $_, File::Spec::Unix->catfile( File::Spec->splitdir( $self->{authdir} ), $modulefile ),
        defined($packages->{$_}) ? $packages->{$_} : 'undef'
      )
    } keys %$packages
  );

  return $self;
}

=item C<added_modules>

Returns a list of hash references describing the modules added by this instance.
Each hashref will contain C<file>, C<authorid>, and C<modules>.
The C<modules> entry is a hashref of module names and versions included in the C<file>.

The list is cumulative.
There will be one entry for each time L</add> was called.

This functionality is mostly provided for the included L<mcpani> script
to be able to verbosely print all the modules added.

=cut

sub added_modules {
  my $self    = shift;
  return @{ $self->{added_modules} ||= [] };
}

=item C<inject>

Insert modules from the repository into the local CPAN::Mini mirror. inject
copies each module into the appropriate directory in the CPAN::Mini mirror
and updates the CHECKSUMS file.

Passing a value to C<inject> enables verbose mode, which lists each module
as it's injected.

=cut

sub inject {
  my $self    = shift;
  my $verbose = shift;

  my $dirmode = oct( $self->config->get( 'dirmode' ) )
   if ( $self->config->get( 'dirmode' ) );

  $self->readlist unless ( exists( $self->{modulelist} ) );

  my %updatedir;
  my %already_injected;
  my %report;
  for my $modline ( @{ $self->{modulelist} } ) {
    my ( $module, $version, $file ) = split( /\s+/, $modline );

    my $target = $self->config->get( 'local' ) . '/authors/id/' . $file;

    # collect all modules of a target/file
    # needed for report
    push @{ $report{$target} }, $module;
    next if $already_injected{$module}++;

    my $source
     = $self->config->get( 'repository' ) . '/authors/id/' . $file;

    $updatedir{ dirname( $file ) } = 1;

    my $tdir = dirname $target;
    _make_path( $tdir, defined $dirmode ? { mode => $dirmode } : {} );
    copy( $source, $tdir )
     or croak "Copy $source to $tdir failed: $!";

    $self->_updperms( $target );
  }

  # if verbose report target file and the modules it contains
  if ( $verbose ) {
    for my $target (keys %report) {
        my $target_str = "$target ... injected modules : ";
        my $fmt = '%' . length($target_str) . "s%s\n";
        my @modules = @{ $report{$target} };
        printf $fmt, $target_str, shift @modules;    # first line with target
        for my $module ( @modules ) {                # rest only the module
            printf $fmt, '', $module;
        }
    }
  }

  for my $dir ( keys( %updatedir ) ) {
    my $root    = catfile( $self->config->get( 'local' ), qw(authors id) );
    my $authdir = catfile( $root, $dir );

    CPAN::Checksums::updatedir( $authdir, $root );
    $self->_updperms( catfile($authdir, 'CHECKSUMS') );
  }

  $self->updpackages;
  $self->updauthors;

  return $self;
}

=item C<updpackages>

Update the CPAN::Mini mirror's modules/02packages.details.txt.gz with the
injected module information.

=cut

sub updpackages {
  my $self = shift;

  my @modules = sort( @{ $self->{modulelist} } );
  my $infile  = $self->_readpkgs;
  my %packages;

  # These need to be unique-per-package, with ones that come from the input
  # file being overridden.
  for my $line (@$infile, @modules) {
    my ($pkg) = split(/\s+/, $line, 2);
    $packages{$pkg} = $line;
  };

  $self->_writepkgs( [ sort { lc $a cmp lc $b } values %packages ] );
}

=item C<updauthors>

Update the CPAN::Mini mirror's authors/01mailrc.txt.gz with
stub information should the author not actually exist on CPAN

=cut

sub updauthors {
  my $self = shift;

  my $repo_authors       = $self->_readauthors;
  my %author_ids_in_repo = map {
    my ( $id ) = $_ =~ /alias \s+ (\S+)/xms;
    $id => 1;
  } @$repo_authors;

  my @authors;
  my %authors_added;
  AUTHOR:
  for my $modline ( @{ $self->{modulelist} } ) {
    my ( $module, $version, $file ) = split( /\s+/, $modline );
    my $author = (File::Spec->splitdir( $file ))[2];

    next AUTHOR if defined $author_ids_in_repo{$author};
    next AUTHOR if defined $authors_added{$author};

    push @$repo_authors,
     sprintf( 'alias %-10s "Custom Non-CPAN author <CENSORED>"',
      $author );
    $authors_added{$author} = 1;
  }

  $self->_writeauthors( $repo_authors );

}

=item C<readlist>

Load the repository's modulelist.

=cut

sub _repo_file {
  File::Spec->catfile( shift->config->get( 'repository' ), @_ );
}

sub _modulelist { shift->_repo_file( 'modulelist' ) }

sub readlist {
  my $self = shift;

  $self->{modulelist} = undef;

  my $ml = $self->_modulelist;
  return $self unless -e $ml;

  open MODLIST, '<', $ml or croak "Can not read module list: $ml ($!)";
  while ( <MODLIST> ) {
    chomp;
    push @{ $self->{modulelist} }, $_;
  }
  close MODLIST;

  return $self;
}

=item C<writelist>

Write to the repository modulelist.

=cut

sub writelist {
  my $self = shift;

  croak 'Can not write module list: '
   . $self->config->get( 'repository' )
   . "/modulelist ERROR: $!"
   unless ( -w $self->{config}{repository} . '/modulelist'
    || -w $self->{config}{repository} );
  return $self unless defined( $self->{modulelist} );

  open( MODLIST,
    '>' . $self->config->get( 'repository' ) . '/modulelist' );
  for ( sort( @{ $self->{modulelist} } ) ) {
    chomp;
    print MODLIST "$_\n";
  }
  close( MODLIST );

  $self->_updperms(
    $self->config->get( 'repository' ) . '/modulelist' );

  return $self;
}

sub _updperms {
  my ( $self, $file ) = @_;

  chmod oct( $self->config->get( 'dirmode' ) ) & 06666, $file
   if $self->config->get( 'dirmode' );
}

sub _optionchk {
  my ( $options, @list ) = @_;
  my @missing;

  for my $option ( @list ) {
    push @missing, $option
     unless defined $$options{$option};
  }

  return join ' ', @missing;
}

sub _make_path {
  my $um = umask 0;
  make_path( @_ );
  umask $um;
}

sub _authordir {
  my ( $self, $author, $dir ) = @_;

  my @author
   = ( substr( $author, 0, 1 ), substr( $author, 0, 2 ), $author );

  my $dm = $self->config->get( 'dirmode' );
  my @new
   = _make_path( File::Spec->catdir( $dir, 'authors', 'id', @author ),
    defined $dm ? { mode => oct $dm } : {} );

  return return File::Spec->catdir( @author );
}

sub _fmtmodule {
  my ( $module, $file, $version ) = @_;
  my $fw = 38 - length $version;
  $fw = length $module if $fw < length $module;
  return sprintf "%-${fw}s %s  %s", $module, $version, $file;
}

sub _cfg { $_[0]->{config}{ $_[1] } }

sub _readpkgs {
  my $self = shift;

  my $gzread = gzopen(
    $self->config->get( 'local' )
     . '/modules/02packages.details.txt.gz', 'rb'
  ) or croak "Cannot open local 02packages.details.txt.gz: $gzerrno";

  my $inheader = 1;
  my @packages;
  my $package;

  while ( $gzread->gzreadline( $package ) ) {
    if ( $inheader ) {
      $inheader = 0 unless $package =~ /\S/;
      next;
    }
    chomp( $package );
    push( @packages, $package );
  }

  $gzread->gzclose;

  return \@packages;
}

sub _writepkgs {
  my $self = shift;
  my $pkgs = shift;

  my $gzwrite = gzopen(
    $self->config->get( 'local' )
     . '/modules/02packages.details.txt.gz', 'wb'
   )
   or croak
   "Can't open local 02packages.details.txt.gz for writing: $gzerrno";

  $gzwrite->gzwrite( "File:         02packages.details.txt\n" );
  $gzwrite->gzwrite(
    "URL:          http://www.perl.com/CPAN/modules/02packages.details.txt\n"
  );
  $gzwrite->gzwrite(
    'Description:  Package names found in directory $CPAN/authors/id/'
     . "\n" );
  $gzwrite->gzwrite( "Columns:      package name, version, path\n" );
  $gzwrite->gzwrite(
    "Intended-For: Automated fetch routines, namespace documentation.\n"
  );
  $gzwrite->gzwrite( "Written-By:   CPAN::Mini::Inject $VERSION\n" );
  $gzwrite->gzwrite( "Line-Count:   " . scalar( @$pkgs ) . "\n" );
  # Last-Updated: Sat, 19 Mar 2005 19:49:10 GMT
  $gzwrite->gzwrite( "Last-Updated: " . _fmtdate() . "\n\n" );

  $gzwrite->gzwrite( "$_\n" ) for ( @$pkgs );

  $gzwrite->gzclose;

}

sub _readauthors {
  my $self = shift;
  my $gzread
   = gzopen( $self->config->get( 'local' ) . '/authors/01mailrc.txt.gz',
    'rb' )
   or croak "Cannot open "
   . $self->config->get( 'local' )
   . "/authors/01mailrc.txt.gz: $gzerrno";

  my @authors;
  my $author;

  while ( $gzread->gzreadline( $author ) ) {
    chomp( $author );
    push( @authors, $author );
  }

  $gzread->gzclose;

  return \@authors;
}

sub _writeauthors {
  my $self    = shift;
  my $authors = shift;

  my $gzwrite
   = gzopen( $self->config->get( 'local' ) . '/authors/01mailrc.txt.gz',
    'wb' )
   or croak
   "Can't open local authors/01mailrc.txt.gz for writing: $gzerrno";

  $gzwrite->gzwrite( "$_\n" ) for ( sort @$authors );

  $gzwrite->gzclose;

}

sub _fmtdate {
  my @date = split( /\s+/, scalar( gmtime ) );
  return "$date[0], $date[2] $date[1] $date[4] $date[3] GMT";
}

=back

=head1 SEE ALSO

L<CPAN::Mini>

=head1 Original Author

Shawn Sorichetti, C<< <ssoriche@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Special thanks to David Bartle, for bringing this module up
to date, and resolving the reported bugs.

Thanks to Jozef Kutej <jozef@kutej.net> for numerous patches.

=head1 BUGS

Report issues to the GitHub queue at

  https://github.com/briandfoy/cpan-mini-inject/issues

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Shawn Sorichetti, Andy Armstrong, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of CPAN::Mini::Inject
