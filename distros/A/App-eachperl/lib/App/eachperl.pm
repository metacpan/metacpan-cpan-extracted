#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.43;

package App::eachperl 0.04;
class App::eachperl;

use Config::Tiny;
use Syntax::Keyword::Dynamically;

use IO::Term::Status;
use IPC::Run ();
use String::Tagged 0.17;
use Convert::Color::XTerm 0.06;

my $RESET = "\e[m";
my $BOLD  = "\e[1m";

my %COL = (
   ( map { $_ => Convert::Color->new( "vga:$_" ) } qw( red blue green ) ),
   grey => Convert::Color->new( "xterm:grey(70%)" ),
);

# Allow conversion of signal numbers into names
use Config;
my @SIGNAMES = split m/\s+/, $Config{sig_name};

use Struct::Dumb qw( struct );
struct Perl => [qw( name fullpath version is_threads selected )];

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

has $_perls;
has $_no_system_perl :param;
has $_no_test        :param;
has $_since_version  :param;
has $_until_version  :param;
has $_reverse        :param;
has $_stop_on_fail   :param;

has $_io_term;

ADJUST
{
   $self->maybe_apply_config( "./.eachperlrc" );
   $self->maybe_apply_config( "$ENV{HOME}/.eachperlrc" );
   $self->postprocess_config;

   $_io_term = IO::Term::Status->new_for_stdout;
}

method maybe_apply_config ( $path )
{
   # Only accept files readable and owned by UID
   return unless -r $path;
   return unless -o _;

   my $config = Config::Tiny->read( $path );

   $_perls         //= $config->{_}{perls};
   $_since_version //= $config->{_}{since_version};
   $_until_version //= $config->{_}{until_version};
}

method postprocess_config ()
{
   foreach ( $_since_version, $_until_version ) {
      defined $_ or next;
      m/^v/ or $_ = "v$_";
      # E.g. --until 5.14 means until the /end/ of the 5.14 series; so 5.14.999
      $_ .= ".999" if \$_ == \$_until_version and $_ !~ m/\.\d+\./;
      $_ = version->parse( $_ );
   }

   if( my $perlnames = $_perls ) {
      $_perls = \my @perls;
      foreach my $perl ( split m/\s+/, $perlnames ) {
         chomp( my $fullpath = `which $perl` );
         $? and warn( "Can't find perl at $perl" ), next;

         my ( $ver, $threads ) = split m/\n/,
            scalar `$fullpath -MConfig -e 'print "\$]\\n\$Config{usethreads}\\n"'`;

         $ver = version->parse( $ver )->normal;
         $threads = ( $threads eq "define" );

         push @perls, Perl( $perl, $fullpath, $ver, $threads, undef );
      }
   }
}

method perls ()
{
   my @perls = @$_perls;
   @perls = reverse @perls if $_reverse;

   return map {
      my $perl = $_;
      my $ver = $perl->version;

      my $selected = 1;
      $selected = 0 if $_since_version and $ver lt $_since_version;
      $selected = 0 if $_until_version and $ver gt $_until_version;
      $selected = 0 if $_no_system_perl and $perl->fullpath eq $^X;

      $perl->selected = $selected;

      $perl;
   } @perls;
}

method run ( @argv )
{
   if( $argv[0] =~ m/^-/ ) {
      unshift @argv, "exec";
   }

   ( my $cmd = shift @argv ) =~ s/-/_/g;
   my $code = $self->can( "run_$cmd" ) or
      die "Unrecognised eachperl command $cmd\n";

   return $self->$code( @argv );
}

method run_list ()
{
   foreach my $perl ( $self->perls ) {
      printf "%s%s: %s (%s%s)\n",
         ( $perl->selected ? "* " : "  " ),
         $perl->name, $perl->fullpath, $perl->version,
         $perl->is_threads ? ",threads" : "";
   }
   return 0;
}

method run_exec ( @argv )
{
   my %opts = %{ shift @argv } if @argv and ref $argv[0] eq "HASH";

   my @results;
   my $ok = 1;

   my $signal;

   my @perls = $self->perls;
   my $idx = 0;
   foreach ( @perls ) {
      $idx++;
      next unless $_->selected;

      my $perl = $_->name;
      my $path = $_->fullpath;

      my @status = (
         ( $ok
            ? String::Tagged->new_tagged( "-OK-", fg => $COL{grey} )
            : String::Tagged->new_tagged( "FAIL", fg => $COL{red} ) ),

         String::Tagged->new
            ->append( "Running " )
            ->append_tagged( $perl, bold => 1 ),

         ( $idx < @perls
            ? String::Tagged->new_tagged( sprintf( "(%d more)", @perls - $idx ), fg => $COL{grey} )
            : () ),
      );

      $_io_term->set_status(
         String::Tagged->join( " | ", @status )
            ->apply_tag( 0, -1, bg => Convert::Color->new( "vga:blue" ) )
      );

      $opts{oneline} ?
         print "$BOLD$perl:$RESET " :
         $_io_term->print_line( "\n$BOLD  --- $perl --- $RESET" );

      my $has_partial = 0;
      IPC::Run::run [ $path, @argv ], ">pty>", sub {
         my @lines = split m/\r?\n/, $_[0], -1;

         if( $has_partial ) {
            my $line = shift @lines;

            if( $line =~ s/^\r// ) {
               $_io_term->replace_partial( $line );
            }
            else {
               $_io_term->more_partial( $line );
            }

            if( @lines ) {
               $_io_term->finish_partial;
               $has_partial = 0;
            }
         }

         # Final element will be empty string if it ended in a newline
         my $partial = pop @lines;

         $_io_term->print_line( $_ ) for @lines;

         if( length $partial ) {
            $_io_term->more_partial( $partial );
            $has_partial = 1;
         }
      };

      if( $? & 127 ) {
         # Exited via signal
         $signal = $?;
         push @results, [ $perl => "aborted on SIG$SIGNAMES[ $? ]" ];
         last;
      }
      else {
         push @results, [ $perl => $? >> 8 ];
         last if $? and $_stop_on_fail;
      }

      $ok = 0 if $?;
   }

   $_io_term->set_status( "" );

   unless( $opts{no_summary} ) {
      $_io_term->print_line( "\n----------" );
      $_io_term->print_line( sprintf "%-20s: %s", @$_ ) for @results;
   }

   kill $signal, $$ if $signal;
   return 0;
}

method run_cpan ( @argv )
{
   return $self->run_exec( "-MCPAN", "-e", join( " ", @argv ) );
}

method _invoke_local ( %opts )
{
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

method run_install ( $module )
{
   dynamically $_no_system_perl = 1;

   return $self->run_install_local if $module eq ".";
   return $self->run_cpan( install => "\"$module\"" );
}

method run_install_local ()
{
   $self->_invoke_local( test => !$_no_test, install => 1 );
}

method run_test ( $module )
{
   return $self->run_test_local if $module eq ".";
   return $self->run_cpan( test => "\"$module\"" );
}

method run_test_local ()
{
   $self->_invoke_local( test => 1 );
}

method run_build_then_perl ( @argv )
{
   $self->_invoke_local( test => !$_no_test, perl => \@argv );
}

method run_modversion ( $module )
{
   return $self->run_exec(
      { oneline => 1, no_summary => 1 },
      "-M$module", "-e", "print ${module}\->VERSION, qq(\\n);"
   );
}

method run_modpath ( $module )
{
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
