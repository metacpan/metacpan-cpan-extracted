#
# $Revision: 1.5 $
# $Source: /home/cvs/CGI-PathParam/lib/CGI/PathParam.pm,v $
# $Date: 2006/06/01 06:23:22 $
#
package CGI::PathParam;
use strict;
use warnings;

=head1 NAME

CGI::PathParam - Add the feature of parsing path_info to CGI.

=head1 VERSION

0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use CGI;
    use CGI::PathParam;

    my $q = CGI->new;

    $q->path_param(qw(foo bar baz));    # same as $q->path_info('/foo/bar/baz')
    my @results = $q->path_param;       # @results is ( 'foo', 'bar', 'baz' ).

=head1 DESCRIPTION

This module adds the feature of parsing PATH_INFO to CGI as a plugin.

=head1 SUBROUTINES/METHODS

=head2 path_param(@)

If the arguments are specified, the values joined by / is set to path_info.
Otherwise, it returns the list of path_info split.

=cut

sub path_param {
    my $self = shift;

    if (@_) {

        # When path_info(undef), only returns current path_info data.
        # The behavior is same as path_info()
        # However, that of path_param(undef) is *NOT* same as path_param().
        # Because path_param($param) occurs two kinds of behavior
        # whether $param is undef or not.

        $self->path_info( join q{/}, map { $self->escape($_) } @_ );

        return $self;
    }

    if ( !$self->path_info ) {
        return;
    }

    return map { $self->unescape($_) }
      split m{/}msx, substr $self->path_info, 1;
}

*CGI::path_param = \&path_param;

=head1 DIAGNOSTICS

=over

=item Use of uninitialized value in join or string at ...

If you pass undef to path_param then you will see this message.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<CGI>

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

The path_param() does not provide a setter feature yet.

Please report any bugs or feature requests to
C<bug-cgi-pathparam@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-PathParam>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc CGI::PathParam

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-PathParam>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-PathParam>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-PathParam>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-PathParam>

=back

=head1 AUTHOR

Hironori Yoshida, C<< <yoshida@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Hironori Yoshida, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of CGI::PathParam
