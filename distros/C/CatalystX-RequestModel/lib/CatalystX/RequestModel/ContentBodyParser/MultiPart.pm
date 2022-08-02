package CatalystX::RequestModel::ContentBodyParser::MultiPart;

use warnings;
use strict;
use base 'CatalystX::RequestModel::ContentBodyParser';

sub content_type { 'multipart/form-data' }

sub default_attr_rules { 
  my ($self, $attr_rules) = @_;
  return +{ flatten=>1, %$attr_rules };
}

sub expand_cgi {
  my ($self) = shift;
  my $params = +{ %{$self->{ctx}->req->body_parameters}, %{$self->{ctx}->req->uploads} };


  my $data;
  foreach my $param (keys %$params) {
    my (@segments) = split /\./, $param;
    my $data_ref = \$data;
    foreach my $segment (@segments) {
      $$data_ref = {} unless defined $$data_ref;

      my ($prefix,$i) = ($segment =~m/^(.+)?\[(\d*)\]$/);
      $segment = $prefix if defined $prefix;

      die "CGI param clash for $param=$_" unless ref $$data_ref eq 'HASH';
      $data_ref = \($$data_ref->{$segment});
      $data_ref = \($$data_ref->{$i}) if defined $i;
    }
    die "CGI param clash for $param value $params->{$param}" if defined $$data_ref;
    $$data_ref = $params->{$param};
  }

  return $data;
}

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $self->{context} ||= $self->expand_cgi;

  return $self;
}

1;

=head1 NAME

CatalystX::RequestModel::ContentBodyParser::MultiPart - Parse multipart uploads

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Given a list of uploads and possible form parameters:

    [debug] "POST" request for "upload" from "127.0.0.1"
    [debug] Body Parameters are:
    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | notes                               | This is the file you seek!           |
    '-------------------------------------+--------------------------------------'
    [debug] File Uploads are:
    .--------------+----------------------------+--------------------+-----------.
    | Parameter    | Filename                   | Type               | Size      |
    +--------------+----------------------------+--------------------+-----------+
    | file         | file.txt                   |                    | 13        |
    '--------------+----------------------------+--------------------+-----------'

If you have a request model like:

    package Example::Model::UploadRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';
    content_type 'multipart/form-data';

    has notes => (is=>'ro', required=>1, property=>1);  
    has file => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

This will be mapped to an instance of the request model:

    $request_model->notes;      # 'This is the file you seek!';
    $request_model->file;     # Instance of L<Catalyst::Request::Upload>.

This is basically a subclass of L<CatalystX::RequestModel::ContentBodyParser::FormURLEncoded>
with added support for multipart form uploads.  You should see the parent file for more
details.

=head1 EXCEPTIONS

See L<CatalystX::RequestModel::ContentBodyParser> for exceptions.

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut
