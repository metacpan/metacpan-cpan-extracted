package Data::Password::zxcvbn::German::RankedDictionaries;
use strict;
use warnings;
use Data::Password::zxcvbn::RankedDictionaries::Common;
use Data::Password::zxcvbn::RankedDictionaries::German;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: ranked dictionaries for common German words


our %ranked_dictionaries = (
    %Data::Password::zxcvbn::RankedDictionaries::Common::ranked_dictionaries,
    %Data::Password::zxcvbn::RankedDictionaries::German::ranked_dictionaries,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::German::RankedDictionaries - ranked dictionaries for common German words

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This merges the common dictionaries from the C<Data::Password::zxcvbn>
distribution, and German dictionaries.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
