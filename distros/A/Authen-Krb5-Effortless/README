Authen-Krb5-Effortless

This module is a subclass to Authen::Krb5, and adds an 'Effortless' interface 
to authenticate against a Kerberos Domain Control server.  
It's intention is to provide a kinder means of integrating Kerberos tickets 
with your application.   While there is Authen::Krb5::Simple, 
Authen::Krb5::Simple doesn't support keytab authentication.  

As I really needed both passphrase and keytab authentication, I wrote a 
module to subclass Authen::Krb5.  After releasing this module to CPAN, I 
became aware of Authen::Krb5::Easy and that it supports keytab for 
authentication.  I still belive Authen::Krb5::Effortless has merit as it 
combines both keytab and passphrase authentication in a single module.  

REQUIREMENETS

Carp is used for warnings and errors.
Authen::Krb5 needs to be installed as this is a subclass.  
In addition, I'm using the parent pragma introduced with perl 5.10.1. 
One can download the 'parent' module from CPAN if using earlier 
versions of perl.  


INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Authen::Krb5::Effortless

You can also look for information at:

    Bugs and feature requests
        https://github.com/opsmekanix/Authen-Krb5-Effortless/issues

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Authen-Krb5-Effortless

    CPAN Ratings
        http://cpanratings.perl.org/d/Authen-Krb5-Effortless

    Search CPAN
        http://search.cpan.org/dist/Authen-Krb5-Effortless/


LICENSE AND COPYRIGHT

Copyright (C) 2013 Adam Faris

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

