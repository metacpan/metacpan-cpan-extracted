#!/usr/bin/env perl

package CLI::Config::Resolver;

# general purpose script for merging secrets and configuration values
# to a template

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans :chars :log-levels);
use Config::Resolver;
use Config::Resolver::Utils qw(is_hash is_array to_boolean slurp_file);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::Temp qw(tempfile);
use Getopt::Long qw(:config no_ignore_case );
use JSON -convert_blessed_universally;
use List::Util qw(any);
use Module::Load;
use Query::Param;
use Scalar::Util qw(looks_like_number reftype);
use YAML::Tiny qw(LoadFile Dump Load);

__PACKAGE__->use_log4perl( level => 'warn' );

use parent qw(CLI::Simple);

########################################################################
our $VERSION = '1.0.10';
########################################################################

use File::Basename;  # <-- Make sure to 'use' this at the top of the file

########################################################################
sub process_manifest {
########################################################################
  my ($self) = @_;

  my $logger = $self->get_logger;

  $logger->info('processing manifest file...');

  my $manifest_file = $self->get_manifest;

  croak "ERROR: no manifest file specified. Use -m or --manifest\n"
    if !$manifest_file;

  croak "ERROR: manifest file not found: $manifest_file\n"
    if !-e $manifest_file;

  my $manifest = $self->fetch_file($manifest_file);
  croak "ERROR: manifest file must be a HASH\n"
    if ref $manifest ne 'HASH';

  my $globals = $manifest->{globals} || {};
  croak "ERROR: 'globals' section in manifest must be a HASH\n"
    if ref $globals ne 'HASH';

  my $jobs = $manifest->{jobs};
  croak "ERROR: manifest file is missing required 'jobs' array\n"
    if !$jobs || ref $jobs ne 'ARRAY';

  for my $job ( @{$jobs} ) {
    # 1. Merge globals and job-specific configs
    my $final_job = { %{$globals}, %{$job} };

    # 2. Extract final values
    my $outfile    = $final_job->{outfile} // q{};
    my $parameters = $final_job->{parameters};
    my $template   = $final_job->{template} // q{};

    $logger->info( sprintf 'processing job: %s => %s', $template, $outfile );

    if ( !$template && $outfile && $final_job->{template_path} ) {
      my $template_name = basename($outfile);
      $template = sprintf '%s/%s.tpl', $final_job->{template_path}, $template_name;

      # Store the derived template path back in the hash
      $final_job->{template} = $template;
    }

    # 3. Validate the final, resolved job
    if ( !$template || !$outfile || !$parameters ) {
      croak sprintf "ERROR: job is missing required keys (template, outfile, parameters)\n" . '(Job data: %s )',
        Dumper($final_job);
    }

    # 4. Check that files exist *before* trying to run
    croak "ERROR: parameter file not found: $parameters\n" if !-e $parameters;
    croak "ERROR: template file not found: $template\n"    if !-e $template;

    # 5. Set object state and run the resolver
    $self->set_parameter_file($parameters);
    $self->set_template($template);
    $self->set_outfile($outfile);
    $self->set_umask( $final_job->{umask} ) if $final_job->{umask};
    $logger->info( sprintf 'resolving %s using %s => %s (umask %o)',
      $template, $parameters, $outfile, $final_job->{umask} // 0 );

    $self->fetch_parameters();
    $self->resolve();

    $logger->info( sprintf '%s %s rendered', $outfile, -e $outfile ? 'sucessfully' : '*was not*' );
  }

  return $SUCCESS;
}

########################################################################
sub build_manifest {
########################################################################
  my ($self) = @_;

  my $output_dir   = $self->get_output_dir;
  my $template_dir = $self->get_template;

  opendir my $dh, $template_dir
    or croak "Can't opendir $template_dir: $OS_ERROR";

  my @templates = map {"$template_dir/$_"} grep {/[.]tpl$/xsm} readdir $dh;
  closedir $dh;

  croak "ERROR: no templates found, templates should have an .tpl extension\n"
    if !@templates;

  my ( $fh, $manifest_file ) = tempfile( 'manifest-XXXXX', SUFFIX => '.yml', );  #UNLINK => $TRUE);

  my $parameter_file = $self->get_parameter_file;
  my $umask          = $self->get_umask // umask;

  print {$fh} <<"END_OF_MANIFEST";
---
globals:
  parameters: $parameter_file
  umask: $umask

jobs:
END_OF_MANIFEST

  foreach my $template (@templates) {
    print {$fh} sprintf "  - template: %s\n", $template;
    print {$fh} sprintf "    outfile: %s/%s\n\n", $output_dir, basename( $template, '.tpl' );
  }

  close $fh;

  $self->set_manifest($manifest_file);

  return @templates;
}

########################################################################
sub cmd_version {
########################################################################
  my ($self) = @_;

  print {*STDOUT} sprintf "%s v%s\n", basename($PROGRAM_NAME), $VERSION;

  return $SUCCESS;
}

########################################################################
sub cmd_resolve {
########################################################################
  my ($self) = @_;

  return $self->process_manifest
    if $self->get_manifest;

  if ( $self->get_template && -d $self->get_template ) {
    my $parameter_file = $self->get_parameter_file;

    croak "ERROR: --parameter-file is missing or invalid\n"
      if !$parameter_file || !-e $parameter_file;

    my $output_dir = $self->get_output_dir;
    croak
      "ERROR: --output-dir is missing or invalid. You must specify an output directory when you specify a template directory\n"
      if !$output_dir || !-d $output_dir;

    $self->build_manifest();

    return $self->cmd_resolve();
  }

  $self->resolve;

  return $SUCCESS;
}

########################################################################
sub fetch_template {
########################################################################
  my ($self) = @_;

  # this will read from STDIN if there is content there
  my $content = $self->fetch_file;

  if ( !$content && $self->get_template_file ) {
    $content = $self->fetch_file( $self->get_template_file );
  }

  $self->set_template($content);

  return;
}

########################################################################
sub resolve {
########################################################################
  my ($self) = @_;

  my $resolver = $self->get_resolver;

  my $parameters = $self->get_parameters_hash;

  croak "ERROR: no parameters available for merging\n"
    if !$parameters;

  my $output = $resolver->resolve($parameters);

  if ( my $template = $self->get_template ) {
    my $template_obj = $self->fetch_file($template);

    if ( !ref $template_obj ) {
      open my $fh, '<', \$template_obj;
      $output = $self->resolve_stream( $fh, $output );
      close $fh;
    }
    else {
      $output = $resolver->resolve( $template_obj, $output );
    }
  }

  return $self->write_output($output);
}

########################################################################
sub cmd_dump {
########################################################################
  my ($self) = @_;

  my ($file) = $self->get_args;

  if ( !$file && !$self->get_parameters_hash ) {
    croak "ERROR: no file specified for dump, use --parameter-file or dump filename\n";
  }
  elsif ( !$self->get_parameters_hash && !-e $file ) {
    croak "ERROR: no such file - $file\n";
  }
  else {
    $self->set_parameter_file($file);
    $self->fetch_parameters();
  }

  my $object = $self->get_parameters_hash;

  if ( my $key = $self->get_key ) {
    $self->write_output( $object->{$key} );
  }
  else {
    $self->write_output($object);
  }

  return $SUCCESS;
}

# converts value to JSON string, undef to <undefined> or just returns value
########################################################################
sub format_value {
########################################################################
  my ( $self, $val, $key ) = @_;

  if ( ref $val && $key ) {
    $val = $val->{$key};

    die "$key not found\n"
      if !defined $val && $self->get_warning_level eq 'error';
  }

  return '<undefined>'
    if !defined $val;

  return $val
    if !ref $val;

  return to_json(
    $val,
    { allow_blessed   => $TRUE,
      convert_blessed => $TRUE,
      pretty          => $self->get_pretty ? $TRUE : $FALSE,
    }
  );
}

########################################################################
sub fetch_parameters {
########################################################################
  my ($self) = @_;

  if ( my $file = $self->get_parameter_file ) {
    my $parameters = $self->fetch_file($file) // {};

    my $new_hash = { %{ $self->get_parameters_hash // {} }, %{$parameters} };
    $self->set_parameters_hash($new_hash);
  }

  return $self->get_parameters_hash;
}

########################################################################
sub to_object {
########################################################################
  my ($content) = @_;

  croak "ERROR: no content\n"
    if !$content;

  local $SIG{__WARN__} = sub { };

  my $obj = eval { from_json($content); };

  return $obj
    if $obj;

  $obj = eval { return Load($content) };

  return $obj
    if $obj;

  $obj = eval { from_ini_file($content); };

  return $obj
    if $obj;

  return;
}

########################################################################
sub from_ini_file {
########################################################################
  my ($content) = @_;

  require Config::INI::Tiny;

  my $config  = Config::INI::Tiny->new->to_hash($content);
  my $globals = delete $config->{q{}};
  $globals //= {};

  return { %{$globals}, %{$config} };
}

########################################################################
sub fetch_file {
########################################################################
  my ( $self, $file ) = @_;

  if ( $file eq q{-} || ( !$file && !-t STDIN ) ) {  ## no critic (ProhibitInteractiveTest)

    return if STDIN->eof();

    local $RS = undef;
    my $content = <>;

    my $obj = eval { return to_object($content); };

    return $obj // $content;
  }

  my $obj = eval {

    return from_ini_file( slurp_file $file )
      if $file =~ /[.]config-resolverrc$/xsm;

    return LoadFile($file)
      if $file =~ /[.]ya?ml$/xsm;

    my $content = slurp_file($file);

    return from_json($content)
      if $file =~ /[.]json$/xsm;

    return $content;
  };

  croak "ERROR: could not fetch object from $file\n$EVAL_ERROR"
    if !$obj || $EVAL_ERROR;

  return $obj;
}

########################################################################
sub fetch_query_params {
########################################################################
  my ($self) = @_;

  my $query_string = $ENV{QUERY_STRING} // $self->get_parameters;

  return
    if !$query_string;

  my $qparams = Query::Param->new($query_string);

  my $new_hash = { %{ $self->get_parameters_hash // {} }, %{ $qparams->params } };
  $self->set_parameters_hash($new_hash);

  return $self->get_parameters_hash;
}

########################################################################
sub resolve_stream {
########################################################################
  my ( $self, $fh, $parameters ) = @_;

  my $resolver = $self->get_resolver;

  my $output = $EMPTY;

  return $output
    if !$fh || $fh->eof();

  while ( my $line = <$fh> ) {
    if ( $line =~ /[$][{](.*)[}]/xsm ) {
      my $ref = $resolver->resolve( { value => $line }, $parameters );
      $output .= $ref->{value};
      next;
    }

    $output .= $line;
  }

  return $output;
}

########################################################################
sub choose(&) {  ## no critic
########################################################################
  return $_[0]->();
}

########################################################################
sub write_output {
########################################################################
  my ( $self, $obj ) = @_;

  my $outfile = $self->get_outfile;

  my $fh = choose {
    return *STDOUT
      if !$self->get_outfile;

    if ( $self->get_umask ) {
      umask $self->get_umask;
    }

    open my $fh, '>', $outfile
      or croak "ERROR: could not open $outfile for writing\n$OS_ERROR\n";

    return $fh;
  };

  if ( ref $obj ) {
    my $format = $self->get_format // 'json';

    if ( $format eq 'json' ) {
      print {$fh} to_json(
        $obj,
        { allow_blessed   => $TRUE,
          convert_blessed => $TRUE,
          pretty          => $self->get_pretty ? $TRUE : $FALSE,
        },
      );
    }
    elsif ( $format =~ /^ya?ml$/xsm ) {
      print {$fh} Dump($obj);
    }
    elsif ( $format eq 'csv' && reftype($obj) eq 'HASH' ) {
      my $sep_char = $self->get_separator // q{ = };

      foreach ( keys %{$obj} ) {
        next if ref $obj->{$_};
        print {$fh} sprintf "%s%s%s\n", $_, $sep_char, $obj->{$_};
      }
    }
    else {
      croak "ERROR: unknown format %s\n", $format;
    }
  }
  else {
    print {$fh} $obj;
  }

  close $fh;

  return;
}

########################################################################
sub _build_plugin_config {
########################################################################
  my ($self) = @_;

  # Layer 1: Load defaults from RC file
  my $rc_file = $ENV{HOME} . '/.config-resolverrc';

  my $rc_config = -e $rc_file ? $self->fetch_file($rc_file) : {};
  my %plugin_configs;

  foreach my $section ( keys %{$rc_config} ) {
    if ( $section =~ /^plugin\s(.*)$/xsm ) {
      next if $rc_config->{$section}->{enabled} && $rc_config->{$section}->{enabled} eq 'false';
      # default to true
      $plugin_configs{$1} = $rc_config->{$section};
    }
  }

  # Layer 2: Parse CLI arguments
  my $cli_config  = {};
  my $plugin_args = $self->get_plugin // [];

  for my $arg ( @{$plugin_args} ) {
    my ( $plugin_name, $key_value_pair ) = split /:/xsm, $arg, 2;
    if ( !$key_value_pair ) {
      warn "WARNING: Ignoring malformed --plugin argument: $arg\n";
      next;
    }

    my ( $key, $value ) = split /=/xsm, $key_value_pair, 2;
    if ( !defined $value ) {
      warn "WARNING: Ignoring malformed --plugin argument: $arg\n";
      next;
    }
    $cli_config->{$plugin_name}{$key} = $value;
  }

  # add auto plugins
  my @plugins = split /\s*,\s*/xsm, $self->get_plugins // $EMPTY;

  $self->set_plugins( join q{,}, @plugins, keys %plugin_configs );

  foreach my $plugin_name ( split /\s*,\s*/xsm, $self->get_plugins ) {
    my $class = 'Config::Resolver::Plugin::' . $plugin_name;
    load $class;

    my $protocol;

    my $stash_name = $class . q{::};  # e.g., 'Config::Resolver::Plugin::SSM::'

    {
      no strict 'refs';               ## no critic

      $protocol = ${ $stash_name . 'PROTOCOL' };

      croak "Plugin $class must define a package variable '\$PROTOCOL'."
        if !$protocol;
    }

    $plugin_configs{$protocol} = delete $plugin_configs{$plugin_name};
  }

  # Layer 3: Deeply merge them (CLI wins)
  my $final_plugin_config = \%plugin_configs;

  foreach my $plugin_name ( keys %{$cli_config} ) {
    $final_plugin_config->{$plugin_name} = { %{ $plugin_configs{$plugin_name} // {} }, %{ $cli_config->{$plugin_name} } };
  }

  return $final_plugin_config;
}

########################################################################
sub check_for_pipelining {
########################################################################
  my ($self) = @_;

  my $pipelining = !-t STDIN;

  my $parameter_file = $self->get_parameter_file;

  my $template = $self->get_template;

  return
       if !$pipelining
    || ( $parameter_file && $template )
    || any { $_ && $_ eq q{-} } ( $parameter_file, $template );

  $self->set( $parameter_file ? 'template' : 'parameter_file', q{-} );

  return;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  if ( $self->get_verbose ) {
    $self->get_logger->level( $LOG_LEVELS{info} );
  }

  if ( $self->get_debug ) {
    $self->get_logger->level( $LOG_LEVELS{debug} );
  }

  if ( $self->get_env ) {
    # create a parameter file from the environment (or add?)
    my ( $fh, $env_file ) = tempfile( 'env-XXXXX', SUFFIX => '.json', UNLINK => 0 );

    my %parameters = ( env => \%ENV );

    if ( my $parameter_file = $self->get_parameter_file ) {
      %parameters = ( %parameters, %{ JSON->new_decode( slurp_file($parameter_file) ) } );
    }

    print {$fh} JSON->new->encode( \%parameters );

    close $fh;

    $self->set_parameter_file($env_file);
  }

  $self->check_for_pipelining;

  my $final_plugin_config = $self->_build_plugin_config();

  my $resolver = Config::Resolver->new(
    logger        => $self->get_logger,
    plugin_config => $final_plugin_config,
    warning_level => $self->get_warning_level,
    debug         => $self->get_debug,
    plugins       => [ split /\s*,\s*/xsm, $self->get_plugins // q{} ],
  );

  $self->set_resolver($resolver);

  $self->fetch_query_params;

  $self->fetch_parameters;

  # support legacy -r, -d options
  if ( $self->get_resolve ) {
    $self->command('resolve');
  }

  if ( $self->get_dump ) {
    $self->command('dump');
  }

  if ( $self->get_version ) {
    $self->command('version');
  }

  return;
}

########################################################################
sub main {
########################################################################

  my @option_specs = qw(
    debug|g
    dump|d
    env|e
    format|f=s
    help
    key|k=s
    manifest|m=s
    outfile|o=s
    output_dir|O=s
    parameter-file|p=s
    pretty|P
    parameters|V=s
    plugins=s
    plugin=s@
    resolve|r
    separator|S=s
    template=s
    umask=s
    warning-level|w=s
    verbose|v
    version
  );

  my %commands = (
    dump    => \&cmd_dump,
    resolve => \&cmd_resolve,
    version => \&cmd_version,
  );

  my %defaults = (
    warning_level => 'warn',
    format        => 'json',
  );

  my $cli = CLI::Config::Resolver->new(
    commands      => \%commands,
    option_specs  => \@option_specs,
    extra_options => [qw(resolver parameters_hash)],
    defaults      => \%defaults
  );

  return $cli->run();
}

exit main()
  if !caller;

1;

__END__

=pod

=head1 NAME

 config-resolver.pl

=head1 SYNOPSIS

Extract a single value from some JSON file...

 export DBI_DSN=$(config-resolver.pl -p /usr/share/my-app/config.json DBI_DSN)

Create a finalized configuration from a template...
 
  config-resolver.pl \
        -p /usr/share/my-app/config.json \
        -t /usr/share/my-app/my-site.conf.tpl > /etc/apache2/sites-available/my-site.conf  

=head1 DESCRIPTION

A command-line utility for dynamically resolving placeholders in
templates. It supports a robust variable substitution syntax that
includes protocol handlers (plugins) that provide customized
resolution of values.

=head1 MOTIVATION

C<Config::Resolver>, the engine behind this script, was created to
provide a single, powerful, and secure tool for managing complex
application configurations. It was designed to solve common challenges
in modern, dynamic applications while giving developers an extensible
tool.

This utility provides a simple command-line interface to C<Config::Resolver>,
allowing you to:

=over 4

=item * 

B<Manage Multiple Environments:> Use conditional logic (e.g., C<${env eq 'prod' ? ...}>)
to build a single, clean template that adapts to any environment.

=item *

B<Securely Fetch Secrets:> Keep secrets out of your codebase by
using pluggable backends to fetch values at runtime (e.g., C<ssm://...>)
right when you need them.

=item *

B<Simplify Deployment Scripts:> Replace complex and brittle C<sed>,
C<awk>, or C<envsubst> logic in deployment scripts (like a
C<docker-entrypoint.sh>) with a single, robust, and testable command.

=item *

B<Enable Simple Data Transformations:> Use safe, "allow-listed"
functions (e.g., C<${uc(hostname)}>) to format values directly in
your configuration.

=item * 

B<Use Plugins:> Use plugins for custom variable resolution.

=back

=head1 USAGE

 config-resolver.pl OPTIONS [key=value key=value]

Utility to extract value from config file, or apply
parameters to a template file.

=head2 Commands

 resolve
 dump

=head2 Options

 -d, --dump                dump the configuration file
 -f, --format              output format (json, yml, csv), default: json
 -g, --debug               debug output
 -h, --help                help
 -k, --key                 key to output from configuration file
 -o, --outfile             output file, default: STDOUT
 -p, --parameter-file      name of the parameter file (JSON)
 -V, --parameters          key/value pairs ala CGI (foo=bar&baz=buz)
 --plugins                 a comma separated list of plugins
 -P, --pretty              pretty print JSON
 -S, --separator           separator character for csv format dump
 -t, --template            name of the template file
 -u, --umask               umask to use output file
 -w, --warning-level       "warn" or "error"

See man 'config-resolver.pl' for more details.

=head1 OPTION DETAILS

=over 5

=item -d, --dump

Outputs all values from the parameters file. Use --format to control the
output format.

I<Note: This is a deprecated. Use the C<dump> command.>

default: json

=item -e, --env

Uses the current environment variables (C<%ENV>) as the parameter source.

This creates a temporary JSON parameter file containing the current environment
and uses it for resolution. This is useful for 12-factor apps where configuration
is passed solely via environment variables.

  config-resolver.pl -e -t app.conf.tpl

=item -f, --format

Output format. Valid values are 'json', 'yml' or 'csv'.

I<Note: 'csv' format is only valid for dumping a hash. It will output
a list of key/value pairs separated by a separation character(s)
(default: ' = '). This will only output the hash to a depth of 1.>

default: json

=item -g,  --debug

Logs debug messages to STDERR.

=item -k, --key

A key to dump from the parameters file.

=item -P, --pretty

Pretty print JSON output.

default: false

=item -m, --manifest

Specifies a manifest file (YAML or JSON) for batch-processing multiple
templates in a single run.

See L</BATCH PROCESSING USING A MANIFEST FILE>

=item -o, --outfile

Name of the output file to create.  If not present, output is sent to STDOUT.

default: STDOUT

=item -O, --output-dir

The target directory for writing output files.

**Required** when C<--template> is a directory.

=item -p, -- parameter-file

A JSON or YAML file that contains the parameters used for
interpolation.

The parameter file is used to populate the template.  Parameters
I<values> should be constants or special values of the form:

 xxx://key-path

...where "xxx" represents the protocol prefix for a plugin
(e.g. ssm:// for retrieving values from thhe AWS SSM Parameter Store
API).

default: none

=item --plugins

A comma delimited list of plugin names. See L</PLUGINS>

=item --plugin xxx:key=value

This is the mechanism you use to pass options to your plugins.

Example:

 --plugin ssm:endpoint_url=http://localhost:4566

=item -V, --parameters

You can supply key/value pairs at the command line to do simple
templating operations.

 echo 'foo=${foo}' | config-resolver -V 'foo=bar&bar=buz'

=item -r, --resolve

Resolve the parameters only and print out the resulting JSON.

B<Example:>

 config-resolver -p /etc/tbc-prod.json -r -P

 config-resolover -p /etc/tbc-prod.json --pretty resolve

=item -S, --separator

If you want to dump a hash as a flatten list of key/value pairs use
the C<--format> csv option. This option will set the separator character(s).

default: ' = '

=item -t, --template

Name of the template file **or directory**.

**File Mode:**
If a file is specified, it treats it as a single template.

**Directory Mode:**
If a directory is specified, the script automatically scans it for files ending in
C<.tpl>. It then generates a corresponding output file for each template in the
directory specified by C<--output-dir>.

See L</BATCH PROCESSING USING A MANIFEST FILE> for details.

=item -u, --umask

A umask to use when creating an output file.  The default is the umask
of the current process.  Use 0027 to create a file that can only be read
by the owner and the group that the owner belongs too.  Hence, if run
by root, the output file will only be readable by root.

default: none

=item -w, --warn-level

Determines how errors or missing paramters are handled. See below.

=over 10

=item warn

Continues on errors but outtputs warning error messages when values
cannot be resolved.

=item error

Halts processing if any value cannot be resolved.

=back

=back

=head1 BATCH PROCESSING USING A MANIFEST FILE

This feature allows you to provision a set of configuration files in a single
pass. There are two ways to use batch processing:

=head2 1. Automatic (Directory Mode)

This mode is ideal for simple 1:1 bulk rendering. If you provide a directory
path to C<--template> (and a target C<--output-dir>), the script automatically
generates a temporary manifest for you.

It scans for files with a C<.tpl> extension and maps every input template
to a corresponding output file, stripping the extension.

 # Renders all *.tpl files in /templates to /etc/app
 config-resolver.pl --template /opt/app/templates --output-dir /etc/app

=head2 2. Manual (Manifest Mode)

For fine-grained control—such as renaming files, using different parameters
for specific templates, or setting file permissions - you can manually create
a manifest file and pass it via C<--manifest>.

The manifest file must be a HASH containing a C<globals> hash and a C<jobs> array.

=head3 Manifest Structure

=over 4

=item B<globals> (Optional)

A HASH of default keys applied to every job. Common defaults include C<parameters>,
C<template_path>, and C<umask>.

=item B<jobs> (Required)

An ARRAY of HASHes. Each entry represents a single file to generate. Keys defined
here override those in C<globals>.

=back

=head3 Inheritance and Merging

For each job, the resolver merges the job-specific keys over the C<globals>
keys. After merging, every job B<must> possess at least an C<outfile> and
a C<parameters> source.

=head3 Convention Over Configuration

You do not always need to explicitly define the C<template> key. If a job omits
the C<template> key, but C<template_path> is defined (usually in globals),
the resolver derives the template filename from the C<outfile>:

 template = template_path / basename(outfile) . '.tpl'

This allows you to define the source directory once in C<globals> and only list
the desired output paths in C<jobs>.

=head3 Example C<manifest.yml>

  # --- Global defaults for all jobs ---
  globals:
    parameters: /etc/my-app/common-config.json
    template_path: /opt/my-app/templates
    umask: 0027

  # --- List of files to generate ---
  jobs:
    # JOB 1: USES CONVENTION
    # 'template' is not specified, so it is derived:
    # -> /opt/my-app/templates/app.properties.tpl
    - outfile: /etc/my-app/app.properties

    # JOB 2: USES CONVENTION
    # 'template' is derived:
    # -> /opt/my-app/templates/database.ini.tpl
    - outfile: /etc/my-app/database.ini

    # JOB 3: "ONE-OFF" (Overrides Globals)
    # This job overrides 'parameters' and 'template'
    # but still inherits 'umask' from globals.
    - parameters: /etc/my-app/nginx-config.json
      template: /opt/my-app/templates/special/nginx.conf.tpl
      outfile: /etc/nginx/sites-available/my-app.conf

=head1 PLUGINS

Plugins (or "protocol handlers") are the core feature of
C<Config::Resolver>. They allow you to fetch values from external
sources directly from within your templates or parameter files.

The script recognizes special value strings formatted as a URI:

  protocol://path/to/value

For example, to fetch a value from AWS SSM Parameter Store, you would use:

  ${ssm:///path/to/my/secret}

=head2 Built-in Backends

The resolver engine includes two built-in backends that are always
available and do not require any configuration:

=over 4

=item B<env://PATH>

Resolves the value from C<$ENV{PATH}>. This is the recommended
way to inject environment variables.

  ${env://USER}

=item B<file://PATH>

Resolves the value by reading the entire contents of the file at
C<PATH>. This is the recommended way to inject secrets, certificates,
or tokens when more advanced plugins (AWS SSM, AWS Secrets Manager,
etc) are not available.

  ${file:///var/run/secrets/token}

=back

=head2 Plugin Configuration

Many plugins, like C<ssm>, require configuration (e.g., the AWS
region, or a custom endpoint for local testing). You can provide this
configuration in two ways, which are layered:

=head3 1. The RC File (Defaults)

On startup, the script will attempt to load a configuration file from:

  $HOME/.config-resolverrc

This file (in JSON or YAML format) is the perfect place to set your
team- or user-wide defaults.

B<Example C<~/.config-resolverrc>:>

 {
   "ssm": {
     "region": "us-east-1",
     "endpoint_url": "http://localhost:4566"
   },
   "another_plugin": {
     "foo": "bar"
   }
 }

=head3 2. Command-Line Overrides (Specifics)

You can override or provide new settings for any plugin on the command
line using the C<--plugin:*> option. This is the top layer and will
*always* win over the RC file.

The syntax is:

  --plugin PROTOCOL:key=value

You can repeat the C<--plugin> option to build up the configuration.

B<Example:>

  config-resolver.pl \
      --plugin ssm:region=us-west-2 \
      --plugin ssm:endpoint_url=http://localhost:4566 \
      -t my-template.tpl

The script merges these two sources, giving command-line options final
priority, and passes the result to the resolver engine.

=head2 Plugin "Setup-Only" Execution Mode

This script does not have a default command (like C<resolve> or C<dump>).
This intentional design enables a powerful "init-only" workflow for plugins
that need to perform on-demand setup or initialization tasks.

If you run C<config-resolver.pl> *without* a command, it will:

=over 4

=item Execute its full initialization phase (parsing all CLI args,
loading plugins, and running their C<new()> or C<init()> methods).

=item Proceed to the C<run()> phase, find no command, and exit cleanly.

=back

This allows you to add features to your plugin's C<init()> method
that are triggered by a specific CLI flag. This is the recommended
pattern for tasks like seeding a local datastore (e.g., LocalStack) or
performing a one-time authentication.

=head3 Recipe for a Plugin "Init-Task"

Follow this 3-step recipe to add an on-demand setup task to your
plugin.

=over 4

=item 1. Define Configuration Keys

In your plugin's documentation, define the keys a user must set in
their C<.config-resolverrc> file .

  # In .config-resolverrc
  [plugin ssm]
    endpoint_url = http://localhost:4566
    
    # --- Keys for your one-time setup ---
    seed_file = /opt/my-app/localstack-seed.json
    load_on_init = false # <-- Default to false!

=item 2. Add Logic to Your Plugin's C<new()>

In your plugin's C<new()> constructor, check for your flag.

  # In lib/Config/Resolver/Plugin/SSM.pm
  sub new {
      my ($class, $options) = @_;
      my $self = $class->SUPER::new($options);

      # --- This is the "on-demand" hook ---
      if ( my $seed_file = $self->get_load_on_init ) {
          print {*STDERR} "Seeding SSM from $seed_file...\n";
          $self->load_data_from_file( $seed_file );
      }
      # --- End of hook ---

      return $self;
  }

=item 3. Document the User's Command

Finally, document the command the user must run. Because the CLI 
flag trumps the config file , this single command
will trigger your logic:

  # Triggers the one-time setup:
  $ config-resolver.pl --plugins SSM --plugin ssm:load_on_init=true

B<How This Works:> The script runs, but no command (like C<resolve>)
is given. The C<init()> phase runs, loading your plugin. The
C<--plugin> flag overrides the config file, setting C<load_on_init> to
true. Your C<new()> method fires, sees the flag, and runs your setup
logic. The script then exits cleanly because no command was specified.

=back

This workflow is fully compatible with STDIN. If your plugin's C<init()>
task reads from STDIN (e.g., C<ssm:load=-_>), C<config-resolver.pl> will
politely detect that the STDIN stream has already been consumed and
will not attempt to read from it again.

=head1 AUTHOR

Rob Lauer - <rclauer@gmail.com>

=head1 SEE ALSO 

L<Config::Resolver>, L<Config::Resolver::Plugin::SSM>, L<Config::Resolver::Plugin::SecretsManager>
