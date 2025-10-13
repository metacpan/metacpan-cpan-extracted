package Data::Password::zxcvbn::RankedDictionaries;
use strict;
use warnings;
use Data::Password::zxcvbn::RankedDictionaries::Common;
use Data::Password::zxcvbn::RankedDictionaries::English;
our $VERSION = '1.1.3'; # VERSION
# ABSTRACT: ranked dictionaries for common English words


our %ranked_dictionaries = (
    %Data::Password::zxcvbn::RankedDictionaries::Common::ranked_dictionaries,
    %Data::Password::zxcvbn::RankedDictionaries::English::ranked_dictionaries,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::RankedDictionaries - ranked dictionaries for common English words

=head1 VERSION

version 1.1.3

=head1 DESCRIPTION

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
