package DBIx::Class::UnicornLogger;
$DBIx::Class::UnicornLogger::VERSION = '0.001004';
# ABSTRACT: Pretty Printing DebugObj with nicer logging features

use Moo;
extends 'DBIx::Class::Storage::Statistics';

use SQL::Abstract::Tree;
use Log::Structured;
use Log::Sprintf;

my %code_to_method = (
  C => 'log_package',
  c => 'log_category',
  d => 'log_date',
  F => 'log_file',
  H => 'log_host',
  L => 'log_line',
  l => 'log_location',
  M => 'log_subroutine',
  P => 'log_pid',
  p => 'log_priority',
  r => 'log_milliseconds_since_start',
  R => 'log_milliseconds_since_last_log',
  T => 'log_stacktrace',
);

sub BUILDARGS {
   my ($self, @rest) = @_;

   my %args = (
      @rest == 1
         ? %{$rest[0]}
         : @rest
   );

   $args{_sqlat} = SQL::Abstract::Tree->new($args{tree} || {});

   return \%args
}

has _sqlat => (
   is => 'ro',
);

has _clear_line_str => (
   is => 'ro',
   init_arg => 'clear_line',
);

has _executing_str => (
   is => 'ro',
   init_arg => 'executing',
);

has _show_progress => (
   is => 'ro',
   init_arg => 'show_progress',
);

has _last_sql => (
   is => 'rw',
   default => sub { '' },
   init_arg => undef,
);

has _squash_repeats => (
   is => 'ro',
   init_arg => 'squash_repeats',
);

has _structured_logger => (
   is => 'rw',
   lazy => 1,
   builder => '_build_structured_logger',
);

sub _build_structured_logger {
   my $self = shift;

   if ($self->_format || $self->_multiline_format) {
      my $format = $self->_format || '%m';

      my $log_sprintf = Log::Sprintf->new({ format => $format });

      my $per_line_log_sprintf = Log::Sprintf->new({
         format => $self->_multiline_format
      }) if $self->_multiline_format;

      my %formats = %{{
         map { $_->{conversion} => 1 }
         grep { ref $_ }
         map @{$log_sprintf->_formatter->format_hunker->($log_sprintf, $_)},
            grep $_,
            $log_sprintf->{format},
            $per_line_log_sprintf->{format}
      }};

      my $sub = $self->_multiline_format
        ? sub {
            my %struc = %{$_[1]};
            my (@msg, undef) = split /\n/, delete $struc{message};
            $self->debugfh->print($log_sprintf->sprintf({
               %struc,
               message => shift @msg,
            }) . "\n");
            $self->debugfh->print($per_line_log_sprintf->sprintf({
               %struc,
               message => $_,
            }) . "\n") for @msg;
         }
        : sub {
          my %struc = %{$_[1]};
          my (@msg, undef) = split /\n/, delete $struc{message};
          $self->debugfh->print($log_sprintf->sprintf({
             %struc,
             message => $_,
          }) . "\n") for @msg;
        };
      return
         Log::Structured->new({
            category     => 'DBIC',
            priority     => 'TRACE',
            caller_depth => 2,
            log_event_listeners => [$sub],
            map { $code_to_method{$_} => 1 }
            grep { exists $code_to_method{$_} }
            keys %formats
         })
   }
}

has _format => (
   is => 'ro',
   init_arg => 'format',
);

has _multiline_format => (
   is => 'ro',
   init_arg => 'multiline_format',
);

sub print {
  my $self = shift;
  my $string = shift;
  my $bindargs = shift || [];

  my ($lw, $lr);
  ($lw, $string, $lr) = $string =~ /^(\s*)(.+?)(\s*)$/s;

  local $self->_sqlat->{fill_in_placeholders} = 0 if defined $bindargs->[0]
    && $bindargs->[0] eq q('__BULK_INSERT__');

  my $use_placeholders = !!$self->_sqlat->fill_in_placeholders;

  my $sqlat = $self->_sqlat;
  my $formatted;
  if ($self->_squash_repeats && $self->_last_sql eq $string) {
     my ( $l, $r ) = @{ $sqlat->placeholder_surround };
     $formatted = '... : ' . join(', ', map "$l$_$r", @$bindargs)
  } else {
     $self->_last_sql($string);
     $formatted = $sqlat->format($string, $bindargs);
     $formatted = "$formatted : " . join ', ', @{$bindargs}
        unless $use_placeholders;
  }

  if ($self->_structured_logger) {
     $self->_structured_logger->log_event({
        message => "$lw$formatted$lr",
     })
  } else {
     $self->next::method("$lw$formatted$lr", @_)
  }
}

sub query_start {
  my ($self, $string, @bind) = @_;

  if(defined $self->callback) {
    $string =~ m/^(\w+)/;
    $self->callback->($1, "$string: ".join(', ', @bind)."\n");
    return;
  }

  $string =~ s/\s+$//;

  $self->print("$string\n", \@bind);

  $self->debugfh->print($self->_executing_str) if $self->_show_progress
}

sub query_end {
  $_[0]->debugfh->print($_[0]->_clear_line_str) if $_[0]->_show_progress
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::UnicornLogger - Pretty Printing DebugObj with nicer logging features

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

 my $debug_obj = DBIx::Class::UnicornLogger->new(
    tree => { profile => 'console' },
 );

=head1 METHODS

=head2 new

 my $pp = DBIx::Class::UnicornLogger->new(
   show_progress  => 1,             # tries it's best to make it clear that a SQL
                                    # statement is still running
   executing      => '...',         # the string that is added to the end of SQL
                                    # if show_progress is on.  You probably don't
                                    # need to set this
   clear_line     => '<CR><ESC>[J', # the string used to erase the string added
                                    # to SQL if show_progress is on.  Again, the
                                    # default is probably good enough.

   squash_repeats => 1,             # set to true to make repeated SQL queries
                                    # be ellided and only show the new bind params

   format => '[%d][%c]%n ** %m',    # both format and multiline format take the
   multiline_format => '   %m',     # formats defined in Log::Sprintf.  If only
                                    # format is defined it will be used for each
                                    # line of the log; if both are defined, format
                                    # will be used for the first line, and
                                    # multiline_format will be used for the rest
   tree => {
      profile => 'console',         # any arguments in the tree hashref will be
   },                               # passed along to the SQL::Abstract::Tree
                                    # constructor
   # any other args are passed through directly to SQL::Abstract::Tree
 );

=head1 SEE ALSO

L<DBIx::Class::UnicornLogger::FromProfile>, L<Log::Sprintf>

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
