#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package App::MatrixTool;

use strict;
use warnings;

our $VERSION = '0.08';

use Getopt::Long qw( GetOptionsFromArray );
use Future;
use List::Util 1.29 qw( pairmap );
use MIME::Base64 qw( encode_base64 );
use Module::Pluggable::Object;
use Module::Runtime qw( use_package_optimistically );
use Scalar::Util qw( blessed );
use Socket qw( getnameinfo AF_INET AF_INET6 AF_UNSPEC NI_NUMERICHOST NI_NUMERICSERV );
use Struct::Dumb qw( readonly_struct );

use Protocol::Matrix::HTTP::Federation;

require JSON;
my $JSON_pretty = JSON->new->utf8(1)->pretty(1);

my $opt_parser = Getopt::Long::Parser->new(
   config => [qw( require_order no_ignore_case )],
);

=head1 NAME

C<App::MatrixTool> - commands to interact with a Matrix home-server

=head1 SYNOPSIS

Usually this would be used via the F<matrixtool> command

 $ matrixtool server-key matrix.org

=head1 DESCRIPTION

Provides the base class and basic level support for commands that interact
with a Matrix home-server. See individual command modules, found under the
C<App::MatrixTool::Command::> namespace, for details on specific commands.

=cut

readonly_struct ArgSpec => [qw( name print_name optional eatall )];
sub ARGSPECS
{
   map {
      my $name = $_;
      my $optional = $name =~ s/\?$//;
      my $eatall   = $name =~ m/\.\.\.$/;

      ( my $print_name = uc $name ) =~ s/_/-/g;

      ArgSpec( $name, $print_name, $optional||$eatall, $eatall )
   } shift->ARGUMENTS;
}

readonly_struct OptSpec => [qw( name print_name shortname getopt description )];
sub OPTSPECS
{
   pairmap {
      my ( $name, $desc ) = ( $a, $b ); # allocate new SVtPVs to placate odd COW-related bug in 5.18

      my $getopt = $name;

      $name =~ s/=.*//;

      my $shortname;
      $name =~ s/^(.)\|// and $shortname = $1;

      my $printname = $name;
      $name =~ s/-/_/g;

      OptSpec( $name, $printname, $shortname, $getopt, $desc )
   } shift->OPTIONS;
}

sub new
{
   my $class = shift;
   return bless { @_ }, $class;
}

sub sock_family
{
   my $self = shift;
   return AF_INET if $self->{inet4};
   return AF_INET6 if $self->{inet6};
   return AF_UNSPEC;
}

sub _pkg_for_command
{
   my $self = shift;
   my ( $cmd ) = @_;

   my $class = ref $self || $self;

   my $base = $class eq __PACKAGE__ ? "App::MatrixTool::Command" : $class;

   # Allow hyphens in command names
   $cmd =~ s/-/_/g;

   my $pkg = "${base}::${cmd}";
   use_package_optimistically( $pkg );
}

sub run
{
   my $self = shift;
   my @args = @_;

   my %global_opts;
   $opt_parser->getoptionsfromarray( \@args,
      'inet4|4' => \$global_opts{inet4},
      'inet6|6' => \$global_opts{inet6},
      'print-request'  => \$global_opts{print_request},
      'print-response' => \$global_opts{print_response},
   ) or return 1;

   my $cmd = @args ? shift @args : "help";

   my $pkg = $self->_pkg_for_command( $cmd );
   $pkg->can( "new" ) or
      return $self->error( "No such command '$cmd'" );

   my $runner = $pkg->new( %global_opts );

   $self->run_command_in_runner( $runner, @args );
}

sub run_command_in_runner
{
   my $self = shift;
   my ( $runner, @args ) = @_;

   my @argvalues;

   if( $runner->can( "OPTIONS" ) ) {
      my %optvalues;

      $opt_parser->getoptionsfromarray( \@args,
         map { $_->getopt => \$optvalues{ $_->name } } $runner->OPTSPECS
      ) or exit 1;

      push @argvalues, \%optvalues;
   }

   my @argspecs = $runner->ARGSPECS;
   while( @argspecs ) {
      my $spec = shift @argspecs;

      if( !@args ) {
         last if $spec->optional;

         return $self->error( "Required argument '${\ $spec->print_name }' missing" );
      }

      if( $spec->eatall ) {
         push @argvalues, @args;
         @args = ();
      }
      else {
         push @argvalues, shift @args;
      }
   }
   @args and return $self->error( "Found extra arguments" );

   my $ret = $runner->run( @argvalues );
   $ret = $ret->get if blessed $ret and $ret->isa( "Future" );
   $ret //= 0;

   return $ret;
}

sub output
{
   my $self = shift;
   print @_, "\n";

   return 0;
}

# Some nicer-formatted outputs for terminals
sub output_ok
{
   my $self = shift;
   $self->output( "\e[32m", "[OK]", "\e[m", " ", @_ );
}

sub output_info
{
   my $self = shift;
   $self->output( "\e[36m", "[INFO]", "\e[m", " ", @_ );
}

sub output_warn
{
   my $self = shift;
   $self->output( "\e[33m", "[WARN]", "\e[m", " ", @_ );
}

sub output_fail
{
   my $self = shift;
   $self->output( "\e[31m", "[FAIL]", "\e[m", " ", @_ );
}

sub format_binary
{
   my $self = shift;
   my ( $bin ) = @_;

   # TODO: A global option to pick the format here
   return "base64::" . do { local $_ = encode_base64( $bin, "" ); s/=+$//; $_ };
}

sub format_hostport
{
   my $self = shift;
   my ( $host, $port ) = @_;

   return "[$host]:$port" if $host =~ m/:/; # IPv6
   return "$host:$port";
}

sub format_addr
{
   my $self = shift;
   my ( $addr ) = @_;
   my ( $err, $host, $port ) = getnameinfo( $addr, NI_NUMERICHOST|NI_NUMERICSERV );
   $err and die $err;

   return $self->format_hostport( $host, $port );
}

sub error
{
   my $self = shift;
   print STDERR @_, "\n";

   return 1;
}

## Command support

sub federation
{
   my $self = shift;

   return $self->{federation} ||= Protocol::Matrix::HTTP::Federation->new;
}

sub http_client
{
   my $self = shift;

   return $self->{http_client} ||= do {
      require App::MatrixTool::HTTPClient;
      App::MatrixTool::HTTPClient->new(
         family => $self->sock_family,
         map { $_ => $self->{$_} } qw( print_request print_response ),
      );
   };
}

sub server_key_store_path { "$ENV{HOME}/.matrix/server-keys" }

sub server_key_store
{
   my $self = shift;

   return $self->{server_key_store} ||= do {
      require App::MatrixTool::ServerIdStore;
      App::MatrixTool::ServerIdStore->new(
         path => $self->server_key_store_path
      );
   };
}

sub client_token_store_path { "$ENV{HOME}/.matrix/client-tokens" }

sub client_token_store
{
   my $self = shift;

   return $self->{client_token_store} ||= do {
      require App::MatrixTool::ServerIdStore;
      App::MatrixTool::ServerIdStore->new(
         path => $self->client_token_store_path,
         encode => "raw", # client tokens are already base64 encoded
      );
   };
}

sub JSON_pretty { $JSON_pretty }

## Builtin commands

package
   App::MatrixTool::Command::help;
use base qw( App::MatrixTool );

use List::Util qw( max );

use constant DESCRIPTION => "Display help information about commands";
use constant ARGUMENTS => ( "command...?" );

use Struct::Dumb qw( readonly_struct );
readonly_struct CommandSpec => [qw( name description argspecs optspecs package )];

sub commands
{
   my $mp = Module::Pluggable::Object->new(
      require => 1,
      search_path => [ "App::MatrixTool::Command" ],
   );

   my @commands;

   foreach my $module ( sort $mp->plugins ) {
      $module->can( "DESCRIPTION" ) or next;

      my $cmd = $module;
      $cmd =~ s/^App::MatrixTool::Command:://;
      $cmd =~ s/_/-/g;
      $cmd =~ s/::/ /g;

      push @commands, CommandSpec(
         $cmd,
         $module->DESCRIPTION,
         [ $module->ARGSPECS ],
         $module->can( "OPTIONS" ) ? [ $module->OPTSPECS ] : undef,
         $module,
      );
   }

   return @commands;
}

my $GLOBAL_OPTS = <<'EOF';
Global options:
   -4 --inet4             Use only IPv4
   -6 --inet6             Use only IPv6
      --print-request     Print sent HTTP requests in full
      --print-response    Print received HTTP responses in full
EOF

sub help_summary
{
   my $self = shift;

   $self->output( <<'EOF' . $GLOBAL_OPTS );
matrixtool [<global options...>] <command> [<command options...>]

EOF

   my @commands = $self->commands;

   my $namelen = max map { length $_->name } @commands;

   $self->output( "Commands:\n" .
      join "\n", map { sprintf "  %-*s    %s", $namelen, $_->name, $_->description } @commands
   );
}

sub _argdesc
{
   shift;
   my ( $argspec ) = @_;
   my $name = $argspec->print_name;
   return $argspec->optional ? "[$name]" : $name;
}

sub _optdesc
{
   my ( $optspec, $namelen ) = @_;

   my $shortname = $optspec->shortname;

   join "",
      ( defined $shortname ? "-$shortname " : "   " ),
      sprintf( "--%-*s", $namelen, $optspec->print_name ),
      "    ",
      $optspec->description,
}

sub help_detailed
{
   my $self = shift;
   my ( $cmd ) = @_;

   my $pkg = App::MatrixTool->_pkg_for_command( $cmd );
   $pkg->can( "new" ) or
      return $self->error( "No such command '$cmd'" );

   my @argspecs = $pkg->ARGSPECS;

   $self->output( join " ", "matrixtool",
      "[<global options...>]",
      $cmd,
      ( map $self->_argdesc($_), @argspecs ),
      "[<command options...>]"
   );
   $self->output( $pkg->DESCRIPTION );
   $self->output();

   $self->output( $GLOBAL_OPTS );

   if( $pkg->can( "OPTIONS" ) ) {
      my @optspecs = $pkg->OPTSPECS;

      my $namelen = max map { length $_->name } @optspecs;

      $self->output( "Options:" );
      foreach my $optspec ( sort { $a->name cmp $b->name } @optspecs ) {
         $self->output( "   " . _optdesc( $optspec, $namelen ) );
      }
      $self->output();
   }
}

sub run
{
   my $self = shift;
   my ( @cmd ) = @_;

   if( @cmd ) {
      $self->help_detailed( join "::", @cmd );
   }
   else {
      $self->help_summary;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
