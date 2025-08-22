package MyScript;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;

use parent qw(CLI::Simple);

__PACKAGE__->use_log4perl( level => 'info' );

caller or __PACKAGE__->main();

########################################################################
sub foo {
########################################################################
  my ($self) = @_;

  my @args = $self->get_args;

  $self->get_logger->info(
    Dumper(
      [ args      => \@args,
        log_level => $self->get_log_level,
        foo       => $self->get_foo,
        bar       => $self->get_bar,
        command   => $self->command,
        biz       => $self->get_biz,
        buz       => $self->get_buz,
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

  $self->get_logger->info(
    Dumper(
      [ args      => \%args,
        log_level => $self->get_log_level,
        foo       => $self->get_foo,
        bar       => $self->get_bar,
        command   => $self->command,
        biz       => $self->get_biz,
        buz       => $self->get_buz,
      ]
    )
  );

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################

  my $app = __PACKAGE__->new(
    extra_options => [qw( biz buz)],
    option_specs  => [
      qw(
        foo|f=s
        bar|b
        help|h
      )
    ],
    commands => {
      bar => \&bar,
      foo => \&foo,
    },
    alias => { commands => { fu => 'foo' }, options => { fu => 'foo' } },
  );

  $app->set_biz('biz');
  $app->set_buz('buz');

  return $app->run();
}

1;

__END__

=pod

=head1 USAGE

 example.pl [options] command args

A minimal example of using CLI::Simple.

=head2 Options
 
 --help, -h        usage
 --log-level, -l   logging level (trace, ebug, info, warn, error), default: info
 --foo, -f         foo name
 --bar, -b         turn bar on/off (use --no-bar for off), default: on

=head2 Commands
 
 Commands       Arguments
 --------       ---------
 help
 foo            arg1, arg2
 bar            arg1, arg2

=head2 Recipes

=over 4

=item 1. Execute the foo command 

 perl myscript.pm -l debug foo biz buz
 
=item 2. Execute the bar commaand
 
 perl myscript.pm bar

=back

=cut
