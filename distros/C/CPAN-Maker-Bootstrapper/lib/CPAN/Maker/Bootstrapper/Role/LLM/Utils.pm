package CPAN::Maker::Bootstrapper::Role::LLM::Utils;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use Cwd qw(abs_path);
use English qw(-no_match_vars);

use Role::Tiny;

########################################################################
sub _check_llm {
########################################################################
  my ( $self, $api_key ) = @_;

  $api_key //= $ENV{LLM_API_KEY};

  # Remove from environment so it is not inherited by child processes
  # such as 'make'. This does not protect against memory inspection
  # of the current process - see LLM::API for how the key is stored
  # using a closure to prevent accidental serialization via Dumper.
  delete $ENV{LLM_API_KEY};

  if ( !$api_key && ( my $helper = $self->get_llm_api_key_helper ) ) {
    chomp( $api_key = qx{$helper} );
    die "ERROR: llm-api-key-helper returned nothing\n" if !$api_key;
  }

  die "ERROR: you must pass an API key or set LLM_API_KEY in the environment\n"
    if !$api_key;

  eval {
    require LLM::API;
    LLM::API->import(qw($LLM_MODEL));
  };

  die "ERROR: LLM::API is required to use AI assisted commands\n"
    if $EVAL_ERROR;

  my $llm = LLM::API->new(
    api_key    => $api_key,
    max_tokens => $self->get_max_tokens,
    model      => $self->get_model,
  );

  die "ERROR: could not create an LLM::API instance\n"
    if !$llm;

  $self->set_llm($llm);

  return $llm;
}

########################################################################
sub _submit_prompt {
########################################################################
  my ( $self, $llm, $prompt ) = @_;

  my $llm_rsp = $llm->send_prompt($prompt);

  die sprintf "ERROR: API request failed: %s %s\n", $llm_rsp->status, $llm_rsp->reason
    if !$llm_rsp->is_success;

  return $llm_rsp;
}

########################################################################
sub _strip_pod {
########################################################################
  my ( $self, $file ) = @_;

  return slurp( abs_path($file) )
    if $file !~ /[.]p[ml](?:[.]in)?\z/xsm;

  require Pod::Extract;
  Pod::Extract->import('extract_pod');

  open my $fh, '<', abs_path($file)
    or die "ERROR: could not open $file for reading\n";

  my ( $pod, $code, $sections ) = extract_pod($fh);
  close $fh;

  return $code;
}

########################################################################
sub _estimate_tokens {
########################################################################
  my ( $self, $text ) = @_;

  return 0 if !$text;
  return int( length($text) / 4 );
}

########################################################################
sub _pre_submission_report {
########################################################################
  my ( $self, %args ) = @_;

  my ( $review_type, $prompt_str, $text, $annotations, $context_files, $max_tokens, $input_tokens, $input_cost ) = @args{
    qw(type prompt text annotations context_files
      max_tokens input_tokens input_cost)
  };

  my ( $input_token_cost, $output_token_cost ) = $self->get_llm->pricing( $self->get_model );

  require Text::ASCIITable;

  my $title = sprintf "%s Review: Pre-Submission Estimate\nModel: %s", ucfirst($review_type), $self->get_model;

  my $t = Text::ASCIITable->new( { headingText => $title } );
  $t->setCols( 'Component', 'Tokens', 'Cost (USD)' );
  $t->setColWidth( 'Component',  24 );
  $t->setColWidth( 'Tokens',     16 );
  $t->setColWidth( 'Cost (USD)', 20 );

  my $prompt_tokens     = $self->_estimate_tokens($prompt_str);
  my $file_tokens       = $self->_estimate_tokens($text);
  my $annotation_tokens = $self->_estimate_tokens($annotations);

  my $context_tokens = 0;
  for my $f ( @{ $context_files // [] } ) {
    $context_tokens += $self->_estimate_tokens( slurp( abs_path($f) ) );
  }

  $t->addRow( 'Prompt (est)',       $prompt_tokens,     sprintf '$%.4f', $prompt_tokens * $input_token_cost );
  $t->addRow( 'Primary file (est)', $file_tokens,       sprintf '$%.4f', $file_tokens * $input_token_cost );
  $t->addRow( 'Annotations (est)',  $annotation_tokens, sprintf '$%.4f', $annotation_tokens * $input_token_cost )
    if $annotation_tokens;
  $t->addRow( 'Context (est)', $context_tokens, sprintf '$%.4f', $context_tokens * $input_token_cost )
    if $context_tokens;
  $t->addRowLine;
  $t->addRow( 'Input total', $input_tokens, sprintf '$%.4f', $input_cost );
  $t->addRowLine;

  my $output_low  = int( $max_tokens / 2 );
  my $output_high = $max_tokens;
  my $cost_low    = $output_low * $output_token_cost;
  my $cost_high   = $output_high * $output_token_cost;

  $t->addRow(
    'Output (est)',
    sprintf( '%d - %d',       $output_low, $output_high ),
    sprintf( '$%.4f - $%.4f', $cost_low,   $cost_high )
  );
  $t->addRow( 'Max tokens', $max_tokens, q{-} );
  $t->addRowLine;
  $t->addRow( 'Total (est)', q{-}, sprintf( '$%.4f - $%.4f', $input_cost + $cost_low, $input_cost + $cost_high ) );

  print {*STDERR} $t;

  return;
}

########################################################################
sub _fmt_tokens {
########################################################################
  my ($n) = @_;

  return q{-}    if !defined $n;
  return "${n}K" if $n < 1_000_000;
  return sprintf '%.1fM', $n / 1_000_000;
}

########################################################################
sub _print_token_usage {
########################################################################
  my ( $self, $llm_rsp, $label ) = @_;

  $label //= 'Token Usage';

  my $usage = eval { $llm_rsp->usage };

  if ( !$usage ) {
    my $raw = JSON::PP->new->decode( $llm_rsp->raw_content );

    $usage = $raw->{usage};
  }

  return if !$usage;

  # pricing per token
  my ( $input_token_cost, $output_token_cost ) = eval { $self->get_llm->pricing(); };

  # ...this should never happen since we are being called from methods
  # that must have instantiated a valid LLM::API instance
  if ($EVAL_ERROR) {
    warn "Pricing estimates cannot be calculated.\n$EVAL_ERROR";
    return;
  }

  my $input_cost  = ( $usage->{input_tokens}                // 0 ) * $input_token_cost;
  my $output_cost = ( $usage->{output_tokens}               // 0 ) * $output_token_cost;
  my $cache_read  = ( $usage->{cache_read_input_tokens}     // 0 );
  my $cache_write = ( $usage->{cache_creation_input_tokens} // 0 );
  my $total_cost  = $input_cost + $output_cost;

  require Text::ASCIITable;

  my $model_name = $self->get_model // 'unknown model';

  my $heading = sprintf "%s\n(%s Estimates)", $label, $model_name;

  my $t = Text::ASCIITable->new( { headingText => $heading } );

  $t->setCols( 'Metric', 'Tokens', 'Cost (USD)' );
  $t->setColWidth( 'Metric',     30 );
  $t->setColWidth( 'Tokens',     12 );
  $t->setColWidth( 'Cost (USD)', 12 );

  $t->addRow( 'Input tokens',       $usage->{input_tokens}  // 0, sprintf '$%.4f', $input_cost );
  $t->addRow( 'Output tokens',      $usage->{output_tokens} // 0, sprintf '$%.4f', $output_cost );
  $t->addRow( 'Cache write tokens', $cache_write, q{-} );
  $t->addRow( 'Cache read tokens',  $cache_read,  q{-} );
  $t->addRowLine;
  $t->addRow( 'Total', ( $usage->{input_tokens} // 0 ) + ( $usage->{output_tokens} // 0 ), sprintf '$%.4f', $total_cost );

  print {*STDERR} $t;

  return;
}

1;
