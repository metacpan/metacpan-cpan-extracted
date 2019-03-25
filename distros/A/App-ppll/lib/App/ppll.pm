package App::ppll v0.0.1;      ## no critic [NamingConventions::Capitalization]

=encoding utf8

=head1 NAME

App::ppll - Command runner

=head1 VERSION

0.0.1

=head1 DESCRIPTION

C<ppll> is a tool to control the execution of commands. It can run commands in
parallel, construct commands from lists of parameters, and more.

It handles the output of commands and can prefix lines with which command
produced it, print timestamps, etc.

C<ppll> has functionality similar to C<xargs> and C<parallel>.

This page documents C<ppll>’s Perl API. For user documentation of the C<ppll>
command see L<ppll|ppll>.

=head1 SYNOPSIS

    my $ppll = App::ppll->new( %args );
    $ppll->call();

=cut

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Carp;
use DateTime;
use Digest::MD5 qw( md5 );
use English qw( -no_match_vars );
use Getopt::Long;
use List::Flatten qw( flat );
use List::Util qw( max shuffle );
use POSIX qw( isatty );
use Pod::Usage qw( pod2usage );
use Readonly;
use String::ShellQuote qw( shell_quote );
use Sys::CPU qw( cpu_count );
use Term::ANSIColor qw( colored );
use Term::ReadKey;
use Time::Duration qw( concise duration );
use Time::HiRes qw( time );

use experimental 'signatures';

require App::ppll::Worker;

Readonly my @COLOURS => (

  'white on_black',
  'black on_red',
  'black on_green',
  'black on_yellow',
  'white on_blue',
  'black on_magenta',
  'black on_cyan',
  'black on_white',
  'white on_bright_black',
  'black on_bright_red',
  'black on_bright_green',
  'black on_bright_yellow',
  'black on_bright_blue',
  'black on_bright_magenta',
  'black on_bright_cyan',
  'black on_bright_white',

);

Readonly my @MODES => ( qw(
    auto
    fields
    lines
    slpf
    ) );

Readonly my $WIDTH => 80;

=head1 SUBROUTINES/METHODS

=head2 C<call>

Runs C<ppll>.

Returns an integer suitable for C<exit> (0 if everything went fine, non-0
otherwise).

=cut

sub call ( $self ) {           ## no critic [Subroutines::ProhibitExcessComplexity]
  if ( $self->{help} ) {
    pod2usage(
      -exitval => 'NOEXIT',
      -output  => \*STDOUT,
      -verbose => 1,
    );
    return 0;
  }

  if ( $self->{version} ) {
    say $App::ppll::VERSION;
    return 0;
  }

  do {
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    $SIG{INT} = $SIG{TERM} = sub { $self->stop };
  };

  my $prefix_width
    = max( 1, map {length} grep {defined} flat( @{ $self->{parameters} } ) );

  $self->{pool} = [];

  my ( @failed, @succeeded );
  while ( @{ $self->{pool} } or @{ $self->{parameters} } ) {
    while ( @{ $self->{parameters} } and @{ $self->{pool} } < $self->{jobs} ) {
      my $queue = @{ $self->{parameters} }[0];

      unless ( @$queue ) {
        last
          if ( @{ $self->{pool} } );

        shift @{ $self->{parameters} };

        say STDERR $self->_coloured( '┄' x $self->_width, 'faint' )
          if @{ $self->{parameters} };

        next;
      }

      my $parameter = shift @{$queue};

      my $colour = defined $parameter ? _string_colour( $parameter ) : undef;

      my $prefix
        = defined $parameter
        ? $self->_coloured( sprintf( "% -${prefix_width}s", $parameter ),
        $colour )
        : undef;

      my @argv   = $self->_make_argv( $parameter );
      my $worker = App::ppll::Worker->new(
        argv      => \@argv,
        colour    => $colour,
        err       => $self->_printer( $prefix, '≫', *STDERR ),
        out       => $self->_printer( $prefix, '>', *STDOUT ),
        parameter => $parameter,
        prefix    => $prefix,
      );

      $worker->{err}->( _ps_four() . shell_quote( @argv ) );

      $worker->start;

      push @{ $self->{pool} }, $worker;
    } ## end while ( @{ $self->{parameters...}})

    for my $worker ( @{ $self->{pool} } ) {
      my $result = $worker->result;

      next
        unless defined $result;

      if ( $result == 0 ) {
        push @succeeded, $worker;

        $worker->{err}->( $self->_coloured( '✓', 'green' ) );
      } else {
        push @failed, $worker;

        $worker->{err}
          ->( $self->_coloured( sprintf( '❌ %d', $result ), 'red' ) );

        $self->stop
          unless ( $self->{force} );
      }
    }

    @{ $self->{pool} } = grep { not $_->{finished} } @{ $self->{pool} };
  } ## end while ( @{ $self->{pool} ...})

  my $ok
    = !@failed && ( ( @succeeded + @failed ) == $self->{total_parameters} );

  if ( $self->{summary} ) {
    say STDERR $self->_coloured( '━' x $self->_width, 'faint' );

    say STDERR $self->_coloured(
      sprintf(
        '%d/%d in %s, %d failed',
        ( @succeeded + @failed ),
        $self->{total_parameters},
        concise( duration( time - $BASETIME ) ),
        scalar @failed,
      ),
      $ok ? 'green' : 'red',
    );
    say STDERR $self->_coloured( '❌ ' . $_, 'red' ) for @failed;
  }

  return $ok ? 0 : 1;
} ## end sub call ( $self )

=head2 C<new( %args )>

Constucts a new C<App::ppll> object that represents an invocation of C<ppll>.
Does I<not> run anything, to do that use L<call|call>.

=head3 NAMED ARGUMENTS

=over

=item C<argv>

An array ref to use instead of C<@ARGV>.

=back

=cut

sub new ( $class, %args ) {    ## no critic [Subroutines::ProhibitExcessComplexity]
  my $self = bless {
    argv => $args{argv} // [@ARGV],
    mode => undef,
  }, $class;

  my $p = Getopt::Long::Parser->new(
    config => [ qw(
        bundling
        no_auto_abbrev
        no_getopt_compat
        no_ignore_case
        no_permute
        ) ] );

  $p->getoptionsfromarray(
    $self->{argv},

    'colour|color!' => \$self->{colour},

    'command|c=s' => \$self->{command},

    'delimiter|d=s' => \$self->{delimiter},

    'empty!' => \$self->{empty},

    'fields|f' => sub { $self->{mode} = 'fields' },

    'force|k!' => \$self->{force},

    'help|h|?' => \$self->{help},

    'jobs|j=o' => \$self->{jobs},

    'lines|l' => sub { $self->{mode} = 'lines' },

    'markers!' => \$self->{markers},

    'mode=s' => sub ( $opt, $val ) {
      croak sprintf( 'Unknown mode ‘%s’' )
        unless scalar grep { $val eq $_ } @MODES;

      $self->{mode} = $val;
    },

    'quiet|q' => sub { $self->{verbosity}-- },

    'random|R!' => \$self->{random},

    'replace-string|replstr|I=s' => \$self->{replstr},

    'reverse|r!' => \$self->{reverse},

    'sequence|s=s' => sub ( $opt, $val, @ ) {
      $self->_push_parameters( $self->_parse_sequence( $val ) );
    },

    'serial-lines-parallel-fields|slpf' => sub { $self->{mode} = 'slpf' },

    'summary|S!' => \$self->{summary},

    'timestamp-format=s' => \$self->{timestamp_format},

    'timestamps|t!' => sub ( $opt, $val, @ ) {
      $self->{timestamp_format} //= '%T.%3N'
        if $val;
    },

    'verbose|v' => sub { $self->{verbosity}++ },

    'version|V' => \$self->{version},

    )
    or pod2usage(
    -exitval => 2,
    -output  => \*STDERR,
    -verbose => 0,
    );

  return $self
    if $self->{help}
    or $self->{version};

  $self->{colour} //= isatty( *STDOUT );

  $self->{mode} //= 'fields'
    if $self->{delimiter};

  $self->{delimiter}
    //= '(?:'
    . join( '|', map {quotemeta} split( //, ( $ENV{IFS} // " \t\n" ) ) ) . ')+';

  $self->{jobs} //= cpu_count() // 1;

  if ( defined $self->{command} ) {
    $self->{cmd}
      = [ ( $ENV{SHELL} // '/bin/sh' ), '-c', $self->{command}, '-' ];
    $self->{parameters} = [ $self->{argv} ];
  } else {
    $self->{cmd} = $self->{argv};
  }

  unless ( $self->{parameters} or isatty( *STDIN ) ) {
    my @lines;

    ## no critic [InputOutput::ProhibitExplicitStdin]
    while ( my $line = <STDIN> ) {
      chomp $line;
      push @lines, $line;
    }

    $self->{mode} = scalar @lines == 1 ? 'fields' : 'lines'
      if ( $self->{mode} // 'auto' ) eq 'auto';

    if ( $self->{mode} eq 'fields' ) {
      $self->_push_parameters( map { $self->_split_fields( $_ ) } @lines );
    } elsif ( $self->{mode} eq 'lines' ) {
      $self->_push_parameters( @lines );
    } elsif ( $self->{mode} eq 'slpf' ) {
      for my $line ( @lines ) {
        $self->_push_parameters;
        push @{ $self->{parameters} }, []
          if @{ $self->{parameters}->[-1] } > 0;
        $self->_push_parameters( $self->_split_fields( $line ) );
      }
    } else {
      croak sprintf( 'Bad mode ‘%s’', $self->{mode} );
    }
  } ## end unless ( $self->{parameters...})

  $self->{parameters} //= [ [undef] ];

  $self->{parameters} = map { reverse @$_ } reverse @{ $self->parameters }
    if $self->{reverse};

  $self->{parameters} = map { shuffle @$_ } shuffle @{ $self->parameters }
    if $self->{random};

  $self->{total_parameters} = scalar flat( @{ $self->{parameters} } );
  $self->{prefix}  //= $self->{total_parameters} > 1;
  $self->{summary} //= $self->{total_parameters} > 1;

  return $self;
} ## end sub new

=head2 stop

=cut

sub stop( $self ) {
  $self->{parameters} = [];

  for my $worker ( @{ $self->{pool} } ) {
    $worker->stop;
  }

  return;
}

sub _coloured ( $self, $str, @args ) {
  return $str
    unless $self->{colour};

  return colored( $str, @args );
}

sub _make_argv ( $self, $parameter ) {
  my @argv = @{ $self->{cmd} };

  return @argv
    unless defined $parameter;

  my $replstr = $self->{replstr} // '{}';

  return ( @argv, $parameter )
    unless scalar grep {m/\Q$replstr\E/} @argv;

  return map {s/\Q$replstr\E/$parameter/gr} @argv;
}

sub _parse_sequence ( $self, $str ) {
  my @seq;

  for my $part ( split( /,/, $str ) ) {
    $part =~ m/^(?:(.*)\.\.)?(.*)$/
      or croak sprintf( 'Bad sequence specifier ‘%s’', $part );

    my $beg = $1 // '1';
    my $end = $2;

    my $w = max( map {length} ( $beg, $end ) );
    push @seq,
      sprintf( '%0*s', $w, $beg ) lt sprintf( '%0*s', $w, $end )
      ? $beg .. $end
      : reverse $end .. $beg;
  }

  return wantarray ? @seq : \@seq;
}

sub _printer ( $self, $prefix, $marker, $dest ) {
  binmode $dest, ':encoding(UTF-8)';
  $dest->autoflush( 1 );

  my @subs;

  push @subs, sub {$prefix}
    if defined $prefix
    and $self->{prefix};

  push @subs, sub {
    $self->_coloured(
      DateTime->from_epoch(
        epoch     => time,
        time_zone => 'local',
      )->strftime( $self->{timestamp_format} ),
      'reverse faint',
    );
    }
    if $self->{timestamp_format};

  push @subs, sub { $self->_coloured( $marker, 'faint' ) }
    if $self->{markers};

  push @subs, sub {' '}
    if @subs;

  return sub {
    for ( @_ ) {
      chomp;
      say {$dest} join( '', map { $_->() } @subs ) . $_;
    }
    return;
  };
} ## end sub _printer

sub _ps_four() {
  state $ps_four;

  unless ( defined $ps_four ) {
    $ps_four = $ENV{PS4};
    utf8::decode(              ## no critic [Subroutines::ProhibitCallsToUnexportedSubs]
      $ps_four,
    ) if $ps_four;
    $ps_four //= '+ ';
  }

  return $ps_four;
}

sub _push_parameters ( $self, @parameters ) {
  $self->{parameters} //= [ [] ];

  @parameters = grep {m/./} @parameters
    unless $self->{empty};

  confess unless $self->{parameters};

  push @{ $self->{parameters}->[-1] }, @parameters;

  return;
}

sub _split_fields ( $self, $str ) {
  return split( $self->{delimiter}, $str );
}

sub _string_colour( $str ) {
  return $COLOURS[ unpack( 'L', substr( md5( $str ), 0, 2 * 2 ) ) %
    scalar @COLOURS ];
}

sub _width( $self ) {
  return $ENV{COLUMNS}
    if $ENV{COLUMNS};

  return ( GetTerminalSize() )[0] // $WIDTH;
}

=head1 AUTHOR

Theo -q Willows, C<< <theo@willows.se> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the web interface at
L<https://gitlab.com/munkei-software/ppll/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ppll

Or:

    ppll --help

You can also look for information at:

=over

=item * MetaCPAN

L<https://metacpan.org/pod/App::ppll>

=item * GitLab

L<https://gitlab.com/munkei-software/ppll>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Theo Willows.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
