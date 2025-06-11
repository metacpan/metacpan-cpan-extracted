package Data::Printer::Filter::JMAP 0.002;
use v5.36.0;

# ABSTRACT: a Data::Printer filter for JMAP::Tester-related objects

use Data::Printer::Filter;

#pod =head1 SYNOPSIS
#pod
#pod This filter will beautify (I hope) dumping of:
#pod
#pod =for :list
#pod * JMAP::Tester::Response
#pod * JMAP::Tester::Response::Sentence
#pod * JMAP::Tester::Result::Failure
#pod
#pod More filtering may be added over time.
#pod
#pod =cut

my sub _one_sentence ($sent, $ddp) {
  my $str = $ddp->maybe_colorize($sent->name, 'jmapmethod', '#00ffff')
          . ' '
          . $ddp->maybe_colorize($sent->client_id, 'jmapcid', '#a0a0ff')
          . ' '
          . $ddp->parse($sent->arguments);
}

filter 'JMAP::Tester::Response' => sub {
  my ($object, $ddp) = @_;

  my $str = $ddp->maybe_colorize(ref $object, 'class')
          . ' '
          . $ddp->maybe_colorize('{', 'brackets');

  $ddp->indent;

  if ($ddp->extra_config->{filter_jmap}{show_wrapper}) {
    $str .= $ddp->newline;

    $str .= 'properties: '
         .  $ddp->parse($object->wrapper_properties);
  }

  {
    $str .= $ddp->newline;

    $str .= 'responses: '
         .  $ddp->maybe_colorize('[', 'brackets');

    $ddp->indent;

    for ($object->sentences) {
      $str .= $ddp->newline . _one_sentence($_, $ddp);
    }

    $ddp->outdent;

    $str .= $ddp->newline;

    $str .= $ddp->maybe_colorize(']', 'brackets');
  }

  if ($ddp->extra_config->{filter_jmap}{show_http}) {
    $str .= $ddp->newline;

    $str .= 'http_response: '
         .  $ddp->parse($object->http_response);
  }

  $ddp->outdent;

  $str .= $ddp->newline;
  $str .= $ddp->maybe_colorize('}', 'brackets');

  $str;
};

filter 'JMAP::Tester::Response::Sentence' => sub {
  my ($object, $ddp) = @_;

  my $str = $ddp->maybe_colorize(ref $object, 'class')
          . ' '
          . _one_sentence($object, $ddp);

  return $str;
};

filter 'JMAP::Tester::Result::Failure' => sub {
  my ($object, $ddp) = @_;

  my $str = $ddp->maybe_colorize(ref $object, 'class')
          . ' '
          . $ddp->maybe_colorize('{', 'brackets');

  $ddp->indent;

  $str .= $ddp->newline;

  $str .= 'http_response: '
       .  $ddp->parse($object->http_response);

  $ddp->outdent;

  $str .= $ddp->newline;

  $str .= $ddp->maybe_colorize('}', 'brackets');

  return $str;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::JMAP - a Data::Printer filter for JMAP::Tester-related objects

=head1 VERSION

version 0.002

=head1 SYNOPSIS

This filter will beautify (I hope) dumping of:

=over 4

=item *

JMAP::Tester::Response

=item *

JMAP::Tester::Response::Sentence

=item *

JMAP::Tester::Result::Failure

=back

More filtering may be added over time.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
