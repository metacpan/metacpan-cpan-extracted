package Data::Sah::Object;

our $DATE = '2015-09-06'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(sah sahn);

sub sah {
    require Data::Sah::Object::Schema;
    Data::Sah::Object::Schema->new($_[0]);
}

sub sahn {
    require Data::Sah::Object::Schema;
    Data::Sah::Object::Schema->new($_[0], 1);
}

1;
# ABSTRACT: Object-oriented interface for Sah schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Object - Object-oriented interface for Sah schemas

=head1 VERSION

This document describes version 0.02 of Data::Sah::Object (from Perl distribution Data-Sah-Object), released on 2015-09-06.

=head1 SYNOPSIS

 use Data::Sah::Object; # automatically exports sah(), sahn()

 # sah() creates a normalized copy of schema
 $osch = sah("array*");
 $osch = sah(['array*', of => 'str*']);

 # sahn() assumes you're passing an already-normalized schema and it will not
 # create a copy
 $osch = sahn([array => {req=>1, of=>'str*'}, {}]);

 say $osch->type; # -> array
 say $osch->clause('req'); # -> 1
 say $osch->clause('of', 'int'); # set clause

=head1 DESCRIPTION

L<Sah> works using pure data structures, but sometimes it's convenient to have
an object-oriented interface (wrapper) for those data. This module provides just
that.

=head1 FUNCTIONS

=head2 sah $sch => OBJECT

Exported by default. A shortcut for Data::Sah::Object::Schema->new($sch).

=head2 sahn $sch => OBJECT

Exported by default. A shortcut for Data::Sah::Object::Schema->new($sch, 1).

=head1 SEE ALSO

L<Sah>, L<Data::Sah>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Sah-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
