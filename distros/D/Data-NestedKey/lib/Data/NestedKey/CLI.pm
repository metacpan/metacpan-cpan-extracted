package Data::NestedKey::CLI;

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(slurp);
use Data::NestedKey;
use English qw(no_match_vars);
use File::Basename qw(fileparse dirname);
use File::Temp qw(tempfile);
use JSON;
use List::Util qw(none pairs);
use YAML::XS;

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main();

########################################################################
sub _write_file {
########################################################################
  my ( $self, $dnk ) = @_;

  my $infile = $self->get_infile;

  die "ERROR: --replace and --backup require an input filename\n"
    if !defined $infile || $infile eq $DASH;

  my $content = $self->_serialize($dnk);
  my $dir     = dirname($infile);

  # Create the replacement next to the original so rename stays on the
  # same filesystem.  Do not disturb the input if serialization fails.
  my ( $fh, $temporary ) = tempfile( '.dnk-XXXXXX', DIR => $dir, UNLINK => 0 );
  my $backup_file;
  my @original_stat = stat($infile);

  die sprintf "ERROR: could not stat %s: %s\n", $infile, $OS_ERROR
    if !@original_stat;

  my $ok = eval {
    print {$fh} $content
      or die sprintf "ERROR: could not write %s: %s\n", $temporary, $OS_ERROR;

    close $fh
      or die sprintf "ERROR: could not close %s: %s\n", $temporary, $OS_ERROR;

    chmod( $original_stat[2] & oct('07777'), $temporary )
      or die sprintf "ERROR: could not preserve permissions on %s: %s\n", $temporary, $OS_ERROR;

    if ( my $backup = $self->get_backup ) {
      my ( $name, $path ) = fileparse( $infile, qr/[.][^.]+$/xsm );
      $backup_file = sprintf '%s%s.%s', $path, $name, $backup;

      die sprintf "ERROR: backup already exists: %s\n", $backup_file
        if -e $backup_file || -l $backup_file;

      rename $infile, $backup_file
        or die sprintf "ERROR: could not create backup %s: %s\n", $backup_file, $OS_ERROR;
    }

    rename $temporary, $infile
      or die sprintf "ERROR: could not replace %s: %s\n", $infile, $OS_ERROR;

    return 1;
  };

  if ( !$ok ) {
    my $error = $EVAL_ERROR;
    close $fh         if defined fileno($fh);
    unlink $temporary if -e $temporary;

    if ( defined $backup_file && -e $backup_file && !-e $infile ) {
      rename $backup_file, $infile
        or die sprintf "ERROR: %s; could not restore backup %s: %s\n", $error, $backup_file, $OS_ERROR;
    }

    die $error;
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

  die sprintf "ERROR: not a valid input format - %s (must be json, yaml, yml, or xml)\n", $format
    if $format && none { $_ eq lc $format } qw(json yaml yml xml);

  my $output_format = $self->get_output_format;

  die sprintf "ERROR: not a valid output format - %s (must be json, yaml, yml, or xml)\n", $output_format
    if $output_format && none { $_ eq lc $output_format } qw(json yaml yml xml);

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
sub _xml_data {
########################################################################
  my ( $self, $data ) = @_;

  eval { require Bedrock::XML; 1 }
    or die "ERROR: XML support requires the optional Bedrock::XML module: $EVAL_ERROR";

  my $xml = Bedrock::XML->newFromString($data);

  die "ERROR: unable to parse Bedrock XML input\n"
    if !$xml;

  return $xml->devolve;
}

########################################################################
sub _serialize {
########################################################################
  my ( $self, $dnk ) = @_;

  my $format = lc( $self->get_output_format // $self->{input_format} // 'json' );
  $format = 'yaml' if $format eq 'yml';

  if ( $format eq 'xml' ) {
    eval { require Bedrock::XML; 1 }
      or die "ERROR: XML output requires the optional Bedrock::XML module: $EVAL_ERROR";

    return Bedrock::XML::writeXML( $self->get_data );
  }

  local $Data::NestedKey::FORMAT = uc $format;
  return $dnk->as_string;
}

########################################################################
sub _fetch_data {
########################################################################
  my ($self) = @_;

  my $data   = slurp( $self->get_fh );
  my $format = $self->get_format;
  my $infile = $self->get_infile;

  # File extensions and recognizable Bedrock XML markup select XML first.
  # Otherwise, prefer JSON to YAML (JSON is also valid YAML).
  my $looks_xml = ( defined $infile && $infile =~ /[.]xml\z/ixsm )
    || $data =~ /\A\s*(?:<\?xml[^>]*>\s*)?<(?:object|array)\b/xsm;

  my @formats = $format ? ( lc $format ) : $looks_xml ? qw(xml) : qw(json yaml);
  my @errors;

  foreach my $candidate (@formats) {
    my $obj = eval {
      return decode_json($data)      if $candidate eq 'json';
      return $self->_xml_data($data) if $candidate eq 'xml';
      return YAML::XS::Load($data);
    };

    if ($EVAL_ERROR) {
      push @errors, sprintf '%s: %s', $candidate, $EVAL_ERROR;
      next;
    }

    die sprintf "ERROR: %s input must contain a hash or array\n", $candidate
      if ref($obj) ne 'HASH' && ref($obj) ne 'ARRAY';

    $self->{input_format} = $candidate eq 'yml' ? 'yaml' : $candidate;
    $Data::NestedKey::FORMAT = uc $self->{input_format};
    $self->set_data($obj);

    return Data::NestedKey->new($obj);
  }

  die sprintf "ERROR: unable to deserialize input\n%s", join( q{}, @errors );
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

  if ( $self->get_replace || $self->get_backup ) {
    $self->_write_file($dnk);
  }
  else {
    print {*STDOUT} $self->_serialize($dnk);
  }

  return $SUCCESS;
}

########################################################################
sub cmd_get {
########################################################################
  my ($self) = @_;

  my ($filter) = $self->get_args;
  $filter //= $PERIOD;

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
    replace|r
    infile|i=s
    format|f=s
    output-format|o=s
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

=head1 NAME

dnk - inspect and modify nested JSON, YAML, and optional Bedrock XML documents

=head1 SYNOPSIS

  dnk [options] get [key]
  dnk [options] set key value [key value ...]

  # Read a nested value from a file
  dnk -i config.json get database.host

  # Read a value from standard input
  cat response.json | dnk get .Listeners[0].ListenerArn

  # Print an updated document without modifying the input file
  dnk -i config.json set database.host localhost

  # Replace the input document
  dnk -i config.json --replace set database.host localhost

  # Replace the input and retain a backup
  dnk -i config.json --backup bak set database.host localhost

  # Update a Bedrock XML configuration (requires Bedrock::XML)
  dnk -r -i /path/to/config/tagx.xml set BEDROCK_SESSION_MANAGER UserSession

  # Convert JSON to YAML while modifying a value
  dnk -i config.json --output-format yaml set database.host localhost

=head1 DESCRIPTION

C<dnk> provides command-line access to nested JSON and YAML data using
C<Data::NestedKey>. Keys are expressed as dot-separated paths; array
subscripts such as C<items[0].name> and C<[0].name> are supported by
C<get>. The C<set> command uses the key syntax supported by
C<Data::NestedKey::set>, which does not accept array subscripts.

Input is read from C<--infile> or standard input. Without an explicit
C<--format>, C<dnk> recognizes C<.xml> files and Bedrock XML markup;
otherwise it attempts JSON decoding first, followed by YAML. The
optional L<Bedrock::XML> module is loaded only when XML is used.
The top-level document must be a hash or array.

=head1 COMMANDS

=head2 get [key]

Print the value at C<key>. If omitted, C<key> defaults to C<.>, meaning
the entire document. A leading dot may also be used for a nested key.

Scalar values are printed directly. Hashes and arrays are printed as
pretty-printed JSON, including when the input was YAML. An undefined
or missing value produces empty output by default; C<--error-on-undefined>
turns it into an error.

=head2 set key value [key value ...]

Apply one or more key/value updates. C<Data::NestedKey::set> supports
plain dot-separated paths as well as C<+> and C<-> prefixes for its
append/merge and removal operations. Array subscripts are not supported
by C<set>.

By default, C<set> prints the modified document to standard output in
the input format. C<--output-format> selects a different output format.
For XML input, the default output is Bedrock XML.
Use C<--format xml> to select Bedrock XML explicitly when necessary.

C<set> does not modify its input file unless replacement is requested. Use C<--replace> to write it back, or
C<--backup EXT> to save the original before replacing it. Replacement
requires an input filename; standard input cannot be replaced in place.

=head1 OPTIONS

=over 4

=item B<-i, --infile FILE>

Read from C<FILE>. If omitted, or if C<FILE> is C<->, read from standard
input.

=item B<-f, --format FORMAT>

Decode using C<json>, C<yaml>, C<yml>, or C<xml>. Without this option,
C<.xml> files and Bedrock XML input are recognized; otherwise JSON is
tried before YAML. XML requires L<Bedrock::XML>, an optional dependency.

=item B<-o, --output-format FORMAT>

Serialize C<set> output as C<json>, C<yaml>, C<yml>, or C<xml>. If omitted,
preserve the decoded input format. XML output requires L<Bedrock::XML>.
Use C<--output-format> to convert between JSON and YAML independently of
C<--format>. In-place format conversion replaces the original file's
contents but does not rename its extension.

=item B<-r, --replace>

With C<set>, replace the input file rather than printing the modified
document. Requires C<--infile> with a filename.

=item B<-b, --backup EXT>

With C<set>, retain the original input under a filename with extension
C<EXT> and replace the input file. Implies C<--replace>. Existing backup
files are not overwritten.

=item B<-u, --error-on-undefined>

Make C<get> fail when the requested key is undefined or missing, rather
than printing an empty value.

=item B<-h, --help>

Display command-line help.

=back

=head1 EXAMPLES

  # Inspect a nested value
  dnk -i config.json get database.host

  # Print an updated document to STDOUT
  dnk -i config.json set database.host localhost

  # Update the original document
  dnk -i config.json -r set database.host localhost

  # Preserve a backup while updating the original
  dnk -i config.json -b bak set database.host localhost

  # Output the entire document (formatted as JSON)
  cat policy.yaml | dnk get .

  # Replace a Bedrock XML configuration value
  dnk -r -i "$BEDROCK_WEB_DIR/config/tagx.xml" set BEDROCK_SESSION_MANAGER UserSession

  # Change a JSON configuration and emit YAML instead
  dnk -i config.json -o yaml set database.host localhost

=head1 SEE ALSO

L<Data::NestedKey>, L<JSON>, L<YAML::XS>, L<Bedrock::XML> (optional)

=cut
