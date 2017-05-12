package App::Presto::CommandHasHelp;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::CommandHasHelp::VERSION = '0.010';
# ABSTRACT: Role for command modules that have help defined

use Moo::Role;

requires 'help_categories';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::CommandHasHelp - Role for command modules that have help defined

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
