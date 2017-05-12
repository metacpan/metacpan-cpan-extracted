package TestApp::View::TT;

use strict;
use warnings;
use FindBin;
use Path::Class;
use base 'Catalyst::View::TT::Filters::LazyLoader';

my $includepath = dir($FindBin::Bin, '/lib/root/' );

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH => $includepath,
);

1;

=pod

=head1 NAME

TestApp::View::TT - TT View for TestApp with L<Template::Filters::LazyLoader> support.

=head1 DESCRIPTION

TT::Filters::LazyLoader View for TestApp

=head1 AUTHOR

Tomohiro Teranishi

=head1 SEE ALSO

L<TestApp>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

