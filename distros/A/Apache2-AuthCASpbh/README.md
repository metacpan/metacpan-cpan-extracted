# Apache2-AuthCASpbh
CAS SSO integration for Apache/mod_perl

AuthCASpbh is a framework for integrating CAS SSO support into the Apache web
server using mod_perl. It can authenticate Apache resources via CAS, perform
authorization via CAS attributes, acquire proxy granting tickets, and provides
a client allowing transparent access to other CAS applications via proxy
authentication. It automatically manages sessions using Apache::Session
(currently via sqlite, but other mechanisms could be used) and provides
mod_perl based applications access to session state and attributes.
