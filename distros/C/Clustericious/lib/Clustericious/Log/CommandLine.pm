package Clustericious::Log::CommandLine;

use warnings;
use strict;
use Log::Log4perl qw(get_logger :levels);
use Getopt::Long;

# ABSTRACT: Simple Command Line Interface for Log4perl
our $VERSION = '1.27'; # VERSION


my %init;     # logconfig, loginit, logfile, logcategory, noinit
my %options;  # options set on command line

my %levelmap =
(
  q => 'off',
  quiet => 'off',
  v => 'info',
  verbose => 'info',
  d => 'debug'
);

sub import
{
  my $class = shift;

  my $caller = caller;

  my @getoptlist;
  my $next;
  foreach (@_)
  {
    if ($next)
    {
      $init{$next} = $_;
      $next = undef;
      next;
    }

    /^:(log(?:config|file|init|category))$/ and $next = $1; # Grab next arg

    /^(?:trace|:levels|:all)$/ and push(@getoptlist, 'trace:s@');
    /^(?:debug|:levels|:all)$/ and push(@getoptlist, 'debug:s@');
    /^(?:info|:levels|:all)$/  and push(@getoptlist, 'info:s@');
    /^(?:warn|:levels|:all)$/  and push(@getoptlist, 'warn:s@');
    /^(?:error|:levels|:all)$/ and push(@getoptlist, 'error:s@');
    /^(?:fatal|:levels|:all)$/ and push(@getoptlist, 'fatal:s@');
    /^(?:off|:levels|:all)$/   and push(@getoptlist, 'off:s@');

    /^(?:quiet|:long|:all)$/   and push(@getoptlist, 'quiet:s@');
    /^(?:verbose|:long|:all)$/ and push(@getoptlist, 'verbose:s@');

    /^(?:q|:short|:all)$/      and push(@getoptlist, 'q:s@');
    /^(?:v|:short|:all)$/      and push(@getoptlist, 'v:s@');
    /^(?:d|:short|:all)$/      and push(@getoptlist, 'd:s@');

    /^(?:loglevel|:logopts|:all)$/ and push(@getoptlist, 'loglevel:s@');

    /^(?:logconfig|:logopts|:all)$/ and
      push(@getoptlist, 'logconfig=s' => \$init{logconfig});

    /^(?:logfile|:logopts|:all)$/ and
      push(@getoptlist, 'logfile=s' => \$init{logfile});

    { no strict 'refs';
      /^handlelogoptions$/ and
        *{"$caller\::handlelogoptions"} = *handlelogoptions;
    }

    /^:noinit$/ and $init{noinit} = 1;
  }

  my $getopt = Getopt::Long::Parser->new
         ( config => [qw(pass_through no_auto_abbrev
                 no_ignore_case)] );

  $getopt->getoptions(\%options, @getoptlist);

  # Allow: --option --option foo --option foo,bar
  while (my ($opt, $cats) = each %options)
  {
    $options{$opt} = [ map { length $_ ? split(',') : '' } @$cats ];
  }

  # --loglevel category=level or --loglevel level
  foreach (@{$options{loglevel}})
  {
    my ($category, $level) = /^([^=]*?)=?([^=]+)$/;
    push(@{$options{$level}}, $category);
  }
  delete $options{loglevel};
}

no warnings;
INIT
{
  use warnings;
  return if $init{noinit};

  if (defined $init{logconfig} and -f $init{logconfig} and -r _)
  {
    Log::Log4perl->init($init{logconfig});
  }
  else
  {
    if ($init{loginit} and not ref $init{loginit})
    {
      Log::Log4perl->init(\$init{loginit});
    }
    elsif ($init{loginit} and ref $init{loginit} eq 'ARRAY')
    {
      Log::Log4perl->easy_init(@{$init{loginit}});
    }
    else
    {
      my $init = ref $init{loginit} eq 'HASH' ? $init{loginit} : {};

      $init->{level} ||= $ERROR;
      $init->{layout} ||= '[%-5p] %m%n';

      Log::Log4perl->easy_init($init);
    }
  }

  handlelogoptions();
}
use warnings;


sub handlelogoptions
{
  if ($init{logfile})
  {
    my $logfile = $init{logfile};
    my $layout = '%d %c %m%n';

    if ($logfile =~ s/\|(.*)$//)   # "logfilename|logpattern"
    {
      $layout = $1;
    }

    my $file_appender = Log::Log4perl::Appender->new(
                "Log::Log4perl::Appender::File",
                name => 'logfile',
                filename  => $logfile);

    $file_appender->layout(Log::Log4perl::Layout::PatternLayout->new(
                 $layout));

    get_logger('')->add_appender($file_appender);
  }

  while (my ($level, $vals) = each %options)
  {
    $level = $levelmap{$level} if exists $levelmap{$level};

    my $level_id = Log::Log4perl::Level::to_priority(uc $level);

    foreach my $category (@$vals)
    {
      if ($category eq '')
      {
        $category = defined($init{logcategory})
              ? $init{logcategory}
              : $level_id >= $INFO ? '' : 'main';
      }

      $category = '' if $category eq 'root';

      get_logger($category)->level($level_id);
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Log::CommandLine - Simple Command Line Interface for Log4perl

=head1 VERSION

version 1.27

=head1 SYNOPSIS

 use Clustericious::Log::CommandLine;

=head1 DESCRIPTION

This is a fork of L<Log::Log4perl::CommandLine> used internally by
L<Clustericious>.  This module is used for legacy purposes and may
be removed in the future, so do not use or depend on it.

=head1 FUNCTIONS

=head2 handlelogoptions

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
