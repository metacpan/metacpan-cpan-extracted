#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package App::eachperl;

use 5.010;  # //
use strict;
use warnings;

use Config::Tiny;

our $VERSION = '0.01';

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
      map { $_ => $args{$_} } qw( no_system_perl since_version until_version ),
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

   return map {
      my $perl = $_;
      my $ver = $perl->version;

      my $selected = 1;
      $selected = 0 if $self->{since_version} and $ver lt $self->{since_version};
      $selected = 0 if $self->{until_version} and $ver gt $self->{until_version};
      $selected = 0 if $self->{no_system_perl} and $perl->fullpath eq $^X;

      $perl->selected = $selected;

      $perl;
   } @{ $self->{perls} };
}

sub run
{
   my $self = shift;
   my ( @argv ) = @_;

   if( $argv[0] =~ m/^-/ ) {
      unshift @argv, "exec";
   }

   my $cmd = shift @argv;
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

   my @results;

   my $signal;

   foreach ( $self->perls ) {
      next unless $_->selected;

      my $perl = $_->name;
      my $path = $_->fullpath;

      print "\n$BOLD  --- $perl --- $RESET\n";

      system( $path, @argv );
      if( $? & 127 ) {
         # Exited via signal
         $signal = $?;
         push @results, [ $perl => "aborted on SIG$SIGNAMES[ $? ]" ];
         last;
      }
      else {
         push @results, [ $perl => $? >> 8 ];
      }
   }

   print "\n----------\n";
   printf "%-20s: %s\n", @$_ for @results;

   kill $signal, $$ if $signal;
   return 0;
}

sub run_cpan
{
   my $self = shift;
   my ( @argv ) = @_;

   return $self->run_exec( "-MCPAN", "-e", join( " ", @argv ) );
}

sub run_install
{
   my $self = shift;
   my ( $module ) = @_;

   local $self->{no_system_perl} = 1;

   return $self->run_cpan( install => "\"$module\"" ) unless $module eq ".";

   # Install the code in the local dir directly, not via CPAN

   if( -r "Build.PL" ) {
      # TODO: Some sort of --notest option
      return $self->run_exec( "-e", <<'EOPERL' );
         system( $^X, "Build.PL" ) == 0 and
         system( $^X, "Build", "clean" ) == 0 and
         system( $^X, "Build", "test" ) == 0 and
         system( $^X, "Build", "install" ) == 0 and
            print "-- PASS --\n" or
            print "-- FAIL --\n";
         kill $?, $$ if $? & 127;
         exit +($? >> 8);
EOPERL
   }
   elsif( -r "Makefile.PL" ) {
      return $self->run_exec( "-e", <<'EOPERL' );
         system( $^X, "Makefile.PL" ) == 0 and
         system( "make", "test" ) == 0 and
         system( "make", "install" ) == 0 and
            print "-- PASS --\n" or
            print "-- FAIL --\n";
         kill $?, $$ if $? & 127;
         exit +($? >> 8);
EOPERL
   }
   else {
      warn "TODO: Work out how to locally install when lacking Build.PL or Makefile.PL";
   }
}

sub run_test
{
   my $self = shift;
   my ( $module ) = @_;

   return $self->run_cpan( test => "\"$module\"" ) unless $module eq ".";

   # Test the code in the local dir directly, not via CPAN

   if( -r "Build.PL" ) {
      return $self->run_exec( "-e", <<'EOPERL' );
         system( $^X, "Build.PL" ) == 0 and
         system( $^X, "Build", "clean" ) == 0 and
         system( $^X, "Build", "test" ) == 0 and
            print "-- PASS --\n" or
            print "-- FAIL --\n";
         kill $?, $$ if $? & 127;
         exit +($? >> 8);
EOPERL
   }
   elsif( -r "Makefile.PL" ) {
      return $self->run_exec( "-e", <<'EOPERL' );
         system( $^X, "Makefile.PL" ) == 0 and
         system( "make", "test" ) == 0 and
            print "-- PASS --\n" or
            print "-- FAIL --\n";
         kill $?, $$ if $? & 127;
         exit +($? >> 8);
EOPERL
   }
   else {
      warn "TODO: Work out how to locally test when lacking Build.PL or Makefile.PL";
   }
}

sub run_modversion
{
   my $self = shift;
   my ( $module ) = @_;

   return $self->run_exec( "-M$module", "-e", "print ${module}\->VERSION, qq(\\n);" );
}

sub run_modpath
{
   my $self = shift;
   my ( $module ) = @_;

   ( my $filename = "$module.pm" ) =~ s{::}{/}g;

   return $self->run_exec( "-M$module", "-e", "print \$INC{qq($filename)}, qq(\\n);" );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
