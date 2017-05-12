package CGI::Ex::Recipes::View;
use utf8;
use warnings;
use strict;
use base qw(CGI::Ex::Recipes);
use CGI::Ex::Dump qw(debug dex_warn ctrace dex_trace);
our $VERSION = '0.3';

sub hash_common { 
    my $self = shift;
    require CGI::Ex::Recipes::Edit;
    #dex_trace; debug $self;
    $self->CGI::Ex::Recipes::Edit::hash_common(@_);
}

1; # End of CGI::Ex::Recipes::View

=head1 NAME

CGI::Ex::Recipes::View - reads and displays a recipe!

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    no synopsis

    ...

=head1 METHOSDS

=head2 hash_common


=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
