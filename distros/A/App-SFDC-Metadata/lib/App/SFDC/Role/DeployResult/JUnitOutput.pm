package App::SFDC::Role::DeployResult::JUnitOutput;
# ABSTRACT: Provides JUnit output functionality to DeployResults

use strict;
use warnings;

use Log::Log4perl ':easy';

our $VERSION = '0.21'; # VERSION

use Moo::Role;

sub _printTestSuccesses {
    my ($self, $FH) = @_;
    return unless $self->complete
        and exists $self->result->{details}->{runTestResult}->{successes};
    print $FH $_ for map {
        my $time = $$_{time}/1000;
        "\n<testcase\n\tname='$$_{methodName}'\n\tclassname='$$_{name}'\n\ttime='$time'>\n</testcase>"} 
        (
            ref $self->result->{details}->{runTestResult}->{successes} eq 'ARRAY'
                ? @{$self->result->{details}->{runTestResult}->{successes}}
                : $self->result->{details}->{runTestResult}->{successes}
        );
}

sub _printTestFailures {
    my ($self, $FH) = @_;
    return unless $self->testFailures;
    print $FH $_ for map {
      my $time = $$_{time}/1000;
      my $stackTrace = '';
      $stackTrace = $$_{stackTrace} if (defined($$_{stackTrace}));
      "\n<testcase\n\tname='$$_{methodName}'\n\tclassname='$$_{name}'\n\ttime='$time'>\n\t<failure>\n\t\t<![CDATA[$stackTrace - $$_{message}]]>\n\t</failure>\n</testcase>"} 
    @{
      $self->testFailures
    };

}


sub printToJUnit {
  my ($self, $fileName) = @_;

  return unless $self->result->{runTestsEnabled} eq 'true';
  INFO "Writing test results to $fileName";
  open my $FH, '>', $fileName
    or ERROR "Couldn't open $fileName for writing: $!";
  print $FH '<?xml version="1.0" encoding="UTF-8"?>';
  print $FH "\n".'<testsuite name="SFDC Unit Tests">';
  $self->_printTestSuccesses($FH);
  $self->_printTestFailures($FH);
  print $FH "\n".'</testsuite>';
}

1;

__END__

=pod

=head1 NAME

App::SFDC::Role::DeployResult::JUnitOutput - Provides JUnit output functionality to DeployResults

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    my $deployResult = WWW::SFDC::Metadata::DeployResult->new(%args);
    Role::Tiny->apply_roles_to_object($deployResult, 'App::SFDC::Role::DeployResult::JUnitOutput');
    $deployResult->printToJUnit($fileName);

=head1 METHODS

=head2 printToJUnit

Accepts a filename and prints JUnit-formatted test results to that file.

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
