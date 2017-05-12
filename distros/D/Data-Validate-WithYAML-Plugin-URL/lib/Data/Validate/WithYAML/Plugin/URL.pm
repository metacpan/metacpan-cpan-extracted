package Data::Validate::WithYAML::Plugin::URL;

use warnings;
use strict; 

use Carp;

use Regexp::Common qw(URI);

# ABSTRACT: Plugin to check URL


our $VERSION = '0.01';


sub check {
    my ($class, $value) = @_;
    
    croak "no value to check" unless defined $value;
    
    my $return = 0;
    if( $value =~ m{\A $RE{URI}{HTTP}{-scheme => qr/https?/} \z}x ){
        $return = 1;
    }
    return $return;
}


1;

__END__
=pod

=head1 NAME

Data::Validate::WithYAML::Plugin::URL - Plugin to check URL

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Data::Validate::WithYAML::Plugin::URL;

    my $foo = Data::Validate::WithYAML::Plugin::URL->check( 'http://test.de/' );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $URL     = 'http://test.de/';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'URL', $URL );

test.yml

  ---
  step1:
      URL:
          plugin: URL
          type: required

=head1 VERSION

Version 0.01

=head1 SUBROUTINES

=head2 check

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::WithYAML::Plugin::URL

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2011 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

