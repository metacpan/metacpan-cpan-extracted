DBIx-Class-LookupColumn
=======================

dbic component generating accessors method to get data by a table pointing to a Lookup table (catalog of terms) in a efficient way (cache system).

Description
--------------

This distribution written in Perl provides some convenient methods (accessors) to table classes
on the top the DBIx::Class (object relational-mapping).

Terminology
---------------

What is meant as a Lookup table is a table containing some terms definition, such as PermissionType (permission_id, name) with such data 
(1, 'Administrator'; 2, 'User'; 3, 'Guest') associated 
with a client table such as User, whose metas might look like this : (id, first_name, last_name, permission_id).


Features
---------------

The three major features this present distro offer are :

* generates accessors to table classes for fectching data stored in the associated lookup table. 
* provides an effecient way to fetch data by means of a cache system.
* automatizes the accessors' generating for a DB schema.
