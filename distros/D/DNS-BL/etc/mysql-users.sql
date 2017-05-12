# Create the users and do the required GRANTs on them
# for use by the DNS::BL modules, on a MySQL database
#
# $Id: mysql-users.sql,v 1.2 2004/12/24 12:58:49 lem Exp $

USE dnsbl;

# Please customize this according to your environment. Note that
# passwords should be used, as well as restrictions for the source
# of the updates. Generally, there is not that much information leaked
# from allowing the RO account to remain without a password, but this
# should be evaluated for your environment.

GRANT SELECT ON dnsbl.* TO 'dnsbl-ro'@'localhost' 
IDENTIFIED BY 'password';

GRANT SELECT,UPDATE,INSERT,DELETE ON dnsbl.* TO 'dnsbl-rw'@'localhost' 
IDENTIFIED BY 'password';
