package Apache::ExtDirect;

# This module is dedicated to documentation

our $VERSION = '0.90';

1;

__END__

=pod

=head1 NAME

Apache::ExtDirect - Ext.Direct remoting interface for mod_perl applications

=head1 SYNOPSIS

In your PerlPostConfigRequire script:

 use RPC::ExtDirect::API api_path    => '/api',
                         router_path => '/router',
                         poll_path   => '/events',
                         before      => \&global_before_hook,
                         after       => \&global_after_hook;
 
 use My::ExtDirect::Published::Module::Foo;
 use My::ExtDirect::Published::Module::Bar;

In your httpd.conf:

 PerlModule Apache::ExtDirect::API
 PerlModule Apache::ExtDirect::Router
 PerlModule Apache::ExtDirect::EventProvider
 
 <Location "/api">
    PerlHandler Apache::ExtDirect::API
    SetHandler perl-script
 </Location>
 
 <Location "/router">
    PerlHandler Apache::ExtDirect::Router
    SetHandler perl-script
 </Location>
 
 <Location "/events">
    PerlHandler Apache::ExtDirect::EventProvider
    SetHandler perl-script
 </Location>

=head1 DESCRIPTION

This module provides RPC::ExtDirect gateway implementation for Apache
mod_perl environment.

=head1 DEPENDENCIES

Apache::ExtDirect is dependent on the following modules:
L<mod_perl2>, L<RPC::ExtDirect>, L<JSON>, L<Attribute::Handlers>.

=head1 SEE ALSO

For more information on core functionality see L<RPC::ExtDirect>.

For more information on Ext.Direct API see specification:
L<http://www.sencha.com/products/extjs/extdirect/> and documentation:
L<http://docs.sencha.com/ext-js/4-0/#!/api/Ext.direct.Manager>.

=head1 BUGS AND LIMITATIONS

Apache 1.x is not supported at this time.

There are no known bugs in this module. To report bugs, use github RT
(the best way) or just drop me an e-mail. Patches are welcome.

=head1 AUTHOR

Alexander Tokarev, E<lt>tokarev@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

I would like to thank IntelliSurvey, Inc for sponsoring my work
on version 2.0 of RPC::ExtDirect suite of modules.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alexander Tokarev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic.>

=cut

