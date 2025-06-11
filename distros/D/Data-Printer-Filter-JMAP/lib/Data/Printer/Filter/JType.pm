package Data::Printer::Filter::JType 0.002;
use v5.36.0;

# ABSTRACT: a Data::Printer filter for when you're using JSON::Typist

use Data::Printer::Filter;

#pod =head1 SYNOPSIS
#pod
#pod This filter will beautify (I hope) dumping of:
#pod
#pod =for :list
#pod * JSON::Typist::Number
#pod * JSON::Typist::String
#pod * JSON::PP::Boolean
#pod
#pod More filtering may be added over time.
#pod
#pod =cut

filter 'JSON::Typist::Number' => sub {
  my ($object, $ddp) = @_;
  return  $ddp->maybe_colorize($$object, 'number')
        . ' '
        . $ddp->maybe_colorize('[', 'brackets')
        . $ddp->maybe_colorize('jnum', 'number')
        . $ddp->maybe_colorize(']', 'brackets');
};

filter 'JSON::Typist::String' => sub {
  my ($object, $ddp) = @_;

  require Data::Printer::Common;
  my $str = Data::Printer::Common::_process_string($ddp, $$object, 'string');
  my $quote = $ddp->maybe_colorize($ddp->scalar_quotes, 'quotes');

  return  $quote . $str . $quote
        . ' '
        . $ddp->maybe_colorize('[', 'brackets')
        . $ddp->maybe_colorize('jstr', 'string')
        . $ddp->maybe_colorize(']', 'brackets');
};

filter 'JSON::PP::Boolean' => sub {
  my ($object, $ddp) = @_;

  $ddp->unsee($object);

  my $s = $object ? "true" : "false";

  return  $ddp->maybe_colorize($s, $s)
        . ' '
        . $ddp->maybe_colorize('[', 'brackets')
        . $ddp->maybe_colorize('jbool', 'true') # assuming "true" is "bool"
        . $ddp->maybe_colorize(']', 'brackets');
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::JType - a Data::Printer filter for when you're using JSON::Typist

=head1 VERSION

version 0.002

=head1 SYNOPSIS

This filter will beautify (I hope) dumping of:

=over 4

=item *

JSON::Typist::Number

=item *

JSON::Typist::String

=item *

JSON::PP::Boolean

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
