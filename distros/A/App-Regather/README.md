# regather

**regather** is a syncrepl consumer to generate ( *re gather* ) files on LDAP synrepl events.

It uses Net::LDAP(3) to do all LDAP related stuff and Template(3) to generate files. Config file is processed with Config::Parser(3) (it's format described in Regather::Config(3)

regather has plugin structure and allows to perform any desired action, based on event data

now it has these two plugins:
* configfile
* nsupdate

As example, regather, on LDAP event can
* create/re-write/delete OpenVPN client config file/s
* create/re-write/delete CRL file for OpenVPN or FreeRADIUS (in this case it is ca+crl pem file)
* create/re-write/delete sieve script for mail user.
* nsupdate DNS zones
* create/re-write/delete mail domain maildir directory in IMAP4 space, on domain binding to IMAP server LDAP configuration (todo)

In theory it is possible to adopt regather to do anything you want on LDAP syncrepl event.

Copyright (c) 2020 [Zeus Panchenko](https://github.com/z-eos)
