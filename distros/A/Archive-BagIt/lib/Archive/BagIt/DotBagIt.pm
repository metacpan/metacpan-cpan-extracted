package Archive::BagIt::DotBagIt;

our $VERSION = '0.063'; # VERSION
use strict;
use warnings;
use Sub::Quote;
use Carp;
use File::Spec;
use Moo;
extends "Archive::BagIt::Base";


before BUILDARGS => sub {
    carp "The module Archive::BagIt::DotBagIt is marked as deprecated and will be erased in next releases!";
};

has 'metadata_path' => (
    is=> 'ro',
    lazy => 1,
    builder => '_build_metadata_path',
);

sub _build_metadata_path {
    my ($self) = @_;
    my $bag_path = $self->bag_path();
    return File::Spec->catdir($bag_path, ".bagit");
}

has 'payload_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_path',
);

sub _build_payload_path {
    my ($self) = @_;
    return $self->bag_path;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::DotBagIt

=head1 VERSION

version 0.063

=head1 NAME

Archive::BagIt::DotBagIt

=head1 VERSION

version 0.063

=head1 NAME

Archive::BagIt::DotBagIt - The inside-out version of BagIt, this package is deprecated and will be erased in next releases

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
