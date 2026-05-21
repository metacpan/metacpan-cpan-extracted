package CPAN::Maker::Bootstrapper::Role::LLM::Models;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use CLI::Simple::Constants qw(:booleans);

use Role::Tiny;

########################################################################
sub cmd_models {
########################################################################
  my ($self) = @_;

  my ($api_key) = $self->get_args;

  my $llm = $self->_check_llm($api_key);

  $self->_show_models( $llm->models );

  return $SUCCESS;
}

########################################################################
sub _show_models {
########################################################################
  my ( $self, $models ) = @_;

  require Text::ASCIITable;

  if ( !$models || !%{$models} ) {
    print {*STDOUT} "No models available.\n\n";
    return;
  }

  my $t = Text::ASCIITable->new( { headingText => 'Available Models' } );

  $t->setCols( 'Model ID', 'Display Name', 'Context', 'Output', 'Released', 'Capabilities' );
  $t->setColWidth( 'Model ID',     30 );
  $t->setColWidth( 'Display Name', 18 );
  $t->setColWidth( 'Context',      9 );
  $t->setColWidth( 'Output',       9 );
  $t->setColWidth( 'Released',     10 );
  $t->setColWidth( 'Capabilities', 30 );

  foreach my $model_id ( sort keys %{$models} ) {
    my $m    = $models->{$model_id};
    my $caps = $m->{capabilities} // {};

    my $display  = $m->{display_name} // q{-};
    my $context  = _fmt_tokens( $m->{max_input_tokens} );
    my $output   = _fmt_tokens( $m->{max_tokens} );
    my $released = ( $m->{created_at} // q{} ) =~ s/T.+//xsmr;

    my $cap_str = join q{ }, grep {defined} ( $caps->{thinking}{supported} ? 'think' : undef ),
      ( $caps->{image_input}{supported}        ? 'img'    : undef ),
      ( $caps->{pdf_input}{supported}          ? 'pdf'    : undef ),
      ( $caps->{code_execution}{supported}     ? 'code'   : undef ),
      ( $caps->{batch}{supported}              ? 'batch'  : undef ),
      ( $caps->{citations}{supported}          ? 'cite'   : undef ),
      ( $caps->{structured_outputs}{supported} ? 'json'   : undef ),
      ( $caps->{effort}{supported}             ? 'effort' : undef );

    $t->addRow( $model_id, $display, $context, $output, $released, $cap_str );
  }

  print {*STDOUT} $t;

  printf {*STDOUT} "%d model%s.\n\n", scalar keys %{$models}, scalar keys %{$models} == 1 ? q{} : q{s};

  return;
}

1;
