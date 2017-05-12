package CMS::Drupal::Modules;
$CMS::Drupal::Modules::VERSION = '0.94';
# ABSTRACT: Provides the namespace for CMS::Drupal::Modules::* packages.

use strict;

# nothing here

1; #return true

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Modules - Provides the namespace for CMS::Drupal::Modules::* packages.

=head1 VERSION

version 0.94

=head1 SYNOPSIS

This an empty package.

=head1 DESCRIPTION

This is an empty package that only exists to provide the namespace for
CMS::Drupal::Modules::* packages.

Drupal has the concept of Modules much like Perl's. They are collections of code in libraries that can be used to extend the core Drupal installation. As in Perl, some are part of the core distribution, some are available from Drupal's equivalent of CPAN, and some may be completely custom to a local installation.

=head1 NAMESPACES

The Perl CMS::Drupal::* system takes no note of the distinction between types of Drupal modules. All are directly under the CMS::Drupal::Modules:: namespace.

So if you want to contribute a Perl interface to the core Drupal module Poll, for example, your Perl package would be:

  CMS::Drupal::Modules::Poll.pm
  CMS::Drupal::Modules::Poll::SubModuleIfNeeded.pm

With others, try to follow the naming hierarchy of the Drupal modules, although this is not always obvious.

If you are working on Perl interfaces to Drupal's Commerce modules, for example, it's obvious that 

  Commerce

should map to 

  CMS::Drupal::Modules::Commerce.pm

And maybe somewhat obvious that other Commerce core modules such as

  Customer
  Order

etc, should map to

  CMS::Drupal::Modules::Commerce::Customer.pm
  CMS::Drupal::Modules::Commerce::Order.pm

and so on.

But what about contributed modules, such as

  Commerce Addressbook

We'll just pretend that it's a Commerce core module and put your Perl package in with the rest of the Commerce interface:

  CMS::Drupal::Modules::Commerce::AddressBook.pm

=head1 TESTING

  The parent module L<CMS::Drupal|CMS::Drupal> has a feature enabling automatic connection if your Drupal credentials are set
  in the environment variable DRUPAL_TEST_CREDS ... this is not recommended for production systems
  because of the obvious security risk. But it is handy for testing your module against a test database.

  See the documentation for L<CMS::Drupal|CMS::Drupal> for more information.

=head1 SEE ALSO

=over 4

=item *

L<CMS::Drupal|CMS::Drupal>

=back

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
