#
#  This file is part of Cloudflare::API.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package Cloudflare::API::Resource;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;


#  Version information
#
$VERSION='1.010';


#  All done. Positive return
#
1;


#============================================================================


sub new {


    #  Keep the parent client so every resource uses the same transport
    #
    my ($class, $api_or)=@_;
    die "Cloudflare::API object is required\n"
        unless ref($api_or)&&$api_or->isa('Cloudflare::API');
    my $self=bless({ api_or => $api_or }, $class);
    return $self;

}


sub api { return $_[0]->{'api_or'} }
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Resource #

# NAME #

Cloudflare::API::Resource - shared base class for Cloudflare resource objects

# SYNOPSIS #

```perl
my $r2=$api->r2();
my $client=$r2->api();
```

# DESCRIPTION #

`Cloudflare::API::Resource` holds the parent `Cloudflare::API` client used by the resource modules. Applications normally obtain a concrete resource object through a parent accessor such as `r2()` or `workers()`. The base class does not make requests on its own.

# METHODS #

* **new($api)** — Construct a resource object retaining a `Cloudflare::API` instance. Throws if the argument is not a `Cloudflare::API` object. Subclasses inherit this constructor; it returns an object of the invoked class.
* **api()** — Return the retained `Cloudflare::API` object. Resource methods use it for authenticated requests and account context.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Cloudflare::API.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Cloudflare::API::Resource - shared base class for Cloudflare resource objects


=head1 SYNOPSIS


 my $r2=$api->r2();
 my $client=$r2->api();

=head1 DESCRIPTION

C<Cloudflare::API::Resource> holds the parent C<Cloudflare::API> client used by the resource modules. Applications normally obtain a concrete resource object through a parent accessor such as C<r2()> or C<workers()>. The base class does not make requests on its own.


=head1 METHODS

=over

=item *

B<new($api)> — Construct a resource object retaining a C<Cloudflare::API> instance. Throws if the argument is not a C<Cloudflare::API> object. Subclasses inherit this constructor; it returns an object of the invoked class.


=item *

B<api()> — Return the retained C<Cloudflare::API> object. Resource methods use it for authenticated requests and account context.


=back


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
