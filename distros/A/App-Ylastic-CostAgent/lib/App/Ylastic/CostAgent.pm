#
# This file is part of App-Ylastic-CostAgent
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
use 5.010;
use strict;
use warnings;
use utf8;

package App::Ylastic::CostAgent;
BEGIN {
  $App::Ylastic::CostAgent::VERSION = '0.006';
}
# ABSTRACT: Perl port of the Ylastic Cost Agent for Amazon Web Services

# Dependencies
use autodie 2.00;
use Archive::Zip qw( :CONSTANTS );
use Carp qw/croak/;
use Config::Tiny;
use File::Spec::Functions qw/catfile/;
use File::Temp ();
use Log::Dispatchouli 2;
use Mozilla::CA;      # force dependency to trigger SSL validation
use IO::Socket::SSL;  # force dependency to trigger SSL support
use Time::Piece;
use Time::Piece::Month;
use WWW::Mechanize;

use Object::Tiny qw(
  accounts
  config_file
  dir
  logger
  mech
  upload
  ylastic_id
);

my %URL = (
  ylastic_service_list  => "http://ylastic.com/cost_services.list",
  ylastic_upload_form   => "http://ylastic.com/usage_upload.html",
  aws_usage_report_form => "https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=usage-report",
);

#--------------------------------------------------------------------------#
# new -- constructor
#
# Parameters for new:
#   * config_file -- path to a .ini style configuration file (required)
#   * dir -- a directory to hold downloaded data (defaults to a tempdir)
#   * logger -- a Log::Dispatchouli object (defaults to a null logger)
#   * upload -- whether to upload data to Ylastic (default is false)
#--------------------------------------------------------------------------#

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( @_ );

  croak __PACKAGE__ . " requires a valid 'config_file' argument\n"
    unless $self->config_file && -r $self->config_file;

  $self->{logger} ||= Log::Dispatchouli->new({ident => __PACKAGE__, to_self => 1});
  $self->{dir} ||= File::Temp::tempdir();
  $self->_parse_config;

  return $self;
}

#--------------------------------------------------------------------------#
# run -- downloads and possibly uploads data for all accounts from config
#--------------------------------------------------------------------------#

sub run {
  my $self = shift;

  for my $account ( @{ $self->accounts } ) {
    my $zipfile = $self->_download_usage( $account );
    $self->_upload_usage( $account, $zipfile )
      if $self->upload;
  }

  return 0;
}

#--------------------------------------------------------------------------#
# private
#--------------------------------------------------------------------------#

sub _do_aws_login {
  my ($self, $id,$user, $pass) = @_;
  $self->mech->get($URL{aws_usage_report_form});
  $self->mech->submit_form(
    form_name => 'signIn',
    fields => {
      email => $user,
      password => $pass,
    }
  );
  $self->logger->log_debug(["Logged into AWS for account %s as %s", $id, $user]);
}

sub _download_usage {
  my ($self, $account) = @_;
  my ($id, $user, $pass) = @$account;
  $self->_initialize_mech;
  $self->_do_aws_login( $id, $user, $pass );

  my $zip = Archive::Zip->new;

  for my $service ( @{ $self->_service_list } ) {
    my $usage = $self->_get_service_usage($id, $service);
    if ( length $usage > 70 ) {
      $self->logger->log_debug("Got $service data for account $id");
      my $filename = sprintf("%s_%s_%s\.csv", $self->ylastic_id, $id, $service);
      my $member = $zip->addString( $usage => $filename );
      $member->desiredCompressionLevel( 9 );
    }
    else {
      $self->logger->log_debug("No $service data available for account $id");
    }
  }

  # write zipfile
  my $zipname = sprintf("%s_%s_aws_usage.zip", $self->ylastic_id, $id);
  my $zippath = catfile($self->dir, $zipname);
  $zip->writeToFileNamed( $zippath );

  $self->logger->log(["Downloaded AWS usage reports for account %s", $id]);

  return $zippath;
}

sub _end_date {
  state $end_date =  Time::Piece::Month->new(
    Time::Piece->new()
  )->next_month->start;
  return $end_date;
}

sub _get_service_usage {
  my ($self, $id, $service) = @_;
  my $usage;

  ATTEMPT: for ( 0 .. 2 ) {
    eval {
      $self->mech->get($URL{aws_usage_report_form});

      $self->mech->submit_form(
        form_name => 'usageReportForm',
        fields => {
          productCode => $service,
        }
      );

      my $action = 'download-usage-report-csv';
      my $form = $self->mech->form_name('usageReportForm');
      return unless $form && $form->find_input($action);

      $self->mech->submit_form(
        form_name => 'usageReportForm',
        button => $action,
        fields => {
          productCode => $service,
          timePeriod  => 'aws-portal-custom-date-range',
          startYear   => $self->_start_date->year,
          startMonth  => $self->_start_date->mon,
          startDay    => $self->_start_date->mday,
          endYear     => $self->_end_date->year,
          endMonth    => $self->_end_date->mon,
          endDay      => $self->_end_date->mday,
          periodType  => 'days',
        }
      );
    };
    if ( $@ ) {
      $self->logger->log_debug("Error downloading $service for account $id: $@");
    }
    else { 
      $usage = $self->mech->content;
      last ATTEMPT;
    }
  }

  return $usage;
}

sub _initialize_mech {
  my $self = shift;
  $self->{mech} = WWW::Mechanize->new(
    quiet => 0,
    on_error => \&Carp::croak
  );
  $self->mech->agent_alias("Linux Mozilla");
  $self->mech->default_header('Accept' => 'text/html, application/xml, */*');
}

sub _parse_config {
  my $self = shift;
  my $config = Config::Tiny->read( $self->config_file )
    or croak Config::Tiny->errstr;

  $self->{ylastic_id} = $config->{_}{ylastic_id}
    or croak $self->config_file . " does not define 'ylastic_id'";

  my @accounts;
  for my $k ( keys %$config ) {
    next if $k eq "_"; # ski config root
    unless ( $k =~ /^(?:\d{12}|\d{4}-\d{4}-\d{4})$/ ) {
      warn "Invalid AWS ID '$k'.  Skipping it.";
      next;
    }
    my ($user, $pass) = map { defined $_ ? $_ : '' }
                        map { $config->{$k}{$_} } qw/user pass/;
    unless ( length $user && length $pass ) {
      warn "Invalid user/password for $k. Skipping it.";
      next;
    }
    $k =~ s{-}{}g;
    push @accounts, [$k, $user, $pass];
  }
  $self->{accounts} = \@accounts;
  $self->logger->log_debug(["Parsed config_file %s", $self->config_file]);
  return;
}

sub _service_list {
  my $self = shift;
  return $self->{services} if $self->{services};
  my $list = $self->mech->get($URL{ylastic_service_list})->decoded_content;
  chomp $list;
  return $self->{services} = [split q{,}, $list];
}

sub _start_date {
  state $start_date = Time::Piece::Month->new("2010-01-01")->start;
  return $start_date;
}

sub _upload_usage {
  my ($self, $account, $zipfile) = @_;
  $self->_initialize_mech;
  $self->mech->get($URL{ylastic_upload_form});
  $self->mech->submit_form(
    form_name => 'upload',
    fields => {
      file1 => $zipfile,
    }
  );
  $self->logger->log(["Uploaded usage reports to Ylastic for account %s",$account->[0]]);
  return;
}

1;



=pod

=head1 NAME

App::Ylastic::CostAgent - Perl port of the Ylastic Cost Agent for Amazon Web Services

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This module contains the internal routines for LE<lt>ylastic-costagentE<gt>.  Please
see that for end-user documentation.

=for Pod::Coverage new
run
accounts
config_file
dir
logger
mech
upload
ylastic_id

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-ylastic-costagent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=App-Ylastic-CostAgent>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<http://github.com/dagolden/app-ylastic-costagent/tree>

  git clone git://github.com/dagolden/app-ylastic-costagent.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__


