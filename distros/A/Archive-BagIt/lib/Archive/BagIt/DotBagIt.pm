use strict;
use warnings;


package Archive::BagIt::DotBagIt;

our $VERSION = '0.052'; # VERSION

use Sub::Quote;
use Moo;

extends "Archive::BagIt::Base";


has 'metadata_path' => (
    is=> 'rw',
    default => sub { my ($self) = @_; return $self->bag_path."/.bagit"; },
);

has 'payload_path' => (
    is => 'rw',
    default => sub { my ($self) = @_; return $self->bag_path; },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::DotBagIt

=head1 VERSION

version 0.052

=head1 NAME

Archive::BagIt::DotBagIt - The inside-out version of BagIt

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<http://github.com/rjeschmi/Archive-BagIt>
and may be cloned from L<git://github.com/rjeschmi/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/rjeschmi/Archive-BagIt/issues>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
