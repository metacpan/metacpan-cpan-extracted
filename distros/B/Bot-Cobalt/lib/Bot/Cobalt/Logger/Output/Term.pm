package Bot::Cobalt::Logger::Output::Term;
$Bot::Cobalt::Logger::Output::Term::VERSION = '0.021003';
use strictures 2;

sub new { bless [], shift }

sub _write {
  local $|=1;
  binmode STDOUT, ":utf8";
  print STDOUT $_[1]
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Logger::Output::Term - Bot::Cobalt::Logger console output

=head1 SYNOPSIS

  $output_obj->add(
    'MyScreen' => {
      type => 'Term',
    },
  );

See L<Bot::Cobalt::Logger::Output>.

=head1 DESCRIPTION

This is a L<Bot::Cobalt::Logger::Output> writer for logging messages to 
STDOUT.

Expects UTF-8.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
