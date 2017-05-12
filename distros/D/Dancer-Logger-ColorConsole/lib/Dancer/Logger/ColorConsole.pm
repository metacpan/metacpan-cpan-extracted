package Dancer::Logger::ColorConsole;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';
use Dancer::Config 'setting';
use Term::ANSIColor;

our $VERSION = '0.0005';

sub _log {
    my ($self, $level, $message) = @_;
    print STDERR $self->format_message($level => $message);
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $config = setting('engines')->{logger};

    $self->{level_colors} = $config->{levels};

    $self->{level_colors}{core}  ||= 'reset';
    $self->{level_colors}{debug} ||= 'bright_blue';
    $self->{level_colors}{warn}  ||= $self->{level_colors}{warning} || 'bright_yellow';
    $self->{level_colors}{error} ||= 'bright_red';
    $self->{level_colors}{info}  ||= 'bright_green';

    if (!exists($config->{default_regexps}) || $config->{default_regexps} != 0) {
        push @{$self->{regexps}} =>
          (
           { re => 'response: 2\d\d',    color => 'bright_green' },
           { re => 'response: [45]\d\d', color => 'bright_red'   },
           { re => '(?:GET|POST|PUT|DELETE) \S+', color => 'bright_blue'  },
          );
    }

    if (exists($config->{regexps}) && ref($config->{regexps}) eq 'ARRAY') {
        push @{$self->{regexps}} => @{$config->{regexps}};
    }

}

sub format_message {
    my ($self, $level, $message) = @_;
    chomp $message;

    if (setting('charset')) {
        $message = Encode::encode(setting('charset'), $message);
    }

    $level = 'warn' if $level eq 'warning';
    $level = color($self->{level_colors}{$level}) . sprintf('%5s', $level);

    my $r     = Dancer::SharedData->request;
    my @stack = caller(3);

    my $block_handler = sub {
        my ( $block, $type ) = @_;
        if ( $type eq 't' ) {
            return "[" . strftime( $block, localtime ) . "]";
        }
        elsif ( $type eq 'h' ) {
            return scalar $r->header($block) || '-';
        }
        else {
            Carp::carp("{$block}$type not supported");
            return "-";
        }
    };

    my $chars_mapping = {
        h => sub {
            defined $r
              ? $r->env->{'HTTP_X_REAL_IP'} || $r->env->{'REMOTE_ADDR'}
              : '-';
        },
        t => sub { Encode::decode(setting('charset'),
                                  POSIX::strftime( "%d/%b/%Y %H:%M:%S", localtime )) },
        T => sub { POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime  ) },
        P => sub { $$ },
        L => sub { $level },
        D => sub {
            my $time = Dancer::SharedData->timer->tick;
            return $time;
        },
        m => sub { $message },
        f => sub { $stack[1] || '-' },
        l => sub { $stack[2] || '-' },
        i => sub {
            defined $r ? "[hit #" . $r->id . "]" : "";
        },
    };

    my $char_mapping = sub {
        my $char = shift;

        my $cb = $chars_mapping->{$char};
        unless ($cb) {
            Carp::carp "\%$char not supported.";
            return "-";
        }
        $cb->($char);
    };

    my $fmt = $self->_log_format();

    $fmt =~ s{
        (?:
            \%\{(.+?)\}([a-z])|
            \%([a-zA-Z])
        )
    }{ $1 ? $block_handler->($1, $2) : $char_mapping->($3) }egx;

    for my $re (@{$self->{regexps}}) {
        $fmt =~ s/($re->{re})/colored($1, $re->{color})/ge;
    }

    return $fmt . color('reset') . "\n";
}


1;

__END__

=encoding UTF-8

=head1 NAME

Dancer::Logger::ColorConsole - colored console-based logging engine for Dancer

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a colored console-based logging engine that prints your logs
to the console.

=head1 CONFIGURATION

First, set the logger. Probably in your C<environment/development.yml> file:

  logger: colorConsole

Then, you can configure colors for the four debug levels:

  engines:
    logger:
      levels:
        core: 'red'
        warning: 'white on_yellow'
        debug: 'clear'
        error: 'bold white on_red'

Check the colors/types supported in the Term::ANSIColor manual.

You can define regular expressions (and colors to be used) with:

  engines:
    logger:
      regexps:
        - re: 'trying to match .*'
          color: 'green'
        - re: 'request: .*'
          color: 'bold'

By default, C<Dancer::Logger::ColorConsole> makes some specific
regular expressions colored. For instance, C<response: 200> are
colored in green, while C<response: 404> are colored in red.

At the moment you can turn off these built-in regexps with:

  engines:
    logger:
      default_regexps: 0

=head1 AUTHOR

Alberto Simões

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alberto Simões

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

