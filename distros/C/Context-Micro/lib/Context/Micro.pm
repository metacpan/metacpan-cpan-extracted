package Context::Micro;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Exporter 'import';

our @EXPORT = qw( new config entry );

=head1 NAME

Context::Micro - Micro Context Class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

First, your context class

    package MyApp::Context;
    use Context::Micro;
    use DBI;
    
    sub db {
        my $self = shift;
        $self->entry( db => sub {
            my $config = $self->config->{db};
            DBI->connect( @{$config->{connect_info}} );
        } );
    }
    
    1;

after, in your application

    package MyApp;
    use MyApp::Context;
    
    my $config = {
        db => {
            connect_info => [ ... ],
        },
        ...
    };
    
    my $context = MyApp::Context->new(config => $config);
    
    sub my_task {
        my $self = shift;
        my $db = $context->db;        ### $db is a singleton instance.
        my $sth = $db->prepare(...);
        ...
    }
    
    1;
    
=head1 EXPORT

=head2 new( %hash )

Provide constructor automatically into your context class.

=cut

sub new {
    my ($class, %opts) = @_;
    my $config = $opts{config} || {};
    return bless { config => $config, container => {} }, $class;
}

=head2 config

Provide config accessor.

=cut

sub config {
    my $self = shift;
    return $self->{config};
}

=head2 entry

Returns an object with specified name. Store a result of coderef when object is not exists.

=cut

sub entry {
    my ($self, $key, $code) = @_;
    return $self->{container}{$key} ? $self->{container}{$key} : do {
        my $o = $code->();
        $self->{container}{$key} = $o;
        $o;
    };
}

=head1 AUTHOR

ytnobody, C<< <ytnobody aaatttt gmail> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-context-micro at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Context-Micro>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Context::Micro


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Context-Micro>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Context-Micro>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Context-Micro>

=item * Search CPAN

L<http://search.cpan.org/dist/Context-Micro/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 ytnobody.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Context::Micro
