package Data::Serializer::JSON::XS;
BEGIN { @Data::Serializer::JSON::XS::ISA = qw/Data::Serializer/ }

use warnings;
use strict;
use JSON::XS;
use vars qw/@ISA/;

sub serialize { return JSON::XS->new
    ->allow_blessed
    ->allow_nonref
    ->convert_blessed
    ->ascii
    ->utf8
    ->relaxed
    ->pretty( 0 )
    ->encode( $_[1] );
}

sub deserialize { return JSON::XS->new
    ->allow_blessed
    ->allow_nonref
    ->convert_blessed
    ->ascii
    ->utf8
    ->relaxed
    ->pretty( 0 )
    ->decode( $_[1] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Serializer::JSON::XS

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Data::Serializer::JSON::XS;

=head1 DESCRIPTION

A serializer using the Data::Serializer interface.

=over 4

=item B<serialize> - implements serialize method.

=item B<deserialize> - implements deserialize method.

=back

=head1 NAME

Data::Serializer::JSON::XS - serialize/deserialize JSON::XS.

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT

  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Data::Serializer(3), JSON::XS(3).

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/data-serializer-json-xs/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/data-serializer-json-xs>

  git clone git://github.com/sharabash/data-serializer-json-xs.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTOR

Nour Sharabash <nour.sharabash@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
