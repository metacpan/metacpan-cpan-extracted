use strict;
use warnings;
package App::Cronjob;
# ABSTRACT: wrap up programs to be run as cron jobs
$App::Cronjob::VERSION = '1.200010';
use Digest::MD5 qw(md5_hex);
use Errno;
use Fcntl qw( :DEFAULT :flock );
use Getopt::Long::Descriptive;
use IPC::Run3 qw(run3);
use Log::Dispatchouli;
use Process::Status 0.002;
use String::Flogger;
use Sys::Hostname::Long;
use Text::Template;
use Time::HiRes ();

#pod =head1 SEE INSTEAD
#pod
#pod This library, App::Cronjob, is not well documented.  Its internals may change
#pod substantially until such point as it is documented.
#pod
#pod Instead of using the library, you should run the program F<cronjob> that is
#pod installed along with the library.
#pod
#pod For a full description of the program's behavior, consult L<cronjob>.
#pod
#pod =cut

my $TEMPLATE;

my (
  $opt,
  $usage,
  $subject,
  $rcpts,
  $host,
  $sender,
);

sub run {
  ($opt, $usage) = describe_options(
    '%c %o',
     [ 'command|c=s',   'command to run (passed to ``)', { required => 1 }   ],
     [ 'subject|s=s',   'subject of mail to send (defaults to command)'      ],
     [ 'rcpt|r=s@',     'recipient of mail; may be given many times',        ],
     [ 'errors-only|E', 'do not send mail if exit code 0, even with output', ],
     [ 'sender|f=s',    'sender for message',                                ],
     [ 'jobname|j=s',   'job name; used for locking, if given'               ],
     [ 'timeout=i',     "fail if the child isn't completed within n seconds" ],
     [ 'ignore-errors=s@',  'error types to ignore (like: lock)'              ],
     [ 'email-header|h=s@', 'add header to the report email, if you send one' ],
     [ 'temp-ignore-lock-errors=i',
                     'failure to lock only signals an error after this long' ],
     [ 'lock!',         'lock this job (defaults to true; --no-lock for off)',
                        { default => 1 }                                     ],
  );

  $subject = $opt->{subject} || $opt->{command};
  $subject =~ s{\A/\S+/([^/]+)(\s|$)}{$1$2} if $subject eq $opt->{command};

  if (defined $opt->{temp_ignore_lock_errors}) {
    if (grep {; $_ eq "lock" } @{$opt->{ignore_errors}}) {
      die "--temp-ignore-lock-errors and --ignore-errors=lock are incompatible\n";
    }
  }

  my @extra_headers;
  for my $entry (@{ $opt->email_header || [] }) {
    my ($h, $v) = split /=/, $entry;

    lc $h eq $_ && die "You can't replace the $_ header!\n"
      for qw(to from subject);

    die "Invalid header name: $h" if $h =~ /\P{ASCII}/;
    die "Invalid header name: $h" unless $h =~ /\A[A-Za-z][-A-Za-z0-9]*\z/;

    push @extra_headers, $h, $v;
  }

  $rcpts   = $opt->{rcpt}
          || [ split /\s*,\s*/, ($ENV{MAILTO} ? $ENV{MAILTO} : 'root') ];

  $host    = hostname_long;
  $sender  = $opt->{sender} || sprintf '%s@%s', ($ENV{USER}||'cron'), $host;

  my $lockfile = sprintf '%s/cronjob.%s',
                 $ENV{APP_CRONJOB_LOCKDIR} || '/tmp',
                 $opt->{jobname} || md5_hex($subject);

  my $got_lock;

  my $okay = eval {
    die "illegal job name: $opt->{jobname}\n"
      if $opt->{jobname} and $opt->{jobname} !~ m{\A[-_A-Za-z0-9]+\z};

    my $logger  = Log::Dispatchouli->new({
      ident    => 'cronjob',
      facility => 'cron',
      log_pid  => 0,
      (defined $opt->{jobname} ? (prefix => "$opt->{jobname}: ") : ()),
    });

    my $lock_fh;
    if ($opt->lock) {
      sysopen $lock_fh, $lockfile, O_CREAT|O_WRONLY
        or die App::Cronjob::Exception->new(
          lockfile => "couldn't open lockfile $lockfile: $!"
        );

      my $lock_flags = LOCK_EX | LOCK_NB;

      unless (flock $lock_fh, $lock_flags) {
        my $error = $!;
        my $mtime = (stat $lock_fh)[9];
        my $stamp = scalar localtime $mtime;
        die App::Cronjob::Exception->new(
          lock => "can't lock; $!; lockfile created $stamp",
          { locked_since => $mtime },
        );
      }

      printf $lock_fh "pid %s running %s\nstarted at %s\n",
        $$, $opt->{command}, scalar localtime $^T;

      $got_lock = 1;
    }

    $logger->log([ 'trying to run %s', $opt->{command} ]);

    my $start = Time::HiRes::time;
    my $output;

    my $ok = eval {
      local $SIG{ALRM} = sub { die "command took too long to run" };
      alarm($opt->timeout) if $opt->timeout;
      run3($opt->{command}, \undef, \$output, \$output);
      alarm(0) if $opt->timeout;
      1;
    };

    unless ($ok) {
      # XXX: does not throw proper exception
      $logger->log_fatal([ 'run3 failed to run command: %s', $@ ]);
    }

    my $status = Process::Status->new;

    my $end = Time::HiRes::time;

    my $send_mail = ($status->exitstatus != 0)
                 || (length $output && ! $opt->{errors_only});

    my $time_taken = sprintf '%0.4f', $end - $start;

    $logger->log([
      'job completed with status %s after %ss',
      $status->as_struct,
      $time_taken,
    ]);

    if ($send_mail) {
      send_cronjob_report({
        is_fail => (!! $status->exitstatus),
        status  => $status,
        time    => \$time_taken,
        output  => \$output,
        extra_headers => \@extra_headers,
      });
    }

    1;
  };

  exit 0 if $okay;
  my $err = $@;

  if (eval { $err->isa('App::Cronjob::Exception'); }) {
    unless (
      grep { $err->{type} and $_ eq $err->{type} } @{$opt->{ignore_errors}}
    ) {
      if ($err->{type} eq "lock" && $opt->{temp_ignore_lock_errors}) {
        my $age = time() - $err->{extra}{locked_since};
        exit 0 if $age <= $opt->{temp_ignore_lock_errors};
      }
      send_cronjob_report({
        is_fail => 1,
        output  => \$err->{text},
        extra_headers => \@extra_headers,
      });
    }

    exit 0;
  } else {
    $subject = "ERROR: $subject";
    send_cronjob_report({
      is_fail => 1,
      output  => \$err,
      extra_headers => \@extra_headers,
    });
    exit 0;
  }
}

# read INI from /etc/cronjob
#sub __config {
#}

sub send_cronjob_report {
  my ($arg) = @_;

  require Email::Simple;
  require Email::Simple::Creator;
  require Email::Sender::Simple;
  require Text::Template;

  my $body     = Text::Template->fill_this_in(
    $TEMPLATE,
    HASH => {
      command => \$opt->{command},
      output  => $arg->{output},
      time    => $arg->{time} || \'(n/a)',
      status  => \($arg->{status} ? $arg->{status}->as_string : 'never ran'),
    },
  );

  my $subject = sprintf '%s%s', ($arg->{is_fail} ? 'FAIL: ' : ''), $subject;

  my $irt = sprintf '<%s@%s>', md5_hex($subject), $host;

  my $email = Email::Simple->create(
    body   => $body,
    header => [
      To      => join(', ', @$rcpts),
      From    => qq{"cron/$host" <$sender>},
      Subject => $subject,
      'In-Reply-To' => $irt,
      'Auto-Submitted' => 'auto-generated',
      @{ $arg->{extra_headers} },
    ],
  );

  Email::Sender::Simple->send(
    $email,
    {
      to      => $rcpts,
      from    => $sender,
    }
  );
}

BEGIN {
$TEMPLATE = <<'END_TEMPLATE'
Command: { $command }
Time   : { $time }s
Status : { $status }

Output :

{ $output || '(no output)' }
END_TEMPLATE
}

{
  package App::Cronjob::Exception;
$App::Cronjob::Exception::VERSION = '1.200010';
sub new {
    my ($class, $type, $text, $extra) = @_;
    bless { type => $type, text => $text, extra => $extra } => $class;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cronjob - wrap up programs to be run as cron jobs

=head1 VERSION

version 1.200010

=head1 SEE INSTEAD

This library, App::Cronjob, is not well documented.  Its internals may change
substantially until such point as it is documented.

Instead of using the library, you should run the program F<cronjob> that is
installed along with the library.

For a full description of the program's behavior, consult L<cronjob>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords chromatic Mark Jason Dominus Ricardo Signes Rob N ★

=over 4

=item *

chromatic <chromatic@wgz.org>

=item *

Mark Jason Dominus <mjd@plover.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
