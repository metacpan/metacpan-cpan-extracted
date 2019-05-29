package Code::Style::Kit::Parts::Perl516;
use strict;
use warnings;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: use features from perl 5.16


use Import::Into;

# use 5.16: say, __SUB__, etc. plus 'state'
sub feature_perl_5_16_default { 1 }
sub feature_perl_5_16_export {
    require feature;
    feature->import(':5.16');
    feature->unimport::out_of($_[1],'switch');
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords smartmatch

=head1 NAME

Code::Style::Kit::Parts::Perl516 - use features from perl 5.16

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Perl516);
  1;

Then:

  package My::Package;
  use My::Kit;

  # you can now use say, state, __SUB__, fc

=head1 DESCRIPTION

This part defines the C<perl_5_16> feature, enabled by default, which
enables all the features of perl version 5.16 (but not C<switch>,
because C<given> / C<when> and the smartmatch operator are not
stable).

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
