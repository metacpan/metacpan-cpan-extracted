package App::cpanminus::reporter;

use warnings;
use strict;

our $VERSION = '0.17';

use Carp ();
use File::Spec     3.19;
use File::HomeDir  0.58 ();
use Test::Reporter 1.54;
use CPAN::Testers::Common::Client 0.13;
use CPAN::Testers::Common::Client::Config;
use Parse::CPAN::Meta;
use CPAN::Meta::Converter;
use Try::Tiny;
use URI;
use Metabase::Resource;
use Capture::Tiny qw(capture);
use IO::Prompt::Tiny ();

sub new {
  my ($class, %params) = @_;
  my $self = bless {}, $class;

  $self->config(
    CPAN::Testers::Common::Client::Config->new(
      prompt => sub { local %ENV; IO::Prompt::Tiny::prompt(@_) },
    )
  );

  if ($params{cpanm}) {
    my $cpanm = $self->_cpanm( $params{cpanm} );
    $params{only} =~ s/-\d+(\.\d+)*$//; # strip version from cpanm's "only" data

    # FIXME: cpanm doesn't provide an accessor here, so
    # we break encapsulation in order to make sure we
    # always have the right paths.
    $params{build_dir}     = $cpanm->{home};
    $params{build_logfile} = $cpanm->{log};
  }

  $self->build_dir(
    $params{build_dir}
      || File::Spec->catdir( File::HomeDir->my_home, '.cpanm' )
  );

  $self->build_logfile(
    $params{build_logfile}
      || File::Spec->catfile( $self->build_dir, 'build.log' )
  );

  foreach my $option ( qw(quiet verbose force exclude only dry-run skip-history ignore-versions) ) {
    my $method = $option;
    $method =~ s/\-/_/g;
    $self->$method( $params{$option} ) if exists $params{$option};
  }

  return $self;
}

sub setup { shift->config->setup }

## basic accessors ##

sub author {
  my ($self, $author) = @_;
  $self->{_author} = $author if $author;
  return $self->{_author};
}

sub distfile {
  my ($self, $distfile) = @_;
  $self->{_distfile} = $distfile if $distfile;
  return $self->{_distfile};
}

sub config {
  my ($self, $config) = @_;
  $self->{_config} = $config if $config;
  return $self->{_config};
}

sub verbose {
  my ($self, $verbose) = @_;
  $self->{_verbose} = $verbose if $verbose;
  return $self->{_verbose};
}

sub force {
  my ($self, $force) = @_;
  $self->{_force} = $force if $force;
  return $self->{_force};
}

sub ignore_versions {
  my ($self, $ignore_versions) = @_;
  $self->{_ignore_versions} = $ignore_versions if $ignore_versions;
  return $self->{_ignore_versions};
}

sub quiet {
  my ($self, $quiet) = @_;
  if ($quiet) {
    $self->verbose(0);
    $self->{_quiet} = 1;
  }
  return $self->{_quiet};
}

sub dry_run {
  my ($self, $dry_run) = @_;
  $self->{_dry_run} = $dry_run if $dry_run;
  $self->{_dry_run};
}

sub skip_history {
    my ($self, $skip) = @_;
    $self->{_skip_history} = $skip if $skip;
    $self->{_skip_history};
}

sub only {
  my ($self, $only) = @_;
  if ($only) {
    $only =~ s/::/-/g;
    my @modules = split /\s*,\s*/, $only;
    foreach (@modules) { $_ =~ s/(\S+)-[\d.]+$/$1/ };

    $self->{_only} = { map { $_ => 0 } @modules };
  }
  return $self->{_only};
}

sub exclude {
  my ($self, $exclude) = @_;
  if ($exclude) {
    $exclude =~ s/::/-/g;
    my @modules = split /\s*,\s*/, $exclude;
    foreach (@modules) { $_ =~ s/(\S+)-[\d.]+$/$1/ };

    $self->{_exclude} = { map { $_ => 0 } @modules };
  }
  return $self->{_exclude};
}

sub build_dir {
  my ($self, $dir) = @_;
  $self->{_build_dir} = $dir if $dir;
  return $self->{_build_dir};
}

sub build_logfile {
  my ($self, $file) = @_;
  $self->{_build_logfile} = $file if $file;
  return $self->{_build_logfile};
}

sub _cpanm {
  my ($self, $cpanm) = @_;
  $self->{_cpanm_object} = $cpanm if $cpanm;
  return $self->{_cpanm_object};
}

sub _check_cpantesters_config_data {
  my $self     = shift;
  my $config   = $self->config;
  my $filename = $config->get_config_filename;

  if (-e $filename) {
    if (!$config->read) {
      print "Error reading CPAN Testers configuration file '$filename'. Aborting.";
      return;
    }
  }
  else {
    my $answer = IO::Prompt::Tiny::prompt("CPAN Testers configuration file '$filename' not found. Would you like to set it up now? (y/n)", 'y');

    if ( $answer =~ /^y/i ) {
      $config->setup;
    }
    else {
      print "The CPAN Testers configuration file is required. Aborting.\n";
      return;
    }
  }
  return 1;
}

sub _check_build_log {
  my $self = shift;

  # as a safety mechanism, we only let people parse build.log files
  # if they were generated up to 30 minutes (1800 seconds) ago,
  # unless the user asks us to --force it.
  my $mtime = (stat $self->build_logfile)[9];
  if ( !$self->force && $mtime && time - $mtime > 1800 ) {
      print <<'EOMESSAGE';
Fatal: build.log was created longer than 30 minutes ago.

As a standalone tool, it is important that you run cpanm-reporter
as soon as you finish cpanm, otherwise your system data may have
changed, from new libraries to a completely different perl binary.

Because of that, this app will *NOT* parse build.log files last modified
longer than 30 minutes before the moment it runs.

You can override this behaviour by touching the file or passing
a --force flag to cpanm-reporter, but please take good care to avoid
sending bogus reports.
EOMESSAGE
    return;
  }
  return 1;
}

sub run {
  my $self = shift;
  return unless ($self->_check_cpantesters_config_data and $self->_check_build_log);

  my $logfile = $self->build_logfile;
  open my $fh, '<', $logfile
    or Carp::croak "error opening build log file '$logfile' for reading: $!";

  my $header = <$fh>;
  if ($header =~ /^cpanm \(App::cpanminus\) (\d+\.\d+) on perl (\d+\.\d+)/) {
    $self->{_cpanminus_version} = $1;
    $self->{_perl_version} = $2;
  }
  else {
      Carp::croak(
          'Unable to find cpanminus/perl versions on build.log. '
        . 'Please update App::cpanminus. If you think this is a mistake, '
        . 'please send us a bug report with your version of App::cpanminus, '
        . 'App::cpanminus::reporter, perl -V and your failing build.log file.'
      );
  }

  my $found = 0;
  my $parser;

  # we could go over 100 levels deep on the dependency track
  no warnings 'recursion';
  $parser = sub {
    my ($dist, $resource) = @_;
    (my $dist_vstring = $dist) =~ s/\-(\d+(?:\.\d)+)$/-v$1/ if $dist;
    my @test_output = ();
    my $recording;
    my $has_tests = 0;
    my $found_na;
    my $fetched;

    while (<$fh>) {
      if ( /^Fetching (\S+)/ ) {
        next if /CHECKSUMS$/;
        $fetched = $1;
        $resource = $fetched unless $resource;
      }
      elsif ( /^Entering (\S+)/ ) {
        my $dep = $1;
        $found = 1;
        if ($recording && $recording eq 'test') {
            Carp::croak 'Parsing error. This should not happen. Please send us a report!';
        }
        else {
            print "entering $dep, " . ($fetched || '(local)') . "\n" if $self->verbose;
            $parser->($dep, $fetched);
            print "left $dep, " . ($fetched || '(local)') . "\n" if $self->verbose;
            next;
        }
      }
      elsif ( /^Running (?:Build|Makefile)\.PL/ ) {
        $recording = 'configure';
      }
      elsif ( $dist and /^Building .*(?:$dist|$dist_vstring)/) {
        print "recording $dist\n" if $self->verbose;
        $has_tests = 1 if /and testing/;
        # if we got here, we need to flush the test output
        # (so far filled with 'configure' output) and start
        # recording the actual tests.
        @test_output = ();
        $recording = 'test';
      }

      push @test_output, $_ if $recording;

      my $result;
      if ($recording) {
        if (   /^Result: (PASS|NA|FAIL|UNKNOWN|NOTESTS)/
           || ($recording eq 'test' && /^-> (FAIL|OK)/)
        ) {
          $result = $1;
          if ($result eq 'FAIL' && $recording eq 'configure') {
            $result = 'NA';
          }
          elsif ($result eq 'OK') {
            $result = $has_tests ? 'PASS' : 'UNKNOWN';
          }
          elsif ($result eq 'NOTESTS') {
              $result = 'UNKNOWN';
          }
        }
        elsif ( $recording eq 'configure' && /^-> N\/A/ ) {
            $found_na = 1;
        }
        elsif (  $recording eq 'configure'
            # https://github.com/miyagawa/cpanminus/blob/devel/lib/App/cpanminus/script.pm#L2269
              && ( /Configure failed for (?:$dist|$dist_vstring)/
                || /proper Makefile.PL\/Build.PL/
                || /configure the distribution/
              )
        ) {
            $result = $found_na ? 'NA' : 'UNKNOWN';
        }
      }
      if ($result) {
        my $dist_without_version = $dist;
        $dist_without_version =~ s/(\S+)-[\d.]+$/$1/;

        if (@test_output <= 2) {
            print "No test output found for '$dist'. Skipping...\n"
                . "To send test reports, please make sure *NOT* to pass '-v' to cpanm or your build.log will contain no output to send.\n";
        }
        elsif (!$resource) {
            print "Skipping report for local installation of '$dist'.\n";
        }
        elsif ( defined $self->exclude && exists $self->exclude->{$dist_without_version} ) {
            print "Skipping $dist as it's in the 'exclude' list...\n" if $self->verbose;
        }
        elsif ( defined $self->only && !exists $self->only->{$dist_without_version} ) {
            print "Skipping $dist as it isn't in the 'only' list...\n" if $self->verbose;
        }
        elsif ( !$self->ignore_versions && defined $self->{_perl_version} && ( $self->{_perl_version} ne $] ) ) {
            print "Skipping $dist as its build Perl version ($self->{_perl_version}) differs from the currently running perl ($])...\n" if $self->verbose;
        }
        else {
            my $report = $self->make_report($resource, $dist, $result, @test_output);
        }
        return;
      }
    }
  };

  print "Parsing $logfile...\n" if $self->verbose;
  $parser->();
  print "No reports found.\n" if !$found and $self->verbose;
  print "Finished.\n" if $self->verbose;

  close $fh;
  return;
}

sub get_author {
  my ($self, $path ) = @_;
  my $metadata;

  try {
    $metadata = Metabase::Resource->new( q[cpan:///distfile/] . $path )->metadata;
  }
  catch {
    print "DEBUG: $_" if $self->verbose;
  };
  return unless $metadata;

  return $metadata->{cpan_id};
}


# returns false in case of error (so, skip!)
sub parse_uri {
  my ($self, $resource) = @_;

  my $uri = URI->new( $resource );
  my $scheme = lc $uri->scheme;
  if (    $scheme ne 'http'
      and $scheme ne 'https'
      and $scheme ne 'ftp'
      and $scheme ne 'cpan'
  ) {
    print "invalid scheme '$scheme' for resource '$resource'. Skipping...\n"
      unless $self->quiet;
    return;
  }

  my $author = $self->get_author( $uri->path );
  unless ($author) {
    print "error fetching author for resource '$resource'. Skipping...\n"
      unless $self->quiet;
    return;
  }

  # the 'LOCAL' user is reserved and should never send reports.
  if ($author eq 'LOCAL') {
    print "'LOCAL' user is reserved. Skipping resource '$resource'\n"
      unless $self->quiet;
    return;
  }

  $self->author($author);

  $self->distfile(substr("$uri", index("$uri", $author)));

  return 1;
}

sub make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;

  if ( index($dist, 'Local-') == 0 ) {
      print "'Local::' namespace is reserved. Skipping resource '$resource'\n"
        unless $self->quiet;
      return;
  }
  return unless $self->parse_uri($resource);

  my $author = $self->author;

  my $cpanm_version = $self->{_cpanminus_version} || 'unknown cpanm version';
  my $meta = $self->get_meta_for( $dist );
  my $client = CPAN::Testers::Common::Client->new(
    author      => $self->author,
    distname    => $dist,
    grade       => $result,
    via         => "App::cpanminus::reporter $VERSION ($cpanm_version)",
    test_output => join( '', @test_output ),
    prereqs     => ($meta && ref $meta) ? $meta->{prereqs} : undef,
  );

  if (!$self->skip_history && $client->is_duplicate) {
    print "($resource, $author, $dist, $result) was already sent. Skipping...\n"
      if $self->verbose;
    return;
  }
  else {
    print "sending: ($resource, $author, $dist, $result)\n" unless $self->quiet;
  }

  my $reporter = Test::Reporter->new(
    transport      => $self->config->transport_name,
    transport_args => $self->config->transport_args,
    grade          => $client->grade,
    distribution   => $dist,
    distfile       => $self->distfile,
    from           => $self->config->email_from,
    comments       => $client->email,
    via            => $client->via,
  );

  if ($self->dry_run) {
    print "not sending (drun run)\n" unless $self->quiet;
    return;
  }

  try {
    $reporter->send() || die $reporter->errstr();
  }
  catch {
    print "Error while sending this report, continuing with the next one...\n" unless $self->quiet;
    print "DEBUG: @_" if $self->verbose;
  } finally{
    $client->record_history unless $self->skip_history;
  };
  return;
}

sub get_meta_for {
  my ($self, $dist) = @_;
  my $distdir = File::Spec->catdir( $self->build_dir, $dist );

  foreach my $meta_file ( qw( META.json META.yml META.yaml ) ) {
    my $meta_path = File::Spec->catfile( $distdir, $meta_file );
    if (-e $meta_path) {
      my $meta = eval { Parse::CPAN::Meta->load_file( $meta_path ) };
      next if $@;

      if (!$meta->{'meta-spec'} or $meta->{'meta-spec'}{version} < 2) {
          $meta = CPAN::Meta::Converter->new( $meta )->convert( version => 2 );
      }
      return $meta;
    }
  }
  return;
}


42;
__END__

=head1 NAME

App::cpanminus::reporter - send cpanm output to CPAN Testers

=head1 SYNOPSIS

This is just the backend module, you are probably looking for L<cpanm-reporter>'s
documentation instead. Please look there for a B<much more> comprehensive documentation.


=head1 STILL HERE?

    use App::cpanminus::reporter;
    my $tester = App::cpanminus::reporter->new( %options );

    $tester->run;

  
=head1 DESCRIPTION

See L<cpanm-reporter>.


=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012-2015, Breno G. de Oliveira C<< <garu@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
