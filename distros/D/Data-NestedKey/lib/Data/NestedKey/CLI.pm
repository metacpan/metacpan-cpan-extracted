package Data::NestedKey::CLI;

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(slurp slurp_json choose);
use Cwd qw(realpath);
use Data::Dumper;
use Data::NestedKey;
use English qw(no_match_vars);
use File::Basename qw(fileparse);
use JSON;
use List::Util qw(none pairs);
use YAML::XS;

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main();

########################################################################
sub _write_file {
########################################################################
  my ( $self, $dnk ) = @_;

  my $backup = $self->get_backup;

  my $infile = $self->get_infile;

  # make a backup of the original file
  if ( $infile && $infile ne $DASH && $backup ) {
    my ( $name, $path, $ext ) = fileparse( $infile, qr/[.][^.]+$/xsm );
    $path = realpath($path);

    rename $infile, sprintf '%s/%s.%s', $path, $name, $backup;
  }

  eval {
    open my $fh, '>', $infile
      or die sprintf "ERROR: could not open %s for writing\n%s", $infile, $OS_ERROR;

    print {$fh} $dnk->as_string;

    close $fh;
  };

  if ($EVAL_ERROR) {
    my $err = $EVAL_ERROR;

    if ($backup) {
      rename $backup, $infile;
    }

    die $err;
  }

  return;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my @args = $self->get_args;

  my $command = $self->command;

  if ( !@args && !$self->commands->{$command} ) {
    $self->command('get');
    $self->command_args( [$command] );
  }
  else {
    die "ERROR: Unknown command ($command)\n"
      if !$self->commands->{$command};
  }

  my $format = $self->get_format;

  die sprintf "ERROR: not a valid format - %s (must be one of: xml, json, yml)\n", $format
    if $format && none { $_ eq lc $format } qw(xml json yaml);

  $Data::NestedKey::FORMAT = uc( $format // q{} );

  my $infile = $self->get_infile;

  my $fh = eval {
    return \*STDIN
      if !$infile || $infile eq $DASH;

    open my $handle, '<', $infile
      or die "ERROR: could not open $infile for reading\n$OS_ERROR";

    return $handle;
  };

  die "ERROR: $EVAL_ERROR"
    if !$fh;

  $self->set_fh($fh);

  return;
}

########################################################################
sub _fetch_data {
########################################################################
  my ($self) = @_;

  my $data = slurp( $self->get_fh );

  my %decoders = (
    xml  => sub { die "ERROR: not implemented\n" },
    json => sub { decode_json(shift) },
    yaml => sub { YAML::XS::Load(shift) },
    yml  => sub { YAML::XS::Load(shift) },
  );

  if ( my $format = $self->get_format ) {
    foreach my $f ( keys %decoders ) {
      next if uc $format eq uc $f;

      delete $decoders{$f};
    }
  }

  foreach my $f ( keys %decoders ) {
    my $obj = eval { $decoders{$f}->($data); };
    next if $EVAL_ERROR;

    $Data::NestedKey::FORMAT = uc $f;

    $self->set_data($obj);

    my $dnk = Data::NestedKey->new($obj);

    return $dnk;
  }

  return;
}

########################################################################
sub cmd_set {
########################################################################
  my ($self) = @_;

  my (@key_values) = $self->get_args;

  die "ERROR: usage: dnk set key value ...\n"
    if !@key_values || @key_values % 2;

  my $dnk = $self->_fetch_data;

  foreach my $p ( pairs @key_values ) {
    $dnk->set( @{$p} );
  }

  if ( $self->get_backup ) {
    $self->_write_file($dnk);
  }
  else {
    print {*STDOUT} $dnk->as_string;
  }

  return $SUCCESS;
}

########################################################################
sub cmd_get {
########################################################################
  my ($self) = @_;

  my ($filter) = $self->get_args;

  my $dnk = $self->_fetch_data;

  die "ERROR: unable to deserialize data\n"
    if !$dnk;

  if ( $filter =~ /^[.].+/xsm ) {
    $filter =~ s/^[.](.*)$/$1/xsm;
  }

  my $elem = $filter eq $PERIOD ? $self->get_data : $dnk->get($filter);

  if ( !defined $elem && !$self->get_error_on_undefined ) {
    $elem = q{};
  }
  elsif ( !defined $elem ) {
    die "ERROR: $filter is undefined\n";
  }

  print {*STDOUT} ref $elem ? JSON->new->pretty->encode($elem) : $elem;

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################
  my @option_specs = qw(
    help|h
    backup|b=s
    infile|i=s
    format|f=s
    error_on_undefined|u
  );

  my %commands = (
    get => \&cmd_get,
    set => \&cmd_set,
  );

  my @extra_options = qw(fh data dnk);

  my $cli = __PACKAGE__->new(
    commands         => \%commands,
    option_specs     => \@option_specs,
    extra_options    => \@extra_options,
    validate_command => $FALSE,
  );

  return $cli->run;
}

1;

__END__

=pod

=head1 SYNOPSIS

  dnk [options] get key
  dnk [options] set key value key value ...

  Set or get values from a structured data object.

   # set a value in a JSON file (output to STDOUT)
   dnk -i my-config.json set config.password foo

   # set a value in a JSON file (in replace file) 
   dnk -b bak -i my-config.json set config.password foo

   # pretty print a JSON file
   cat policy.json | dnk get .

   # retrieve a value from a JSON file
   cat alb-listener-rule.json | dnk get .ListenerArn

=head1 OPTIONS

 --help, -h                this help message
 --error-on-undefined, -u  throws an exception if the result of the expression is undefined 
 --infile, -i              input file
 --format, -f              xml, json, yml (default: input format)
 --replace, -r             replace file
 --backup, -b              backup extension, make a backup of the file before replacing

=head2 Notes

=over 5

=item 1. Input format is determined by trying various deserializers (json, yml)

=item 2. You can set multiple values on the command line

=item 3. C<--backup> implies C<--replace>

=back

=head2 Example:

 dnk -i infile.json set foo.bar buz foo.buz bar

 dnk -i infile.json -b bak set foo.bar buz

=cut
