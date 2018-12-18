use lib '.';
use t::Util;
use App::git::ship::perl;

t::Util->goto_workdir('perl-ship', 0);

{
  # 0.07: test to see if perldoc -tT should work
  open my $FH, '>', 'README'
    or plan
    skip_all => sprintf 'Could not touch README in %s',
    Cwd::getcwd;
}

my $upload_file;
eval <<'DUMMY' or die $@;
package CPAN::Uploader;
sub new { bless $_[1], $_[0] }
sub read_config_file { {} }
sub upload_file { $upload_file = $_[1] }
$INC{'CPAN/Uploader.pm'} = 'dummy';
DUMMY

diag 'First release';
my $app = App::git::ship->new;
$app = $app->start('Perl/Ship.pm', 0);
$upload_file = '';

create_bad_main_module();
eval { $app->ship };
like $@, qr{Could not update VERSION in}, 'Could not update VERSION';

create_main_module();
eval { $app->ship };
like $@, qr{Project built}, 'Project built';

eval { $app->ship };
is $@, '', 'no ship error';
like $upload_file, qr{\bPerl-Ship-0\.01\.tar\.gz$}, 'CPAN::Uploader uploaded version 0.01';

diag 'Second release';
$app = App::git::ship->new;
bless $app, $app->detect;
$upload_file = '';

ok !$app->config('next_version'), 'no next_version yet';

eval { $app->ship };
like $@, qr{Unable to add timestamp}, 'Unable to add timestamp';

{
  local @ARGV = ('Changes');
  local $^I   = '';
  while (<>) {
    print "0.02 Not Released\n - Some other cool feature\n\n" if $. == 3;
    print;
  }
}

$app->build->ship;
is $app->config('next_version'), '0.02', 'next_version is 0.02';
like $upload_file, qr{\bPerl-Ship-0\.02\.tar\.gz$}, 'CPAN::Uploader uploaded version 0.01';

done_testing;

sub create_bad_main_module {
  open my $MAIN_MODULE, '>', File::Spec->catfile(qw(lib Perl Ship.pm)) or die $!;
  print $MAIN_MODULE "package Perl::Ship;\n=head1 NAME\n\nPerl::Ship\n\n1";
}

sub create_main_module {
  open my $MAIN_MODULE, '>', File::Spec->catfile(qw(lib Perl Ship.pm)) or die $!;
  print $MAIN_MODULE "package Perl::Ship;\n=head1 NAME\n\nPerl::Ship\n\n=head1 VERSION\n\n0.00\n\n=cut\n\nour \$VERSION = '42';\n\n1";
}
