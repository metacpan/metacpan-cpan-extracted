package CGI::Application::Plugin::Menu;
use strict;
use LEOCHARRE::DEBUG;
use warnings;
use Carp;
use Exporter;
use HTML::Template::Menu;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw/ Exporter /;
@EXPORT = qw(menu ___menus_ ___menus_order menus menus_count menu_delete);
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;

sub menu {
   my ($self,$label) = @_;
   $label ||= 'main';
   
   unless ( exists $self->___menus_->{$label} ) {
      $self->___menus_->{$label} = 
         # new CGI::Application::Plugin::MenuObject;
         new HTML::Template::Menu;
         
      $self->___menus_->{$label}->name_set($label);
      push @{$self->___menus_order},$label;
   }
   return $self->___menus_->{$label};
}

*menus = \&___menus_order;

sub ___menus_ {
   $_[0]->{'__CGI::Application::Plugin::Menu::Objects'} ||={};
   $_[0]->{'__CGI::Application::Plugin::Menu::Objects'};
}

sub ___menus_order {
   $_[0]->{'__CGI::Application::Plugin::Menu::ObjectsOrder'} ||=[];
   $_[0]->{'__CGI::Application::Plugin::Menu::ObjectsOrder'};
}

sub menus_count { scalar @{$_[0]->menus} }

sub menu_delete { 
   my $self = shift;
   my $label = shift;
   delete $self->___menus_->{$label};

   my @order;
   for my $menu_label ( @{$self->___menus_order} ){
      $menu_label eq $label and next;
      push @order, $menu_label;
   }
   $self->{'__CGI::Application::Plugin::Menu::ObjectsOrder'} = \@order;

   1;
}
   


1;



__END__

=pod

=head1 NAME

CGI::Application::Plugin::Menu - manage navigation menus for cgi apps

=head1 SYNOPSIS
  
   use base 'CGI::Application';   
   use CGI::Application::Plugin::Menu;

   sub _get_menu_outputs {
      my $self = shift;
   
      my $html_output;
   
      my $menu_main  = $self->menu;
   
      # resolves to a 'Home' link
      $menu_main->add('/');
      
      # makes into runmodelink for CGI::Application 
      # <a href='?rm=view_stats'>View Statistics</a>
      $menu_main->add( view_stats, 'View Statistics'); # with label
      
      # makes into runmodelink for CGI::Application 
      # <a href='?rm=view_history'>View History</a>   
      $menu_main->add('view_history'); # label is optional
         
      
      my $menu_info = $self->menu('info');
      $menu_info->add('/about_us.html');
      $menu_info->add('/contact_info.html');
      
      $html_output .= 
         $menu_main->output
         . $menu_info->output;
   
      return $html_output;   
   }


=head1 EXAMPLE USAGE 1

   sub _inject_menus_into_tmpl {
      my ($self,$tmpl) = @_;
   
      my $m = $self->menu;
   
      $m->add('home'); # ?rm=home / 'Home'
      $m->add('account_view'); # ?rm=account_view / Account View
      $m->add('account_edit','edit bogus'); # ?rm=account_edit / edit bogus
      $m->add('account_delete');
      $m->add('/info.html'); # /info.html / Info
   
      $tmpl->param( MENU_LOOP => $m->loop);   
   }


=head1 EXAMPLE USAGE 2

   sub _set_menus_in_template {
      my $self = shift;
   
   
      my $m = $self->menu('main');
   
      $m->add('home','home page');
      $m->add('view_stats');
      $m->add('http://cpan.org','visit cpan');
   
      $m->name; # returns 'main', for this example
   
      # GETTING THE HTML TEMPLATE LOOP
   
      my $main_menu_loop = $m->loop; 
   
      my $tmpl = $self->this_method_returns_HTML_Template_object;
      
      $tmpl->param( 'MAIN_MENU' => $main_menu_loop );
   
      #or
      $tmpl->param( 'MAIN_MENU' => $self->menu_get('main_menu')->loop );   
   
      # IN YOUR HTML TEMPLATE:
      # 
      # <ul>
      #  <TMPL_LOOP MAIN_MENU>  
      #  <li><a href="<TMPL_VAR URL>"><TMPL_VAR LABEL></a></li>
      #  </TMPL_LOOP>
      # </ul>
   
      return 1;
   }

=head1 DESCRIPTION

This is a simple way of having menus in your cgi apps.

=head1 METHODS

=head2 menu()

if you don't provide an argument, the default is used, which is 'main'.
returns HTML::Template::Menu A MENU OBJECT object.

=head2 menus()

returns array ref of names of menus that exist now.
They are in the order that they were instanced

   my $m0 = $self->menu('main');
   $m0->add('home');
   $m0->add('news');
   
   my $m1 = $self->menu('session');
   $m1->add('logout');
   $m1->add('login_history');
   
   for ( @{$self->menus} ){
      my $m = $_;
      my $menu_name = $m->name;
      my $loop_for_html_template = $m->loop;
   }


=head1 A MENU OBJECT

Are instances of HTML::Template::Menu

=head2 METHODS

=head3 name()

returns name of the menu.

=head3 add()

argument is url or runmode
optional argument is label 

If the first argument has no funny chars, it is treated as a runmode.

The label is what will appear in the link text
If not provided, one will be made. 
If you have a runmode called see_more, the link text is "See More".

The link will be 

   <a href="?=$YOURRUNMODEPARAMNAME=$ARG1">$ARG2</a>

So in this example:

   $m->add('view_tasks');

The result is:

   <a href="?rm=view_tasks">View Tasks</a>

=head3 loop()

   get loop suitable for HTML::Template object
   See SYNOPSIS.

=head2 output()

   If you just want the output with the default hard coded template.
   The default template code is stored in:

   $HTML::Template::Menu::DEFAULT_TMPL

=head2 menu_delete()

Argument is menu label, deletes the menu.
Returns true, does not check for existance.

=head2 ADDING MENU ITEMS

   my $m = $self->menu_get('main menu');

   $m->add('home');   
   $m->add('http://helpme.com','Need help?');
   $m->add('logout');

   Elements for the menu are shown in the order they are inserted.


=head1 AUTOMATICALLY GENERATING A MENU

See CGI::Application::Plugin::AutoMenuitem


=head1 SEE ALSO

L<CGI::Application>
L<HTML::Template>
L<HTML::Template::Menu>


=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut



