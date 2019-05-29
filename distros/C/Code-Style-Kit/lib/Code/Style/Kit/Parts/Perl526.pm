package Code::Style::Kit::Parts::Perl526;
use strict;
use warnings;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: use features from perl 5.26


use Import::Into;

# use 5.26: say state switch unicode_strings unicode_eval evalbytes
# current_sub fc postderef_qq
sub feature_perl_5_26_default { 1 }
sub feature_perl_5_26_export {
    my ($self, $caller) = @_;
    require feature;
    feature->import(':5.26');
    feature->unimport::out_of($caller,'switch'); # we don't want smartmatch!

    feature->import::into($caller,'signatures');
    require experimental;
    experimental->import::into($caller,'signatures');
}

# if warnings are fatalised (e.g. by Code::Style::Kit::Parts::Common),
# disable warnings for the experimental features we want
sub feature_fatal_warnings_export {
    my ($self, $caller) = @_;

    require experimental;
    experimental->import::into($caller,'signatures');
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords smartmatch

=head1 NAME

Code::Style::Kit::Parts::Perl526 - use features from perl 5.26

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Perl526);
  1;

Then:

  package My::Package;
  use My::Kit;

  # you can now use say, state, __SUB__, fc, my sub,
  # sub foo($arg,@etc), $a->@*

=head1 DESCRIPTION

This part defines the C<perl_5_26> feature, enabled by default, which
enables all the features of perl version 5.26 (but not C<switch>,
because C<given> / C<when> and the smartmatch operator are not
stable). It also enables subroutine signatures (which are
experimental, but stable enough).

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
