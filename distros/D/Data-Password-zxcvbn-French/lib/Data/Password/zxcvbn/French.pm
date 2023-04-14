package Data::Password::zxcvbn::French;
use strict;
use warnings;
use Data::Password::zxcvbn;
use Exporter 'import';
our @EXPORT_OK=qw(password_strength);
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: Dropbox's password estimation logic, with French defaults


sub password_strength {
    my ($password, $opts) = @_;

    my %actual_opts = %{$opts // {}};
    $actual_opts{ranked_dictionaries} //= do {
        require Data::Password::zxcvbn::French::RankedDictionaries;
        \%Data::Password::zxcvbn::French::RankedDictionaries::ranked_dictionaries;
    };
    $actual_opts{graphs} //= do {
        require Data::Password::zxcvbn::French::AdjacencyGraph;
        \%Data::Password::zxcvbn::French::AdjacencyGraph::graphs;
    };

    return Data::Password::zxcvbn::password_strength(
        $password,
        \%actual_opts,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::French - Dropbox's password estimation logic, with French defaults

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  use Data::Password::zxcvbn::French qw(password_strength);

  my $strength = password_strength($my_password);
  warn $strength->{warning} if $strength->{score} < 3;

=head1 DESCRIPTION

This is a variant of L<< C<Data::Password::zxcvbn> >> with French
data. See that distribution for all the documentation.

=for Pod::Coverage password_strength

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
