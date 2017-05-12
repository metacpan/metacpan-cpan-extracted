package Dancer::Plugin::KossyValidator;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Hash::MultiValue;


our $VERSION = '0.04';

our %VALIDATOR = (
    NOT_NULL => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        return if $val eq "";
        return 1;
    },
    CHOICE => sub {
        my ($req, $val, @args) = @_;
        for my $c (@args) {
            if ($c eq $val) {
                return 1;
            }
        }
        return;
    },
    INT => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        $val =~ /^\-?[\d]+$/;
    },
    UINT => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        $val =~ /^\d+$/;  
    },
    NATURAL => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        $val =~ /^\d+$/ && $val > 0;
    },
    '@SELECTED_NUM' => sub {
        my ($req,$vals,@args) = @_;
        my ($min,$max) = @args;
        scalar(@$vals) >= $min && scalar(@$vals) <= $max
    },
    '@SELECTED_UNIQ' => sub {
        my ($req,$vals) = @_;
        my %vals;
        $vals{$_} = 1 for @$vals;
        scalar(@$vals) == scalar keys %vals;
    },
);

register validator => sub {
    my $rule = shift || [];

    my @errors;
    my $valid = Hash::MultiValue->new;
    my $req = request;

    for ( my $i=0; $i < @$rule; $i = $i+2 ) {
        my $param = $rule->[$i];
        my $constraints;
        my $param_name = $param;
        $param_name =~ s!^@!!;
        my @vals = param($param_name);
        my $vals = ( $param =~ m!^@! ) ? \@vals : [$vals[-1]];

        if ( ref($rule->[$i+1]) && ref($rule->[$i+1]) eq 'HASH' ) {
            if ( $param !~ m!^@! && !$VALIDATOR{NOT_NULL}->($req,$vals->[0])  && exists $rule->[$i+1]->{default} ) {
                my $default = $rule->[$i+1]->{default};
                $vals = [$default];
            }
            $constraints = $rule->[$i+1]->{rule};
        }
        else {
            $constraints = $rule->[$i+1];
        }

        my $error;
        PARAM_CONSTRAINT: for my $constraint ( @$constraints ) {
            if ( ref($constraint->[0]) eq 'ARRAY' ) {
                my @constraint = @{$constraint->[0]};
                my $constraint_name = shift @constraint;
                if ( ref($constraint_name) && ref($constraint_name) eq 'CODE' ) {
                    for my $val ( @$vals ) {
                        if ( !$constraint_name->($req, $val, @constraint) ) {
                            push @errors, { param => $param_name, message => $constraint->[1] };
                            $error=1;
                            last PARAM_CONSTRAINT;
                        }
                    }
                    next PARAM_CONSTRAINT;
                }
                die "constraint:$constraint_name not found" if ! exists $VALIDATOR{$constraint_name};
                if ( $constraint_name =~ m!^@! ) {
                    if ( !$VALIDATOR{$constraint_name}->($req,$vals,@constraint) ) {
                        push @errors, { param => $param_name, message => $constraint->[1] };
                        $error=1;
                        last PARAM_CONSTRAINT;
                    }                    
                }
                else {
                    for my $val ( @$vals ) {
                        if ( !$VALIDATOR{$constraint_name}->($req,$val,@constraint) ) {
                            push @errors, { param => $param_name, message => $constraint->[1] };
                            $error=1;
                            last PARAM_CONSTRAINT;
                        }
                    }
                }
            }
            elsif ( ref($constraint->[0]) eq 'CODE' ) {
                for my $val ( @$vals ) {
                    if ( !$constraint->[0]->($req, $val) ) {
                        push @errors, { param => $param_name, message => $constraint->[1] };
                        $error=1;
                        last PARAM_CONSTRAINT;
                    }
                }
            }
            else {
                die "constraint:".$constraint->[0]." not found" if ! exists $VALIDATOR{$constraint->[0]};
                if ( $constraint->[0] =~ m!^@! ) {
                    if ( !$VALIDATOR{$constraint->[0]}->($req,$vals) ) {
                        push @errors, { param => $param_name, message => $constraint->[1] };
                        $error=1;
                        last PARAM_CONSTRAINT;
                    }                    
                }
                else {
                    for my $val ( @$vals ) {
                        if ( !$VALIDATOR{$constraint->[0]}->($req, $val) ) {
                            push @errors, { param => $param_name, message => $constraint->[1] };
                            $error=1;
                            last PARAM_CONSTRAINT;
                        }
                    }
                }
            }
        }
        $valid->add($param_name,@$vals) unless $error;
    }
    
    Kossy::Validator::Result->new(\@errors,$valid);
};

register_plugin;

package Kossy::Validator::Result;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $errors = shift;
    my $valid = shift;
    bless {errors=>$errors,valid=>$valid}, $class;
}

sub has_error {
    my $self = shift;
    return 1 if @{$self->{errors}};
    return;
}

sub messages {
    my $self = shift;
    my @errors = map { $_->{message} } @{$self->{errors}};
    \@errors;
}

sub errors {
    my $self = shift;
    my %errors = map { $_->{param} => $_->{message} } @{$self->{errors}};
    \%errors;
}

sub valid {
    my $self = shift;
    if ( @_ == 2 ) {
        $self->{valid}->add(@_);
        return $_[1];
    }
    elsif ( @_ == 1 ) {
        return $self->{valid}->get($_[0]) if ! wantarray;
        return $self->{valid}->get_all($_[0]);
    }
    $self->{valid};
}

1;

=head1 NAME

Dancer::Plugin::KossyValidator - 根据 Kossy 中的 Validator 移植过来的模块

=head1 SYNOPSIS

    use Dancer ':syntax';
    use Dancer::Plugin::KossyValidator;

    any ['post', 'put'] => '/isp' => sub {
        my $result = validator([
            'name' => {
                rule => [
                    ['NOT_NULL', '运营商名不能为空'],
                ],  
            },  
            'description' => {
                default => '无',
                rule    => [], 
            },  
        ]); 
    
        return {
            result => 'false',
            messages => $result->errors
        } if $result->has_error;

        $result->has_error:Flag
        $result->messages:ArrayRef[`Str]
         
        my $val = $result->valid('name');  # 注意取请求过来的参数时原函数 param 替换为 valid 了
        my @val = $result->valid('description');
         
        my $hash = $result->valid:Hash::MultiValue;
        # ...
    };

    dancer;

=head1 DESCRIPTION

Kossy 是 Perl 中另一个迷你框架，这个模块根据 Kossy 中的 Validator 移植过来支持 Dancer 的模块。

=head1 VALIDATORS

=over 4

=item NOT_NULL

=item CHOICE

  ['CHOICE',qw/dog cat/]

=item INT

int

=item UINT

unsigned int

=item NATURAL

natural number

=item @SELECTED_NUM

  ['@SELECTED_NUM',min,max]

=item @SELECTED_UNIQ

all selected values are unique

=back

=head1 CODEref VALIDATOR

  my $result = validator([
      'q' => [
          [sub{
              my ($req,$val) = @_;
          },'invalid']
      ],
  ]);
  
  my $result = validator([
      'q' => [
          [[sub{
              my ($req,$val,@args) = @_;
          },0,1],'invalid']
      ],
  ]);


=head1 AUTHOR

原模块作者 Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt> 移植人: 扶凯 iakuf {at} 163.com

=head1 SEE ALSO

L<Kossy::Validator>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

