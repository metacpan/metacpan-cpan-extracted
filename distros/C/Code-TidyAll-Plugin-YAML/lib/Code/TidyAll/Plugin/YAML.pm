package Code::TidyAll::Plugin::YAML;
$Code::TidyAll::Plugin::YAML::VERSION = '0.000001';
use YAML;
use Moo;

extends 'Code::TidyAll::Plugin';

my @attributes = (
    'AnchorPrefix',        'CompressSeries',
    'DumpCode',            'Indent',
    'QuoteNumericStrings', 'SortKeys',
    'Stringify',           'UseAliases',
    'UseBlock',            'UseCode',
    'UseFold',             'UseHeader',
    'UseVersion',
);

foreach my $attr ( @attributes ) {
    has $attr => ( is => 'ro', predicate => '_has_' . $attr );
}

sub transform_source {
    my $self   = shift;
    my $source = shift;

    no strict 'refs';
    foreach my $attr ( @attributes ) {
        my $predicate = '_has_' . $attr;
        if ( $self->$predicate ) {
            *{"YAML::$attr"} = \($self->$attr);
        }
    }
    use strict 'refs';

    return Dump( Load( $source ) );
}

1;

# ABSTRACT: Use the YAML module to tidy YAML documents with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::YAML - Use the YAML module to tidy YAML documents with tidyall

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

   In configuration:

   [YAML]
   select = **/*.yaml
   Indent = 4

=head1 DESCRIPTION

Uses L<YAML> to format YAML files.  Has the same defaults as YAML.pm

=head1 CONFIGURATION

The following configuration options can be set.  See L<YAML> for a full
description of each option.

=over

=item AnchorPrefix

=item CompressSeries

=item DumpCode

=item Indent

=item QuoteNumericStrings

=item SortKeys

=item Stringify

=item UseAliases

=item UseBlock

=item UseCode

=item UseFold

=item UseHeader

=item UseVersion

=back

=head1 SEE ALSO

L<Code::TidyAll>, L<YAML>

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
