package App::Smolder::Report;

use warnings;
use strict;
use 5.008;
use LWP::UserAgent;
use Getopt::Long;
use Carp::Clan qw(App::Smolder::Report);

our $VERSION = '0.04';


###################
# Smolder reporting

sub report {
  my $self = shift;
  
  $self->{run_as_api} = 1;
  return $self->_do_report(@_);
}

sub _do_report {
  my $self = shift;
  
  $self->_fatal("Required 'server' setting is empty or missing")
    unless $self->server;
  $self->_fatal("Required 'project_id' setting is empty or missing")
    unless $self->project_id;
  $self->_fatal("Required 'username' setting is empty or missing")
    unless $self->username;
  $self->_fatal("Required 'password' setting is empty or missing")
    unless $self->password;
  $self->_fatal("You must provide at least one report to upload")
    unless @_;
  
  return $self->_upload_reports(@_);
}

sub _upload_reports {
  my ($self, @reports) = @_;
  my $server = $self->server;
  my $reports_url;
  
  $server = "http://$server"
    unless $server =~ m/^http/;
  
  my $ua = LWP::UserAgent->new;
  my $url
    = $server
    . '/app/developer_projects/process_add_report/'
    . $self->project_id;
  
  REPORT_FILE:
  foreach my $report_file (@reports) {
    $self->_fatal("Could not read report file '$report_file'")
      unless -r $report_file;
  
    if ($self->dry_run) {
      $self->_log("Dry run: would POST to $url: $report_file");
      next REPORT_FILE;
    }
    
    my $response = $ua->post(
      $url,
      'Content-Type' => 'form-data',
      'Content'      => [
        username => $self->username,
        password => $self->password,
        tags     => '',
        report_file => [$report_file],
      ],
    );
    
    if ($response->code == 302) {
      if (! $reports_url) {
        $reports_url = $response->header('Location');
        $reports_url = "$server$reports_url"
          unless $reports_url =~ m/^http/;
      }
      
      $self->_log("Report '$report_file' sent successfully");
      
      if ($self->delete) {
        if (!unlink($report_file)) {
          $self->_log("WARNING: could not delete file $report_file: $!");
        }
      }
    }
    else {
      $self->_fatal(
        "Could not upload report '$report_file'",
        "HTTP Code: ".$response->code,
        $response->message,
      );
    }
  }
  
  $self->_log("See all reports at $reports_url") if $reports_url;
  return $reports_url;
}


###################################
# Configuration loading and merging

sub _load_configs {
  my ($self) = @_;
  
  my $filename = '.smolder.conf';
  my @files_to_check = ($filename);
  unshift @files_to_check, "$ENV{HOME}/$filename" if $ENV{HOME};
  push @files_to_check, $ENV{APP_SMOLDER_REPORT_CONF}
    if $ENV{APP_SMOLDER_REPORT_CONF};
  
  foreach my $file (@files_to_check) {
    $self->_merge_cfg_file($file);
  }
  
  return;
}

sub _merge_cfg_file {
  my ($self, $file) = @_;
  
  my $cfg = $self->_read_cfg_file($file);
  return unless $cfg;
  
  $self->_merge_cfg_hash($cfg);
  
  if (%$cfg) {
    my @bad_keys = sort keys %$cfg;
    $self->_fatal("Invalid configuration keys in $file:", @bad_keys);
  }
  
  return;
}

sub _read_cfg_file {
  my ($self, $file) = @_;
  my %cfg;
  local $_;
  
  open(my $fh, '<', $file) || return;
  while (<$fh>) {
    s/^\s+|\s+$//g;
    next if /^(#.*)?$/;
    
    if (/^(\S+)\s*=\s*(["'])(.*)\2$/) {
      $cfg{$1} = $3;
    }
    elsif (/^(\S+)\s*=\s*(.+)$/) {
      $cfg{$1} = $2;
    }
    else {
      $self->_fatal("Could not parse line $. of $file: $_");
    }
  }
  close($fh);
  
  return \%cfg;
}

sub _merge_cfg_hash {
  my ($self, $cfg) = @_;
  
  my @valid_settings = qw{
    server project_id
    username password
    delete
  };
  foreach my $cfg_key (@valid_settings) {
    next unless exists $cfg->{$cfg_key};
    $self->{$cfg_key} = delete $cfg->{$cfg_key};
  }
    
  return;
}


##################################
# Deal with command line arguments

sub process_args {
  my ($self) = @_;
  
  my ($username, $password, $server, $project_id, $dry_run, $delete, $quiet);
  my $ok = GetOptions(
    "username=s"   => \$username,
    "password=s"   => \$password,
    "server=s"     => \$server,
    "project-id=i" => \$project_id,
    "dry-run|n"    => \$dry_run,
    "quiet"        => \$quiet,
    "delete"       => \$delete,
  );
  exit(2) unless $ok;
  
  $self->_load_configs;
  
  $self->{username} = $username     if defined $username;
  $self->{password} = $password     if defined $password;
  $self->{server} = $server         if defined $server;
  $self->{project_id} = $project_id if defined $project_id;
  $self->{dry_run} = $dry_run       if defined $dry_run;
  $self->{quiet} = $quiet           if defined $quiet;
  $self->{delete} = $delete         if defined $delete;
  
  return;
}

sub run {
  my $self = shift;
  
  $self->{run_as_api} = 0;
  return $self->_do_report(@_);
}


#######
# Utils

sub _fatal {
  my ($self, $mesg, @more) = @_;
  
  $mesg = "FATAL: $mesg\n";
  foreach my $line (@more) {
    $mesg .= "  $line\n";
  }
  
  croak($mesg) if $self->run_as_api;

  print $mesg;
  exit(1);
}

sub _log {
  my ($self, $mesg) = @_;
  return if $self->run_as_api;
  return if $self->quiet;

  print "$mesg\n";

  return;
}


###########################
# Constructor and accessors
#   boring stuff

sub new {
  my $class = shift;
  my $self = bless {}, $class;

  my %args;
  if (ref($_[0])) { %args = %{$_[0]} }
  else            { %args = @_       }

  $self->_load_configs if delete $args{load_config};  
  
  while (my ($k, $v) = each %args) {
    $self->{$k} = $v;
  }
  
  return $self;
}

sub dry_run    { return $_[0]{dry_run}    }
sub quiet      { return $_[0]{quiet}      }
sub username   { return $_[0]{username}   }
sub password   { return $_[0]{password}   }
sub delete     { return $_[0]{delete}     }
sub project_id { return $_[0]{project_id} }
sub server     { return $_[0]{server}     }
sub run_as_api { return $_[0]{run_as_api} }

__END__

=encoding utf8

=head1 NAME

App::Smolder::Report - Report test runs to a smoke server

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

    # You should use the smolder_report frontend really...
    
    use App::Smolder::Report;

    my $app = App::Smolder::Report->new();
    $app->process_args(@ARGV);
    $app->run;


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-smolder-report at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Smolder-Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Smolder::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Smolder-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Smolder-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Smolder-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Smolder-Report>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Smolder::Report
