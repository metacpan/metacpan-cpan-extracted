package AWS::SNS::Confess;
# ABSTRACT: Publish errors to an SNS topic

use base 'Exporter';
use Amazon::SNS;
use Devel::StackTrace;
use strict;
use warnings 'all';

our @EXPORT_OK = qw/confess/;

our ($access_key_id, $secret_access_key, $topic, $sns, $sns_topic);

sub setup
{
  my (%args) = @_;
  $access_key_id = $args{access_key_id};
  $secret_access_key = $args{secret_access_key};
  $topic = $args{topic};
  $sns = $args{sns} || Amazon::SNS->new({
    key => $access_key_id,
    secret => $secret_access_key,
  });
  $sns->service(_service_url());
  $sns_topic = $sns->GetTopic($topic);
}

sub confess
{
  my ($msg) = @_;
  my $full_message = "Runtime Error: $msg\n"
    . Devel::StackTrace->new->as_string;

  _send_msg( $full_message );
  die $msg;
}

sub _service_url
{
  die "no topic specified" unless $topic;
  if ($topic =~ m/^arn:aws:sns:([^:]+):\d+:[^:]+$/)
  {
    return "http://sns.$1.amazonaws.com";
  }
  return "http://sns.us-east-1.amazonaws.com";
}

sub _send_msg
{
  $sns_topic->Publish(shift);
}

1;



__END__
=pod

=head1 NAME

AWS::SNS::Confess - Publish errors to an SNS topic

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use AWS::SNS::Confess 'confess';
  AWS::SNS::Confess::setup(
    access_key_id => 'E654SAKIASDD64ERAF0O',
    secret_access_key => 'LgTZ25nCD+9LiCV6ujofudY1D6e2vfK0R4GLsI4H'
    topic => 'arn:aws:sns:us-east-1:738734873:YourTopic',
  );
  confess "Something went wrong";

=head1 DESCRIPTION

AWS::SNS::Confess uses L<Amazon::SNS> to post any errors to an Amazon SNS
feed for more robust management from there.

=head1 NAME

AWS::S3 - Publish Errors, with a full stack trace to an Amazon SNS
topic

=head1 PUBLIC METHODS

=head2 setup( access_key_id => $aws_access_key_id, secret_access_key => $aws_secret_access_key, topic => $aws_topic );

Sets up to send errors to the given AWS Account and Topic

=head2 confess( $msg );

Publishes the given error message to SNS with a full stack trace

=head1 SEE ALSO

L<Amazon::SNS>

L<Carp>

=head1 AUTHOR

Tristan Havelick <tristan@havelick.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Tristan Havelick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

