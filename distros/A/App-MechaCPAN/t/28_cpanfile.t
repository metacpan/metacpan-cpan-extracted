use strict;
use FindBin;
use File::Copy;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir tempfile/;

require q[./t/helper.pm];

my $pwd = cwd;

my $tmpdir = tempdir(
  TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX",
  CLEANUP  => 1
);
chdir $tmpdir;
my $dir = cwd;

my ( $fh, $cpanfile ) = tempfile( "cpanfile.XXXXXXXX", DIR => $tmpdir );

my @resolvd;
my @pkgs = qw/Try::Tiny Test::More/;

$fh->say("requires '$_';") foreach @pkgs;
$fh->seek( 0, 0 );

*App::MechaCPAN::Install::_resolve = sub
{
  my $target = shift;
  push @resolvd, $target->{src_name};
  return;
};

# Check that it will handle with a filname
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, $cpanfile ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );

# Check that it will handle with a filehandle that is text-like
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, $fh ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );

# Check that we can use the default cpanfile file search
File::Copy::move( $cpanfile, 'cpanfile' );
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, $tmpdir ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );

# Check that we can use the default cpanfile directory search
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply(
  [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile'
);

# parse_cpanfile type-filter behavior. Write a cpanfile that exercises
# every directive type across phases, then verify how each opts shape
# trims the returned hash.
{
  my ( $tfh, $tname ) = tempfile( 'mecha_cpanfile_XXXXXX', DIR => $tmpdir, UNLINK => 1 );
  print $tfh <<'EOF';
requires    'Runtime::Req'      => '1.0';
recommends  'Runtime::Rec'      => '2.0';
suggests    'Runtime::Sug'      => '3.0';
conflicts   'Runtime::Conflict' => '4.0';

on 'configure' => sub
{
  requires 'Configure::Req' => '5.0';
};
on 'test' => sub
{
  requires   'Test::Req' => '7.0';
  recommends 'Test::Rec' => '7.0';
};
EOF
  close $tfh;

  # No type-filter args: every type captured verbatim, including conflicts. (raw mode)
  {
    my $prereq = App::MechaCPAN::parse_cpanfile($tname);

    isnt( $prereq->{runtime}->{requires}->{'Runtime::Req'},       undef, 'raw: requires captured' );
    isnt( $prereq->{runtime}->{recommends}->{'Runtime::Rec'},     undef, 'raw: recommends captured' );
    isnt( $prereq->{runtime}->{suggests}->{'Runtime::Sug'},       undef, 'raw: suggests captured' );
    isnt( $prereq->{runtime}->{conflicts}->{'Runtime::Conflict'}, undef, 'raw: conflicts captured' );
    isnt( $prereq->{configure}->{requires}->{'Configure::Req'},   undef, 'raw: phase-scoped requires captured' );
    isnt( $prereq->{test}->{recommends}->{'Test::Rec'},           undef, 'raw: phase-scoped recommends captured' );
  }

  # requires + recommends: suggests and conflicts trimmed off.
  {
    my $prereq = App::MechaCPAN::parse_cpanfile( $tname, qw/requires recommends/ );

    isnt( $prereq->{runtime}->{requires}->{'Runtime::Req'},   undef, 'requires kept' );
    isnt( $prereq->{runtime}->{recommends}->{'Runtime::Rec'}, undef, 'recommends kept' );
    isnt( $prereq->{test}->{recommends}->{'Test::Rec'},       undef, 'phase-scoped recommends kept' );
    is( $prereq->{runtime}->{suggests},  undef, 'suggests dropped' );
    is( $prereq->{runtime}->{conflicts}, undef, 'conflicts dropped' );
  }

  # requires only: every other type trimmed off (including conflicts).
  {
    my $prereq = App::MechaCPAN::parse_cpanfile( $tname, 'requires' );

    isnt( $prereq->{runtime}->{requires}->{'Runtime::Req'}, undef, 'requires kept' );
    is( $prereq->{runtime}->{recommends}, undef, 'recommends dropped' );
    is( $prereq->{runtime}->{suggests},   undef, 'suggests dropped' );
    is( $prereq->{runtime}->{conflicts},  undef, 'conflicts dropped' );
  }

  # Double check that extra types don't affect the outcome
  {
    my $prereq = App::MechaCPAN::parse_cpanfile( $tname, 'requires', '', 'NOTHING' );

    isnt( $prereq->{runtime}->{requires}->{'Runtime::Req'}, undef, 'requires kept' );
    is( $prereq->{runtime}->{recommends}, undef, 'recommends dropped' );
    is( $prereq->{runtime}->{suggests},   undef, 'suggests dropped' );
    is( $prereq->{runtime}->{conflicts},  undef, 'conflicts dropped' );
  }
}

chdir $pwd;
done_testing;
