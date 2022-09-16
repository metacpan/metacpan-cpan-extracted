package Babble::Plugin::Sigify;

use strictures 2;
use Moo;

sub transform_to_plain {
  my ($self, $top) = @_;
  my $tf = sub {
    my ($m) = @_;
    my $body = $m->submatches->{body}->text;
    $body =~ s/^\s+//;
    if ($body =~ s/^\{\s*my\s*(\([^\)]+\))\s*=\s*\@_\s*;/{/sm) {
      my $sig = $1;
      $body =~ s/^{\n\n/{\n/;
      $m->submatches->{body}->replace_text($sig.' '.$body);
    }
  };
  $top->each_match_within('SubroutineDeclaration' => [
    'sub \b (?&PerlOWS) (?&PerlOldQualifiedIdentifier) (?&PerlOWS)',
    '(?: (?>(?&PerlAttributes)) (?&PerlOWS) )?+',
    [ body => '(?&PerlBlock)' ], '(?&PerlOWS)'
  ] => $tf);
  $top->each_match_within('AnonymousSubroutine' => [
    'sub \b (?&PerlOWS)',
    '(?: (?>(?&PerlAttributes)) (?&PerlOWS) )?+',
    [ body => '(?&PerlBlock)' ], '(?&PerlOWS)'
  ] => $tf);
}

1;
__END__

=head1 NAME

Babble::Plugin::Sigify - Plugin to convert @_ unpacking to signature syntax

=head1 SEE ALSO

L<signatures feature|feature/"The 'signatures' feature">

=cut
