#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package App::eachperl 0.11;
class App::eachperl;

use Object::Pad::FieldAttr::Checked 0.04;
use Data::Checks 0.08 qw( Str Maybe );

use Config::Tiny;
use Syntax::Keyword::Dynamically;

use Commandable::Finder::MethodAttributes 0.13 ':attrs';
use Commandable::Invocation;

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

my $VersionString_re;
my $VersionString;
BEGIN {
   $VersionString = Data::Checks::StrMatch
      $VersionString_re = qr/^v?\d+(?:\.\d+)*$/;
}

field $_finder;

field $_perls;
field $_install_no_system :param                                = undef;
field $_no_system_perl = !!$ENV{NO_SYSTEM_PERL};
field $_no_test;
field $_since_version;
field $_until_version;
field $_use_devel;
field $_only_if;
field $_reverse;
field $_stop_on_fail;

field $_io_term = IO::Term::Status->new_for_stdout;

class App::eachperl::_Perl {
   field $name         :param :reader  :Checked(Str);
   field $fullpath     :param :reader  :Checked(Str);
   field $version      :param :reader  :Checked($VersionString);
   field $is_threads   :param :reader;
   field $is_debugging :param :reader;
   field $is_devel     :param :reader;
   field $selected            :mutator;
}

field @_perlobjs;

ADJUST
{
   $_finder = Commandable::Finder::MethodAttributes->new( object => $self );

   $_finder->add_global_options(
      { name => "no-system-perl", into => \$_no_system_perl,
         description => "Deselects the system perl version" },
      { name => "no-test", into => \$_no_test,
         description => "Skips the 'test' step when building a local distribution" },
      { name => "since=", into => \$_since_version,
         matches => $VersionString_re, match_msg => "a version string",
         description => "Selects only perl versions that are at least as new as the requested version" },
      { name => "until=", into => \$_until_version,
         matches => $VersionString_re, match_msg => "a version string",
         description => "Selects only perl versions that are at least as old as the requested version" },
      { name => "version|v=", into => sub { $_since_version = $_until_version = $_[1] },
         matches => $VersionString_re, match_msg => "a version string",
         description => "Selects only the given perl version" },
      { name => "devel", into => \$_use_devel, mode => "bool",
         description => "Select only perl versions that are (or are not) development versions" },
      { name => "only-if=", into => \$_only_if,
         description => "Select only perl versions where this expression returns true" },
      { name => "reverse|r", into => \$_reverse,
         description => "Reverses the order in which perl versions are invoked" },
      { name => "stop-on-fail|s", into => \$_stop_on_fail,
         description => "Stops running after the first failure" },
   );

   $self->maybe_apply_config( "./.eachperlrc" );
   $self->maybe_apply_config( "$ENV{HOME}/.eachperlrc" );
}

method maybe_apply_config ( $path )
{
   # Only accept files readable and owned by UID
   return unless -r $path;
   return unless -o _;

   my $config = Config::Tiny->read( $path );

   $_perls             //= $config->{_}{perls};
   $_since_version     //= $config->{_}{since_version};
   $_until_version     //= $config->{_}{until_version};
   $_only_if           //= $config->{_}{only_if};
   $_install_no_system //= $config->{_}{install_no_system};
}

method postprocess_config ()
{
   foreach ( $_since_version, $_until_version ) {
      defined $_ or next;
      m/^v/ or $_ = "v$_";
      # E.g. --until 5.14 means until the /end/ of the 5.14 series; so 5.14.999
      $_ .= ".999" if \$_ == \$_until_version and $_ !~ m/\.\d+\./;
      $_ = version->parse( $_ )->stringify;
   }

   if( my $perlnames = $_perls ) {
      foreach my $perl ( split m/\s+/, $perlnames ) {
         chomp( my $fullpath = `which $perl` );
         $? and warn( "Can't find perl at $perl" ), next;

         my ( $ver, $usethreads, $ccflags ) = split m/\n/,
            scalar `$fullpath -MConfig -e 'print "\$]\\n\$Config{usethreads}\\n\$Config{ccflags}\\n"'`;

         $ver = version->parse( $ver )->normal;
         my $threads = ( $usethreads eq "define" );
         my $debug = $ccflags =~ m/-DDEBUGGING\b/;
         my $devel = ( $ver =~ m/^v\d+\.(\d+)/ )[0] % 2;

         push @_perlobjs, App::eachperl::_Perl->new(
            name         => $perl,
            fullpath     => $fullpath,
            version      => $ver,
            is_threads   => $threads,
            is_debugging => $debug,
            is_devel     => $devel,
         );
      }
   }
}

method perls ()
{
   my @perls = @_perlobjs;
   @perls = reverse @perls if $_reverse;

   return map {
      my $perl = $_;
      my $ver = $perl->version;

      my $selected = 1;
      $selected = 0 if $_since_version and $ver lt $_since_version;
      $selected = 0 if $_until_version and $ver gt $_until_version;
      $selected = 0 if $_no_system_perl and $perl->fullpath eq $^X;
      $selected = 0 if defined $_use_devel and $perl->is_devel ^ $_use_devel;

      if( $selected and defined $_only_if ) {
         IPC::Run::run(
            [ $perl->fullpath, "-Mstrict", "-Mwarnings", "-MConfig",
               "-e", "exit !do {$_only_if}" ]
         ) == 0 and $selected = 0;
      }

      $perl->selected = $selected;

      $perl;
   } @perls;
}

method run ( @argv )
{
   my $cinv = Commandable::Invocation->new_from_tokens( @argv );

   $_finder->handle_global_options( $cinv );

   $self->postprocess_config;

   if( $cinv->peek_remaining =~ m/^-/ ) {
      $cinv->putback_tokens( "exec" );
   }

   return $_finder->find_and_invoke( $cinv );
}

method command_list
   :Command_description("List the available perls")
   ()
{
   foreach my $perl ( $self->perls ) {
      my @flags;
      push @flags, $perl->version;
      push @flags, "threads"   if $perl->is_threads;
      push @flags, "DEBUGGING" if $perl->is_debugging;
      push @flags, "devel"     if $perl->is_devel;

      printf "%s%s: %s (%s)\n",
         ( $perl->selected ? "* " : "  " ),
         $perl->name, $perl->fullpath, join( ",", @flags ),
      ;
   }
   return 0;
}

method exec ( @argv )
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

      $opts{oneline}
         ? $_io_term->more_partial( "$BOLD$perl:$RESET " )
         : $_io_term->print_line( "\n$BOLD  --- $perl --- $RESET" );

      my $has_partial = $opts{oneline};
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

      if( $has_partial ) {
         $_io_term->finish_partial;
      }

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

method command_exec
   :Command_description("Execute a given command on each selected perl")
   :Command_arg("argv...", "commandline arguments")
   ( $argv )
{
   return $self->exec( @$argv );
}

method cpan ( $e, @argv )
{
   return $self->exec( "-MCPAN", "-e", $e, @argv );
}

method invoke_local ( %opts )
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

   return $self->exec( "-e", $perl . <<'EOPERL', @args);
         and print "-- PASS -\n" or print "-- FAIL --\n";
      kill $?, $$ if $? & 127;
      exit +($? >> 8);
EOPERL
}

method command_install
   :Command_description("Installs a given module")
   :Command_arg("module", "name of the module (or \".\" for current directory)")
   ( $module )
{
   dynamically $_no_system_perl = 1 if $_install_no_system;

   return $self->command_install_local if $module eq ".";
   return $self->cpan( 'CPAN::Shell->install($ARGV[0])', $module );
}

method command_install_local
   :Command_description("Installs a module from the current directory")
   ()
{
   $self->invoke_local( test => !$_no_test, install => 1 );
}

method command_test
   :Command_description("Tests a given module")
   :Command_arg("module", "name of the module (or \".\" for current directory)")
   ( $module )
{
   return $self->command_test_local if $module eq ".";
   return $self->cpan( 'CPAN::Shell->test($ARGV[0])', $module );
}

method command_test_local
   :Command_description("Tests a module from the current directory")
   ()
{
   $self->invoke_local( test => 1 );
}

method command_build_then_perl
   :Command_description("Build the module in the current directory then run a perl command")
   :Command_arg("argv...", "commandline arguments")
   ( $argv )
{
   $self->invoke_local( test => !$_no_test, perl => [ @$argv ] );
}

method command_modversion
   :Command_description("Print the installed module version")
   :Command_arg("module", "name of the module")
   ( $module )
{
   return $self->exec(
      { oneline => 1, no_summary => 1 },
      "-M$module", "-e", "print ${module}\->VERSION, qq(\\n);"
   );
}

method command_modpath
   :Command_description("Print the installed module path")
   :Command_arg("module", "name of the module")
   ( $module )
{
   ( my $filename = "$module.pm" ) =~ s{::}{/}g;

   return $self->exec(
      { oneline => 1, no_summary => 1 },
      "-M$module", "-e", "print \$INC{qq($filename)}, qq(\\n);"
   );
}

method command_uninstall
   :Command_description("Uninstalls a module")
   :Command_arg("module", "name of the module")
   ( $module )
{
   return $self->exec(
      "-e", <<'EOPERL' =~ s/^\s+//gr, $module
         use Errno;
         my $module = shift;
         ( my $path = $module ) =~ s{::}{/}g;
         my $packlist;
         foreach ( @INC ) {
            my $trial = "$_/auto/$path/.packlist";
            next unless -f $trial;
            $packlist = $trial; last;
         }
         defined $packlist or
            die "Unable to find a .packlist file for $module\n";
         open my $fh, "<", $packlist or
            die "Unable to read $packlist - $!";
         my $failed;
         sub remove {
            my ( $path ) = @_;
            unlink $path or
               $! == Errno::ENOENT or
               $failed++, warn("Unable to unlink $path - $!"), return;
            print "UNLINK $path\n";

            while( length $path ) {
               $path =~ s{/[^/]+$}{};
               rmdir $path and next;
               $! == Errno::ENOENT and next;
               $! == Errno::ENOTEMPTY and last;

               $failed++, warn("Unable to rmdir $path - $!"), return;
            }
         }
         while( <$fh> ) {
            chomp;
            remove($_);
         }
         remove($packlist) if !$failed;
         exit $failed;
EOPERL
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
