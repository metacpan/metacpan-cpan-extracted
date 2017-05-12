package Catalyst::Model::CDBI::Sweet;

use strict;
use base qw[Class::DBI::Sweet Catalyst::Base];

use Catalyst::Exception;

our $VERSION = '0.06';

*new = Catalyst::Base->can('new');

sub _croak {
    my ( $self, $message ) = @_;
    
    local $Carp::CarpLevel = 2;
    
    Catalyst::Exception->throw( message => $message );
}

1;

__END__

=head1 NAME

    Catalyst::Model::CDBI::Sweet - Making sweet things sweeter

=head1 SYNOPSIS

    package MyApp::Model::CDBI;
    use base 'Catalyst::Model::CDBI::Sweet';
    MyApp::Model::CDBI->connection('DBI:driver:database');
    
    package MyApp::Model::Article;
    use base 'MyApp::Model::CDBI';
    
	... # table class config here

=head1 DESCRIPTION

This model is a thin wrapper around L<Class::DBI::Sweet> to let you use it 
as a Catalyst Model easily. It's similar to L<Catalyst::Model::CDBI::Plain>.

If you want to use loader, you will probably want to add something like this
to your CDBI model config section instead:

           left_base_classes       => qw/Class::DBI::Sweet/,

To see how you can take advantage of this module, please check out the
L<Class::DBI::Sweet> documentation.

=head1 SEE ALSO

L<Class::DBI::Sweet>, L<Catalyst::Model::CDBI>, L<Catalyst>.

=head1 AUTHOR

Christian Hansen <ch@ngmedia.com>

=head1 THANKS TO

Danijel Milicevic, Jesse Sheidlower, Marcus Ramberg, Sebastian Riedel,
Viljo Marrandi

=head1 SUPPORT

#catalyst on L<irc://irc.perl.org>

L<http://lists.rawmode.org/mailman/listinfo/catalyst>

L<http://lists.rawmode.org/mailman/listinfo/catalyst-dev>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst>

L<Class::DBI::Sweet>

=cut
