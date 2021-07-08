# -*- mode: cperl; eval: (follow-mode) -*-
#

package App::gqmt;

use strict;
use warnings;
use diagnostics;

use Data::Printer caller_info => 1, print_escapes => 1, output => 'stdout', class => { expand => 2 },
  caller_message => "DEBUG __FILENAME__:__LINE__ ";
use Getopt::Long  qw(:config no_ignore_case gnu_getopt auto_help auto_version);
use Pod::Man;
use Pod::Usage    qw(pod2usage);
use File::Basename;
use HTTP::Request ();
use LWP::UserAgent;
use JSON;
use Time::Piece;
use Template;

my  @PROGARG = ($0, @ARGV);
our $VERSION = '1.02';

sub new {
  my $class = shift;
  my $self =
    bless {
	   _progname => fileparse($0),
	   _progargs => [$0, @ARGV],
	   _option   => { d                => 0,
			  colored          => 0,
			  rows_number      => 100,
			  age              => 60*60*24*14,
			  versions_to_hold => 2,
			  url              => 'https://api.github.com/graphql',
			  single_iteration => 0,
			  http_timeout     => 180,
			  pkg         => {
					  alpine    => 1,
					  api       => 1,
					  app       => 1,
					  scheduler => 1,
					 },
			  re          =>  {
					   default   => '^(?:docker-base-layer|develop|release|master|v[0-9]+\.[0-9]+\.[0-9]+)$',
					   alpine    => '^(?:docker-base-layer|develop|release|master|v[0-9]+\.[0-9]+\.[0-9]+)$',
					   api       => '^(?:docker-base-layer|develop|release|master|v[0-9]+\.[0-9]+\.[0-9]+)$',
					   app       => '^(?:docker-base-layer|develop|qa|release|master|v[0-9]+\.[0-9]+\.[0-9]+)$',
					   scheduler => '^(?:docker-base-layer|develop|release|master|v[0-9]+\.[0-9]+\.[0-9]+)$',
					  },
			},
	  }, $class;

  GetOptions (
	      'a|age=i'             => \$self->{_option}{age},
	      'U|url=s'             => \$self->{_option}{url},
	      'u|user=s'            => \$self->{_option}{user},
	      'T|token=s'           => \$self->{_option}{token},
	      'R|repository=s'      => \$self->{_option}{repo},
	      'P|package=s'         => \$self->{_option}{package},
	      'package-regex=s'     => \$self->{_option}{package_regex},
	      'n|dry-run'           => \$self->{_option}{dry_run},
	      'N|rows-number=i'     => \$self->{_option}{rows_number},
	      'versions-to-hold=i'  => \$self->{_option}{versions_to_hold},
	      'http-timeout=i'      => \$self->{_option}{http_timeout},
	      'C|colored'           => \$self->{_option}{colored},
	      'D|delete'            => \$self->{_option}{delete},
	      's|single-iteration'  => \$self->{_option}{single_iteration},
	      't|query-template=s'  => \$self->{_option}{query_template},
	      'v|package-version=s' => \$self->{_option}{v},

	      'h|help'              => sub { pod2usage(-exitval => 0, -verbose => 2); exit 0 },
	      'd|debug+'            => \$self->{_option}{d},
	      'V|version'           => sub { print "$self->{_progname}, version $VERSION\n"; exit 0 },
	     );

  pod2usage(-exitval => 0, -verbose => 2, -msg => "\nERROR: repository owner not provided, option -u\n\n")
    if ! $self->{_option}{user};

  pod2usage(-exitval => 0, -verbose => 2, -msg => "\nERROR: query template file does not exist, option -t\n\n")
    if defined $self->{_option}{query_template} && ! -e $self->{_option}{query_template};

  pod2usage(-exitval => 2, -verbose => 2, -msg => "\nERROR: access token is not provided, option -T\n\n" )
    if ! $self->{_option}{token};

  pod2usage(-exitval => 2, -verbose => 2, -msg => "\nERROR: repository name is not provided, option -R\n\n" )
    if ! $self->{_option}{repo};

  pod2usage(-exitval => 2, -verbose => 2, -msg => "\nERROR: package name not provided, option -P\n\n")
    if ! $self->{_option}{package};

  # pod2usage(-exitval => 2, -verbose => 2, -msg => "\nERROR: not supported package\n\n")
  #   if $self->{_option}{package} && ! exists $self->{_option}{pkg}{$self->{_option}{package}};

  pod2usage(-exitval => 2, -verbose => 2, -msg => "\nERROR: requested rows number should be 1..100\n\n")
    if $self->{_option}{rows_number} && ( $self->{_option}{rows_number} < 1 || $self->{_option}{rows_number} > 100 );

  # pod2usage(-exitval => 0, -verbose => 2, -msg => "\nERROR: -v is mandatory when -D and -s are used together\n\n")
  #   if $delete && $single_iteration && ! $v;

  p $self->{_option} if $self->{_option}{d} > 2;

  $self->{_option}{req} = HTTP::Request->new( 'POST',
					      $self->{_option}{url},
					      [ 'Authorization' => 'bearer ' . $self->{_option}{token} ] );

  return $self;
}

sub progname { shift->{_progname} }
sub progargs { return join(' ', @{shift->{_progargs}}); }

sub option {
  my ($self,$opt) = @_;
  return $self->{_option}{$opt};
}

sub lwp {
  my $self = shift;
  my $lwp = LWP::UserAgent->new( agent   => "$self->{_progname}/$VERSION ",
				 timeout => $self->option('http_timeout'), );
  return $lwp;
}

sub jso {
  my $self = shift;
  my $jso = JSON->new->allow_nonref;
  return $jso;
}

sub run {
  my $self = shift;
  my $versions = [];

  p ( $self->progargs, colored => $self->option('colored') ) if $self->option('d') > 0;
  
  my $to_delete;
  if ( ! $self->option('v') ) {

    my $res = $self->get_versions ({ res => $versions });

    my $t_now = localtime;
    my $t_ver;
    # my $i = 0;
    my $re;
    if ( $self->option('package_regex') ) {
      $re = $self->option('package_regex');
    } elsif ( exists $self->option('re')->{$self->option('package')} ) {
      $re = $self->option('re')->{$self->option('package')}
    } else {
      $re = $self->option('re')->{default};
    }
    
    foreach ( @{$versions} ) {
      next if $_->{version} =~ /$re/;
      p ($_, caller_message => "VERSION DOES NOT MATCH REGEX ($re) AND IS BEEN PROCESSED: __FILENAME__:__LINE__ ") if $self->option('d') > 2;

      if ( defined $_->{files}->{nodes}->[0]->{updatedAt} ) {
	$t_ver = Time::Piece->strptime( $_->{files}->{nodes}->[0]->{updatedAt},
					"%Y-%m-%dT%H:%M:%SZ" );

	next if ($t_ver->epoch + $self->option('age') ) >= $t_now->epoch;
      }

      # $to_delete->{ defined $_->{files}->{nodes}->[0]->{updatedAt} ?
      # 		$_->{files}->{nodes}->[0]->{updatedAt} : sprintf('NODATE_%04d', $i++) } = $_->{version};

      $to_delete->{ $_->{id} } = { version => $_->{version},
				   ts      => $_->{files}->{nodes}->[0]->{updatedAt} };
    }
  } else {
    $to_delete->{ $self->option('v') } = { version => 'STUB VERSION',
					   ts      => 'STUB TS' };
  }

  p ($to_delete, caller_message => "VERSIONS TO DELETE: __FILENAME__:__LINE__ ") if $self->option('d') > 2;

  if ( $self->option('delete') && defined $to_delete &&
       scalar(keys(%{$to_delete})) gt $self->option('versions_to_hold') ) {
    $self->del_versions ({
			  del => $to_delete,
			  # dbg => $self->option('d'),
			  # dry => $self->option('dry_run')
			 });

  } elsif ( $self->option('delete') && !defined $to_delete ) {
    print "nothing to delete\n";
  } else {
    # p ( $versions, colored => $self->option('colored') ) if $self->option('d') > 2 || $self->option('dry_run');
    my @vers_arr = map {
      sprintf("%30s\t%20s\t%s\n",
	      $_->{version},
	      scalar @{$_->{files}->{nodes}} > 0 && exists $_->{files}->{nodes}->[0]->{updatedAt}
	      ? $_->{files}->{nodes}->[0]->{updatedAt} : '',
	      $_->{id}
	     )
    } @{$versions};
    print "Versions of package \"", $self->option('package'), "\":\n\n", join('', @vers_arr);
  }
}


sub del_versions {
  my ($self, $args) = @_;
  my $arg  = {
	      del => $args->{del} // [],  # array of IDs to delete
	     };

  p ($arg->{del}, caller_message => "VERSIONS TO DELETE: __FILENAME__:__LINE__ ") if $self->option('d') > 2;

  $self->option('req')->header(Accept => 'application/vnd.github.package-deletes-preview+json');

  my $query;

  foreach ( keys( %{$arg->{del}} ) ) {
    $query = sprintf('mutation { deletePackageVersion(input:{packageVersionId:"%s"}) { success }}', $_);

    p ( $query, colored => $self->option('colored') ) if $self->option('d') > 1 || $self->option('dry_run');
    next if $self->option('dry_run');

    $self->option('req')->content( $self->jso->encode({ query => $query }) );

    my $res = $self->lwp->request($self->option('req'));

    if ( ! $res->is_success ) {
      my $res_cont  = $self->jso->decode( $res->content );
      my $res_error = sprintf("--- ERROR ---\n\n%s\n\nMessage: %s\n    doc: %s\n\n",
			      $res->status_line,
			      $res_cont->{message},
			      $res_cont->{documentation_url} );
      print $res_error;
      exit 1;
    }

    my $reply = $self->jso->decode( $res->decoded_content );

    if ( exists $reply->{errors} ) {
      unshift @{$reply->{errors}}, "--- ERROR ---";
      p ( $reply->{errors}, colored => $self->option('colored') );
      exit 1;
    }

    p ( $reply, colored => $self->option('colored') );
    print "package of version ID: $_, has been successfully deleted\n" if $self->option('d') > 0;

  }

}


sub get_versions {
  my ($self, $args) = @_;
  my $arg  = {
	      res => $args->{res},	  # result
	      inf => $args->{inf} // {    # pageInfo
				      startCursor     => undef,
				      endCursor       => undef,
				      hasNextPage     => -1,
				      hasPreviousPage => -1
				     }
	     };

  my $query;
  if ( defined $self->option('query_template') ) {
    my $tt_out;
    my $tt = Template->new( ABSOLUTE => 1,
			    RELATIVE => 1 ) || die Template->error(), "\n";

    $tt->process(
		 $self->option('query_template'),
		 {
		  repo     => $self->option('repo'),
		  user     => $self->option('user'),
		  pkg_num  => $self->option('rows_number'),
		  pkg_name => $self->option('package'),
		  vers_num => $self->option('rows_number'),
		  cursor   => $arg->{inf}->{hasPreviousPage} == 1 ? sprintf(', before: "%s"', $arg->{inf}->{startCursor}) : ''
		 },
		 \$tt_out
		);
    $query = { query => $tt_out };

  } else {
    $query = $self->
      query_default({ inf => $arg->{inf}->{hasPreviousPage} == 1 ? sprintf(', before: "%s"', $arg->{inf}->{startCursor}) : ''});
  }

  p( $query->{query}, colored => $self->option('colored'), print_escapes => 0 )
    if $self->option('d') > 0 && ! defined $arg->{inf}->{startCursor};

  my $json = $self->jso->encode( $query );

  $self->option('req')->content( $json );

  my $res   = $self->lwp->request($self->option('req'));

  if ( ! $res->is_success ) {
    my $res_cont  = $self->jso->decode( $res->content );
    my $res_error = sprintf("--- ERROR ---\n\n%s\n\nMessage: %s\n    doc: %s\n\n",
			    $res->status_line,
			    $res_cont->{message},
			    $res_cont->{documentation_url} );
    print $res_error;
    exit 1;
  }

  my $reply = $self->jso->decode( $res->decoded_content );

  p ( $reply, caller_message => "REPLY: __FILENAME__:__LINE__ ", colored => $self->option('colored') )
    if $self->option('d') > 2 && ! defined $arg->{inf}->{startCursor};

  if ( exists $reply->{errors} ) {
    unshift @{$reply->{errors}}, "--- ERROR ---";
    p ( $reply->{errors}, colored => $self->option('colored') );
    exit 1;
  } elsif ( $reply->{data}->{repository}->{packages}->{nodes} ) {
    print "WARNING: not hardcoded package name \"", $self->option('package'), "\"\n"
      if $self->option('d') > 1;
  }

  push @{$arg->{res}}, @{$reply->{data}->{repository}->{packages}->{nodes}->[0]->{versions}->{nodes}};

  return 1 if $arg->{inf}->{hasPreviousPage} == 0 || $self->option('single_iteration') == 1;

  my $pageInfo = $reply->{data}->{repository}->{packages}->{nodes}->[0]->{versions}->{pageInfo};
  $self->get_versions ({
			res => $arg->{res},
			inf => {
				startCursor     => $pageInfo->{startCursor},
				endCursor       => $pageInfo->{endCursor},
				hasNextPage     => $self->jso->decode( $pageInfo->{hasNextPage} ),
				hasPreviousPage => $self->jso->decode( $pageInfo->{hasPreviousPage} ),
			       }
		       });

  return 0;
}


sub query_default {
  my ($self, $args) = @_;

  return {
	  query => sprintf('query { repository(name: "%s", owner: "%s") {
                               packages(first: %d names: ["%s"]) {
                                   nodes {
                                     id
                                     name
                                     versions(last: %d%s) {
                                       nodes {
                                         id
                                         version
                                         files(first:1, orderBy: {direction: DESC, field: CREATED_AT}) {
                                           totalCount
                                           nodes {
                                             updatedAt
                                             packageVersion {
                                               version
                                               id
                                             }
                                           }
                                         }
                                       }
                                       pageInfo {
                                         endCursor
                                         hasNextPage
                                         hasPreviousPage
                                         startCursor
                                       }
                                     }
                                   }
                                 }
                               }
                             }',
			   $self->option('repo'),
			   $self->option('user'),
			   $self->option('rows_number'),
			   $self->option('package'),
			   $self->option('rows_number'),
			   $args->{inf})
	 };
}

1;



