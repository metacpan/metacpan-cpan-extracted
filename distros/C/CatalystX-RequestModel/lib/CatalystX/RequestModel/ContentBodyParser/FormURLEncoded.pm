package CatalystX::RequestModel::ContentBodyParser::FormURLEncoded;

use warnings;
use strict;
use base 'CatalystX::RequestModel::ContentBodyParser';

sub content_type { 'application/x-www-form-urlencoded' }

sub default_attr_rules { 
  my ($self, $attr_rules) = @_;
  return +{ flatten=>1, %$attr_rules };
}

sub expand_cgi { 
  my ($self) = shift;
  my $params = (($self->{ctx}->req->method eq 'GET') || ($self->{request_model}->get_content_in eq 'query')) ?
    $self->{ctx}->req->query_parameters :
      $self->{ctx}->req->body_parameters;

  my $data = +{};
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

CatalystX::RequestModel::ContentBodyParser::FormURLEncoded - Parse HTML Form POSTS

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Given a flat list of HTML Form posted parameters will attempt to convert it to a hash of values,
with nested and arrays of nested values as needed.  For example you can convert something like:

    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | person.username                     | jjn                                  |
    | person.first_name [multiple]        | 2, John                              |
    | person.last_name                    | Napiorkowski                         |
    | person.password                     | abc123                               |
    | person.password_confirmation        | abc123                               |
    '-------------------------------------+--------------------------------------'

Into:

    {
      first_name => "John",
      last_name => "Napiorkowski",
      username => "jjn",
    }

Or:

    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | person.first_name [multiple]        | 2, John                              |
    | person.last_name                    | Napiorkowski                         |
    | person.person_roles[0]._nop         | 1                                    |
    | person.person_roles[1].role_id      | 1                                    |
    | person.person_roles[2].role_id      | 2                                    |
    | person.username                     | jjn                                  |
    '-------------------------------------+--------------------------------------'

Into:

    {
      first_name => "John",
      last_name => "Napiorkowski",
      username => "jjn",
      person_roles => [
        {
          role_id => 1,
        },
        {
          role_id => 2,
        },
      ],
    }

We define some settings described below to help you deal with some of the issues you find when trying
to parse HTML form posted body content.  For now please see the test cases for more examples.

=head1 VALUE PARSER CONFIGURATION

This parser defines the following attribute properties which effect how a value is parsed.

=head2 flatten

If the value associated with a field is an array, flatten it to a single value.  Its really a hack to deal
with HTML form POST and Query parameters since the way those formats work you can't be sure if a value is
flat or an array.

=head2 always_array

Similar to C<flatten> but opposite, it forces a value into an array even if there's just one value.

B<NOTE>: The attribute property settings C<flatten> and C<always_array> are currently exclusive (only one of
the two will apply if you supply both.  The C<always_array> property always takes precedence.  At some point
in the future supplying both might generate an exception so its best not to do that.  I'm only leaving it
allowed for now since I'm not sure there's a use case for both.

=head1 INDEXING

When POSTing deeply nested forms with repeated elements you can use a naming convention to indicate ordering:

    param[index]...

For example:

    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | person.person_roles[0]._nop         | 1                                    |
    | person.person_roles[1].role_id      | 1                                    |
    | person.person_roles[2].role_id      | 2                                    |
    | person.person_roles[].role_id       | 3                                    |
    '-------------------------------------+--------------------------------------'

Could convert to:

    [
      {
        role_id => 1,
      },
      {
        role_id => 2,
      },
    ]

Please note the the index value is just used for ordering purposed, the actual value is tossed after its
used to do the sorting.  Also if you just need to add a new item to the end of the indexed list you can use an
empty index '[]' as in the example above.  You might find this useful if you are building HTML forms and need
to tack on an extra value but don't know the last index.

=head1 HTML FORM POST ISSUES

Many HTML From input controls don't make it easy to send a default value if they are left blank.  For example
HTML checkboxes will not send a 'false' value if you leave them unchecked.  To deal with this issue you can either
set a default attribute property or you can use a hidden field to send the 'unchecked' value and rely on the
flatten option to choose the correct value.

You may also have this issue with indexed parameters if the indexed parameters are associated with a checkbox
or other control that sends no default value.  In that case you can do the same thing, either set a default
empty arrayref as the value for the attribute or send a ignored indexed parameter (as in the above example '_nop').

=head1 EXCEPTIONS

See L<CatalystX::RequestModel::ContentBodyParser> for exceptions.

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut
