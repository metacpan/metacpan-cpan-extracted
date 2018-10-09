package App::MechaCPAN::Deploy;

use strict;
use warnings;
use autodie;
use Carp;
use CPAN::Meta;
use List::Util qw/first reduce/;
use App::MechaCPAN qw/:go/;

our @args = (
  'skip-perl!',
  'update!',
);

sub munge_args
{
  my $class = shift;
  my $opts  = shift;
  my $file  = shift || '.';

  if ( $file =~ git_re )
  {
    my ( $git_url, $branch ) = $file =~ git_extract_re;

    if ( !eval { run(qw/git --version/); 1; } )
    {
      croak "Was given a git-looking URL, but could not run git";
    }

    my $remote      = 'origin';
    my $needs_clone = 1;

    # Determine if we're in a git directory
    if ( -d '.git' || eval { run(qw/git rev-parse --git-dir/); 1 } )
    {
      my $remote_line = first {m/\t $git_url \s/xms} run(qw/git remote -v/);
      if ($remote_line)
      {
        ($remote) = $remote_line =~ m/^ ([^\t]*) \t/xms;

        success "Found git checkout of of $git_url";

        $needs_clone = 0;
      }
      elsif ( -d '.git' )
      {
        # Only croak if there is a .git here which means we can't clone here
        croak "Found git checkout but could not find remote URL $git_url";
      }
    }

    if ($needs_clone)
    {
      info 'git-clone', "Cloning $git_url";

      my ($descr) = $git_url =~ m{ ([^/]*) $}xms;
      my $dir = humane_tmpdir($descr);

      # We use a temp directory and --seperate-git-dir  since byt his point
      # local exists because we're created it and started logging. These
      # options, plus the git config below, allow us to clone a git repo
      # without a clean current directory.
      run qw/git clone/, '--separate-git-dir=.git', '-n', '-o', $remote,
        $git_url, $dir;
      run qw/git config --unset core.worktree/;
      $branch //= 'master';
      success 'git-clone', "Cloned $git_url";
    }

    if ($branch)
    {
      info 'git-branch', "Checking out $branch";
      run qw/git checkout/, $branch;
      run qw/git fetch/, $remote, $branch;
      info 'git-branch', "Merging with remote branch $remote/$branch";
      run qw/git merge --ff-only FETCH_HEAD/;
      success 'git-branch', "Switched branch to $remote/$branch";
    }

    if ( !-f 'cpanfile' )
    {
      my @cpanfiles = glob '*/cpanfile';
      if ( scalar @cpanfiles == 1 )
      {
        my $dir = $cpanfiles[0];
        $dir =~ s[/cpanfile$][]xms;
        chdir $dir;
        $file = 'cpanfile';
      }
    }
  }

  return ($file);
}

sub go
{
  my $class = shift;
  my $opts  = shift;
  my $file  = shift || '.';

  if ( -d $file )
  {
    $file = "$file/cpanfile";
  }

  if ( !-e $file )
  {
    croak "Could not find cpanfile ($file)";
  }

  if ( !-f $file )
  {
    croak "cpanfile must be a regular file";
  }

  my $prereq = parse_cpanfile($file);
  my @phases = qw/configure build test runtime/;

  my @acc = map {%$_} map { values %{ $prereq->{$_} } } @phases;
  my @reqs;
  while (@acc)
  {
    push @reqs, [ splice( @acc, 0, 2 ) ];
  }

  if ( -f "$file.snapshot" )
  {
    my $snapshot_info = parse_snapshot("$file.snapshot");
    my %srcs;
    my %reqs;
    foreach my $dist ( values %$snapshot_info )
    {
      my $src = $dist->{pathname};
      foreach my $provide ( keys %{ $dist->{provides} } )
      {
        if ( exists $srcs{$provide} )
        {
          error "Found duplicate distribution for $provide in $file.snapshot";
          info "  $src and $srcs{$provide} both provide the same module";
          info "  This will cause an error if it is used as a dependency";
          $srcs{$provide} = undef;
          next;
        }
        $srcs{$provide} = $src;
      }

      foreach my $req ( keys %{ $dist->{requirements} } )
      {
        $reqs{$req} = undef;
      }
    }

    if ( ref $opts->{source} eq 'HASH' )
    {
      %srcs = ( %srcs, %{ $opts->{source} } );
    }
    $opts->{source}         = { %reqs, %srcs };
    $opts->{update}         = 0;
    $opts->{'only-sources'} = 1;
    $opts->{'smart-tests'}  = 1
      if !defined $opts->{'smart-tests'};
  }

  my $result;
  $opts->{update} //= 0;

  if ( !$opts->{'skip-perl'} )
  {
    $result = App::MechaCPAN::Perl->go($opts);
    return $result if $result;
  }

  $result = App::MechaCPAN::Install->go( $opts, @reqs );
  return $result if $result;

  return 0;
}

my $sandbox_num = 1;

sub parse_cpanfile
{
  my $file = shift;

  my $result = { runtime => {} };

  $result->{current} = $result->{runtime};

  my $methods = {
    on => sub
    {
      my ( $phase, $code ) = @_;
      local $result->{current} = $result->{$phase} //= {};
      $code->();
    },
    feature => sub {...},
  };

  foreach my $type (qw/requires recommends suggests conflicts/)
  {
    $methods->{$type} = sub
    {
      my ( $module, $ver ) = @_;
      if ( $module eq 'perl' )
      {
        $result->{perl} = $ver;
        return;
      }
      $result->{current}->{$type}->{$module} = $ver;
    };
  }

  foreach my $phase (qw/configure build test author/)
  {
    $methods->{ $phase . '_requires' } = sub
    {
      my ( $module, $ver ) = @_;
      $result->{$phase}->{requires}->{$module} = $ver;
    };
  }

  open my $code_fh, '<', $file;
  my $code = do { local $/; <$code_fh> };

  my $pkg = __PACKAGE__ . "::Sandbox$sandbox_num";
  $sandbox_num++;

  foreach my $method ( keys %$methods )
  {
    no strict 'refs';
    *{"${pkg}::${method}"} = $methods->{$method};
  }

  local $@;
  my $sandbox = join(
    "\n",
    qq[package $pkg;],
    qq[no warnings;],
    qq[# line 1 "$file"],
    qq[$code],
    qq[return 1;],
  );

  my $no_error = eval $sandbox;

  croak $@
    unless $no_error;

  delete $result->{current};

  return $result;
}

my $snapshot_re = qr/^\# carton snapshot format: version 1\.0/;

sub parse_snapshot
{
  my $file = shift;

  my $result = {};

  open my $snap_fh, '<', $file;

  if ( my $line = <$snap_fh> !~ $snapshot_re )
  {
    die "File doesn't looks like a carton snapshot: $file";
  }

  my @stack  = ($result);
  my $prefix = '';
  while ( my $line = <$snap_fh> )
  {
    chomp $line;

    if ( $line =~ m/^ \Q$prefix\E (\S+?) :? $/xms )
    {
      my $new_depth = {};
      $stack[0]->{$1} = $new_depth;
      unshift @stack, $new_depth;
      $prefix = '  ' x $#stack;
      next;
    }

    if ( $line =~ m/^ \Q$prefix\E (\S+?) (?: :? \s (.*) )? $/xms )
    {
      $stack[0]->{$1} = $2;
      next;
    }

    if ( $line !~ m/^ \Q$prefix\E /xms )
    {
      shift @stack;
      $prefix = '  ' x $#stack;
      redo;
    }

    die "Unable to parse snapshot (line $.)\n";
  }

  return $result->{DISTRIBUTIONS};
}

1;
__END__

=encoding utf-8

=head1 NAME

App::MechaCPAN::Deploy - Mechanize the deployment of CPAN things.

=head1 SYNOPSIS

  # Install perl and everything from the cpanfile into local/
  # If cpanfile.snapshot exists, it will be consulted exclusivly
  user@host:~$ mechacpan deploy
  user@host:~$ mechacpan deploy git://git@example.com/MyApp.git
  user@host:~$ zhuli do the thing

=head1 DESCRIPTION

=head2 Deploy

  user@host:~$ mechacpan deploy

The C<deploy> command is used for automating a deployment. It will install both L<perl> and all the modules specified from the C<cpanfile>.

=head3 C<cpanfile.snapshot>

If there is a C<cpanfile.snapshot> that was created by L<Carton>, C<deploy> will treat the modules listed in the snapshot file as the only modules available to install. If a module has a dependency not listed in the snapshot, the deployment will fail.

The option C<smart-tests> is enabled by default when there is a C<cpanfile.snapshot> file. See L<App::MechaCPAN::Install/smart-tests> for more details.

=head2 Methods

=head3 go( \%opts, $cpanfile )

This is the entry point into deployment. It will deploy perl and modules into the C<local> directory of the current directory. C<$cpanfile> is optional and does not have to provided. If it is provided, it needs to be either a path to a directory that contains a file named C<cpanfile> or the path to a file that can be used as a C<cpanfile>.

C<$cpanfile> can also refer to a git repository. In this case, C<App:MechaCPAN::Deploy> will attempt to clone the repository if it's not already and checkout the branch specified branch if given. If there is a cpanfile in the checked out repository or inside a top-level directory, then that cpanfile and directory will be used.

The options available are listed below.

=head2 Arguments

=head3 skip-perl

The C<skip-perl> boolean option will force C<deploy> to not install perl, only the modules.

  # Examples of skip-perl
  mechacpan deploy --skip-perl

=head3 update

Determines what to do with the installation of top-level dependencies. By default, C<deploy> does not update the immediate prerequisites in the C<cpanfile>. This overrides the same option in C<App::MechaCPAN::Install>. See L<update|App::MechaCPAN::Install/update> in L<App::MechaCPAN::Install>.

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=over

=item L<App::cpanminus>

=item L<local::lib>

=item L<Carton>

=item L<CPAN>

=item L<plenv|https://github.com/tokuhirom/plenv>

=item L<App::perlbrew>

=back

=cut
