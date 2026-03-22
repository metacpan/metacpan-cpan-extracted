##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Exception.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/22
## Modified 2026/03/22
## All rights reserved.
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    our $VERSION = 'v0.1.0';
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Exception - DB::Object Exception Class

=head1 SYNOPSIS

    use DB::Object::Exception;
    my $e = DB::Object::Exception->new( "Something went wrong" );
    die( $e );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its methods from L<Module::Generic::Exception>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Exception>, L<DB::Object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
