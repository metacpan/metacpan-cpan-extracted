use strict;
use warnings;
package Config::Any::TOML;

our $VERSION = '0.002'; # VERSION

# ABSTRACT: Load TOML config files

use base 'Config::Any::Base';


sub extensions {
    return qw( toml );
}


sub load {
    my $class = shift;
    my $file  = shift;

    open( my $fh, $file ) or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;

    require TOML;

    my ( $data, $err ) = TOML::from_toml($content);
        unless ($data) {
        die "Error parsing toml: $err";
    }

    return $data;
}


sub requires_any_of { 'TOML' }


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Config::Any::TOML - Load TOML config files

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Loads TOML files. See L<https://github.com/mojombo/toml>

=head1 METHODS

=head2 extensions()

return an array of valid extensions (C<toml>).

=head2 load( $file )

Attempts to load C<$file> as an TOML file.

=head2 requires_any_of()

Specifies that this module requires one of the following TOML modules in order
to work.

=over

=item *

L<TOML>

=back

=head1 SEE ALSO

=over

=item * L<Config::Any>

=item * L<TOML>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/config-any-toml/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/config-any-toml>

  git clone git://github.com/mjemmeson/config-any-toml.git

=head1 AUTHOR

Michael Jemmeson <mjemmeson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Jemmeson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
