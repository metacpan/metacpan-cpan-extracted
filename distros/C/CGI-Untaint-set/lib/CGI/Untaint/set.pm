package CGI::Untaint::set;

use warnings;
use strict;

use base 'CGI::Untaint::printable';

our $VERSION = 0.01;

=head1 NAME

CGI::Untaint::set - untaint sets of values

=head1 SYNOPSIS

    use CGI::Untaint;
    my $handler = CGI::Untaint->new($q->Vars);
                                                                                
    $value = $handler->extract(-as_set => 'films' );    


=head1 DESCRIPTION

Untaints an arrayref (as might be submitted by an HTML multiple select form field, or multiple 
selections from a checkbox group) as a comma separated string suitable for use as a value for 
a MySQL (maybe others?) SET column. 

Values are validated against the L<CGI::Untaint::printable|CGI::Untaint::printable> 
regex. To validate against a specific set of allowed values, subclass this 
package and provide a custom C<_untaint_re> method. 

=cut

sub _untaint
{
    my ( $self ) = @_;
    
    my $value = $self->value;
    
    return $self->SUPER::_untaint unless ref $value;
    
    my $re = $self->_untaint_re;

    $self->value( join ',', map { $_ =~ $re or die; $1 } @$value );
    
    return 1;
}



=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-untaint-set@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-set>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Untaint::set
