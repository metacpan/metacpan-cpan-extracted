package Buscador;
use strict;
use vars qw($VERSION);
use base 'Maypole::Redirect';
#use base 'Apache::MVC';

$VERSION = "0.2";

#use Maypole::Cache;
use Buscador::Config;
Buscador->config->{cache_options}{class} = "Cache::FileCache";

use Maypole::Constants;
our $home;
sub debug() {0}

BEGIN { 
    require Email::Store;

    Email::Store->import(Buscador::Config->dsn, verbose => 1 );

    use Module::Pluggable           search_path => [ "Email::Store" ], sub_name => 'stores', require => 1;
    use Module::Pluggable::Ordered  search_path => [ "Buscador" ];
    
    $home = Buscador::Config->home;
    Buscador->config->{cache_options}{class} = "Cache::FileCache";
    Buscador->config->{model} = "Maypole::Model::CDBI::Plain";

    
    # this is a bit of an egregious hack
    # perhaps plugins should specifically state whether they
    # are capable of being set up or not
    my @stores = sort grep { !/(DBI|Addressing)$/ }
                      grep { !/SUPER$/ } 
                      grep { $_->can("table") } 
                      Buscador->stores;


    
    # not needed any more
    #@stores =  sort qw/ Email::Store::Mail Email::Store::List  Email::Store::Date
    #Email::Store::Entity Email::Store::Entity::Name Email::Store::Attachment
    #Email::Store::Entity::Address Email::Store::NamedEntity Email::Store::Vote /;


    Buscador->setup([ @stores ]); 
};

Buscador->config->{rows_per_page}         = 10;
Buscador->config->{template_root}         = "$home/templates";
Buscador->config->{uri_base}              = Buscador::Config->uri;
Buscador->config->{img_base}              = Buscador::Config->image_uri;

Buscador->config->{uri_base} .= "/" unless Buscador->config->{uri_base} =~ m!/$!;
Buscador->config->{img_base} .= "/" unless Buscador->config->{img_base} =~ m!/$!;


$Email::Store::Plucene::index_path         = "$home/emailstore-index";
$Plucene::QueryParser::DefaultOperator    = "AND";



sub parse_path {
    my $self = shift;

    Buscador->call_plugins("parse_path", $self);
    $self->SUPER::parse_path();
}
1;

__END__

=head1 NAME

Buscador - a dynamic mail archiver with a twist

=head1 DESCRIPTION

Buscador is web based mail archival and retrieval tool based 
around the concept of Intertwingle :

    http://www.mozilla.org/blue-sky/misc/199805/intertwingle.html

In essence it provides a variety of different views on the mail
using a system of plugins. Plugins provided include ones to
show thread views, date views, seperation into mailing lists, 
extraction of named entities and Atom feeds for recent mails,
per thread, per list and per person and for handling mailing.


=head1 WARNING!

Buscador is distinctly B<ALPHA> level software and details of its
architecture could change at anytime. Be prepared for DB changes 
and plugin system gutting and rebuilding by reading the safety
card in the pocket in front of you and bracing you hands over your head
in the event of catastrophic architecture rethinking.

=head1 INSTALL

=head2 Install dependencies

There's a C<Bundle::Buscador> available from

    http://thegestalt.org/simon/perl/Bundle-Buscador-0.1.tar.gz

however some people have had problems installing some of these. 
Namely 

    Apache::Request
    Class::DBI::AsForm
    Email::MIME
    Email::MIME::Attachment::Stripper
    Mail::ListDetector

And, in particular C<SQL::Translator>. C<SQL::Translator> 
installs a lot of weird things such as C<GD>, C<Graphviz> 
and C<Spreadsheet::ParseExcel>.

A cut down version of C<SQL::Translator> without these 
dependencies is available from

     http://thegestalt.org/simon/perl/SQL-Translator-0.05-lite.tar.gz

=head2 Create config file

Make a directory in your web root, cd into it and do

    % buscador -init

this will copy some templates and some images into the directory and 
then generate a sample config file. You should edit the config file.

You might want to move your chrome directory outside your new buscador 
directory and alter your config accordingly. That way Maypole (which 
Buscador is based on) doesn't try and first see if there's a table 
called 'chrome' before passing through to the actual chrome directory
and also won't fill your logs with errors.


=head2 Import some mails

Run

        % buscador -setup

and then

        % buscador /path/to/mail/folder


=head2 Create Apache config

Something like


   <Location /buscador>
        SetHandler perl-script
        PerlHandler Buscador
   </Location>

but changed to whatever directory you wnat to install it under.


If you're using the default SQLite db remember to make sure that
the web server has enough access to read it and get a lock.

=head1 PLUGINS

The plugin system is based around C<Module::Pluggable::Ordered>.
Each plugin get the chance to influence the path being passed in.
The order that they are called in is set by the B<parse_path_order>
method, the lower the return value the higher the priority.
For example:

    package Buscador::Foo;

    # we're middling important
    sub parse_path_order { 13 }     

    sub parse_path {
        my ($self, $buscador) = @_;

        # buscador is an alias for search
        $buscador->{path} =~ s!/buscador/!/search/!;
        
    }

    1;

however they don't have to touch the path at all and can simply 
install methods in other namespaces;


    package Buscador::Bar;
    
    # this is where path parsing methods would go

    package Email::Store::Mail;
    use Fortune;

    sub bar :Exported {
        my $fortune = Fortune ('fortunefile')->read_header()->get_random_fortune();
        $r->{template_args}{fortune} = $fortune;
        $r->{template}               = "fortune";
    }

    1;


And now, if we write a 'fortune' template and go to 

    http://example.com/buscador/mail/bar

we'll be presented with a fortune.

=head1 BUGS

Lots and lots. And then some more 

=over 4

=item UTF8 doesn't work properly.

This needs serious testing.

=item The templates are ugly.

I have a vague design in mind. We could also do with having themes.

=item see TODO file

=back

=head1 AUTHOR

Originally Simon Cozens, E<lt>simon@cpan.orgE<gt>
Now maintained by Simon Wistow, E<lt>simon@thegestalt.orgE<gt>

=head1 SUPPORT

This module is part of the Siesta project - http://siesta.unixbeard.net

There is a mailing list at siesta-dev@siesta.unixbeard.net (subscribe at siesta-dev-sub@siesta.unixbeard.net).

SVN/DAV access is available via http://siesta.unixbeard.net/svn/trunk/buscador/


=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Simon Cozens and Simon Wistow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
