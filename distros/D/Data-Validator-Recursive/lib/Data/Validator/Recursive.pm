package Data::Validator::Recursive;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.07';

use Carp 'croak';
use Data::Validator;

sub new {
    my ($class, @args) = @_;
    croak "Usage: Data::Validator::Recursive->new(\$arg_name => \$rule [, ... ])" unless @args;

    my $self = bless {
        validator         => undef,
        nested_validators => [],
        error             => undef,
    }, ref $class || $class;

    $self->_build_rules(@args);
    return $self;
}

sub _build_rules {
    my ($self, @args) = @_;

    for (my ($i, $l) = (0, scalar @args); $i < $l; $i += 2) {
        my ($name, $rule) = @args[$i, $i+1];
        $rule = { isa => $rule } unless ref $rule eq 'HASH';

        if (my $nested_rule = delete $rule->{rule}) {
            if (ref $nested_rule eq 'HASH') {
                $nested_rule = [ %$nested_rule ];
            }
            elsif (ref $nested_rule ne 'ARRAY') {
                croak "$name.rule must be ARRAY or HASH";
            }

            $rule->{isa} ||= 'HashRef';
            my $with = delete $rule->{with};
            my $validator = $self->new(@$nested_rule);
            if ($with) {
                $with = [ $with ] unless ref $with eq 'ARRAY';
                $validator->with(@$with);
            }

            push @{ $self->{nested_validators} }, {
                name      => $name,
                validator => $validator,
            };
        }
    }

    $self->{validator} = Data::Validator->new(@args)->with('NoThrow');
}

sub with {
    my ($self, @extentions) = @_;
    $self->{validator}->with(@extentions);
    return $self;
}

sub validate {
    my ($self, $params, $_parent_name) = @_;
    $self->{errors} = undef;

    my ($result) = $self->{validator}->validate($params);
    if (my $errors = $self->{validator}->clear_errors) {
        $self->{errors} = [
            map {
                my $name = $_parent_name ? "$_parent_name.$_->{name}" : $_->{name};
                my $type = $_->{type};
                my ($message, $other_name);
                if ($type eq 'ExclusiveParameter') {
                    $other_name = $_parent_name
                        ? "$_parent_name.$_->{conflict}" : $_->{conflict};
                    $message = sprintf q{'%s' and '%s' is %s}, $name, $other_name, $type;
                }
                elsif ($type eq 'InvalidValue') {
                    my $org_message = (split ': ', $_->{message}, 2)[1];
                    $message = sprintf q{Invalid value for '%s': %s}, $name, $org_message;
                }
                elsif ($type eq 'MissingParameter') {
                    my $org_message = (split ': ', $_->{message}, 2)[1];
                    $org_message =~ s/'([^']+)'/'$_parent_name.$1'/g if $_parent_name;
                    $message = sprintf q{Missing parameter: %s}, $org_message;
                }
                else {
                    $message = sprintf q{'%s' is %s}, $name, $type;
                }

                +{
                    type    => $type,
                    name    => $name,
                    message => $message,
                    defined $other_name ? (conflict => $other_name) : (),
                };
            } @$errors
        ];
        return;
    }

    for my $rule (@{ $self->{nested_validators} }) {
        my $name = $rule->{name};
        next unless exists $result->{$name};

        my $validator = $rule->{validator};

        my $result_in_nested;
        if (ref $result->{$name} eq 'ARRAY') {
            $result_in_nested = [];
            my $i = 0;
            for my $child_params (@{ $result->{$name} }) {
                my $indexed_name = sprintf('%s[%d]', $name, $i++);
                my ($child_result) = $validator->validate($child_params, $_parent_name ? "$_parent_name.$indexed_name" : $indexed_name);
                if (my $errors = $validator->errors) {
                    $self->{errors} = $errors;
                    return;
                }
                push @$result_in_nested, $child_result;
            }
        }
        else {
            ($result_in_nested) = $validator->validate($result->{$name}, $_parent_name ? "$_parent_name.$name" : $name);
        }

        if (my $errors = $validator->errors) {
            $self->{errors} = $errors;
            return;
        } else {
            $result->{$name} = $result_in_nested;
        }
    }

    return $result;
}

sub error {
    my $self = shift;
    my $errors = $self->errors or return;
    $errors->[0];
}

sub errors {
    my $self = shift;
    $self->{errors};
}

sub has_errors {
    my $self = shift;
    $self->{errors} ? 1 : 0;
}
*has_error = *has_errors; # backward compatible

sub clear_errors {
    my $self = shift;
    delete $self->{errors};
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Validator::Recursive - recursive data friendly Data::Validator

=head1 SYNOPSIS

  use Data::Validator::Recursive;

  # create a new rule
  my $rule = Data::Validator::Recursive->new(
      foo => 'Str',
      bar => { isa => 'Int' },
      baz => {
          isa  => 'HashRef', # default
          rule => [
              hoge => { isa => 'Str', optional => 1 },
              fuga => 'Int',
          ],
      },
  );

  # input data for validation
  $input = {
      foo => 'hoge',
      bar => 1192,
      baz => {
          hoge => 'kamakura',
          fuga => 1185,
      },
  };

  # do validation
  my $params = $rule->validate($iput) or croak $rule->error->{message};

=head1 DESCRIPTION

Data::Validator::Recursive is recursive data friendly Data::Validator.

You are creates the validation rules contain C<< NoThrow >> as default.

=head1 METHODS

=head2 C<< new($arg_name => $rule [, ... ]) : Data::Validator::Recursive >>

Create a validation rule.

  my $rule = Data::Validator::Recursive->new(
      foo => 'Str',
      bar => { isa => 'Int' },
      baz => {
          rule => [
              hoge => { isa => 'Str', optional => 1 },
              fuga => 'Int',
          ],
      },
  );

I<< $rule >>'s attributes is L<< Data::Validator >> compatible, And additional attributes as follows:

=over

=item C<< rule => $rule : Array | Hash | Data::Validator::Recursive | Data::Validator >>

You can defined a I<< $rule >> recursively to I<< rule >>.

For example:

  my $rule = Data::Validator::Recursive->new(
      foo => {
        rule => [
            bar => {
                baz => [
                    rule => ...
                ],
            },
        ],
      }
  );

=item C<< with => $extention : Str | Array >>

Applies I<< $extention >> to this rule.

See also L<< Data::Validator >>.

=back

=head2 C<< with(@extentions) >> : Data::Validator::Recursive

Applies I<< @extention >> to this rule.

See also L<< Data::Validator >>.

=head2 C<< validate(@args) : \%hash | undef >>

Validates I<< @args >> and returns a restricted HASH reference, But return undefined value if there found invalid parameters.

  my $params = $rule->validate(@args) or croak $rule->error->{message};

=head2 C<< has_errors() : Bool >>

Return true if there is an error.

   $rule->validate($params);
   if ($rule->has_errors) {
      ...
   }

=head2 C<< errors() : \@errors | undef >>

Returns last error datum or undefined value.

  my $errors = $rule->errors;
  # $error = [
  #     {
  #         name    => 'xxx',
  #         type    => 'xxx',
  #         message => 'xxx',
  #     },
  #     { ... },
  #     ...
  # ]

=head2 C<< error() : \%error | undef >>

Returns last first error data or undefined value.

  my $error = $rule->error;
  # $error = $rule->errors->[0]

=head2 C<< clear_errors  : \@errors | undef >>

Clear last errors after return last errors or undefined value.

  my $errors = $rule->clear_errors;
  say $rule->has_errors; # 0

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {@} GMAIL.COME<gt>

=head1 CONTRIBUTORS

punytan

=head1 COPYRIGHT

Copyright 2013 - Yuji Shimada

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< Data::Validator >>

=cut
