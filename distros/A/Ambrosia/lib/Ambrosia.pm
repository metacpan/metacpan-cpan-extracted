package Ambrosia;
our $VERSION = 0.010;
1;

__END__

=head1 NAME

Ambrosia - a powerful web application framework that can be used to create general applications too.

=head1 VERSION

    The current release is experimental.
version 0.010

=head1 DESCRIPTION

(I'm sorry for my English. And I apologize for the scant documentation. A little bit later I will fill this gap.)

The Ambrosia is a powerful framework to build web applications.
The Ambrosia implements MVC model for applications.
In this document I will briefly describe how to use the Ambrosia in general.
For better understanding see the examples.

For further information, please check the following documentation:

=over 4

=item L<Ambrosia::Meta>

One more builder of classes for Perl 5.

=item L<Ambrosia::DataProvider>

The container for data source such as DBI and Resource. 

=item L<Ambrosia::QL>

Common Query Language to data source.

=item L<Ambrosia::EntityDataModel>

The ORM.

=item L<Ambrosia::CommonGatewayInterface>

The wrapper for common access to stream IO.
Now is implementing CGI, Apache and Options.

=item L<Ambrosia::Context>

The class for working with the context of the application.

=item L<Ambrosia::Dispatcher>

The main class that controls the flow of the application.

=item L<Ambrosia::BaseManager>

The abstract class that is a base class for Managers of the application.

=item L<Ambrosia::View>

The base class, which creates a view of the application.
The result can be represented in  JSON, XML and HTML.
L<XML::LibXSLT> is used to generate HTML.

=item L<Ambrosia::Validator>

The class for validation of data of entity classes.

=item L<Ambrosia::RPC>

The class for remote calls.
Now only L<SOAP::Lite> has been implemented.

=item L<Ambrosia::Event>

Use this class for publishing and subscribing on events.

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
