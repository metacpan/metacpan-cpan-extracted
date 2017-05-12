# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2015-09-21 10:19:13 +0100 (Mon, 21 Sep 2015) $ $Author: zerojinx $
# Id:            $Id: ClearPress.pm 470 2015-09-21 09:19:13Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress.pm,v $
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/lib/ClearPress.pm $
#
package ClearPress;
use strict;
use warnings;
use ClearPress::model;
use ClearPress::view;
use ClearPress::controller;
use ClearPress::util;

our $VERSION = q[475.3.3];

1;
__END__

=head1 NAME

ClearPress - Simple, vaguely-MVC web application framework - http://clearpress.net/

=head1 VERSION

$Revision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Application Structure

 /cgi-(bin|perl)/application
 /lib/application/model/*.pm
 /lib/application/view/*.pm
 /data/config.ini
 /data/templates/*.tt2

=head2 Application Setup

 The simplest method for setting up a clearpress application is to use
 the 'clearpress' script in the scripts/ subdirectory. See the POD
 there for usage instructions.

=head2 Adding models

 Models should generally be object representations of rows of entities
 from a specific database table. There are some occasions where models
 can be purely virtual, usually for convenience or inheritance, but on
 the whole things are quite straight-forward.

 ClearPress models do not (currently) inspect the database to
 determine structure and accessors. The rationale for this is that
 schema structure changes relatively infrequently and when it does
 it's reasonable to modify the data model to reflect it. There are of
 course both pros and cons in terms of efficiency for this approach.

 So let's say we have a table called 'person' for our application
 'app', looking like this:

 id_person forename surname initials

 To create a model for this by hand we'd make app/model/person.pm ,
 and extend ClearPress::model . Firstly we specify the array of fields
 in the database. Secondly we ask Class::Accessor to auto-create
 accessors for those fields. There you have it!

 package app::model::person;
 use base qw(ClearPress::model);
 use strict;
 use warnings;

 __PACKAGE__->mk_accessors(fields());

 sub fields {
  return qw(id_person forename surname initials);
 }

 1;

 Let's now say that a person has a person_role but we want to normalise roles
 to a dictionary table, person_role_dict.

 person_role looks like this:

 id_person_role id_person id_person_role_dict

 and person_role_dict looks like this:

 id_person_role_dict description


 To add the role dictionary association 'through' the person_role
 table in our person model we say:

 __PACKAGE__->belongs_to_through('person_role_dict|person_role');

 You can also use the synonym 'has_a_through' if it makes more
 grammatical sense. You will also need to define person_role_dict and
 person_role models to support querying database fields.

=head2 Adding views

 Basic views are extremely easy to add. To create a view to reflect
 our new 'person' model we would add the file app/view/person.pm and
 make it inherit from ClearPress::view.

 package app::view::person;
 use strict;
 use warnings;
 use base qw(ClearPress:view);

 1;

 For each standard action there needs to be a tt2 template in
 data/templates, so add the files:

 data/templates/person_list.tt2
 data/templates/person_add.tt2
 data/templates/person_edit.tt2
 data/templates/person_create.tt2
 data/templates/person_read.tt2
 data/templates/person_update.tt2
 data/templates/person_delete.tt2

 and put appropriate content into each one. See 'Templates' for more
 about the things you can do with these.

 That's really all there is to it for the basic functionality. By
 default there's no authentication or authorisation built-in so this
 basic view allows list/edit/add/create/read/update/delete as you'd
 expect.

=head2 Templates

 There are a number of things which ClearPress makes available to the
 template system. See ClearPress::view for a full list but the most
 important ones are:

 requestor   - an object (usually) representing the person requesting
               the page, if authentication is available.

 model       - the data model for the entity being viewed

 SCRIPT_NAME - very useful for building self-referential urls for
               links, forms, ajax etc.

 So person_list.tt2 might look like this:

 <table id="people">
  <caption>People</caption>
  <thead><tr><th>Id</th><th>Name</th><th>Initials</th></tr></thead>
  <tbody>
   [% FOREACH person = model.people %]
   <tr>
    <td>[% person.id_person %]</td>
    <td>[% person.forename | html %]</td>
    <td>[% person.initials | html %]</td>
   </tr>
   [% END %]
  </tbody>
 </table>

 person_add.tt2 might look like this:

 <form method="post" action="[% SCRIPT_NAME %]/person">
 <ul>
  <li><label for="forename">Forename</label><input type="text" name="forename" id="forename"/></li>
  <li><label for="surname">Surname</label>  <input type="text" name="surname"  id="surname" /></li>
  <li><label for="initials">Initials</label><input type="text" name="initials" id="initials"/></li>
 </ul>
 </form>

 person_create.tt2 might look like this:

 <h1>Person Created!</h1>
 Click <a href="[% SCRIPT_NAME %]/person/[% model.id_person %]">here</a> to continue.

 <script type="text/javascript">
  document.location.href="[% SCRIPT_NAME %]/person/[% model.id_person %]";
 </script>

=head1 SUBROUTINES/METHODS

 There are no methods in this module. It's purely for documentation
 purposes. See the POD for this module's dependencies for details of
 the guts.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

 Most configuration settings for ClearPress-based applications come
 form data/config.ini . Environment variables which have influential
 effects include in particular 'dev' (set to 'dev', 'test' or 'live')
 and DOCUMENT_ROOT, commonly set to './htdocs'.

=head1 DEPENDENCIES

=over

=item ClearPress::model

=item ClearPress::view

=item ClearPress::controller

=item ClearPress::util

=item strict

=item warnings

=item CGI

=item POSIX

=item Template

=item Lingua::EN::Inflect

=item HTTP::Server::Simple::CGI

=item Config::IniFiles

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

ClearPress is not an implementation of the classic MVC pattern, in
particular ClearPress views are more like classic MVC controllers, so
if you're expecting that, you may be disappointed. Having said that it
has been used extremely effectively in rapid development of a number
of production applications.

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
