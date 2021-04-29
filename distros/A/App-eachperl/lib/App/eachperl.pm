#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package App::eachperl;

use 5.010;  # //
use strict;
use warnings;

use Config::Tiny;

our $VERSION = '0.03';

my $RESET = "\e[m";
my $BOLD  = "\e[1m";

# Allow conversion of signal numbers into names
use Config;
my @SIGNAMES = split m/\s+/, $Config{sig_name};

use Struct::Dumb qw( struct );
struct Perl => [qw( name fullpath version selected )];

=head1 NAME

C<App::eachperl> - a wrapper script for iterating multiple F<perl> binaries

=head1 SYNOPSIS

   $ eachperl exec -E 'say "Hello"'

     --- perl5.30.0 --- 
   Hello

     --- bleadperl --- 
   Hello

   ----------
   perl5.30.0          : 0
   bleadperl           : 0

=head1 DESCRIPTION

For more detail see the manpage for the eachperl(1) script.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = bless {
      map { $_ => $args{$_} } qw(
         no_system_perl no_test since_version until_version reverse stop_on_fail
      ),
   }, $class;

   $self->maybe_apply_config( "./.eachperlrc" );
   $self->maybe_apply_config( "$ENV{HOME}/.eachperlrc" );
   $self->postprocess_config;

   return $self;
}

sub maybe_apply_config
{
   my $self = shift;
   my ( $path ) = @_;

   # Only accept files readable and owned by UID
   return unless -r $path;
   return unless -o _;

   my $config = Config::Tiny->read( $path );

   foreach my $key (qw( perls since_version until_version )) {
      $self->{$key} //= $config->{_}{$key};
   }
}

sub postprocess_config
{
   my $self = shift;

   foreach (qw( since_version until_version )) {
      my $ver = $self->{$_} or next;
      $ver =~ m/^v/ or $ver = "v$ver";
      # E.g. --until 5.14 means until the /end/ of the 5.14 series; so 5.14.999
      $ver .= ".999" if $_ eq "until_version" and $ver !~ m/\.\d+\./;
      $self->{$_} = version->parse( $ver );
   }

   if( my $perls = $self->{perls} ) {
      $self->{perls} = \my @perls;
      foreach my $perl ( split m/\s+/, $perls ) {
         chomp( my $fullpath = `which $perl` );
         $? and warn( "Can't find perl at $perl" ), next;

         my $ver;
         if( $perl =~ m/(5\.[\d.]+)/ ) {
            $ver = version->parse( "v$1" );
         }
         else {
            my $verstring = `$fullpath -e 'print \$^V'`;
            $ver = version->parse( $verstring );
         }

         push @perls, Perl( $perl, $fullpath, $ver, undef );
      }
   }
}

sub perls
{
   my $self = shift;

   my @perls = @{ $self->{perls} };
   @perls = reverse @perls if $self->{reverse};

   return map {
      my $perl = $_;
      my $ver = $perl->version;

      my $selected = 1;
      $selected = 0 if $self->{since_version} and $ver lt $self->{since_version};
      $selected = 0 if $self->{until_version} and $ver gt $self->{until_version};
      $selected = 0 if $self->{no_system_perl} and $perl->fullpath eq $^X;

      $perl->selected = $selected;

      $perl;
   } @perls;
}

sub run
{
   my $self = shift;
   my ( @argv ) = @_;

   if( $argv[0] =~ m/^-/ ) {
      unshift @argv, "exec";
   }

   ( my $cmd = shift @argv ) =~ s/-/_/g;
   my $code = $self->can( "run_$cmd" ) or
      die "Unrecognised eachperl command $cmd\n";

   return $self->$code( @argv );
}

sub run_list
{
   my $self = shift;

   foreach my $perl ( $self->perls ) {
      printf "%s%s: %s (%s)\n",
         ( $perl->selected ? "* " : "  " ),
         $perl->name, $perl->fullpath, $perl->version;
   }
   return 0;
}

sub run_exec
{
   my $self = shift;
   my ( @argv ) = @_;
   my %opts = %{ shift @argv } if @argv and ref $argv[0] eq "HASH";

   my @results;

   my $signal;

   foreach ( $self->perls ) {
      next unless $_->selected;

      my $perl = $_->name;
      my $path = $_->fullpath;

      print $opts{oneline} ?
         "$BOLD$perl:$RESET " :
         "\n$BOLD  --- $perl --- $RESET\n";

      system( $path, @argv );
      if( $? & 127 ) {
         # Exited via signal
         $signal = $?;
         push @results, [ $perl => "aborted on SIG$SIGNAMES[ $? ]" ];
         last;
      }
      else {
         push @results, [ $perl => $? >> 8 ];
         last if $? and $self->{stop_on_fail};
      }
   }

   unless( $opts{no_summary} ) {
      print "\n----------\n";
      printf "%-20s: %s\n", @$_ for @results;
   }

   kill $signal, $$ if $signal;
   return 0;
}

sub run_cpan
{
   my $self = shift;
   my ( @argv ) = @_;

   return $self->run_exec( "-MCPAN", "-e", join( " ", @argv ) );
}

sub _invoke_local
{
   my $self = shift;
   my %opts = @_;

   my $perl = "";
   my @args;

   if( -r "Build.PL" ) {
      $perl .= <<'EOPERL';
         system( $^X, "Build.PL" ) == 0 and
         system( $^X, "Build", "clean" ) == 0 and
         system( $^X, "Build" ) == 0
EOPERL
      $perl .= ' and system( $^X, "Build", "test" ) == 0'    if $opts{test};
      $perl .= ' and system( $^X, "Build", "install" ) == 0' if $opts{install};
   }
   elsif( -r "Makefile.PL" ) {
      $perl .= <<'EOPERL';
         system( $^X, "Makefile.PL" ) == 0 and
         system( "make" ) == 0
EOPERL
      $perl .= ' and system( "make", "test" ) == 0'    if $opts{test};
      $perl .= ' and system( "make", "install" ) == 0' if $opts{install};
   }
   else {
      die "TODO: Work out how to locally control dist when lacking Build.PL or Makefile.PL";
   }

   $perl .= ' and system( $^X, @ARGV ) == 0', push @args, "--", @{$opts{perl}} if $opts{perl};

   return $self->run_exec( "-e", $perl . <<'EOPERL', @args);
         and print "-- PASS -\n" or print "-- FAIL --\n";
      kill $?, $$ if $? & 127;
      exit +($? >> 8);
EOPERL
}

sub run_install
{
   my $self = shift;
   my ( $module ) = @_;

   local $self->{no_system_perl} = 1;

   return $self->run_install_local if $module eq ".";
   return $self->run_cpan( install => "\"$module\"" );
}

sub run_install_local
{
   my $self = shift;
   $self->_invoke_local( test => !$self->{no_test}, install => 1 );
}

sub run_test
{
   my $self = shift;
   my ( $module ) = @_;

   return $self->run_test_local if $module eq ".";
   return $self->run_cpan( test => "\"$module\"" );
}

sub run_test_local
{
   my $self = shift;
   $self->_invoke_local( test => 1 );
}

sub run_build_then_perl
{
   my $self = shift;
   my ( @argv ) = @_;
   $self->_invoke_local( test => !$self->{no_test}, perl => \@argv );
}

sub run_modversion
{
   my $self = shift;
   my ( $module ) = @_;

   return $self->run_exec(
      { oneline => 1, no_summary => 1 },
      "-M$module", "-e", "print ${module}\->VERSION, qq(\\n);"
   );
}

sub run_modpath
{
   my $self = shift;
   my ( $module ) = @_;

   ( my $filename = "$module.pm" ) =~ s{::}{/}g;

   return $self->run_exec(
      { oneline => 1, no_summary => 1 },
      "-M$module", "-e", "print \$INC{qq($filename)}, qq(\\n);"
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
