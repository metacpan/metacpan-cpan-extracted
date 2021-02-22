BEGIN{
  # Avoid Slurp warnings on perl 5.8
  no warnings 'redefine';
  require File::Slurp;
  use warnings;
}
use strict;
use warnings;
package App::CSE;
$App::CSE::VERSION = '0.016';

use Moose;
use Class::Load;
use Cwd;
use App::CSE::Colorizer;
use DateTime;
use File::MimeInfo::Magic;
use IO::Interactive;
use JSON;
use String::CamelCase;

use Path::Class::Dir;
use File::stat;
use Getopt::Long qw//;
use Regexp::Assemble;
use Text::Glob;
use XML::LibXML;

use Log::Log4perl qw/:easy/;

=head1 NAME

App::CSE - Code search engine. Implements the 'cse' program

=head1 INSTALLATION

Using system wide cpan:

   sudo cpan -i App::CSE

Using cpanm:

   cpanm App::CSE

=head1 SYNOPSIS

  cse

See L<App::CSE::Command::Help> For a description the available commands.

=head1 FEATURES

=over

=item Hits highlighting

=item Prefix* queries

=item Complex queries syntax (Lucy)

=item Dirty files indicator

=item Directory watcher

=item Declaration queries (Perl subs and packages)

=item Directory filtering

=item Paging

=item Ignoring files

=item Works with Perl 5.8.8 up to 5.20

=back

=head1 PROGRAMMATIC USAGE

In addition of using this via the command line program 'cse', you can use this app
in an object oriented way.

For instance:

  my $app = App::CSE->new( { command_name => 'index',
                             options => { 'idx' => '/path/to/the/index' ,
                                           'dir' => '/code/directory/to/index'
                                        });

  if( $app->execute() ){
      .. and error occured ..
  }else{
      .. It is a success ..
  }

Retrieving search hits after a search:

  my $app = App::CSE->new( { command_name => 'search',
                             args => [ 'search_query' ],
                             options => { 'idx' => '/path/to/the/index' ,
                                           'dir' => '/code/directory/to/index'
                                        });
 my $hits = $app->command()->hits();
 # This is a L<Lucy::Search::Hits>

See L<App::CSE::Command::Help> for a list of available commands and options.

=head1 LOGGING

App::CSE uses L<Log::Log4perl>

=head1 BUILD STATUS

=begin html

<a href="https://travis-ci.org/jeteve/App-CSE"><img src="https://travis-ci.org/jeteve/App-CSE.svg?branch=master"></a>

=end html

=head1 COPYRIGHT

See L<App::CSE::Command::Help>

=cut

my $LOGGER = Log::Log4perl->get_logger();

has 'command_name' => ( is => 'ro', isa => 'Str', required => 1 , lazy_build => 1);
has 'command' => ( is => 'ro', isa => 'App::CSE::Command', lazy_build => 1);
has 'max_size' => ( is => 'ro' , isa => 'Int' , lazy_build => 1);

has 'interactive' => ( is => 'ro' , isa => 'Bool' , lazy_build => 1  );
has 'colorizer' => ( is => 'ro' , isa => 'App::CSE::Colorizer' , lazy_build => 1);

# GetOpt::Long options specs.
has 'options_specs' => ( is => 'ro' , isa => 'ArrayRef[Str]', lazy_build => 1);

# The options as slurped by getopts long
has 'options' => ( is => 'ro' , isa => 'HashRef[Str]', lazy_build => 1);

# The arguments after any option
has 'args' => ( is => 'ro' , isa => 'ArrayRef[Str]', lazy_build => 1);


has 'index_dir' => ( is => 'ro' , isa => 'Path::Class::Dir', lazy_build => 1);
has 'index_mtime' => ( is => 'ro' , isa => 'DateTime' , lazy_build => 1);
has 'index_dirty_file' => ( is => 'ro' , isa => 'Path::Class::File', lazy_build => 1);
has 'dirty_files' => ( is => 'ro', isa => 'HashRef[Str]', lazy_build => 1);

has 'index_meta_file' => ( is => 'ro' , isa => 'Path::Class::File' , lazy_build => 1);
has 'index_meta' => ( is => 'ro', isa => 'HashRef[Str]', lazy_build => 1);

# File utilities
has 'xml_parser' => ( is => 'ro' , isa => 'XML::LibXML', lazy_build => 1);

# Environment slurping
has 'cseignore' => ( is => 'ro', isa => 'Maybe[Path::Class::File]', lazy_build => 1 );
has 'ignore_reassembl' => ( is => 'ro', isa => 'Regexp::Assemble', lazy_build => 1);

{# Singleton flavour
  my $instance;
  sub BUILD{
    my ($self) = @_;
    $instance = $self;
  }
  sub instance{
    return $instance;
  }
}

sub _build_cseignore{
    my ($self) = @_;
    my $file = Path::Class::Dir->new()->file('.cseignore');
    unless( -e $file ){
        return;
    }
    $LOGGER->info("Will ignore patterns from '$file'");
    return $file;
}

sub _build_ignore_reassembl{
    my ($self) = @_;
    my $re = Regexp::Assemble->new();
    if( my $cseignore = $self->cseignore() ){
        my @lines = split(q/\n/ , $cseignore->slurp());
        foreach my $line ( @lines ){
            if( $line =~ /^\s*(?:#|$)/ ){
                next;
            }
            $line =~ s/^\s*//; $line =~ s/\s*$//;
            $re->add( Text::Glob::glob_to_regex_string( $line ) );
        }
    }
    return $re;
}

sub _build_xml_parser{
  my ($self) = @_;
  return XML::LibXML->new();
}

sub _build_colorizer{
  my ($self) = @_;
  return App::CSE::Colorizer->new( { cse => $self } );
}

sub _build_interactive{
  my ($self) = @_;
  return IO::Interactive::is_interactive();
}

sub _build_index_meta_file{
  my ($self) = @_;
  return $self->index_dir()->file('cse_meta.js');
}

sub _build_index_dirty_file{
  my ($self) = @_;
  return $self->index_dir()->file('cse_dirty.js');
}

sub _build_index_meta{
  my ($self) = @_;
  unless( -r $self->index_meta_file() ){
    return { version => '-unknown-' };
  }
  return JSON::decode_json(File::Slurp::read_file($self->index_meta_file().'' , { binmode => ':raw' }));
}

sub _build_dirty_files{
  my ($self) = @_;
  unless( -r $self->index_dirty_file() ){
    return {};
  }
  return JSON::decode_json(File::Slurp::read_file($self->index_dirty_file().'' , { binmode => ':raw' }));
}

sub _build_index_mtime{
  my ($self) = @_;
  my $st = File::stat::stat($self->index_dir());
  return DateTime->from_epoch( epoch => $st->mtime() );
}

sub _build_max_size{
  my ($self) = @_;
  return $self->options()->{max_size} || 1048576; # 1 MB default. This is the buffer size of File::Slurp
}

sub _build_index_dir{
  my ($self) = @_;

  if( my $opt_idx = $self->options->{idx} ){
    return Path::Class::Dir->new($opt_idx);
  }

  return Path::Class::Dir->new('.cse.idx');
}

sub _build_command_name{
  my ($self) = @_;

  unless( $ARGV[0] ){
    return 'help';
  }

  if( $ARGV[0] =~ /^-/ ){
    # The first argv is an option. Assume search
    return 'search';
  }

  ## Ok the first argv is a normal string.
  ## Attempt loading a command class.
  my $command_class = eval{ Class::Load::load_class(__PACKAGE__.'::Command::'.String::CamelCase::camelize($ARGV[0])) };
  if( $command_class ){
    # Valid command class. Return it.
    return shift @ARGV;
  };


  ## This first word is not a valid commnad class.
  ## Assume search.
  return 'search';

}

sub _build_command{
  my ($self) = @_;
  my $command_class = Class::Load::load_class(__PACKAGE__.'::Command::'.String::CamelCase::camelize($self->command_name()));
  my $command = $command_class->new({ cse => $self });
  return $command;
}

sub _build_options_specs{
  my ($self) = @_;
  return $self->command()->options_specs();
}

sub _build_options{
  my ($self) = @_;

  my %options = ();

  my $p = Getopt::Long::Parser->new;
  ## Avoid capturing unknown options, like -hello
  $p->configure( 'pass_through' );
  # Beware that accessing options_specs will consume the command as the first ARGV
  $p->getoptions(\%options , 'idx=s', 'dir=s', 'max-size=i', 'verbose+', @{$self->options_specs()} );
  return \%options;
}

sub _build_args{
  my ($self) = @_;
  $self->options();
  my @args = @ARGV;
  return \@args;
}

my $standard_log = q|
log4perl.rootLogger= INFO, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=%m%n
|;

my $verbose_log = q|
log4perl.rootLogger= TRACE, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d [%p] %m%n
|;


sub main{
  my ($self) = @_;

  unless( Log::Log4perl->initialized() ){

    binmode STDOUT , ':utf8';
    binmode STDERR , ':utf8';

    if( $self->options()->{verbose} ){
      Log::Log4perl::init(\$verbose_log);
    }else{
      Log::Log4perl::init(\$standard_log);
    }
  }

  return $self->command()->execute();
}

sub save_index_meta{
  my ($self) = @_;
  File::Slurp::write_file($self->index_meta_file().'' , { binmode => ':raw' }, JSON::encode_json($self->index_meta));
  return 1;
}

sub save_dirty_files{
  my ($self) = @_;
  File::Slurp::write_file($self->index_dirty_file().'' , { binmode => ':raw' }, JSON::encode_json($self->dirty_files));
  return 1;
}

sub version{
  my ($self) = @_;
  return $App::CSE::VERSION || 'dev';
}


# Performs very basic checks on a filename, see if its valid
# for indexing.
sub is_file_valid{
  my ($self, $file_name , $opts ) = @_;

  unless( defined( $opts ) ){
    $opts = {};
  }

  if( $self->ignore_reassembl()->match( $file_name ) ){
      $LOGGER->trace("File $file_name is ignoreed. Skipping");
      return $opts->{on_skip} ? &{$opts->{on_skip}}() : undef;
  }

  if( $file_name =~ /(?:\/|^)\.[^\/\.]+/ ){
    $LOGGER->trace("File $file_name is hidden. Skipping");
    return $opts->{on_hidden} ? &{$opts->{on_hidden}}() : undef;
  }

  unless( -r $file_name ){
    $LOGGER->warn("Cannot read $file_name. Skipping");
    return $opts->{on_unreadable} ? &{$opts->{on_unreadable}}() : undef;
  }

  return 1;
}


# Returns this file mimetype if we find its
# not a blacklisted one.
{
  my $BLACK_LIST = {
                    'application/x-trash' => 1
                   };
  sub valid_mime_type{
    my ($self, $file_name , $opts) = @_;
    my $mime_type = File::MimeInfo::Magic::mimetype($file_name.'') || 'application/octet-stream';

    if( $BLACK_LIST->{$mime_type} ){
      return;
    }
    return $mime_type;
  }

}
__PACKAGE__->meta->make_immutable();
