package Amazon::API::Help;

use strict;
use warnings;

use Amazon::API::BuildInfo;
use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(slurp slurp_json choose);
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::ShareDir qw(dist_file dist_dir);
use IO::Uncompress::Gunzip qw(gunzip);
use List::Util qw(max none);
use Pod::HTML2Pod;
use Pod::Text;
use Storable qw(retrieve);
use Template;

use parent qw(CLI::Simple);

our $VERSION = '1.0.3';

caller or exit __PACKAGE__->main();

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my $command = $self->command;

  if ( none { $command eq $_ } keys %{ $self->commands } ) {
    $self->set_args( [ $command, $self->get_args ] );
    $self->command('help');
  }

  if ( $self->command eq 'help' ) {

    my @candidates = ( 'botocore-services.api.gz', dist_file( 'Amazon-API-Help', 'botocore-services.api.gz' ) );

    my ($services_file) = grep { defined $_ && -e $_ } @candidates;

    my $services;
    gunzip( $services_file, \$services );

    my $service_meta = retrieve( \$services );

    $self->set_services($service_meta);
  }

  my $version = Amazon::API::BuildInfo->version();

  my $botocore_version = $version->{botocore_version};

  $self->set_version($version);

  $self->set_provenance(
    { version => $botocore_version->{version} // 'unknown',
      commit  => $botocore_version->{commit}  // 'unknown'
    }
  );

  return;
}

########################################################################
sub cmd_help {
########################################################################
  my ( $self, $init_flag ) = @_;

  if ( $self->get_help ) {
    $self->usage();
  }

  return
    if $init_flag;

  my ( $service_name, $method_or_shape ) = $self->get_args;

  if ($service_name) {
    my $service_meta = $self->get_services->{$service_name}
      or die "ERROR: no such service '$service_name'\n";

    if ($method_or_shape) {
      my $meta = $service_meta->{metadata};

      if ( $self->get_shape ) {
        return $self->_shape_help( $service_name, $service_meta, $method_or_shape )
          if $meta->{shapes}{$method_or_shape};

        if ( $meta->{operations}{$method_or_shape} ) {
          die "ERROR: no shape '$method_or_shape'. If you meant the operation '$method_or_shape' drop --shape\n";
        }
        else {
          die "ERROR: no shape '$method_or_shape' in service '$service_name'\n";
        }
      }

      return $self->_operation_help( $service_name, $service_meta, $method_or_shape )
        if $meta->{operations}{$method_or_shape};

      return $self->_shape_help( $service_name, $service_meta, $method_or_shape )
        if $meta->{shapes}{$method_or_shape};

      die "ERROR: '$method_or_shape' is not an operation or shape in service '$service_name'\n";
    }

    return $self->_service_help( $service_meta, $service_name );
  }

  my $all = $self->get_services;

  $self->_show_pod(
    template => 'all-services.tt',
    stash    => {
      services => [ sort keys %{$all} ],
      modules  => [ sort map { $all->{$_}{metadata}{metadata}{perl_module_name} // '(unresolved)' } keys %{$all} ],
    },
  );

  return $SUCCESS;
}

########################################################################
sub _operation_help {
########################################################################
  my ( $self, $service, $service_meta, $operation_name ) = @_;

  my $meta      = $service_meta->{metadata};
  my $operation = $meta->{operations}{$operation_name}
    or die "ERROR: no such operation '$operation_name' in service '$service'\n";

  my $shapes = $meta->{shapes};

  my $input_shape  = $operation->{input}  ? $operation->{input}{shape}  : undef;
  my $output_shape = $operation->{output} ? $operation->{output}{shape} : undef;

  my $input_members  = $input_shape  ? ( $shapes->{$input_shape}{members}  // {} ) : {};
  my $output_members = $output_shape ? ( $shapes->{$output_shape}{members} // {} ) : {};

  my @errors;

  foreach my $e ( @{ $operation->{errors} // [] } ) {
    my $name   = $e->{shape};
    my $eshape = $shapes->{$name} // {};
    my $detail = $eshape->{error};

    push @errors,
      {
      name          => $name,
      documentation => $eshape->{documentation} // $EMPTY,
      detail        => $detail
      ? [ map { { key => $_, value => $detail->{$_} } } sort keys %{$detail} ]
      : [],
      };
  }

  my %seen;
  my @see_also = sort grep { !$seen{$_}++ }
    grep {defined} ( $input_shape, $output_shape, map { $_->{shape} } @{ $operation->{errors} // [] } );

  my $http = $operation->{http} // {};
  $_->{documentation} //= $EMPTY for values %{$input_members}, values %{$output_members};

  $self->_show_pod(
    template => 'operation.tt',
    stash    => {
      service        => $service,
      method         => $operation_name,
      documentation  => $operation->{documentation} // $EMPTY,
      input_members  => $input_members,
      output_members => $output_members,
      errors         => \@errors,
      http_method    => $http->{method}     // $EMPTY,
      request_uri    => $http->{requestUri} // $EMPTY,
      see_also       => \@see_also,
      provenance     => $self->get_provenance,
      package_name   => $meta->{metadata}{perl_module_name} // '(unresolved)',
    },
  );

  return $SUCCESS;
}

########################################################################
sub _shape_help {
########################################################################
  my ( $self, $service, $service_meta, $shape_name ) = @_;

  my $shape = $service_meta->{metadata}{shapes}{$shape_name}
    or die "ERROR: no such shape '$shape_name' in service '$service'\n";

  my %seen;
  my @see_also
    = sort grep { !$seen{$_}++ } ( $shape->{members} ? map { $shape->{members}{$_}{shape} } keys %{ $shape->{members} } : () ),
    ( $shape->{member} ? $shape->{member}{shape} : () ),
    ( $shape->{key}    ? $shape->{key}{shape}    : () ),
    ( $shape->{value}  ? $shape->{value}{shape}  : () );

  my @limits = map { { key => $_, value => $shape->{$_} } }
    grep { defined $shape->{$_} } qw(min max pattern);

  my $is_structure  = ( $shape->{type} // $EMPTY ) eq 'structure';
  my $show_synopsis = $is_structure && !( $shape->{members} && $shape->{members}{message} );

  $shape->{documentation} //= $EMPTY;
  $shape->{members}       //= {} if $is_structure;
  $_->{documentation}     //= $EMPTY for values %{ $shape->{members} // {} };

  $self->_show_pod(
    template => 'shape.tt',
    stash    => {
      class         => sprintf( 'Amazon::API::Botocore::Shape::%s::%s', $service, $shape_name ),
      lc_name       => snake_case($shape_name),
      service       => $service,
      shape         => $shape,
      limits        => \@limits,
      see_also      => \@see_also,
      provenance    => $self->get_provenance,
      show_synopsis => $show_synopsis,
      enum          => [ @{ $shape->{enum} // [] } ],
    },
  );

  return $SUCCESS;
}

########################################################################
sub _service_help {
########################################################################
  my ( $self, $service_meta, $service ) = @_;

  $self->_show_pod(
    template => 'service.tt',
    stash    => {
      service          => $service,
      documentation    => $service_meta->{metadata}{documentation} // $EMPTY,
      operations       => [ sort keys %{ $service_meta->{metadata}{operations} } ],
      botocore_version => $self->get_provenance->{version},
    },
  );

  return $SUCCESS;
}

########################################################################
sub snake_case {
########################################################################
  my ($name) = @_;

  while ( $name =~ s/([[:upper:]])([[:lower:]])/lc("_$1").$2/xsme ) { }

  $name =~ s/^_//xsm;
  $name =~ s/([[:lower:]])([[:upper:]])/$1_$2/gxsm;

  return $name;
}

########################################################################
sub _html2pod {
########################################################################
  my ($html) = @_;

  my $pod = Pod::HTML2Pod::convert(
    a_href  => $TRUE,
    a_name  => $TRUE,
    content => $html // $EMPTY,
  );

  $pod =~ s/^=pod//xsm;
  $pod =~ s/^=cut//xsm;
  $pod =~ s/^[#].*$//gxsm;

  $pod =~ s/\A\s+//xsm;  # template owns leading/trailing blank lines
  $pod =~ s/\s+\z//xsm;

  return $pod;
}

########################################################################
sub _show_pod {
########################################################################
  my ( $self, %args ) = @_;

  my $tt = $self->_template_engine;

  my $pod = $EMPTY;

  $tt->process( $args{template}, $args{stash}, \$pod )
    or die sprintf "ERROR: rendering %s: %s\n", $args{template}, $tt->error;

  my $paged;

  if ( $self->get_cli_pager ) {
    $paged = eval {
      require IO::Pager;
      IO::Pager::open( *STDOUT, '|-:utf8', 'Unbuffered' );
      return $TRUE;
    };
  }

  binmode STDOUT, ':encoding(UTF-8)'
    if !$paged;

  Pod::Text->new->parse_string_document($pod);

  return;
}

########################################################################
sub _template_engine {
########################################################################
  my ($self) = @_;

  my $tt = $self->get_tt;

  return $tt
    if $tt;

  $tt = Template->new(
    { INCLUDE_PATH => [ dist_dir('Amazon-API-Help') ],
      STRICT       => $TRUE,
      ENCODING     => 'utf8',
      FILTERS      => { html2pod => \&_html2pod },
    }
  ) or die sprintf "ERROR: could not create template engine: %s\n", Template->error;

  $self->set_tt($tt);

  return $tt;
}

########################################################################
sub cmd_dump_service {
########################################################################
  my ($self) = @_;

  my ($service) = $self->get_args;

  die "ERROR: usage dump-service service-name\n"
    if !$service;

  my $service_meta = $self->get_services->{$service};

  die "ERROR: no such service '$service'\n"
    if !$service_meta;

  print {*STDOUT} JSON->new->pretty->encode($service_meta);

  return $SUCCESS;
}

########################################################################
sub cmd_version {
########################################################################
  my ($self) = @_;

  my $version = Amazon::API::BuildInfo->version();

  require Text::ASCIITable;

  my $t = Text::ASCIITable->new( { headingText => 'Amazon::API Version Info' } );

  $t->setCols( q{}, qw(Version Commit) );
  $t->addRow( 'Amazon::API', $version->{version},                     $version->{commit} );
  $t->addRow( 'Botocore',    $version->{botocore_version}->{version}, $version->{botocore_version}->{commit} );

  print {*STDOUT} $t;

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################
  my %commands = (
    'dump-service' => \&cmd_dump_service,
    'help'         => \&cmd_help,
    'version'      => \&cmd_version,
    'default'      => 'help',
  );

  my @option_specs = qw(
    help|h
    cli-pager!
    shape
  );

  my $cli = __PACKAGE__->new(
    commands         => \%commands,
    option_specs     => \@option_specs,
    extra_options    => [qw(services tt provenance version)],
    default_options  => { cli_pager => 1 },
    validate_command => $FALSE,
  );

  return $cli->run();
}

1;

__END__

=pod

=head1 NAME

amzn-api-help - Help for AWS services and types

=head1 DESCRIPTION

C<amzn-api-help> renders documentation for AWS services, their
operations, and their data types (shapes) on demand, for developers
working with L<Amazon::API>. It answers the questions you hit while
writing API calls: what operations a service exposes, what parameters
an operation takes and returns, what errors it can raise, and what a
given shape looks like.

The documentation is generated from the same Botocore metadata the
L<Amazon::API> classes are built from, pinned to the Botocore version
recorded in L<Amazon::API::BuildInfo> and shown at the foot of each
page. This matters: it is the one description of the request and
response shapes guaranteed to match what L<Amazon::API> actually
sends and expects. You can approximate the same information by reading
C<aws SERVICE OPERATION help> from the AWS CLI, but those shapes are
the CLI's own rendering of Botocore -- close, but not guaranteed to
line up with the shape names and structures L<Amazon::API> uses, or
with the Botocore version it was built against.

Within a service, B<operations> are the callable actions (for example
C<ListQueues>) and B<shapes> are the data types those operations send
and receive (for example C<ListQueuesRequest>, or reusable types like
C<Arn>). Operations reference shapes; the same shape may be reached
through several operations. When a name exists as both an operation
and a shape, the operation takes precedence -- use C<--shape> to ask
for the shape instead.

Documentation is paged through your default pager unless
C<--no-cli-pager> is given.

=head2 Design: Documentation Lives Here, Not in the Runtime

The other Perl AWS SDK, L<Paws>, takes the opposite approach, and the
contrast is the reason this tool exists as a separate install. Paws
renders POD into every generated class and builds on L<Moose>, so both
the documentation and the meta-object protocol are compiled into the
runtime whether or not they are used. C<Amazon::API> installs neither:
its generated classes are lean stubs carrying only the metadata slice
they need to make calls, and the documentation lives here, in a
developer tool you install only if you want it. The result is a
smaller install and a faster cold start -- Paws itself notes its
objects must be immutabilized "at the cost of startup time".

=head1 USAGE

=head2 Commands

=over 4

=item help

 amzn-api-help help service type|operation

=over 8

=item * Get a list of all services

 amzn-api-help help

I<Note: 'help' is optional in all examples. C<amzn-api-help sts> is also valid for example.>

=item * Get a list of all operations for a service

 amzn-api-help help sqs

=item * Get documentation for an operation

 amzn-api-help help sqs ListQueues

=item * Get documention for a type or shape

 amzn-api-help help sqs ListQueuesRequest

=back

=item dump-service

Dump service metadata as JSON.

 amzn-api-help dump-service sts

=item version

Display the L<Amazon::API> and Botocore versions.

=back

=head2 Options

 --help, -h       This help
 --shape          Force shape lookup precendence.
 --no-cli-pager   Disable use of pager.

=head1 VERSION

This documentation refers to version 1.0.3

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO

L<Amazon::API>

=cut
