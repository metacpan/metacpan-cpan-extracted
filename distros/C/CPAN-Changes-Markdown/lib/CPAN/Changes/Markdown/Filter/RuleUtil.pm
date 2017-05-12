use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Markdown::Filter::RuleUtil;

# ABSTRACT: short-hand for constructing rule objects.

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY




















use Sub::Exporter::Progressive -setup =>
  { exports => [qw( rule_NumericsToCode rule_UnderscoredToCode rule_PackageNamesToCode rule_VersionsToCode )] };





## no critic ( RequireArgUnpacking Capitalization NamingConventions::ProhibitMixedCaseSub )

sub rule_NumericsToCode {
  require CPAN::Changes::Markdown::Filter::Rule::NumericsToCode;
  return CPAN::Changes::Markdown::Filter::Rule::NumericsToCode->new(@_);
}





sub rule_UnderscoredToCode {
  require CPAN::Changes::Markdown::Filter::Rule::UnderscoredToCode;
  return CPAN::Changes::Markdown::Filter::Rule::UnderscoredToCode->new(@_);
}





sub rule_PackageNamesToCode {
  require CPAN::Changes::Markdown::Filter::Rule::PackageNamesToCode;
  return CPAN::Changes::Markdown::Filter::Rule::PackageNamesToCode->new(@_);
}





sub rule_VersionsToCode {
  require CPAN::Changes::Markdown::Filter::Rule::VersionsToCode;
  return CPAN::Changes::Markdown::Filter::Rule::VersionsToCode->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Markdown::Filter::RuleUtil - short-hand for constructing rule objects.

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    use CPAN::Changes::Markdown::Filter::RuleUtil qw(:all);

    rule_NumericsToCode() # Create instance passing @_

=head1 EXPORTS

=head2 C<rule_NumericsToCode>

=head2 C<rule_UnderscoredToCode>

=head2 C<rule_PackageNamesToCode>

=head2 C<rule_VersionsToCode>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"CPAN::Changes::Markdown::Filter::RuleUtil",
    "interface":"exporter"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
