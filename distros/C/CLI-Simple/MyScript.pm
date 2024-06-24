package MyScript;

use strict;
use warnings;

use lib 'src/main/perl/lib';

use Data::Dumper;

use CLI::Simple::Constants qw(:booleans);

use parent qw(CLI::Simple);

__PACKAGE__->use_log4perl( level => 'info' );

caller or __PACKAGE__->main();

########################################################################
sub foo {
########################################################################
  my ($self) = @_;

  my %args = $self->get_args(qw(arg1 arg2));

  $self->get_logger->debug(
    Dumper(
      [ args      => \%args,
        log_level => $self->get_log_level,
        foo       => $self->get_foo,
        bar       => $self->get_bar
      ]
    )
  );

  return $SUCCESS;
}

########################################################################
sub bar {
########################################################################
  my ($self) = @_;

  my %args = $self->get_args(qw(arg1 arg2));

  $self->get_logger->debug(
    Dumper(
      [ args      => \%args,
        log_level => $self->get_log_level,
        foo       => $self->get_foo,
        bar       => $self->get_bar
      ]
    )
  );

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################
  return __PACKAGE__->new(
    option_specs => [
      qw(
        foo=s
        bar
        help|h
      )
    ],
    commands => {
      bar => \&bar,
      foo => \&foo,
    },
  )->run;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 USAGE

  myscript.pm [options] command args
 
 Options           Description
 -------           -----------
 --help, -h        usage
 --log-level, -l   logging level (trace, ebug, info, warn, error), default: info
 --foo, -f         foo name
 --bar, -b         turn bar on/off (use --no-bar for off), default: on
 
 Commands       Arguments
 --------       ---------
 help
 foo            arg1, arg2
 bar            arg1, arg2
 
 Recipes
 -------
 1. Execute the foo command 
 
    perl myscript.pm -l debug foo biz buz
 
 2. Execute the bar commaand
 
    perl myscript.pm bar
 
=cut
