package BioX::Workflow::Command::run::Rules::Directives::Inspect;

use Moose::Role;
use namespace::autoclean;

use Data::Dumper;
use Storable qw(dclone);
use YAML;

use BioX::Workflow::Command::run::Rules::Directives::Exceptions::DidNotDeclare;
use BioX::Workflow::Command::run::Rules::Directives::Exceptions::SyntaxError;

with 'BioX::Workflow::Command::inspect::Utils::ParsePlainText';

has 'inspect_obj' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { return {} },
);

has 'path' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_path',
);

sub return_rule_as_obj {
    my $self = shift;
    my $attr = shift;

    my $clean = {};
    $self->get_line_number_rules;

    foreach my $key ( @{ $self->rule_keys } ) {
        my $t = $self->check_path( $attr->$key );
        $t =~ s/__DUMMYSAMPLE123456789__/Sample_XYZ/g;
        $clean->{$key} = $t;
        $self->get_error_message( $key, $t );
    }

    my @haves = ( 'indir', 'outdir', 'INPUT', 'OUTPUT', 'stash' );
    foreach my $h (@haves) {
        next if exists $clean->{$h};
        my $t = $self->check_path( $attr->$h );
        $t =~ s/__DUMMYSAMPLE123456789__/Sample_XYZ/g;
        $clean->{$h} = $t;
        $self->get_error_message( $h, $t );
    }

    $self->inspect_obj->{rules}->{ $self->rule_name }->{local} = $clean;
    $self->inspect_obj->{rules}->{ $self->rule_name }->{rule_keys} =
      dclone( $self->rule_keys );

    return $clean;
}

sub return_global_as_object {
    my $self = shift;

    $self->get_global_keys;

    my $attr = dclone( $self->global_attr );
    $attr->walk_process_data( $self->global_keys );

    my $global = {};

    foreach my $key ( @{ $self->global_keys } ) {
        $global->{$key} = $self->check_path( $attr->{$key} );
    }
    $self->inspect_obj->{global} = $global;
}

sub check_path {
    my $self = shift;
    my $val  = shift;

    if ( ref($val) eq 'Path::Tiny' ) {
        $val = $val->stringify;
    }
    return $val;
}

sub get_error_message {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;
    my $keep = shift;

    my $msg = Dump($v);
    return unless $msg =~ m/The following errors/;

    my $template = <<EOF;
###################################################
# The following errors were encountered:
(.*)
####################################################
EOF

    my (@match) = $msg =~ m/$template/sg;
    return unless @match;
    my $error;

    if ($keep) {
        $error = join( "\n", @match );
    }
    else {
        $error = $match[0];
    }
    return unless $error;

    $error =~ s/__DUMMYSAMPLE123456789__/Sample_XYZ/g;
    my @split = split( "\n", $error );
    shift @split;

    @split = map { my $t = $_; $t =~ s/# //; $t } @split;
    $error = join( "\n\t", @split );

    return unless $error;

    $self->inspect_obj->{errors}->{rules}->{ $self->rule_name }->{local}->{$k}->{msg} =
      $error;

    $self->app_log->warn( 'Error for key \''
          . $k
          . '\' Line #: '
          . $self->inspect_obj->{line_numbers}->{rules}->{ $self->rule_name }
          ->{local}->{$k}->{line} ) if $self->inspect_obj->{line_numbers}->{rules}->{ $self->rule_name }->{local}->{$k}->{line};
    $self->inspect_obj->{errors}->{rules}->{ $self->rule_name }->{local}->{$k}
      ->{error_types} = $self->get_error_types( $k, $error );

    return $error;
}

sub get_error_types {
    my $self  = shift;
    my $k     = shift;
    my $error = shift;

    my @error_types = ();
    my $print_error = 0;
    if ( $error =~ m/Did you declare/ ) {
        my $except =
          BioX::Workflow::Command::run::Rules::Directives::Exceptions::DidNotDeclare
          ->new( info => '[ERROR DidNotDeclare]: ' );
        $except->warn( $self->app_log );
        push( @error_types, 'DidNotDeclare' );
    }
    if ( $error =~ m/syntax/ ) {
        my $except =
          BioX::Workflow::Command::run::Rules::Directives::Exceptions::SyntaxError
          ->new( info => '[ERROR Syntax]: ' );
        $except->warn( $self->app_log );
        push( @error_types, 'Syntax' );
    }
    $self->app_log->warn( $error . "\n" );

    return \@error_types;

}

1;
