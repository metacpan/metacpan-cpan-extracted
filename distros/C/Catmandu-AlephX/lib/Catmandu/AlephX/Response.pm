package Catmandu::AlephX::Response;
use Catmandu::Sane;
use Moo::Role;
use Catmandu::Util qw(:is :check);
use Catmandu::AlephX::XPath::Helper qw(:all);
use Exporter qw(import);
our @EXPORT_OK=qw(get_children xpath);
our %EXPORT_TAGS = (all=>[@EXPORT_OK]);

our $VERSION = "1.071";

=head1 NAME

  Catmandu::AlephX::Response - base class for xml-responses from the AlephX-server

=head1 SYNOPSIS

  All responses from the AlephX-server share the same functionality and keys:
    - expressed in XML
    - name of the parent element is equal to the parameter 'op', except when
      the value in 'op' is not recognized. Then it is set to 'login'.
    - when an internal error occurred, the error is reported in the key 'error'
    - session-id is reported in the key 'session-id'
    - al the other subkeys are be treated as 'data'

  All public methods from Catmandu::AlephX return an object of a subclass of Catmandu::AlepX::Response.
  In case of connection errors, or xml parsing problems, exceptions are thrown.

=head1 methods

=head2 op

  type of 'op'.

=head2 error

  internal error that was reported in the xml response.
  These errors only apply to values in your parameters.
  Other errors, like connection errors or problems while parsing the xml response are thrown as exceptions.

=head2 session_id

  session-id of the current request

=head2 is_success

  This method only checks if there was an internal error in the AlephX-response.
  So it simply tests if the key 'error' was undefined.

  As said before, other errors are thrown as exceptions

=cut

requires qw(op parse);
has errors => (
  is => 'rw',
  isa => sub { check_array_ref($_[0]); },
  lazy => 1,
  default => sub { []; }
);
#deprecated, use $self->errors
sub error {
  warn "method 'error' is deprecated, and only return one error. Please use method 'errors' which gives you an array reference of all errors.";
  $_[0]->errors()->[-1];
}
has session_id => (is => 'rw');
sub is_success {
  return !scalar(@{$_[0]->errors()});
}
has content_ref => (
  is => 'rw'
);
sub parse_errors {
  my($self,$xpath)=@_;
  my $op = $self->op();
  [map { $_->to_literal; } $xpath->find("/$op/error|/login/error|/$op/error-text-1|/$op/error-text-2")->get_nodelist()];
}

1;
