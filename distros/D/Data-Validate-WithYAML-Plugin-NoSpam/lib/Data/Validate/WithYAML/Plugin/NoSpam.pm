package Data::Validate::WithYAML::Plugin::NoSpam;

use warnings;
use strict; 

use Carp;

# ABSTRACT: Plugin to check that a given text is no spam.

our $VERSION = '0.02';


sub check {
    my ($class, $value) = @_;
    
    croak "no value to check" unless defined $value;
    
    if ( $value =~ /(?:\[url|<a href)/ ) {
        return 0;
    }
    elsif ( $value =~ /viagra|cialis/i ) {
        return 0;
    }
    
    return 1;
}


1; # End of Data::Validate::WithYAML::Plugin::NoSpam

__END__
=pod

=head1 NAME

Data::Validate::WithYAML::Plugin::NoSpam - Plugin to check that a given text is no spam.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

The check is done with heuristics. It checks that there are no
<a href="..."> or [url=""] tags in the text...

    use Data::Validate::WithYAML::Plugin::NoSpam;

    my $foo = Data::Validate::WithYAML::Plugin::NoSpam->check(
       'This is a <a href="anything">Spam-Link</a>',
    );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $text      = 'This is a <a href="anything">Spam-Link</a>';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'textfield', $text );

test.yml

  ---
  step1:
      textfield:
          plugin: NoSpam
          type: required

=head1 SUBROUTINES

=head2 check

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-validate-withyaml-plugin-NoSpam at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-WithYAML-Plugin-NoSpam>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::WithYAML::Plugin::NoSpam

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data::Validate::WithYAML::Plugin::NoSpam>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data::Validate::WithYAML::Plugin::NoSpam>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Validate::WithYAML::Plugin::NoSpam>

=item * Search CPAN

L<http://search.cpan.org/dist/Data::Validate::WithYAML::Plugin::NoSpam>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

