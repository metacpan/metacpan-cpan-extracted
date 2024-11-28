#!/usr/bin/env perl

# Script for exercising Amazon::SQS examples.

use strict;
use warnings;

use Amazon::SQS::Sample;
use Data::Dumper;
use English qw(-no_match_vars);
use Carp qw(carp croak);
use Pod::Usage;
use Module::Load qw(load);

use Getopt::Long qw(:config no_ignore_case);

########################################################################
sub main {
########################################################################
  my %options;

  my @option_specs = qw(
    file|f=s
    help|h
    endpoint-url|e=s
    debug|d
  );

  my $retval = GetOptions( \%options, @option_specs );

  if ( !$retval || ( $options{help} && !@ARGV ) ) {
    pod2usage(1);
  }

  my $example = shift @ARGV;

  load $example;

  my $sample = $example->new( \%options );

  if ( $options{help} ) {
    $sample->help();
  }

  eval { $sample->sample(@ARGV); };

  $sample->check_error($EVAL_ERROR);

  return 0
    if !$options{debug};

  print {*STDERR} Dumper(
    [ request     => $sample->get_service->get_last_request,
      response    => $sample->get_service->get_last_response,
      credentials => $sample->get_service->get_credentials,
    ]
  );

  return 0;
}

exit main();

1;

## no critic

__END__

=pod

=head1 NAME

example.pl

=head1 USAGE

 example.pl -f config-name example args

=head1 OPTIONS

 --endpoint-url, -e  API endpoint, default: https://queue.amazonaws.com
 --file, -f          Name of a .ini configuration file
 --help, -h          help

=head2 Configuration File

Some examples may rely on values you must set in your .ini file.

See L<Amazon::SQS::Config> for the format of the .ini file.

=head2 AWS Credentials

You can set your credentials in the config file in the C<[aws]>
section or rely on the L<Amazon::Credentials> to find your credentials
in the environment.

=head2 Running the Examples

To get help for running a specific example:

 example.pl -h ListQueues

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=head1 SEE ALSO

L<Amazon::SQS::Client>

=cut
