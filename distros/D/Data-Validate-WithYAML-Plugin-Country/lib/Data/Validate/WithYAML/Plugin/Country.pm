package Data::Validate::WithYAML::Plugin::Country;

# ABSTRACT: check whether a given value is a valid country code

use strict;
use warnings;

use Carp;
use Locale::Country::Multilingual;

our $VERSION = 0.02;

sub check {
    my ($class, $value, $conf) = @_;

    $conf->{format} ||= 'alpha-2';

    if ( $conf->{format} eq 'alpha-2' ) {
        if ( length $value != 2 ) {
            carp "value is not in alpha-2 format";
            return;
        }
    }
    elsif ( $conf->{format} eq 'alpha-3' ) {
        if ( length $value != 3 ) {
            carp "value is not in alpha-3 format";
            return;
        }
    }
    else {
        croak "unsupported format " . $conf->{format};
    }

    my $lcm = Locale::Country::Multilingual->new(
        lang         => $conf->{lang} || 'en',
        use_io_layer => 1,
    );

    if ( $lcm->code2country( $value ) ) {
        return 1;
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Data::Validate::WithYAML::Plugin::Country - check whether a given value is a valid country code

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Your F<test.pl>:

  use Data::Validate::WithYAML;
  
  my $validator = Data::Validate::WithYAML->new( 'validate.yml' );
  my %params    = (
      country => 'DE',
      # more user input
  );
  my %errors = $validator->validate( \%params );

Your F<validate.yml>:

  ---
  country:
    type: required
    plugin: Country
    format: alpha-2
    lang: en

Currently this module supports to formats: I<alpha-2> that are two-letter country codes like 'DE', 'FR', etc. and I<alpha-3> that is
the three-letter code (e.g. DEU, FRA).

And it supports different languages so you use the country codes in your preferred language (see C<Locale::Country::Multilingual>).

=head1 DESCRIPTION

Check if the given value is a valid country code.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
