package Dancer::Plugin::DataTransposeValidator::Validator;

use Data::Transpose::Validator;
use File::Spec;
use Moo;
use namespace::clean;

=head1 NAME

Dancer::Plugin::DataTransposeValidator::Validator - validator class for
Dancer::Plugin::DataTransposeValidator

=head1 METHODS

=head2 additional_args

Any additional arguments passed in to validator are passed as arguments
to L</rules_file> if it contains a code reference.

=cut

has additional_args => (
    is => 'ro',
    isa => sub {
        die "params must be as array reference" unless ref( $_[0] ) eq 'ARRAY';
    },
    default => sub { [] },
);

=head2 appdir

Dancer's appdir. Required.

=cut

has appdir => (
    is  => 'ro',
    isa => sub {
        die "appdir must be a valid string"
          unless ( defined $_[0] && $_[0] =~ /\S/ );
        die "appdir must be a valid directory" unless -d $_[0];
    },
    required => 1,
);

=head2 css_error_class

Returns the value supplied via L</plugin_setting> or 'has-error'.

=cut

has css_error_class => (
    is  => 'lazy',
    isa => sub {
        die "rules_file must be a valid string"
          unless ( defined $_[0] && $_[0] =~ /\S/ );
    },
);

sub _build_css_error_class {
    my $self = shift;
    return
      defined $self->plugin_setting->{css_error_class}
      ? $self->plugin_setting->{css_error_class}
      : 'has-error';
}

=head2 params

Hash reference of params to validate. Required.

=cut

has params => (
    is  => 'ro',
    isa => sub {
        die "params must be a hash reference" unless ref( $_[0] ) eq 'HASH';
    },
    required => 1,
);

=head2 plugin_setting

plugin_setting hash reference. Required.

=cut

has plugin_setting => (
    is  => 'ro',
    isa => sub {
        die "plugin_setting must be a hash reference"
          unless ref( $_[0] ) eq 'HASH';
    },
    required => 1,
);

=head2 rules_dir

rules_dir setting from L</plugin_setting> or 'validation' if that is undef

=cut

has rules_dir => (
    is  => 'lazy',
    isa => sub {
        die "rules directory does not exist: $_[0]" unless -d $_[0];
    },
);

sub _build_rules_dir {
    my $self = shift;
    my $dir =
      defined $self->plugin_setting->{rules_dir}
      ? $self->plugin_setting->{rules_dir}
      : 'validation';
    return File::Spec->catdir( $self->appdir, $dir );
}

=head2 rules_file

The name of the rules file. Required.

=cut

has rules_file => (
    is  => 'ro',
    isa => sub {
        die "rules_file must be a valid string"
          unless ( defined $_[0] && $_[0] =~ /\S/ );
    },
    required => 1,
);

=head2 rules

The rules produced via eval of L</rules_file>

=cut

has rules => (
    is  => 'lazy',
    isa => sub {
        die "plugin_setting must be a hash reference"
          unless ref( $_[0] ) eq 'HASH';
    },
);

sub _build_rules {
    my $self  = shift;
    my $path  = File::Spec->catfile( $self->rules_dir, $self->rules_file );
    my $rules = do $path or die "bad rules file: $path - $! $@";
    if ( ref($rules) eq 'CODE' ) {
        return $rules->( @{ $self->additional_args } );
    }
    return $rules;
}

=head2 transpose

Uses Data::Transpose::Validator to transpose and validate L</params>.

=cut

sub transpose {
    my $self = shift;

    my $rules = $self->rules;

    my $options = $rules->{options} || {};
    my $prepare = $rules->{prepare} || {};

    my $dtv = Data::Transpose::Validator->new(%$options);
    $dtv->prepare(%$prepare);

    my $params = $self->params;

    my $clean = $dtv->transpose($params);
    my $ret;

    if ($clean) {
        $ret->{valid}  = 1;
        $ret->{values} = $clean;
    }
    else {
        $ret->{valid}  = 0;
        $ret->{values} = $dtv->transposed_data;

        my $errors_hash = $self->plugin_setting->{errors_hash};

        my $v_hash = $dtv->errors_hash;
        while ( my ( $key, $value ) = each %$v_hash ) {

            $ret->{css}->{$key} = $self->css_error_class;

            my @errors = map { $_->{value} } @{$value};

            if ( $errors_hash && $errors_hash eq 'joined' ) {
                $ret->{errors}->{$key} = join( ". ", @errors );
            }
            elsif ( $errors_hash && $errors_hash eq 'arrayref' ) {
                $ret->{errors}->{$key} = \@errors;
            }
            else {
                $ret->{errors}->{$key} = $errors[0];
            }
        }
    }
    return $ret;
}

1;
